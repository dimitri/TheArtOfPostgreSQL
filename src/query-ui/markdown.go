package main

import (
	"regexp"
	"strings"
)

// renderMarkdown is a small, hand-rolled Markdown-to-HTML renderer covering
// exactly what the starter-kit pages actually use: headers, paragraphs,
// bold/italic/inline code, links, images, ordered/unordered lists (including
// multi-paragraph list items and an indented "console output" block within
// one, as used in 02-grouping-sets.md's numbered walkthrough), and fenced
// code blocks (```sql fences are pulled out as separate runnable cells
// before this ever runs — see ParseCells — so any ``` fence reaching here
// is either a generic output-display block or ```bash, both rendered as
// plain preformatted text). Pulling in a full CommonMark library would be
// the only alternative for something this narrow, and it doesn't fit a
// project whose query-ui binary is otherwise entirely dependency-light
// (chi + pgx are the only two).
func renderMarkdown(md string) string {
	lines := strings.Split(md, "\n")
	var out strings.Builder
	i := 0
	n := len(lines)

	for i < n {
		trimmed := strings.TrimSpace(lines[i])

		if trimmed == "" {
			i++
			continue
		}

		if isFenceLine(trimmed) {
			i = renderFence(lines, i, &out)
			continue
		}

		if m := headerRE.FindStringSubmatch(trimmed); m != nil {
			level := len(m[1])
			out.WriteString("<h" + itoa(level) + ">" + renderInline(m[2]) + "</h" + itoa(level) + ">\n")
			i++
			continue
		}

		if marker, ok := matchListMarker(lines[i]); ok {
			i = renderList(lines, i, marker, &out)
			continue
		}

		if blockquoteRE.MatchString(trimmed) {
			i = renderBlockquote(lines, i, &out)
			continue
		}

		i = renderParagraph(lines, i, &out)
	}

	return out.String()
}

// isFenceLine recognizes both CommonMark fence styles: ``` (used for the
// ```sql cells ParseCells already extracts, plus generic/```bash blocks
// still reaching this renderer) and ~~~ (used once in 02-grouping-sets.md:
// "~~~ psql" around a formatted query-result table).
func isFenceLine(trimmed string) bool {
	return strings.HasPrefix(trimmed, "```") || strings.HasPrefix(trimmed, "~~~")
}

func renderFence(lines []string, start int, out *strings.Builder) int {
	i := start + 1
	var buf []string
	for i < len(lines) && !isFenceLine(strings.TrimSpace(lines[i])) {
		buf = append(buf, lines[i])
		i++
	}
	out.WriteString("<pre class=\"md-code-block\">" + escapeHTMLText(strings.Join(buf, "\n")) + "</pre>\n")
	if i < len(lines) {
		i++ // skip the closing fence
	}
	return i
}

func renderParagraph(lines []string, start int, out *strings.Builder) int {
	i := start
	var buf []string
	for i < len(lines) {
		trimmed := strings.TrimSpace(lines[i])
		if trimmed == "" || isFenceLine(trimmed) || headerRE.MatchString(trimmed) {
			break
		}
		if _, ok := matchListMarker(lines[i]); ok {
			break
		}
		buf = append(buf, trimmed)
		i++
	}
	if len(buf) > 0 {
		out.WriteString("<p>" + renderInline(strings.Join(buf, " ")) + "</p>\n")
	}
	return i
}

var (
	headerRE        = regexp.MustCompile(`^(#{1,4})\s+(.*)$`)
	orderedMarkerRE = regexp.MustCompile(`^(\s*)(\d+\.\s+)(.*)$`)
	bulletMarkerRE  = regexp.MustCompile(`^(\s*)([-*]\s+)(.*)$`)
	blockquoteRE    = regexp.MustCompile(`^>\s?(.*)$`)
)

