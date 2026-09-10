# Regenerate dbipcity.csv.xz from a fresh DB-IP City Lite release.
#
#   make            # fetch + load + filter + stop-db, in order
#   make fetch      # download dbip-city-lite.csv.gz and gunzip it
#   make start-db   # start a throwaway postgres container (ip4r preinstalled)
#   make load       # \copy the whole raw file into it (load.sql)
#   make filter     # build + export the filtered dbipcity.csv.xz (filter.sql)
#   make stop-db    # remove the throwaway container
#   make clean      # stop-db + remove downloaded/intermediate files
#
# No pgloader, no text-munging of the CSV before it reaches Postgres: the
# country/IPv4 filtering happens in SQL against loaded data (filter.sql),
# not via awk/cut on the raw file -- those aren't CSV-quote-aware and will
# silently corrupt rows whose city name contains a comma (e.g. "Los Angeles
# (Westwood, Los Angeles)").
#
# dbipcity.csv.xz, not dbipcity.csv, is what's committed: xz -9e beats gzip
# by a wide margin on this data (9.1 MB vs 15 MB on the GB/FR/whole-US cut)
# and is available everywhere. taop dbipcity decompresses it at load time
# (see tooling/taop/dbipcity.lisp) -- xz-utils is on the load path in both
# docker/taop.Dockerfile and docker/seeded-postgres.Dockerfile.
#
# Requires: curl, gunzip, xz, docker.

SNAPSHOT  ?= $(shell date +%Y-%m)
URL       ?= https://download.db-ip.com/free/dbip-city-lite-$(SNAPSHOT).csv.gz

CONTAINER := dbipcity-refresh
IMAGE     := ghcr.io/dimitri/theartofpostgresql/postgres-seeded:16
PSQL      := docker exec -i -w /tmp $(CONTAINER) psql -U taop -d taop -v ON_ERROR_STOP=1

.PHONY: all fetch load filter start-db stop-db clean

all: fetch load filter stop-db ;

dbip-city-lite.csv.gz:
	curl -fSL --retry 3 -o $@ $(URL)

dbip-city-lite.csv: dbip-city-lite.csv.gz
	gunzip -k $<

fetch: dbip-city-lite.csv ;

start-db:
	docker run -d --name $(CONTAINER) \
	    -e POSTGRES_DB=taop -e POSTGRES_USER=taop -e POSTGRES_PASSWORD=taop \
	    $(IMAGE) >/dev/null
	# -h 127.0.0.1 matters: on first start the seeded image's entrypoint
	# runs a *temporary* postgres (unix socket only) while it restores its
	# own seed dump, before starting the real, network-reachable one.
	# Plain pg_isready (no -h) connects over the unix socket and reports
	# ready against that temporary instance -- forcing TCP here waits for
	# the real server instead.
	until docker exec $(CONTAINER) pg_isready -h 127.0.0.1 -U taop -d taop >/dev/null 2>&1; do sleep 2; done

load: dbip-city-lite.csv start-db
	docker cp dbip-city-lite.csv $(CONTAINER):/tmp/dbip-city-lite.csv
	$(PSQL) < load.sql

filter:
	$(PSQL) < filter.sql
	docker cp $(CONTAINER):/tmp/dbipcity.csv dbipcity.csv
	xz -9e -f dbipcity.csv
	@echo "Wrote dbipcity.csv.xz: $$(xz -dc dbipcity.csv.xz | wc -l) rows, $$(du -h dbipcity.csv.xz | cut -f1)"

stop-db:
	docker rm -f $(CONTAINER) >/dev/null 2>&1 || true

clean: stop-db
	rm -f dbip-city-lite.csv dbip-city-lite.csv.gz dbipcity.csv
