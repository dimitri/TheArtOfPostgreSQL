# Query UI — Reference Guide

A local, interactive web app for browsing and running every query in this
repository, plus a guided Jupyter-style notebook version of the starter kit.
See [QUICKSTART_QUERY_UI.md](QUICKSTART_QUERY_UI.md) to get it running in
under a minute.

## Two views, one binary

### Book Queries (`/`)

- **Sidebar**: the full book table of contents, parsed from `toc.txt` —
  Parts → Chapters → Sections → individual query files.
- **Editor**: pick a query, it loads verbatim; edit freely before running.
- **Run**: executes against PostgreSQL, results render as a table. Cells
  that are GeoJSON or a query-built `<svg>...</svg>` string render as an
  inline map instead of raw text/JSON.
- **EXPLAIN**: three tabs — Text (Postgres's own `EXPLAIN ANALYZE` output),
  Diagram (a hand-rolled SVG tree view built from `EXPLAIN (FORMAT JSON,
  ANALYZE)`), and JSON (the raw plan).
- **Read-only / Read-write toggle**: queries run inside a `READ ONLY`
  transaction by default (real Postgres transaction-level enforcement, not a
  keyword blocklist) — flip the toggle for the handful of queries that need
  `CREATE`/`INSERT`/`UPDATE`/`DELETE`.
- **CSV export** of the current result set.

### Starter Kit (`/starter-kit.html`)

The same six-lab walkthrough as [`starter-kit/`](starter-kit/), rendered as
a notebook: markdown prose interleaved with runnable `sql` cells, each with
its own **▶ Run** button and output area — the source `.md` files are
literally re-parsed on every page load, so there's no separate content
format to keep in sync.

## Architecture

```
src/query-ui/
├── main.go              # server setup, routing, embeds frontend/dist/*
├── toc.go                # parses toc.txt into Part → Chapter → Section → Query
├── queries.go             # indexes every .sql/.py/.java/.diff under queries/
├── starterkit.go           # parses starter-kit/*.md into markdown/sql cells
├── markdown.go              # small hand-rolled Markdown → HTML renderer
├── handlers.go               # HTTP handlers: execute, explain, toc, starter-kit
├── db.go                      # pgx connection pool
├── psql.go                     # \d, \dt etc. psql-meta-command emulation
├── queryparams.go                # query-params.json → \set overrides
├── go.mod / go.sum
├── Dockerfile
└── frontend/dist/
    ├── index.html                # Book Queries SPA
    └── starter-kit.html            # Starter Kit notebook SPA
```

Both HTML files are complete, dependency-free single-page apps: no build
step, no npm, no CDN — everything (including the handful of Font Awesome
icons on the Starter Kit menu) is inlined directly in the file. The whole
frontend is compiled into the Go binary with `//go:embed frontend/dist/*`.

### Data flow

```
Book Queries:
  pick a query  → GET /api/query/{part}/{chapter}/{section}/{queryID}
  Run           → POST /api/query/execute   → table / inline map / error
  EXPLAIN       → POST /api/query/explain   → Text + Diagram + JSON tabs

Starter Kit:
  load page     → GET /api/starter-kit/{slug} → markdown + sql cells
  Run on a cell → POST /api/query/execute      → table or Map/Table tabs
```

## API Endpoints

```
GET  /health
GET  /api/toc
GET  /api/part/{partNum}
GET  /api/query/{part}/{chapter}/{section}/{queryID}
POST /api/query/execute     { "sql": "...", "read_write": false }
POST /api/query/explain     { "sql": "...", "read_write": false }
GET  /api/starter-kit
GET  /api/starter-kit/{slug}
```

## What's mounted vs. what's embedded — and why it matters for edits

| Path                          | How it reaches the container      | Reload needed after an edit |
|--------------------------------|-----------------------------------|------------------------------|
| `queries/`, `starter-kit/`, `toc.txt` | bind-mounted read-only, indexed once at startup | `docker compose restart query-ui` |
| `src/query-ui/**` (Go source + `frontend/dist/*.html`) | compiled into the binary via `go:embed` | `docker compose build query-ui && docker compose up -d query-ui` |

Sanity-check what a running container is actually serving:

```bash
curl -s http://localhost:8042/ | diff - src/query-ui/frontend/dist/index.html
```

An empty diff means it's current.

## Security model

- Every query runs inside an explicit `READ ONLY` or `READ WRITE`
  transaction (`pgx.TxOptions{AccessMode: ...}`), driven by the frontend's
  toggle — this is Postgres itself rejecting writes in read-only mode, not
  a client-side keyword filter.
- Runs against a local `postgres` service defined in `docker-compose.yml`;
  no authentication in front of the UI itself (it's a local dev tool).
- No query timeout is currently enforced server-side beyond Postgres's own
  defaults.

## Local development (outside Docker)

```bash
cd src/query-ui
go mod download
go build -o query-ui
DATABASE_URL=postgresql://taop:taop@localhost:5433/taop ./query-ui
# defaults: -port 8042 -queries ../../queries -toc ../../toc.txt -starter-kit ../../starter-kit
```

```bash
go test ./...
```
