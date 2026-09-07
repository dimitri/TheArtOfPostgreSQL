#!/usr/bin/env bash
#
# Regenerate data/f1db/f1db.2018-2024.sql.
#
# data/f1db/f1db.dump is the last Ergast release and stops at the 2017
# season. This script extracts the seasons after it from a database that
# has newer data loaded into a schema called f1db24, and writes them as
# an idempotent append that runs on top of the dump.
#
# To refresh (e.g. when 2025 becomes available):
#
#   1. Download the current CSVs, which follow the original Ergast schema:
#      https://github.com/raceoptidata/Ergast_like-dumps  (CC BY-SA 4.0)
#   2. Load them into a schema named f1db24 in the same database that
#      already holds f1db. Only these 13 tables are needed; two differ
#      from ours and are handled below -- their races carries ten extra
#      fp*/quali_*/sprint_* columns we do not have, and our circuits
#      carries an extra "position" geography column they do not.
#   3. Run this script, then load the result over a fresh f1db.dump and
#      check the row counts.
#
# BEFORE TRUSTING A REFRESH, re-check that the primary keys are still
# stable -- that is the whole premise of appending rather than reloading:
#
#   select count(*) from f1db.races o join f1db24.races n using(raceid)
#    where o.year <> n.year or o.name <> n.name or o.date <> n.date;
#
# It was 0 for the 2024 data. If a refresh ever makes it non-zero,
# upstream has renumbered and this file cannot be an append any more.
#
set -euo pipefail

OUT=${1:-data/f1db/f1db.2018-2024.sql}
PSQL=(psql -X -q)
FROM_YEAR=${FROM_YEAR:-2017}
BODY=$(mktemp)
trap 'rm -f "$BODY"' EXIT

emit_table () {   # $1 table, $2 select-list, $3 from-clause tail
  {
    echo "-- $1"
    echo "create temp table load_$1 (like f1db.$1) on commit drop;"
    echo "copy load_$1 from stdin;"
  } >> "$BODY"
  "${PSQL[@]}" -c "\\copy (select $2 from f1db24.$1 $3) to stdout" >> "$BODY"
  {
    echo '\.'
    echo "insert into f1db.$1 select * from load_$1 on conflict do nothing;"
    echo
  } >> "$BODY"
}

NEW="where raceid in (select raceid from f1db24.races where year > $FROM_YEAR)"

# Reference rows first, so the per-race data below has its foreign keys.
emit_table circuits "circuitid,circuitref,name,location,country,lat,lng,alt,url,null::geography" \
  "d where not exists (select 1 from f1db.circuits o where o.circuitid=d.circuitid)"
emit_table constructors "*" "d where not exists (select 1 from f1db.constructors o where o.constructorid=d.constructorid)"
emit_table drivers "*" "d where not exists (select 1 from f1db.drivers o where o.driverid=d.driverid)"
emit_table seasons "*" "d where not exists (select 1 from f1db.seasons o where o.year=d.year)"
emit_table status "*" "d where not exists (select 1 from f1db.status o where o.statusid=d.statusid)"
# Only the eight Ergast columns: the upstream schema's extra session-time
# columns are not part of the schema the book was written against.
emit_table races "raceid,year,round,circuitid,name,date,time,url" "where year > $FROM_YEAR"
emit_table results "*" "$NEW"
emit_table qualifying "*" "$NEW"
emit_table driverstandings "*" "$NEW"
emit_table constructorstandings "*" "$NEW"
emit_table constructorresults "*" "$NEW"
emit_table pitstops "*" "$NEW"
emit_table laptimes "*" "$NEW"

cat data/f1db/f1db.2018-2024.header.sql > "$OUT"
{
  echo "begin;"
  echo
  cat "$BODY"
  echo "commit;"
  echo
  echo "-- Fresh statistics for the newly appended rows."
  for t in races results qualifying driverstandings constructorstandings \
           constructorresults pitstops laptimes drivers constructors \
           circuits seasons status; do
    echo "analyze f1db.$t;"
  done
} >> "$OUT"

echo "wrote $OUT ($(wc -c < "$OUT") bytes)"
