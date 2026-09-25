package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLeadingNameComment(t *testing.T) {
	cases := []struct {
		name    string
		content string
		want    string
		wantOK  bool
	}{
		{
			name: "real query file shape",
			content: `-- name: list-albums-by-artist
-- List the album titles and duration of a given artist
  select album.title as album
    from album;`,
			want:   "list-albums-by-artist",
			wantOK: true,
		},
		{
			name:    "no name header at all",
			content: "select 1;",
			wantOK:  false,
		},
		{
			name: "a -- name:-shaped comment further down doesn't count",
			content: `-- List albums
-- name: not-the-first-line
select 1;`,
			wantOK: false,
		},
		{
			name: "blank lines before the header are skipped",
			content: "\n\n-- name: after-blank-lines\nselect 1;",
			want:    "after-blank-lines",
			wantOK:  true,
		},
		{
			name:    "empty name is not a match",
			content: "-- name:   \nselect 1;",
			wantOK:  false,
		},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got, ok := leadingNameComment(c.content)
			if ok != c.wantOK || got != c.want {
				t.Errorf("leadingNameComment(%q) = (%q, %v), want (%q, %v)", c.content, got, ok, c.want, c.wantOK)
			}
		})
	}
}

func TestIndexQueriesByName(t *testing.T) {
	dir := t.TempDir()
	sub := filepath.Join(dir, "03-writing-sql-queries", "06-application-use-case")
	if err := os.MkdirAll(sub, 0o755); err != nil {
		t.Fatal(err)
	}
	const content = "-- name: list-albums-by-artist\nselect 1;\n"
	if err := os.WriteFile(filepath.Join(sub, "05_01_album-by-artist.sql"), []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	// A file with no -- name: header must not show up in ByName at all —
	// distinct from being present with an empty key, which a naive
	// implementation could produce instead.
	if err := os.WriteFile(filepath.Join(sub, "05_02_no-header.sql"), []byte("select 2;\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	idx, err := IndexQueries(dir)
	if err != nil {
		t.Fatal(err)
	}

	qf, ok := idx.ByName["list-albums-by-artist"]
	if !ok {
		t.Fatal("expected \"list-albums-by-artist\" in ByName")
	}
	wantPath := "03-writing-sql-queries/06-application-use-case/05_01_album-by-artist.sql"
	if qf.RelPath != wantPath {
		t.Errorf("ByName[...].RelPath = %q, want %q", qf.RelPath, wantPath)
	}

	if _, ok := idx.ByName[""]; ok {
		t.Error("a headerless file must not be indexed under the empty-string key")
	}
	if len(idx.ByName) != 1 {
		t.Errorf("ByName has %d entries, want 1", len(idx.ByName))
	}
}
