# PostgreSQL + PostGIS server image for the lab, additionally extended with the
# Citus HyperLogLog (hll) extension built from source.
#
# We start from the official postgis/postgis image (Debian bookworm based). It
# bundles PostGIS and the stock cube / earthdistance contribs that the geo
# chapters use, then we compile hll on top with PGXS and drop the build tools.
# hll is C++, so libstdc++ (already present in the Debian base, pulled by g++)
# is kept as a runtime dependency.  with_llvm=no skips JIT bitcode generation,
# which avoids pulling clang/llvm.
#
# NOTE: this image is Debian/glibc, whereas the previous one was Alpine/musl.
# An existing postgres_data volume initialised under the old image is NOT
# locale-compatible; run `make clean` (docker compose down -v) before rebuilding.
ARG POSTGRES_VERSION=16
ARG POSTGIS_VERSION=3.4
FROM postgis/postgis:${POSTGRES_VERSION}-${POSTGIS_VERSION}

ARG HLL_VERSION=v2.18

# queries/05-data-types/23-pg-data-types-101/11_06.sql does
# `set lc_time to 'fr_FR';` to render month/day names in French — that GUC
# resolves to an OS-level glibc locale, which this Debian base doesn't ship
# by default (only C/C.UTF-8/en_US.UTF-8 out of the box). Generate the exact
# "fr_FR" locale name the book query references (bare, no .UTF-8 suffix).
RUN apt-get update && apt-get install -y --no-install-recommends locales && \
    localedef -i fr_FR -c -f ISO-8859-1 fr_FR && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates git build-essential "postgresql-server-dev-${PG_MAJOR}"; \
    git clone --depth 1 --branch "${HLL_VERSION}" \
        https://github.com/citusdata/postgresql-hll.git /tmp/hll; \
    make -C /tmp/hll with_llvm=no \
        PG_CONFIG="/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config"; \
    make -C /tmp/hll with_llvm=no \
        PG_CONFIG="/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config" install; \
    rm -rf /tmp/hll; \
    apt-get purge -y --auto-remove git build-essential "postgresql-server-dev-${PG_MAJOR}"; \
    rm -rf /var/lib/apt/lists/*

# ip4r (queries/08-extensions/50-geolocation-ip4r) is a PGDG package, not a
# stock contrib module like cube/earthdistance/hstore/intarray/pg_trgm/
# uuid-ossp — those are already bundled in this image (see comment above)
# and just need CREATE EXTENSION, done by docker-entrypoint-initdb.d/
# 01-extensions.sql below.
RUN apt-get update && \
    apt-get install -y --no-install-recommends "postgresql-${PG_MAJOR}-ip4r" && \
    rm -rf /var/lib/apt/lists/*

# Runs once, only against a freshly-initialized (empty) data directory — see
# docker/initdb/01-extensions.sql for why these are needed and which one
# (plxslt) is intentionally left out.
COPY docker/initdb/01-extensions.sql /docker-entrypoint-initdb.d/
