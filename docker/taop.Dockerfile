#
# Build our base image.
#
FROM debian:bookworm-slim AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    sbcl \
    curl \
    git \
    make \
    sudo \
    ca-certificates \
    postgresql-client \
    python3 \
    python3-pip \
    python3-psycopg2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/taop

RUN useradd -m taop && \
    usermod -aG sudo taop && \
    echo 'taop ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    chown -R taop:taop /usr/src/taop


#
# Build stage: compiles the taop binary
#
FROM base AS taop-build

USER root
WORKDIR /usr/src/taop

COPY tooling/build/ ./build/
COPY tooling/Makefile ./Makefile

RUN make quicklisp
RUN make pubnames
RUN make qload

COPY tooling/taop.asd .
COPY tooling/taop/ ./taop/
COPY tooling/bin/ ./bin/

RUN make taop
RUN sudo install -D -m 755 ./bin/taop /usr/local/bin/taop

USER taop

#
# Natural Earth stage: convert the committed 1:50m Admin-0 country shapefile
# into a PostGIS-loadable SQL dump at build time.  Keeping only the tiny zip in
# git (≈800 KB) makes provenance obvious and reproducible; the generated SQL is
# never committed, and the runtime image / loader need only psql against a
# PostGIS-enabled server (no GDAL at run time).  Only a curated set of the
# shapefile's ~170 attribute columns is kept, to keep the dump small.
#
FROM ghcr.io/osgeo/gdal:alpine-small-latest AS naturalearth-build
COPY data/naturalearth/ne_50m_admin_0_countries.zip /tmp/ne.zip
RUN apk add --no-cache unzip \
    && unzip -o /tmp/ne.zip -d /tmp/ne \
    && ogr2ogr -f PGDUMP /tmp/ne_50m_admin_0_countries.sql \
         /tmp/ne/ne_50m_admin_0_countries.shp \
         -nln naturalearth.countries \
         -lco SCHEMA=naturalearth -lco GEOMETRY_NAME=geom -lco SRID=4326 \
         -lco CREATE_SCHEMA=ON -nlt PROMOTE_TO_MULTI \
         -select NAME,NAME_LONG,ISO_A2,ISO_A3,CONTINENT,REGION_UN,SUBREGION,POP_EST,GDP_MD

#
# Final stage: taop container with data, queries, and apps
#
FROM base AS taop

COPY --from=taop-build /usr/local/bin/taop /usr/local/bin/taop

# install the data and queries in that image
COPY --chown=taop:taop queries/ /usr/src/taop/queries/
COPY --chown=taop:taop apps/cdstore/ /usr/src/taop/cdstore/
COPY --chown=taop:taop data/ /data/
COPY --chown=taop:taop starter-kit/ /starter-kit/

# Natural Earth: drop in the SQL dump generated from the committed shapefile at
# build time (see the naturalearth-build stage above).  Loaded with
# `taop naturalearth`, which only needs psql + a PostGIS-enabled server.
COPY --from=naturalearth-build --chown=taop:taop \
     /tmp/ne_50m_admin_0_countries.sql /data/naturalearth/ne_50m_admin_0_countries.sql

# Fetch the hashtag CSV from OVH Cloud at build time (optional; skip if HASHTAG_URL unset)
ARG HASHTAG_URL=""
RUN if [ -n "$HASHTAG_URL" ]; then \
      mkdir -p /data/hashtag && \
      curl -fSL --retry 3 -o /data/hashtag/tweets.csv "$HASHTAG_URL" && \
      chown taop:taop /data/hashtag/tweets.csv ; \
    else echo "HASHTAG_URL unset — skipping hashtag CSV fetch"; fi

USER taop
WORKDIR /usr/src/taop/queries

# also install the runtime files needed for the pubnames dataset
COPY --from=taop-build /usr/src/taop/build/quicklisp/local-projects/pubnames/ /usr/src/taop/build/quicklisp/local-projects/pubnames/

ENTRYPOINT ["taop"]
CMD ["--help"]

#
# commitlog container: fetches git repos at build time
#
# Avoid dependency with taop builds.
#
FROM base AS commitlog-data

COPY --chown=taop:taop data/ /data/

# Fetch git repositories at build time
USER taop
WORKDIR /data/commitlog
RUN make postgres
RUN make pgloader

#
# Compose commitlog data with the taop command
#
FROM commitlog-data AS commitlog

COPY --from=taop-build /usr/local/bin/taop /usr/local/bin/taop

ENTRYPOINT ["taop"]
CMD ["commitlog"]

