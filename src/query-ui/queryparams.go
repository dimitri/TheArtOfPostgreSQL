package main

import (
	"encoding/json"
	"log"
	"os"
)

// QueryParams maps a query's toc.txt-style path (e.g.
// "03-writing-sql-queries/07-psql/04_01_alesi.sql") to literal \set lines
// to prepend when serving that file's content.
//
// Some book queries deliberately show bare :name / :n parameters with no
// \set of their own — the book uses them to illustrate passing values from
// application code (see queries/regresql/plans/ for the same queries tested
// via regresql's own bind-param mechanism), not psql variables. Loading one
// of these into query-ui as-is leaves an unresolved ":name" that Postgres
// rejects with a syntax error. This file lets each such query be made
// runnable in the interactive editor without editing the .sql file itself
// (which would misrepresent what the book actually shows).
type QueryParams map[string][]string

// LoadQueryParams reads the JSON config. A missing file is not an error —
// the feature is optional — but a malformed one is, since silently running
// queries without their intended parameters would be worse than failing to
// start.
func LoadQueryParams(path string) (QueryParams, error) {
	data, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return QueryParams{}, nil
	}
	if err != nil {
		return nil, err
	}

	// Decode as map[string]json.RawMessage first: query-params.json carries
	// a "_comment" key documenting the file's purpose, whose value is a
	// plain string rather than a []string of \set lines, and that one key
	// should be skipped rather than fail the whole file to parse.
	var raw map[string]json.RawMessage
	if err := json.Unmarshal(data, &raw); err != nil {
		return nil, err
	}

	params := make(QueryParams, len(raw))
	for key, value := range raw {
		var lines []string
		if err := json.Unmarshal(value, &lines); err != nil {
			log.Printf("query-params.json: skipping %q (not a list of \\set lines)", key)
			continue
		}
		params[key] = lines
	}
	return params, nil
}
