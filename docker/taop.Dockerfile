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
# Natural Earth stage: convert the committed shapefiles into PostGIS-loadable
# SQL dumps at build time.  Keeping the zips in git makes provenance obvious;
# the generated SQL is never committed, and the runtime image / loader need only
# psql against a PostGIS-enabled server (no GDAL at run time).  Admin-1 (French
# départements) and rivers are clipped to the France frame to keep them small.
#
FROM ghcr.io/osgeo/gdal:alpine-small-latest AS naturalearth-build
COPY data/naturalearth/ne_50m_admin_0_countries.zip        /tmp/z/countries.zip
COPY data/naturalearth/ne_10m_admin_1_states_provinces.zip /tmp/z/admin1.zip
COPY data/naturalearth/ne_10m_rivers_lake_centerlines.zip  /tmp/z/rivers.zip
RUN set -eux; \
    apk add --no-cache unzip; \
    mkdir -p /tmp/ne; \
    unzip -o /tmp/z/countries.zip -d /tmp/ne; \
    unzip -o /tmp/z/admin1.zip    -d /tmp/ne; \
    unzip -o /tmp/z/rivers.zip     -d /tmp/ne; \
    ogr2ogr -f PGDUMP /tmp/ne_50m_admin_0_countries.sql /tmp/ne/ne_50m_admin_0_countries.shp \
      -nln naturalearth.countries -lco SCHEMA=naturalearth -lco GEOMETRY_NAME=geom -lco SRID=4326 \
      -lco CREATE_SCHEMA=ON -nlt PROMOTE_TO_MULTI \
      -select NAME,NAME_LONG,ISO_A2,ISO_A3,CONTINENT,REGION_UN,SUBREGION,POP_EST,GDP_MD; \
    ogr2ogr -f PGDUMP /tmp/ne_10m_admin_1.sql /tmp/ne/ne_10m_admin_1_states_provinces.shp \
      -nln naturalearth.admin1 -lco SCHEMA=naturalearth -lco GEOMETRY_NAME=geom -lco SRID=4326 \
      -nlt PROMOTE_TO_MULTI -where "adm0_a3 IN ('FRA','USA','GBR','IRL')" -select name,adm0_a3,iso_3166_2,region; \
    ogr2ogr -f PGDUMP /tmp/ne_10m_rivers.sql /tmp/ne/ne_10m_rivers_lake_centerlines.shp \
      -nln naturalearth.rivers -lco SCHEMA=naturalearth -lco GEOMETRY_NAME=geom -lco SRID=4326 \
      -nlt PROMOTE_TO_MULTI -select name,name_en; \
    sed -i 's/^CREATE SCHEMA "naturalearth";/CREATE SCHEMA IF NOT EXISTS "naturalearth";/' \
      /tmp/ne_50m_admin_0_countries.sql /tmp/ne_10m_admin_1.sql /tmp/ne_10m_rivers.sql

#
# HydroRIVERS stage: fetch the European river network from OVH Cloud at build
# time, clip it to France (preserving the NEXT_DOWN downstream topology used by
# the WITH RECURSIVE example), and convert to a PostGIS-loadable SQL dump.
# Optional: if the URL is unset, a harmless placeholder is produced so the COPY
# in the final stage still succeeds.
#
FROM ghcr.io/osgeo/gdal:alpine-small-latest AS hydrorivers-build
ARG HYDRORIVERS_URL=""
RUN set -eux; \
    mkdir -p /out; \
    if [ -n "$HYDRORIVERS_URL" ]; then \
      apk add --no-cache curl unzip; \
      curl -fSL --retry 3 -o /tmp/hydro.zip "$HYDRORIVERS_URL"; \
      unzip -o /tmp/hydro.zip -d /tmp/hydro; \
      SHP="$(find /tmp/hydro -iname '*.shp' | head -1)"; \
      ogr2ogr -f PGDUMP /out/hydrorivers.sql "$SHP" \
        -nln hydrorivers.rivers -lco SCHEMA=hydrorivers -lco GEOMETRY_NAME=geom -lco SRID=4326 \
        -lco CREATE_SCHEMA=ON -nlt PROMOTE_TO_MULTI -spat -5.5 41 9.0 51.5 \
        -select HYRIV_ID,NEXT_DOWN,MAIN_RIV,ORD_STRA,DIS_AV_CMS,LENGTH_KM; \
    else \
      echo '-- HYDRORIVERS_URL was unset at build time; set it (see .env.example) and rebuild to load French rivers.' > /out/hydrorivers.sql; \
    fi

