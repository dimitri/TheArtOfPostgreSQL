#!/usr/bin/env bash
# Overlay PG-major-specific expected files before `regresql test`.
#
# regresql has no notion of server version: it compares each query's output
# against exactly one queries/regresql/expected/<path>.out.  A few book queries
# are legitimately version-dependent -- 05-data-types/23-pg-data-types-101/01.sql
# lists the pg_catalog types, and every major adds some (PG 19 adds oid8).  For
# those we commit the baseline .out plus one .pgNN.out per diverging major, and
# swap the matching variant in here.
#
# Queries whose output merely *happens* to differ between majors (unstable row
# order, because the ORDER BY is not a total order or is missing entirely) do
# NOT belong here -- fix the query instead, so one expected file serves every
# matrix leg.  See queries/regresql/regress.yaml for the third case: output
# that is non-deterministic by nature and is excluded from testing outright.
#
# The variants are inert to regresql itself: it walks queries/**/*.sql and
# derives the expected path from each query, so it never sees 01.pg19.out as a
# test of its own.
set -euo pipefail
cd "$(dirname "$0")/../.."

: "${PG_MAJOR:?PG_MAJOR must be set (the bare major, e.g. 19 for 19beta3)}"

# find rather than a globstar glob: macOS ships bash 3.2, which has no globstar,
# and this script is meant to be runnable locally as well as on the CI runner.
find queries/regresql/expected -type f -name "*.pg${PG_MAJOR}.out" -print | while read -r variant; do
  base="${variant%.pg${PG_MAJOR}.out}.out"
  echo "PG ${PG_MAJOR}: using $(basename "$variant") for $(basename "$base")"
  cp "$variant" "$base"
done
