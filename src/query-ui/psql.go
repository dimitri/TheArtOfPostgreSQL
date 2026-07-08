package main

import "strings"

// preprocessPsqlScript mimics the subset of psql's client-side preprocessing
// that the book's queries actually rely on: \set variable assignment plus
// :name / :'name' / :"name" substitution. PostgreSQL itself has no notion of
// any of this — it's purely a psql-side text transform — so queries copied
// verbatim from the book (e.g. queries/02-intro/02-usecase/04_01.sql, which
// opens with `\set start '2017-02-01'` and references `:'start'` below) fail
// outright when sent to the server as-is. Every other backslash meta-command
// found in the book's queries (\pset, \copy) is display/client-only or
// belongs to setup scripts already excluded by isReadOnly, so those lines are
// simply dropped rather than specially handled.
//
// vars accumulates \set assignments made within this single script and is
// then used for substitution — each query file is expected to be
// self-sufficient (any \set line it depends on copied in), so a fresh empty
// map per call is correct; this is not session state shared across queries.
func preprocessPsqlScript(sql string, vars map[string]string) string {
	lines := strings.Split(sql, "\n")
	var kept []string

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "\\set") {
			name, value, ok := parseSetCommand(trimmed)
			if ok {
				vars[name] = value
			}
			continue
		}
		if strings.HasPrefix(trimmed, "\\") {
			// Other meta-commands (\pset, \copy, ...): client-side only or
			// already excluded by the read-only guard; drop the line.
			continue
		}
		kept = append(kept, line)
	}

	return substituteVariables(strings.Join(kept, "\n"), vars)
}

// parseSetCommand parses a line of the form `\set name value`, where value
// may be a single-quoted token using SQL-style ” escaping for an embedded
// quote (e.g. \set season 'date ”1978-01-01”') or a bare word/number
// (e.g. \set months 3). It returns ok=false if the line isn't a well-formed
// \set command.
func parseSetCommand(line string) (name, value string, ok bool) {
	rest := strings.TrimSpace(strings.TrimPrefix(line, "\\set"))
	if rest == "" {
		return "", "", false
	}

	sp := strings.IndexAny(rest, " \t")
	if sp == -1 {
		// "\set name" with no value: psql sets it to empty.
		return rest, "", true
	}
	name = rest[:sp]
	rest = strings.TrimLeft(rest[sp:], " \t")
	if rest == "" {
		return name, "", true
	}

	if rest[0] == '\'' {
		value = parseQuotedValue(rest[1:])
		return name, value, true
	}

	// Bare token: psql would stop at the next whitespace, but every value in
	// the book's \set lines is a single word, so take the rest of the line.
	return name, rest, true
}

// parseQuotedValue reads a SQL-style single-quoted literal (input has already
// had its opening quote consumed), where ” represents one literal quote
// character, and returns the unescaped contents.
func parseQuotedValue(s string) string {
	var out strings.Builder
	runes := []rune(s)
	for i := 0; i < len(runes); i++ {
		if runes[i] == '\'' {
			if i+1 < len(runes) && runes[i+1] == '\'' {
				out.WriteRune('\'')
				i++
				continue
			}
			break // unescaped quote: end of literal
		}
		out.WriteRune(runes[i])
	}
	return out.String()
}

func isIdentRune(r rune) bool {
	return r == '_' || (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9')
}

// substituteVariables replaces :name, :'name', and :"name" references with
// the corresponding variable's value, matching psql's three substitution
// forms (raw, single-quoted literal, double-quoted identifier). It leaves
// "::" (the cast operator) untouched and passes through any ":name" whose
// name isn't a known variable unchanged, so plain-SQL colons are never
// corrupted.
func substituteVariables(sql string, vars map[string]string) string {
	runes := []rune(sql)
	var out strings.Builder
	n := len(runes)

	for i := 0; i < n; {
		c := runes[i]
		if c != ':' {
			out.WriteRune(c)
			i++
			continue
		}
		if i+1 < n && runes[i+1] == ':' {
			// Cast operator "::": not a variable reference.
			out.WriteString("::")
			i += 2
			continue
		}

		j := i + 1
		var quote rune
		if j < n && (runes[j] == '\'' || runes[j] == '"') {
			quote = runes[j]
			j++
		}

		start := j
		for j < n && isIdentRune(runes[j]) {
			j++
		}
		name := string(runes[start:j])

		if name == "" || (quote != 0 && (j >= n || runes[j] != quote)) {
			// Not a valid reference (e.g. bare ":" or unterminated quote):
			// emit the colon literally and keep scanning right after it.
			out.WriteRune(':')
			i++
			continue
		}

		val, known := vars[name]
		if !known {
			// Unknown variable: leave the original text untouched, same as
			// psql does by default (it substitutes an empty string and
			// warns, but silently corrupting unrelated queries that happen
			// to contain a bare ":name" is worse than a clear DB error).
			out.WriteRune(':')
			if quote != 0 {
				out.WriteRune(quote)
			}
			out.WriteString(name)
			if quote != 0 {
				out.WriteRune(quote)
			}
			i = j
			if quote != 0 {
				i++ // consume closing quote
			}
			continue
		}

		switch quote {
		case '\'':
			out.WriteByte('\'')
			out.WriteString(strings.ReplaceAll(val, "'", "''"))
			out.WriteByte('\'')
			j++ // consume closing quote
		case '"':
			out.WriteByte('"')
			out.WriteString(strings.ReplaceAll(val, `"`, `""`))
			out.WriteByte('"')
			j++ // consume closing quote
		default:
			out.WriteString(val)
		}
		i = j
	}

	return out.String()
}