// renderBlockquote consumes a run of consecutive "> ..." lines (as used for
// the starter kit's "This example is drawn from Chapter N..." footers, each
// wrapped across two source lines with no blank line between) and joins
// them into one paragraph, the same way renderParagraph merges wrapped
// prose — a hard line break mid-sentence isn't meaningful here.
func renderBlockquote(lines []string, start int, out *strings.Builder) int {
	i := start
	var buf []string
	for i < len(lines) {
		trimmed := strings.TrimSpace(lines[i])
		m := blockquoteRE.FindStringSubmatch(trimmed)
		if m == nil {
			break
		}
		buf = append(buf, strings.TrimSpace(m[1]))
		i++
	}
	out.WriteString("<blockquote><p>" + renderInline(strings.Join(buf, " ")) + "</p></blockquote>\n")
	return i
}

type listMarker struct {
	ordered    bool
	indent     int // column the marker itself starts at
	contentCol int // column the item's text starts at (indent + marker width)
	firstText  string
}

func matchListMarker(line string) (listMarker, bool) {
	if m := orderedMarkerRE.FindStringSubmatch(line); m != nil {
		return listMarker{ordered: true, indent: len(m[1]), contentCol: len(m[1]) + len(m[2]), firstText: m[3]}, true
	}
	if m := bulletMarkerRE.FindStringSubmatch(line); m != nil {
		return listMarker{ordered: false, indent: len(m[1]), contentCol: len(m[1]) + len(m[2]), firstText: m[3]}, true
	}
	return listMarker{}, false
}

// renderList consumes every line belonging to one list (all items at the
// same marker indentation as the first), handling three shapes seen across
// the starter-kit pages: simple single-line items (README.md), items
// wrapped across two lines with no blank line between (06-recursive-
// rivers.md), and items with multiple blank-line-separated paragraphs plus
// an indented "console output" block (02-grouping-sets.md).
func renderList(lines []string, start int, marker listMarker, out *strings.Builder) int {
	tag := "ul"
	if marker.ordered {
		tag = "ol"
	}
	out.WriteString("<" + tag + ">\n")

	i := start
	for i < len(lines) {
		m, ok := matchListMarker(lines[i])
		if !ok || m.indent != marker.indent || m.ordered != marker.ordered {
			break
		}

		itemLines := []string{m.firstText}
		j := i + 1
		for j < len(lines) {
			line := lines[j]
			if strings.TrimSpace(line) == "" {
				// A blank line only continues the item if further-indented
				// content follows — otherwise it ends the item (and,
				// unless a same-indent marker comes next, the whole list).
				k := j + 1
				for k < len(lines) && strings.TrimSpace(lines[k]) == "" {
					k++
				}
				if k < len(lines) && lineIndent(lines[k]) >= m.contentCol {
					itemLines = append(itemLines, "")
					j = k
					continue
				}
				break
			}

			if lineIndent(line) < m.contentCol {
				break // dedented: this item, and possibly the list, ends here
			}
			itemLines = append(itemLines, stripColumns(line, m.contentCol))
			j++
		}

		out.WriteString("<li>" + renderItemContent(itemLines) + "</li>\n")
		i = j

		// A run of blank lines between items is fine; anything else at this
		// point (a dedented line, a new block) ends the list.
		for i < len(lines) && strings.TrimSpace(lines[i]) == "" {
			i++
		}
	}

	out.WriteString("</" + tag + ">\n")
	return i
}

func lineIndent(line string) int {
	return len(line) - len(strings.TrimLeft(line, " "))
}

// stripColumns removes up to n leading spaces from line, preserving any
// spaces beyond that — the extra indentation left behind is exactly what
// marks a run as a preformatted block rather than continuation prose.
func stripColumns(line string, n int) string {
	stripped := 0
	for stripped < n && stripped < len(line) && line[stripped] == ' ' {
		stripped++
	}
	return line[stripped:]
}

