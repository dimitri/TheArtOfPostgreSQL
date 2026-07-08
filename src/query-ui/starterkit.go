package main

import (
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// Cell is one unit of a starter-kit page: either narrative prose (already
// rendered to HTML) or a runnable SQL query, in the order they appear in
// the source file — the same alternating markdown/code-cell structure a
// Jupyter notebook uses, just expressed as plain Markdown with ```sql
// fences marking the code cells instead of a .ipynb JSON file.
type Cell struct {
	Type string `json:"type"` // "markdown" or "sql"
	HTML string `json:"html,omitempty"`
	SQL  string `json:"sql,omitempty"`
}

// StarterKitPage is one of the hand-picked starter-kit/NN-name.md files,
// each covering a single PostgreSQL feature end to end.
type StarterKitPage struct {
	Slug  string `json:"slug"`
	Title string `json:"title"`
	Cells []Cell `json:"cells,omitempty"`
}

// LoadStarterKit reads every NN-name.md file in dir (README.md is the
// directory's own explanatory text, not a page — excluded), sorted by
// filename so the numeric prefixes (01-, 02-, ...) control page order.
func LoadStarterKit(dir string) ([]StarterKitPage, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}

	var names []string
	for _, e := range entries {
		name := e.Name()
		if e.IsDir() || !strings.HasSuffix(name, ".md") || strings.EqualFold(name, "README.md") {
			continue
		}
		names = append(names, name)
	}
	sort.Strings(names)

	pages := make([]StarterKitPage, 0, len(names))
	for _, name := range names {
		content, err := os.ReadFile(filepath.Join(dir, name))
		if err != nil {
			return nil, err
		}

		slug := strings.TrimSuffix(name, ".md")
		pages = append(pages, StarterKitPage{
			Slug:  slug,
			Title: firstHeading(string(content), slug),
			Cells: ParseCells(string(content)),
		})
	}
	return pages, nil
}

// firstHeading extracts the text of a page's leading "# Title" line, so the
// nav menu can show a real title instead of the raw filename; falls back to
// the slug if the file has no top-level heading.
func firstHeading(content, fallback string) string {
	for _, line := range strings.Split(content, "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "# ") {
			return strings.TrimSpace(strings.TrimPrefix(trimmed, "# "))
		}
	}
	return fallback
}

// ParseCells splits a page's markdown source into cells on ```sql ... ```
// fences: everything outside such a fence is one markdown cell (rendered
// via renderMarkdown, which itself understands the *other* kinds of fence —
// plain ``` output blocks and ```bash — as preformatted text, not cells),
// everything inside a ```sql fence becomes one runnable SQL cell verbatim.
func ParseCells(source string) []Cell {
	var cells []Cell
	lines := strings.Split(source, "\n")

	var buf []string
	inSQL := false

	flushMarkdown := func() {
		text := strings.TrimSpace(strings.Join(buf, "\n"))
		if text != "" {
			cells = append(cells, Cell{Type: "markdown", HTML: renderMarkdown(text)})
		}
		buf = nil
	}
	flushSQL := func() {
		text := strings.TrimRight(strings.Join(buf, "\n"), "\n")
		if strings.TrimSpace(text) != "" {
			cells = append(cells, Cell{Type: "sql", SQL: text})
		}
		buf = nil
	}

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "```sql" {
			flushMarkdown()
			inSQL = true
			continue
		}
		if inSQL && trimmed == "```" {
			flushSQL()
			inSQL = false
			continue
		}
		buf = append(buf, line)
	}

	if inSQL {
		flushSQL() // unterminated fence: still surface the SQL rather than drop it
	} else {
		flushMarkdown()
	}

	return cells
}
