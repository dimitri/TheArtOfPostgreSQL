package main

import (
	"strings"
	"testing"
)

func TestParseCells(t *testing.T) {
	source := "# Intro\n\nSome **bold** prose with a [link](https://example.com).\n\n" +
		"```sql\nSELECT 1;\n```\n\n" +
		"More prose after.\n\n" +
		"```sql\nSELECT 2;\n```\n"

	cells := ParseCells(source)

	if len(cells) != 4 {
		t.Fatalf("expected 4 cells, got %d: %+v", len(cells), cells)
	}

	if cells[0].Type != "markdown" || !strings.Contains(cells[0].HTML, "<h1>Intro</h1>") {
		t.Errorf("cell 0: expected markdown with h1, got %+v", cells[0])
	}
	if !strings.Contains(cells[0].HTML, "<strong>bold</strong>") {
		t.Errorf("cell 0: expected bold rendering, got %s", cells[0].HTML)
	}
	if !strings.Contains(cells[0].HTML, `<a href="https://example.com"`) {
		t.Errorf("cell 0: expected link rendering, got %s", cells[0].HTML)
	}

	if cells[1].Type != "sql" || cells[1].SQL != "SELECT 1;" {
		t.Errorf("cell 1: expected sql 'SELECT 1;', got %+v", cells[1])
	}

	if cells[2].Type != "markdown" || !strings.Contains(cells[2].HTML, "More prose after") {
		t.Errorf("cell 2: expected markdown prose, got %+v", cells[2])
	}

	if cells[3].Type != "sql" || cells[3].SQL != "SELECT 2;" {
		t.Errorf("cell 3: expected sql 'SELECT 2;', got %+v", cells[3])
	}
}

func TestRenderMarkdownEscapesHTML(t *testing.T) {
	html := renderMarkdown("A query like <script>alert(1)</script> should not execute.")
	if strings.Contains(html, "<script>") {
		t.Errorf("expected HTML to be escaped, got %s", html)
	}
}

func TestRenderMarkdownList(t *testing.T) {
	html := renderMarkdown("- one\n- two\n- three")
	if !strings.Contains(html, "<ul>") || strings.Count(html, "<li>") != 3 {
		t.Errorf("expected a 3-item list, got %s", html)
	}
}

// A generic (non-```sql) fence, as used in 01-nested-lateral.md to show
// \dt output, must render as preformatted text — not be swallowed as a SQL
// cell (ParseCells only pulls out ```sql fences) and not have its
// box-drawing/alignment mangled by paragraph reflow.
func TestRenderMarkdownGenericFence(t *testing.T) {
	html := renderMarkdown("Some text.\n\n```\n taop@taop=# \\dt sandbox.*\n col1 │ col2\n```\n\nMore text.")
	if !strings.Contains(html, `<pre class="md-code-block">`) {
		t.Errorf("expected a preformatted code block, got %s", html)
	}
	if !strings.Contains(html, "col1 │ col2") {
		t.Errorf("expected box-drawing content preserved verbatim, got %s", html)
	}
}

func TestRenderMarkdownBlockquote(t *testing.T) {
	html := renderMarkdown("> This example is drawn from Chapter 15 of *The Art of PostgreSQL*, **Group By,\n> Having, With, Union All**.")
	if !strings.Contains(html, "<blockquote><p>") {
		t.Errorf("expected a blockquote wrapper, got %s", html)
	}
	if strings.Contains(html, "&gt;") {
		t.Errorf("expected the leading '> ' markers stripped, not rendered as text, got %s", html)
	}
	if !strings.Contains(html, "Having, With, Union All") {
		t.Errorf("expected the two source lines merged into one paragraph, got %s", html)
	}
}

func TestRenderMarkdownImage(t *testing.T) {
	html := renderMarkdown("![The ten nearest pubs](img/fig-pubs-knn.png)")
	if !strings.Contains(html, `<img src="/starter-kit-assets/img/fig-pubs-knn.png" alt="The ten nearest pubs"`) {
		t.Errorf("expected image tag rewritten to /starter-kit-assets/, got %s", html)
	}
}

