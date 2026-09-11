#!/bin/bash
#
# Wraps the official docker-entrypoint.sh solely to inject the correct
# shared_preload_libraries for this image's PG_MAJOR (computed at build
# time into /usr/local/share/preload-libraries -- see postgres.Dockerfile /
# seeded-postgres.Dockerfile).
#
# This can't be baked into postgresql.conf.sample instead: that file is
# what initdb itself copies into PGDATA/postgresql.conf, and initdb's own
# internal single-user bootstrap process ("performing post-bootstrap
# initialization...") reads it too -- confirmed by testing that preloading
# pg_stat_plans this way segfaults initdb on PG 16/17 (it relies on
# pluggable cumulative statistics infrastructure that isn't fully wired up
# in that early bootstrap context on those majors, even though the
# extension works fine once the server is actually running).
#
# A command-line -c flag doesn't have this problem: docker-entrypoint.sh's
# _main() calls `docker_init_database_dir` (which runs initdb) with no
# arguments at all -- only `docker_temp_server_start "$@"` and the final
# `exec "$@"` see this wrapper's injected flag, and both of those always
# run strictly after initdb has already completed.
set -euo pipefail

if [ $# -eq 0 ]; then
    set -- postgres
fi

if [ "$1" = 'postgres' ]; then
    preload="$(cat /usr/local/share/preload-libraries)"
    shift
    set -- postgres -c "shared_preload_libraries=${preload}" "$@"
fi

exec docker-entrypoint.sh "$@"
