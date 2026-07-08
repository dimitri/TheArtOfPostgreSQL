package main

import (
	"os"
	"path/filepath"
	"strings"
)

type QueryIndex struct {
	ByPath map[string]QueryFile
	ByID   map[string]QueryFile
}

// queryFileExtensions lists every file type toc.txt references alongside
// .sql queries — .py/.java code samples and .diff patches shown for
// reading, not execution (see handleQueryExecute's read-only guard and the
// frontend's readonly-script editor mode). handleQueryFile tries these in
// order when resolving a queryID that has no extension of its own.
var queryFileExtensions = []string{".sql", ".py", ".java", ".diff"}

// languageForPath returns the editor language for a file's extension and
// whether that extension is one query-ui indexes/serves at all.
func languageForPath(path string) (lang string, ok bool) {
	switch {
	case strings.HasSuffix(path, ".sql"):
		return "sql", true
	case strings.HasSuffix(path, ".py"):
		return "python", true
	case strings.HasSuffix(path, ".java"):
		return "java", true
	case strings.HasSuffix(path, ".diff"):
		return "diff", true
	default:
		return "", false
	}
}

type QueryFile struct {
	Path     string
	RelPath  string // Relative to queries dir
	Filename string
	Content  string
	Language string // sql, py, etc
}

func IndexQueries(queriesDir string) (*QueryIndex, error) {
	idx := &QueryIndex{
		ByPath: make(map[string]QueryFile),
		ByID:   make(map[string]QueryFile),
	}

	// Walk all files
	err := filepath.Walk(queriesDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		// Only index file types actually referenced from toc.txt: .sql
		// queries plus their .py/.java/.diff companion scripts.
		lang, ok := languageForPath(path)
		if !ok {
			return nil
		}

		// Read file content
		content, err := os.ReadFile(path)
		if err != nil {
			return err
		}

		relPath, _ := filepath.Rel(queriesDir, path)

		qf := QueryFile{
			Path:     path,
			RelPath:  relPath,
			Filename: filepath.Base(path),
			Content:  string(content),
			Language: lang,
		}

		// Index by full path (as referenced in toc.txt)
		// toc.txt uses forward slashes, normalize our path
		tocPath := strings.ReplaceAll(relPath, string(filepath.Separator), "/")
		idx.ByPath[tocPath] = qf

		// Also index by query ID (e.g., "02-intro/02-usecase/03_01_factbook.sql" → "03_01_factbook")
		id := strings.TrimSuffix(filepath.Base(path), filepath.Ext(path))
		idx.ByID[id] = qf

		return nil
	})

	return idx, err
}

func (q *QueryFile) FirstLines(n int) string {
	lines := strings.Split(q.Content, "\n")
	if len(lines) > n {
		lines = lines[:n]
	}
	return strings.Join(lines, "\n")
}

func (q *QueryFile) Summary() string {
	// Try to extract first meaningful comment as description
	lines := strings.Split(strings.TrimSpace(q.Content), "\n")
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "--") {
			desc := strings.TrimPrefix(trimmed, "--")
			return strings.TrimSpace(desc)
		}
	}

	// Fallback: first line of SQL
	if len(lines) > 0 {
		return lines[0]
	}
	return ""
}