// Integration check against the real starter-kit/ directory: every page
// must parse to at least one SQL cell (a page with zero runnable cells
// would mean ParseCells silently failed to recognize its ```sql fences).
func TestLoadRealStarterKit(t *testing.T) {
	pages, err := LoadStarterKit("../../starter-kit")
	if err != nil {
		t.Fatalf("LoadStarterKit failed: %v", err)
	}
	if len(pages) != 6 {
		t.Fatalf("expected 6 pages, got %d: %v", len(pages), pageSlugs(pages))
	}
	for _, page := range pages {
		sqlCells := 0
		for _, c := range page.Cells {
			if c.Type == "sql" {
				sqlCells++
			}
		}
		if sqlCells == 0 {
			t.Errorf("page %q parsed with zero SQL cells — likely a ```sql fence not recognized", page.Slug)
		}
		if page.Title == page.Slug {
			t.Errorf("page %q has no distinct title — missing top-level # heading?", page.Slug)
		}
	}
}

func pageSlugs(pages []StarterKitPage) []string {
	slugs := make([]string, len(pages))
	for i, p := range pages {
		slugs[i] = p.Slug
	}
	return slugs
}

// Reproduces the reported bug: 02-grouping-sets.md's numbered walkthrough
// has multi-paragraph items and one indented "ERROR: ..." console-output
// line — that line must render as a <pre> code block, not get flattened
// into ordinary paragraph prose, and each numbered item must render as a
// proper <li> (not lose its list structure/indentation).
func TestRenderMarkdownNumberedListWithCodeBlock(t *testing.T) {
	md := "  1. First item text\n     continues here.\n\n" +
		"     Second paragraph in the same item:\n\n" +
		"        ERROR:  aggregate function calls cannot be nested\n\n" +
		"     Third paragraph after the error.\n\n" +
		"  2. Second item."

	html := renderMarkdown(md)

	if !strings.Contains(html, "<ol>") {
		t.Fatalf("expected an ordered list, got %s", html)
	}
	if strings.Count(html, "<li>") != 2 {
		t.Errorf("expected 2 list items, got %s", html)
	}
	if !strings.Contains(html, `<pre class="md-code-block">ERROR:  aggregate function calls cannot be nested</pre>`) {
		t.Errorf("expected the ERROR line as a preformatted block, got %s", html)
	}
	if !strings.Contains(html, "<p>First item text continues here.</p>") {
		t.Errorf("expected first paragraph joined and wrapped, got %s", html)
	}
	if !strings.Contains(html, "<p>Third paragraph after the error.</p>") {
		t.Errorf("expected paragraph after code block preserved, got %s", html)
	}
}

func TestRenderMarkdownWrappedListItemNoBlankLine(t *testing.T) {
	md := "1. The **base case** seeds the result — here, the single\n   outlet reach.\n" +
		"2. The **recursive term** refers back."

	html := renderMarkdown(md)
	if !strings.Contains(html, "<li>The <strong>base case</strong> seeds the result — here, the single outlet reach.</li>") {
		t.Errorf("expected wrapped continuation line joined with a space, got %s", html)
	}
}

// 02-grouping-sets.md uses a "~~~ psql" tilde fence (a valid CommonMark
// fence style distinct from ```) around a formatted result table — it must
// render as preformatted text like a ``` fence would, not fall through to
// paragraph reflow (which would collapse the box-drawing table layout).
func TestRenderMarkdownTildeFence(t *testing.T) {
	md := "Some intro text.\n\n~~~ psql\n season │ champion\n════════╪═════════\n   1950 │ Farina\n~~~\n\nAfter."
	html := renderMarkdown(md)

	if !strings.Contains(html, `<pre class="md-code-block">`) {
		t.Fatalf("expected a preformatted block, got %s", html)
	}
	if !strings.Contains(html, "season │ champion") {
		t.Errorf("expected table content preserved verbatim, got %s", html)
	}
	if !strings.Contains(html, "<p>After.</p>") {
		t.Errorf("expected content after the closing fence to resume as a paragraph, got %s", html)
	}
}