#
# Castles stage: download European medieval castle locations from the OpenStreetMap
# Overpass API at build time, extract id/name/lon/lat with jq, and write a CSV
# file.  Loaded at run time with `taop castles`.  If the Overpass API is
# unreachable the stage produces an empty CSV so the final image still builds.
#
FROM debian:bookworm-slim AS castles-build
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl jq ca-certificates && rm -rf /var/lib/apt/lists/*
RUN set -eux; \
    mkdir -p /out; \
    curl -fSL --retry 3 --max-time 300 -X POST \
      --data-urlencode \
        'data=[out:json][timeout:180][bbox:35,-15,72,45];(node["historic"="castle"];way["historic"="castle"];relation["historic"="castle"];);out center;' \
      https://overpass-api.de/api/interpreter \
      -o /tmp/castles.json \
    && jq -r '.elements[] | select((.type=="node" and .lon!=null) or ((.type=="way" or .type=="relation") and .center!=null)) | [.id, (.tags.name // ""), (if .type=="node" then .lon else .center.lon end), (if .type=="node" then .lat else .center.lat end)] | @csv' \
         /tmp/castles.json > /out/castles.csv \
    && echo "Fetched $(wc -l < /out/castles.csv) castle locations from Overpass API." \
    || { echo "Overpass API fetch failed — creating empty placeholder CSV."; \
         : > /out/castles.csv; }

#
# London OSM stage: convert the committed OpenStreetMap extract for the Holborn
# area (major streets + parks, fetched from Overpass) into PostGIS-loadable SQL
# dumps at build time. Provides the street-map backdrop for the kNN pub figure.
#
FROM ghcr.io/osgeo/gdal:alpine-small-latest AS osmlondon-build
COPY data/osm-london/holborn.osm /tmp/holborn.osm
RUN set -eux; \
    ogr2ogr -f PGDUMP /tmp/osm_roads.sql /tmp/holborn.osm lines \
      -nln osm_london.roads -lco SCHEMA=osm_london -lco GEOMETRY_NAME=geom -lco SRID=4326 \
      -lco CREATE_SCHEMA=ON -nlt PROMOTE_TO_MULTI -select highway,name; \
    ogr2ogr -f PGDUMP /tmp/osm_parks.sql /tmp/holborn.osm multipolygons \
      -nln osm_london.parks -lco SCHEMA=osm_london -lco GEOMETRY_NAME=geom -lco SRID=4326 \
      -nlt PROMOTE_TO_MULTI -where "leisure IS NOT NULL"; \
    sed -i 's/^CREATE SCHEMA "osm_london";/CREATE SCHEMA IF NOT EXISTS "osm_london";/' \
      /tmp/osm_roads.sql /tmp/osm_parks.sql

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

# Natural Earth: SQL dumps generated from the committed shapefiles at build time
# (see the naturalearth-build stage above).  Loaded with `taop naturalearth`.
COPY --from=naturalearth-build --chown=taop:taop /tmp/ne_50m_admin_0_countries.sql /data/naturalearth/ne_50m_admin_0_countries.sql
COPY --from=naturalearth-build --chown=taop:taop /tmp/ne_10m_admin_1.sql           /data/naturalearth/ne_10m_admin_1.sql
COPY --from=naturalearth-build --chown=taop:taop /tmp/ne_10m_rivers.sql            /data/naturalearth/ne_10m_rivers.sql

# HydroRIVERS: French river network fetched from OVH Cloud and clipped to France
# at build time (see the hydrorivers-build stage above).  Loaded with
# `taop hydrorivers`; needs psql + a PostGIS-enabled server.
COPY --from=hydrorivers-build --chown=taop:taop /out/hydrorivers.sql /data/hydrorivers/hydrorivers.sql

# London OSM: street + park SQL dumps generated from the committed Holborn-area
# OSM extract at build time (see the osmlondon-build stage above).  Loaded with
# `taop osm-london`.
COPY --from=osmlondon-build --chown=taop:taop /tmp/osm_roads.sql /data/osm-london/osm_roads.sql
COPY --from=osmlondon-build --chown=taop:taop /tmp/osm_parks.sql /data/osm-london/osm_parks.sql

# Castle ruins: CSV of European medieval castle locations fetched from OSM Overpass API
# at build time (see the castles-build stage above).  Loaded with `taop castles`.
COPY --from=castles-build --chown=taop:taop /out/castles.csv /data/castles/castles.csv

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

