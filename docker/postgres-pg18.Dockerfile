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

ARG POSTGRES_VERSION=18

# PostgreSQL 18 support: HLL extension v2.18 does not compile due to
# -Werror=missing-variable-declarations in PG 18's strict compiler flags.
# HLL will be added back once upstream releases a PG 18-compatible version.