// renderItemContent splits one list item's (already column-stripped) lines
// into blank-line-separated runs, rendering each as a preformatted block
// (every line still has >=4 leading spaces after stripping the item's own
// indentation) or a normal paragraph. A single plain-prose run renders
// without a <p> wrapper, so a simple item still reads as
// "<li>text</li>" rather than "<li><p>text</p></li>".
func renderItemContent(itemLines []string) string {
	var runs [][]string
	var cur []string
	for _, l := range itemLines {
		if strings.TrimSpace(l) == "" {
			if len(cur) > 0 {
				runs = append(runs, cur)
				cur = nil
			}
			continue
		}
		cur = append(cur, l)
	}
	if len(cur) > 0 {
		runs = append(runs, cur)
	}
	if len(runs) == 0 {
		return ""
	}

	if len(runs) == 1 && !isCodeRun(runs[0]) {
		return renderInline(joinTrimmed(runs[0]))
	}

	var b strings.Builder
	for _, run := range runs {
		if isCodeRun(run) {
			b.WriteString("<pre class=\"md-code-block\">" + escapeHTMLText(dedentCommon(run)) + "</pre>")
		} else {
			b.WriteString("<p>" + renderInline(joinTrimmed(run)) + "</p>")
		}
	}
	return b.String()
}

// A run counts as preformatted if every one of its lines has *any* extra
// indentation beyond the item's own content column — not the stricter
// CommonMark "4 extra spaces" rule. The real content this renders (see
// 02-grouping-sets.md) offsets its one console-output line by only 3 extra
// spaces, clearly meant to set it apart from the surrounding prose (which
// sits at exactly the item's content column, 0 extra, throughout); 4 would
// silently swallow it back into a paragraph.
func isCodeRun(lines []string) bool {
	for _, l := range lines {
		if lineIndent(l) < 1 {
			return false
		}
	}
	return true
}

func joinTrimmed(lines []string) string {
	trimmed := make([]string, len(lines))
	for i, l := range lines {
		trimmed[i] = strings.TrimSpace(l)
	}
	return strings.Join(trimmed, " ")
}

func dedentCommon(lines []string) string {
	min := -1
	for _, l := range lines {
		n := lineIndent(l)
		if min == -1 || n < min {
			min = n
		}
	}
	if min < 0 {
		min = 0
	}
	out := make([]string, len(lines))
	for i, l := range lines {
		if len(l) >= min {
			out[i] = l[min:]
		} else {
			out[i] = l
		}
	}
	return strings.Join(out, "\n")
}

var (
	boldRE   = regexp.MustCompile(`\*\*([^*]+)\*\*`)
	italicRE = regexp.MustCompile(`\*([^*]+)\*`)
	codeRE   = regexp.MustCompile("`([^`]+)`")
	imageRE  = regexp.MustCompile(`!\[([^\]]*)\]\(([^)]+)\)`)
	linkRE   = regexp.MustCompile(`\[([^\]]+)\]\(([^)]+)\)`)
)

// renderInline escapes HTML first, then applies inline formatting — in that
// order, so formatting markers never get corrupted by escaping and no user
// content can inject markup through the prose text. Images are matched
// before links since "![...]" would otherwise also match the link pattern.
func renderInline(text string) string {
	escaped := escapeHTMLText(text)
	escaped = imageRE.ReplaceAllStringFunc(escaped, func(m string) string {
		parts := imageRE.FindStringSubmatch(m)
		return `<img src="/starter-kit-assets/` + parts[2] + `" alt="` + parts[1] + `" loading="lazy">`
	})
	escaped = linkRE.ReplaceAllString(escaped, `<a href="$2" target="_blank" rel="noopener">$1</a>`)
	escaped = boldRE.ReplaceAllString(escaped, `<strong>$1</strong>`)
	escaped = italicRE.ReplaceAllString(escaped, `<em>$1</em>`)
	escaped = codeRE.ReplaceAllString(escaped, `<code>$1</code>`)
	return escaped
}

func escapeHTMLText(s string) string {
	r := strings.NewReplacer("&", "&amp;", "<", "&lt;", ">", "&gt;")
	return r.Replace(s)
}

func itoa(n int) string {
	digits := "0123456789"
	if n < 10 {
		return string(digits[n])
	}
	return string(digits[n/10]) + string(digits[n%10])
}
