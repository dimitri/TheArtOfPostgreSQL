#!/bin/bash
#
# Restores the pre-seeded dataset from 02-taop-seed.dump (pg_dump -Fc,
# custom format) with a parallel pg_restore -- runs only on the first start
# of a fresh data volume, same as any other docker-entrypoint-initdb.d
# script.
#
# Custom format instead of plain SQL specifically to unlock --jobs: plain
# SQL (the previous format here) can only be replayed serially through
# psql. Measured on the published image: gunzip | psql -f took ~9.5s,
# pg_restore --jobs=4 took ~5.7s for the same data (~40% faster) -- gains
# taper off past roughly the host's core count, since pg_restore can't
# parallelize beyond the number of independent tables/indexes it's
# restoring anyway.
#
# --no-owner --no-acl: matches how the dump itself was produced (see the
# seed stage in seeded-postgres.Dockerfile) -- nothing here to fail on a
# missing role.
set -euo pipefail

DUMP="/docker-entrypoint-initdb.d/02-taop-seed.dump"
JOBS="$(nproc)"

echo "Restoring seed data from $DUMP (--jobs=$JOBS)..."
pg_restore \
    --username="$POSTGRES_USER" \
    --dbname="$POSTGRES_DB" \
    --no-owner --no-acl \
    --jobs="$JOBS" \
    "$DUMP"
echo "Seed data restored."
