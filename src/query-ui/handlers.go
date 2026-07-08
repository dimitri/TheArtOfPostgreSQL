package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
)

// writeJSONError writes {"error": message} with the given status code. Every
// endpoint here otherwise returns JSON, and the frontend calls res.json()
// on responses; a plain-text http.Error() body fails that parse and surfaces
// a confusing "Failed to load query: <JSON parse error>" instead of the
// actual problem.
func writeJSONError(w http.ResponseWriter, status int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{"error": message})
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "ok",
		"mode":   "local",
		"port":   s.port,
	})
}

func (s *Server) handleTOC(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(s.toc)
}

func (s *Server) handlePart(w http.ResponseWriter, r *http.Request) {
	partNum := chi.URLParam(r, "partNum")

	var partInt int
	if n, err := fmt.Sscanf(partNum, "%d", &partInt); err != nil || n == 0 {
		writeJSONError(w, 400, "Invalid part number")
		return
	}

	for _, part := range s.toc.Parts {
		if part.Num == partInt {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(part)
			return
		}
	}

	writeJSONError(w, 404, "Part not found")
}

func (s *Server) handleQueryFile(w http.ResponseWriter, r *http.Request) {
	// URL: /api/query/{part}/{chapter}/{section}/{queryID}
	// Reconstruct path: chapter/section/queryID.sql

	chapter := chi.URLParam(r, "chapter")
	section := chi.URLParam(r, "section")
	queryID := chi.URLParam(r, "queryID")

	// Build the path as referenced in toc.txt, trying every extension
	// query-ui indexes (.sql, then its .py/.java/.diff companions).
	var query QueryFile
	var found bool
	var tocPath string
	for _, ext := range queryFileExtensions {
		tocPath = fmt.Sprintf("%s/%s/%s%s", chapter, section, queryID, ext)
		if query, found = s.queries.ByPath[tocPath]; found {
			break
		}
	}
	if !found {
		writeJSONError(w, 404, fmt.Sprintf("Query not found: %s/%s/%s.*", chapter, section, queryID))
		return
	}

	content := query.Content
	if setLines, ok := s.queryParams[tocPath]; ok && len(setLines) > 0 {
		// This query shows bare :name/:n parameters in the book to
		// illustrate values coming from application code, not from psql
		// \set — running it as-is would hit an unresolved ":name" and fail.
		// query-params.json supplies the \set line(s) to prepend so it's
		// directly runnable here; the .sql file on disk is untouched.
		content = "-- The \\set line(s) below were added by query-ui (see query-params.json),\n" +
			"-- not part of the book's source file, so this example can be run directly.\n" +
			strings.Join(setLines, "\n") + "\n\n" + content
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"id":       queryID,
		"path":     query.RelPath,
		"content":  content,
		"language": query.Language,
		"summary":  query.Summary(),
	})
}

type QueryExecuteRequest struct {
	SQL       string `json:"sql"`
	ReadWrite bool   `json:"read_write"`
}

type QueryResult struct {
	Columns    []string                 `json:"columns"`
	Rows       []map[string]interface{} `json:"rows"`
	RowCount   int                      `json:"row_count"`
	CommandTag string                   `json:"command_tag,omitempty"`
	TimingMS   float64                  `json:"timing_ms"`
	Error      string                   `json:"error,omitempty"`
}

// accessMode picks the transaction's access mode from the request's
// read_write flag: false (the default) is pgx.ReadOnly, matching prior
// behavior exactly for anyone not opting in to the toggle.
func accessMode(readWrite bool) pgx.TxAccessMode {
	if readWrite {
		return pgx.ReadWrite
	}
	return pgx.ReadOnly
}

// finishTx commits on success in read-write mode (so CREATE TABLE/INSERT/
// UPDATE/DELETE actually persist) or rolls back otherwise — read-only mode
// always rolls back regardless of outcome, and any error always rolls back
// regardless of mode. Call via defer; committing before the deferred
// Rollback runs makes that later Rollback a harmless no-op (pgx returns
// ErrTxClosed, which is expected and ignored here).
func finishTx(ctx context.Context, tx pgx.Tx, readWrite bool, succeeded bool) {
	if readWrite && succeeded {
		tx.Commit(ctx)
		return
	}
	tx.Rollback(ctx)
}

