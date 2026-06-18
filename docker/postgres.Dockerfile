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
# For PG 18, use postgis:18-latest (3.4 not yet released for PG 18)
# Override via: docker build --build-arg POSTGIS_IMAGE_TAG=18-latest
ARG POSTGIS_IMAGE_TAG=${POSTGRES_VERSION}-${POSTGIS_VERSION}
FROM postgis/postgis:${POSTGIS_IMAGE_TAG}

ARG HLL_VERSION=v2.18

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
