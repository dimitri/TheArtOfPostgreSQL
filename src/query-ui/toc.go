package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"strings"
)

type TOC struct {
	Parts []Part
}

type Part struct {
	Num      int
	Title    string
	Chapters []Chapter
}

type Chapter struct {
	Num      string // e.g., "2", "2.1"
	Title    string
	Sections []Section
	Queries  []QueryRef // queries directly under the chapter (no section)
}

type Section struct {
	Num     string // e.g., "2.1.1", "3.4.2"
	Title   string
	Queries []QueryRef
}

type QueryRef struct {
	Path string
	File string
}

// numberedLineRE matches "<number(.number)*> <title>", used for Part/Chapter/
// Section/Subsection headings alike; only indentation tells them apart.
var numberedLineRE = regexp.MustCompile(`^(\d+(?:\.\d+)*)\s+(.+)$`)

// isFileRef reports whether a trimmed toc.txt line is a source file reference
// (e.g. "04-sql-select/14-sql-101/02_01.sql") rather than a heading. Headings
// always contain "<number> <title with spaces>"; file references never
// contain whitespace and always contain a path separator.
func isFileRef(trimmed string) bool {
	return !strings.ContainsAny(trimmed, " \t") && strings.Contains(trimmed, "/")
}

func ParseTOC(filename string) (*TOC, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	toc := &TOC{}
	scanner := bufio.NewScanner(file)

	var currentPart *Part
	var currentChapter *Chapter
	var currentSection *Section

	for scanner.Scan() {
		line := scanner.Text()
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			continue
		}
		indent := len(line) - len(strings.TrimLeft(line, " "))

		if isFileRef(trimmed) {
			ref := QueryRef{Path: trimmed, File: extractFilename(trimmed)}
			switch {
			case currentSection != nil:
				currentSection.Queries = append(currentSection.Queries, ref)
			case currentChapter != nil:
				currentChapter.Queries = append(currentChapter.Queries, ref)
			}
			continue
		}

		matches := numberedLineRE.FindStringSubmatch(trimmed)
		if matches == nil {
			continue
		}
		num, title := matches[1], strings.TrimSpace(matches[2])

		switch {
		case indent <= 2:
			// Part heading, e.g. "1 Preface"
			var n int
			fmt.Sscanf(num, "%d", &n)
			toc.Parts = append(toc.Parts, Part{Num: n, Title: title})
			currentPart = &toc.Parts[len(toc.Parts)-1]
			currentChapter = nil
			currentSection = nil

		case indent == 4:
			// Chapter heading, e.g. "2 Structured Query Language"
			if currentPart == nil {
				continue
			}
			currentPart.Chapters = append(currentPart.Chapters, Chapter{Num: num, Title: title})
			currentChapter = &currentPart.Chapters[len(currentPart.Chapters)-1]
			currentSection = nil

		case indent == 6:
			// Section heading, e.g. "2.1 Some of the Code is Written in SQL"
			if currentChapter == nil {
				continue
			}
			currentChapter.Sections = append(currentChapter.Sections, Section{Num: num, Title: title})
			currentSection = &currentChapter.Sections[len(currentChapter.Sections)-1]

		default:
			// Deeper subsection headings (indent >= 8): not modeled as their
			// own nav level; any file refs beneath them attach to the
			// enclosing section/chapter, which keeps navigation matching the
			// book's chapter/section structure without fragmenting it.
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	toc.normalize()
	return toc, nil
}

// normalize replaces nil slices with empty ones throughout the tree. A Part,
// Chapter, or Section that never got a child (e.g. "9 Closing Thoughts" has
// no sub-chapters) keeps its slice field as Go's nil zero-value, which
// encoding/json renders as `null`. The frontend does `x.forEach(...)` on
// these fields directly, and `null.forEach` throws — so every level must be
// guaranteed `[]`, never `null`, on the wire.
func (t *TOC) normalize() {
	for pi := range t.Parts {
		if t.Parts[pi].Chapters == nil {
			t.Parts[pi].Chapters = []Chapter{}
		}
		for ci := range t.Parts[pi].Chapters {
			ch := &t.Parts[pi].Chapters[ci]
			if ch.Sections == nil {
				ch.Sections = []Section{}
			}
			if ch.Queries == nil {
				ch.Queries = []QueryRef{}
			}
			for si := range ch.Sections {
				if ch.Sections[si].Queries == nil {
					ch.Sections[si].Queries = []QueryRef{}
				}
			}
		}
	}
}

func extractFilename(path string) string {
	parts := strings.Split(path, "/")
	return parts[len(parts)-1]
}

func (t *TOC) TotalChapters() int {
	count := 0
	for _, part := range t.Parts {
		count += len(part.Chapters)
	}
	return count
}
