package main

import (
	"context"
	"fmt"
	"log"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// connectDB opens a pool with search_path forced to cover every dataset
// schema in the database (f1db, chinook, geoname, hydrorivers, ...), not
// just the ones a given CI/setup step happened to ALTER ROLE for.
//
// The book's queries are written the way a reader's psql session would run
// them: mostly unqualified table names (`from results`, not
// `from f1db.results`), relying on search_path already covering the
// relevant schema. ci.yml reproduces that with a one-time
// `ALTER ROLE taop SET search_path TO f1db, chinook, public, scan34`, but
// that's (a) a persistent role-level change made out-of-band, so a bare
// `docker compose up` here never runs it, and (b) a fixed, partial list that
// doesn't cover every dataset (geoname, hydrorivers, magic, moma, ...). So
// query-ui discovers every schema in the connected database once at startup
// and applies it as a session-level SET on every pooled connection — no
// dependency on an external ALTER ROLE step, and it stays correct as new
// datasets are added.
func connectDB(ctx context.Context, dbURL string) (*pgxpool.Pool, error) {
	config, err := pgxpool.ParseConfig(dbURL)
	if err != nil {
		return nil, fmt.Errorf("parsing database URL: %w", err)
	}

	searchPath, err := discoverSearchPath(ctx, dbURL)
	if err != nil {
		return nil, fmt.Errorf("discovering schemas: %w", err)
	}
	log.Printf("✓ search_path = %s", searchPath)

	setSearchPath := fmt.Sprintf("SET search_path TO %s", searchPath)
	config.AfterConnect = func(ctx context.Context, conn *pgx.Conn) error {
		_, err := conn.Exec(ctx, setSearchPath)
		return err
	}

	return pgxpool.NewWithConfig(ctx, config)
}

// discoverSearchPath connects once, lists every non-system schema (anything
// but pg_% and information_schema), and returns them as a comma-separated,
// quoted-identifier list ordered so "public" comes last — book queries that
// rely on unqualified names generally want their dataset schema checked
// before the near-empty public schema.
func discoverSearchPath(ctx context.Context, dbURL string) (string, error) {
	conn, err := pgx.Connect(ctx, dbURL)
	if err != nil {
		return "", err
	}
	defer conn.Close(ctx)

	rows, err := conn.Query(ctx, `
		SELECT nspname FROM pg_namespace
		WHERE nspname !~ '^pg_' AND nspname <> 'information_schema'
		ORDER BY (nspname = 'public'), nspname`)
	if err != nil {
		return "", err
	}
	defer rows.Close()

	var schemas []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return "", err
		}
		schemas = append(schemas, quoteIdent(name))
	}
	if err := rows.Err(); err != nil {
		return "", err
	}

	if len(schemas) == 0 {
		return "public", nil
	}
	return strings.Join(schemas, ", "), nil
}

func quoteIdent(name string) string {
	return `"` + strings.ReplaceAll(name, `"`, `""`) + `"`
}