func (s *Server) handleQueryExecute(w http.ResponseWriter, r *http.Request) {
	var req QueryExecuteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, 400, "Invalid request")
		return
	}

	sql := strings.TrimSpace(req.SQL)
	if sql == "" {
		writeJSONError(w, 400, "Empty query")
		return
	}

	// Handle \set variable assignment and :name / :'name' / :"name"
	// substitution the way psql does client-side; strip other meta-commands
	// (\pset, \copy) that PostgreSQL itself can't execute.
	sql = strings.TrimSpace(preprocessPsqlScript(sql, map[string]string{}))
	if sql == "" {
		writeJSONError(w, 400, "Query is empty after removing psql meta-commands")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	start := time.Now()

	// Read-only (the default) rejects any write attempt (INSERT, UPDATE,
	// CREATE, sequence nextval(), etc.) at the Postgres level rather than
	// pattern-matching keywords — a plain "WITH cte AS (...) SELECT ..."
	// (no data-modifying CTE) is correctly allowed, which a keyword
	// blocklist could not tell apart from "WITH RECURSIVE" without also
	// blocking harmless CTEs. Read-write is an explicit opt-in per request
	// (the frontend's mode toggle) so CREATE TABLE and friends can run.
	tx, err := s.db.BeginTx(ctx, pgx.TxOptions{AccessMode: accessMode(req.ReadWrite)})
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(QueryResult{Error: err.Error()})
		return
	}
	succeeded := false
	defer func() { finishTx(ctx, tx, req.ReadWrite, succeeded) }()

	// Execute query. Simple protocol (rather than the default extended
	// protocol) supports semicolon-separated multi-statement text such as
	// `set lc_time to 'fr_FR'; select ...;` (queries/05-data-types/
	// 23-pg-data-types-101/11_06.sql) — the extended protocol rejects that
	// outright with "cannot insert multiple commands into a prepared
	// statement", exactly the kind of thing a real psql session runs fine.
	rows, err := tx.Query(ctx, sql, pgx.QueryExecModeSimpleProtocol)
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(QueryResult{
			Error: err.Error(),
		})
		return
	}
	defer rows.Close()

	// Get column descriptions
	var columnNames []string
	for _, fd := range rows.FieldDescriptions() {
		columnNames = append(columnNames, string(fd.Name))
	}

	// Fetch all rows
	var resultRows []map[string]interface{}
	for rows.Next() {
		values, err := rows.Values()
		if err != nil {
			break
		}

		rowMap := make(map[string]interface{})
		for i, col := range columnNames {
			if i < len(values) {
				rowMap[col] = values[i]
			}
		}
		resultRows = append(resultRows, rowMap)
	}

	// rows.Next() returns false both at natural end-of-data AND on error (e.g.
	// "cannot execute DROP TABLE in a read-only transaction" surfaces here,
	// not from the earlier tx.Query() call) — rows.Err() is the only way to
	// tell those apart, and skipping it silently swallowed exactly the write
	// attempts the read-only transaction is supposed to report.
	if err := rows.Err(); err != nil {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(QueryResult{Error: err.Error()})
		return
	}

	// CommandTag (e.g. "CREATE TABLE", "INSERT 0 3", "SELECT 10") is only
	// meaningful once rows are fully consumed, and is most useful in
	// read-write mode where a DDL/DML statement has no result rows at all.
	succeeded = true
	result := QueryResult{
		Columns:    columnNames,
		Rows:       resultRows,
		RowCount:   len(resultRows),
		CommandTag: rows.CommandTag().String(),
		TimingMS:   time.Since(start).Seconds() * 1000,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

type ExplainResult struct {
	Plan     json.RawMessage `json:"plan"`
	Text     string          `json:"text,omitempty"`
	TimingMS float64         `json:"timing_ms"`
	Error    string          `json:"error,omitempty"`
}

func (s *Server) handleQueryExplain(w http.ResponseWriter, r *http.Request) {
	var req QueryExecuteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, 400, "Invalid request")
		return
	}

	sql := strings.TrimSpace(req.SQL)
	if sql == "" {
		writeJSONError(w, 400, "Empty query")
		return
	}

	// Handle \set variable assignment and :name / :'name' / :"name"
	// substitution the way psql does client-side; strip other meta-commands
	// (\pset, \copy) that PostgreSQL itself can't execute.
	sql = strings.TrimSpace(preprocessPsqlScript(sql, map[string]string{}))
	if sql == "" {
		writeJSONError(w, 400, "Query is empty after removing psql meta-commands")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	start := time.Now()

	// EXPLAIN ANALYZE executes the query (including any side effects, if it's
	// a write wrapped in EXPLAIN ANALYZE), so it respects the same read-write
	// toggle as handleQueryExecute — see accessMode/finishTx above.
	tx, err := s.db.BeginTx(ctx, pgx.TxOptions{AccessMode: accessMode(req.ReadWrite)})
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(ExplainResult{Error: err.Error()})
		return
	}
	succeeded := false
	defer func() { finishTx(ctx, tx, req.ReadWrite, succeeded) }()

	// EXPLAIN (FORMAT JSON, ANALYZE) drives the Diagram tab.
	explainSQL := "EXPLAIN (FORMAT JSON, ANALYZE) " + sql
	var planJSON string

	err = tx.QueryRow(ctx, explainSQL, pgx.QueryExecModeSimpleProtocol).Scan(&planJSON)
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(ExplainResult{
			Error: err.Error(),
		})
		return
	}

	// The Text tab is Postgres's own default-format EXPLAIN ANALYZE output,
	// fetched and shown verbatim rather than reconstructed from the JSON
	// plan — Postgres already produces exactly the indentation/layout that
	// output is supposed to have. This is a *second* EXPLAIN ANALYZE
	// execution of the same statement, which is harmless for a read-only
	// SELECT but would re-run (and re-apply) a write statement a second
	// time in read-write mode — skipped there; the Diagram/JSON tabs still
	// work from the single JSON explain above.
	var explainText string
	if !req.ReadWrite {
		textRows, textErr := tx.Query(ctx, "EXPLAIN (ANALYZE) "+sql, pgx.QueryExecModeSimpleProtocol)
		if textErr == nil {
			var lines []string
			for textRows.Next() {
				var line string
				if scanErr := textRows.Scan(&line); scanErr == nil {
					lines = append(lines, line)
				}
			}
			textRows.Close()
			explainText = strings.Join(lines, "\n")
		}
	}

	succeeded = true
	result := ExplainResult{
		Plan:     json.RawMessage(planJSON),
		Text:     explainText,
		TimingMS: time.Since(start).Seconds() * 1000,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

// handleStarterKit returns the parsed starter-kit.md notebook: an ordered
// list of markdown (prose) and sql (runnable) cells, for the /starter-kit
// page to render Jupyter-style — narrative and code interleaved, each SQL
// cell runnable independently via the existing /api/query/execute endpoint.
// handleStarterKit returns the page index (slug + title only, no cells —
// the /starter-kit.html landing menu needs just enough to list and link to
// each page, not their full content).
func (s *Server) handleStarterKit(w http.ResponseWriter, r *http.Request) {
	index := make([]map[string]string, len(s.starterKit))
	for i, page := range s.starterKit {
		index[i] = map[string]string{"slug": page.Slug, "title": page.Title}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"pages": index,
	})
}

// handleStarterKitPage returns one page's full cell list: the markdown
// (prose) and sql (runnable) cells for /starter-kit.html to render
// Jupyter-style — narrative and code interleaved, each SQL cell runnable
// independently via /api/query/execute.
func (s *Server) handleStarterKitPage(w http.ResponseWriter, r *http.Request) {
	slug := chi.URLParam(r, "slug")

	for _, page := range s.starterKit {
		if page.Slug == slug {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(page)
			return
		}
	}

	writeJSONError(w, 404, "Starter kit page not found: "+slug)
}

// Middleware to enable CORS (useful for frontend development)
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		next.ServeHTTP(w, r)
	})
}
