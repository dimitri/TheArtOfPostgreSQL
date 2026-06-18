# PostgreSQL 18 server image for the lab with HyperLogLog extension.
#
# PostgreSQL 18 is not yet supported by postgis/postgis Docker images,
# so we start from the plain postgres:18 image and compile HLL on top.
# PostGIS-dependent datasets are skipped via SKIP_POSTGIS_DATASETS=true
# in the CI environment.
#
# This Dockerfile is used only for PG 18 testing until PostGIS releases
# official PG 18 support. Other versions (14-17) use docker/postgres.Dockerfile
# with postgis/postgis base image.
ARG POSTGRES_VERSION=18
FROM postgres:${POSTGRES_VERSION}

ARG HLL_VERSION=v2.18

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates git build-essential postgresql-server-dev; \
    git clone --depth 1 --branch "${HLL_VERSION}" \
        https://github.com/citusdata/postgresql-hll.git /tmp/hll; \
    make -C /tmp/hll with_llvm=no \
        PG_CONFIG="/usr/lib/postgresql/${POSTGRES_VERSION}/bin/pg_config"; \
    make -C /tmp/hll with_llvm=no \
        PG_CONFIG="/usr/lib/postgresql/${POSTGRES_VERSION}/bin/pg_config" install; \
    rm -rf /tmp/hll; \
    apt-get purge -y --auto-remove git build-essential postgresql-server-dev; \
    rm -rf /var/lib/apt/lists/*
