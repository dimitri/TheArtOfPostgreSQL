#
# seeded-postgres.Dockerfile
#
# Builds a postgres image pre-seeded with all taop datasets.
#
# Usage:
#   docker compose build          # one-time; takes ~15 min (compile + load)
#   docker compose up -d postgres query-ui
#   open http://localhost:8042
#
# On first `docker compose up`, postgres restores the seed dump automatically
# via docker-entrypoint-initdb.d (runs only when the data volume is empty).
# Subsequent starts skip initdb entirely.
#
# Commitlog data (git histories of postgres/pgloader) is included: the
# commitlog-data stage below clones both repos at build time and the seed
# stage imports them with `taop commitlog`, same as docker/taop.Dockerfile's
# standalone commitlog service — only the resulting commitlog.commitlog rows
# end up in the seed dump, the ~2 GB of cloned git history itself never
# reaches the final image.
#

ARG POSTGRES_VERSION=16
ARG POSTGIS_VERSION=3.4
ARG HLL_VERSION=v2.18

# ─────────────────────────────────────────────────────────────────────────────
# taop binary — Common Lisp toolchain + compiled binary
# ─────────────────────────────────────────────────────────────────────────────
#
# Plain debian:bookworm-slim, same OS/glibc as postgres-base below (also
# bookworm) — this stage's compiled taop binary gets copied directly into
# postgres-base's filesystem in the seed stage further down, so they must
# match architecture and glibc. Both are natively multi-arch (amd64 + arm64),
# so this also builds natively on Apple Silicon rather than under QEMU.
FROM debian:bookworm-slim AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    sbcl curl git make sudo ca-certificates postgresql-client \
    python3 python3-psycopg2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/taop

RUN useradd -m taop && \
    usermod -aG sudo taop && \
    echo 'taop ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    chown -R taop:taop /usr/src/taop

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

# ─────────────────────────────────────────────────────────────────────────────
# Commitlog data — clone postgres/pgloader git histories at build time, same
# as taop.Dockerfile's commitlog-data stage. Kept as its own stage (rather
# than folded into taop-build) so a change to the taop source doesn't bust
# the clone cache and vice versa.
# ─────────────────────────────────────────────────────────────────────────────
FROM base AS commitlog-data

COPY --chown=taop:taop data/commitlog/ /data/commitlog/

USER taop
WORKDIR /data/commitlog
RUN make postgres
RUN make pgloader

# ─────────────────────────────────────────────────────────────────────────────
# Geodata stages — same as taop.Dockerfile
# ─────────────────────────────────────────────────────────────────────────────
FROM ghcr.io/osgeo/gdal:alpine-small-latest AS naturalearth-build
COPY data/naturalearth/ne_50m_admin_0_countries.zip        /tmp/z/countries.zip
COPY data/naturalearth/ne_10m_admin_1_states_provinces.zip /tmp/z/admin1.zip
COPY data/naturalearth/ne_10m_rivers_lake_centerlines.zip  /tmp/z/rivers.zip
RUN set -eux; \
    apk add --no-cache unzip; \
    mkdir -p /tmp/ne; \
    unzip -o /tmp/z/countries.zip -d /tmp/ne; \
    unzip -o /tmp/z/admin1.zip    -d /tmp/ne; \
    unzip -o /tmp/z/rivers.zip    -d /tmp/ne; \
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
      echo '-- HYDRORIVERS_URL unset at build time.' > /out/hydrorivers.sql; \
    fi

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

# ─────────────────────────────────────────────────────────────────────────────
# postgres base — same as postgres.Dockerfile
# ─────────────────────────────────────────────────────────────────────────────
FROM postgres:${POSTGRES_VERSION}-bookworm AS pg-entrypoint

FROM debian:bookworm-slim AS postgres-base

ARG POSTGRES_VERSION=16
ARG POSTGIS_VERSION=3.4
ARG HLL_VERSION=v2.18

RUN groupadd -r postgres --gid=999 && \
    useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres && \
    install --verbose --directory --owner postgres --group postgres --mode 1777 /var/lib/postgresql

# queries/05-data-types/23-pg-data-types-101/11_06.sql does
# `set lc_time to 'fr_FR';` to render month/day names in French — that GUC
# resolves to an OS-level glibc locale, which this Debian base doesn't ship
# by default (only C/C.UTF-8 out of the box). Generate both the exact
# "fr_FR" locale the book query references (bare, no .UTF-8 suffix) and the
# en_US.UTF-8 locale Postgres itself defaults to -- both through
# /etc/locale.gen + locale-gen, not a standalone localedef call: locale-gen
# treats /etc/locale.gen as the authoritative list and purges any locale not
# in it, so a `localedef fr_FR` run before `locale-gen` gets silently wiped
# out the moment locale-gen runs for en_US.UTF-8.
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates gnupg locales && \
    { echo 'en_US.UTF-8 UTF-8'; echo 'fr_FR ISO-8859-1'; } >> /etc/locale.gen && \
    locale-gen && \
    rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.utf8

# PGDG apt repo: this is where postgresql-$PG_MAJOR and its postgis package
# for that specific major version come from -- Debian bookworm's own repo
# only carries PostgreSQL 15.
RUN install -d /usr/share/postgresql-common/pgdg && \
    curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail \
        https://www.postgresql.org/media/keys/ACCC4CF8.asc && \
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list

ENV PG_MAJOR=${POSTGRES_VERSION}
ENV PATH=$PATH:/usr/lib/postgresql/${PG_MAJOR}/bin

# postgresql-$PG_MAJOR alone already bundles the stock cube / earthdistance /
# hstore / intarray / pg_trgm / uuid-ossp contribs used by the geo chapters
# (confirmed: their .control files ship with the base package, no separate
# "contrib" package exists per-version in PGDG's packaging) -- CREATE
# EXTENSION for those is done by docker-entrypoint-initdb.d/01-extensions.sql
# below. postgis's major version tracks Postgres's own package split
# (postgresql-$PG_MAJOR-postgis-3, independent of the PostGIS point release).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        "postgresql-${PG_MAJOR}" \
        "postgresql-${PG_MAJOR}-postgis-${POSTGIS_VERSION%%.*}" \
        "postgresql-${PG_MAJOR}-postgis-${POSTGIS_VERSION%%.*}-scripts" \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        git build-essential "postgresql-server-dev-${PG_MAJOR}"; \
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
# stock contrib module — needs its own install, then just CREATE EXTENSION
# (done by docker-entrypoint-initdb.d/01-extensions.sql below).
RUN apt-get update && \
    apt-get install -y --no-install-recommends "postgresql-${PG_MAJOR}-ip4r" && \
    rm -rf /var/lib/apt/lists/*

COPY docker/initdb/01-extensions.sql /docker-entrypoint-initdb.d/01-extensions.sql

# initdb's default sample config has listen_addresses='localhost' — fine for
# a single-container use case, but this image is always reached from another
# container (query-ui, taop, psql) over the compose network, never from
# inside its own container, so it must listen on all interfaces. Same fix
# the official postgres image applies to its own sample config.
RUN dpkg-divert --add --rename --divert "/usr/share/postgresql/postgresql.conf.sample.dpkg" "/usr/share/postgresql/${PG_MAJOR}/postgresql.conf.sample" && \
    cp -v /usr/share/postgresql/postgresql.conf.sample.dpkg /usr/share/postgresql/postgresql.conf.sample && \
    ln -sv ../postgresql.conf.sample "/usr/share/postgresql/${PG_MAJOR}/" && \
    sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample && \
    grep -F "listen_addresses = '*'" /usr/share/postgresql/postgresql.conf.sample

# Same PGDATA/socket layout and entrypoint tooling as the official image.
RUN install --verbose --directory --owner postgres --group postgres --mode 3777 /var/run/postgresql
ENV PGDATA=/var/lib/postgresql/data
RUN install --verbose --directory --owner postgres --group postgres --mode 1777 "$PGDATA"
VOLUME /var/lib/postgresql/data

COPY --from=pg-entrypoint /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-ensure-initdb.sh /usr/local/bin/
COPY --from=pg-entrypoint /usr/local/bin/gosu /usr/local/bin/gosu
RUN ln -sT docker-ensure-initdb.sh /usr/local/bin/docker-enforce-initdb.sh

ENTRYPOINT ["docker-entrypoint.sh"]
STOPSIGNAL SIGINT
EXPOSE 5432
CMD ["postgres"]

# ─────────────────────────────────────────────────────────────────────────────
# seed — start postgres locally, load all datasets, pg_dump
# ─────────────────────────────────────────────────────────────────────────────
FROM postgres-base AS seed

# taop is a standalone executable (build.lisp calls uiop:dump-image with
# :executable t, which embeds the SBCL runtime) — no sbcl needed here. The
# runtime dependencies across every load-data command are: magic.lisp
# shelling out to `python3 magic.py` (needs psycopg2), gitlog.lisp shelling
# out to `git log` against the commitlog-data clones copied in below, and
# curl/ca-certificates for the HASHTAG_URL fetch further down this stage (not
# for the taop binary itself, which never shells out to curl).
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-psycopg2 git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# taop binary and the quicklisp pubnames project it loads at runtime
COPY --from=taop-build /usr/local/bin/taop /usr/local/bin/taop
COPY --from=taop-build \
    /usr/src/taop/build/quicklisp/local-projects/pubnames/ \
    /usr/src/taop/build/quicklisp/local-projects/pubnames/

# All dataset source files
COPY data/ /tmp/data/
COPY apps/cdstore/ /tmp/cdstore/

# Geodata SQL artefacts from the build stages above
COPY --from=naturalearth-build /tmp/ne_50m_admin_0_countries.sql /tmp/data/naturalearth/ne_50m_admin_0_countries.sql
COPY --from=naturalearth-build /tmp/ne_10m_admin_1.sql           /tmp/data/naturalearth/ne_10m_admin_1.sql
COPY --from=naturalearth-build /tmp/ne_10m_rivers.sql            /tmp/data/naturalearth/ne_10m_rivers.sql
COPY --from=hydrorivers-build  /out/hydrorivers.sql              /tmp/data/hydrorivers/hydrorivers.sql
COPY --from=osmlondon-build    /tmp/osm_roads.sql                /tmp/data/osm-london/osm_roads.sql
COPY --from=osmlondon-build    /tmp/osm_parks.sql                /tmp/data/osm-london/osm_parks.sql

# Cloned postgres/pgloader repos from the commitlog-data stage, layered on
# top of the commitlog.sql schema file the blanket `COPY data/` above already
# placed at /tmp/data/commitlog/.
COPY --from=commitlog-data --chown=taop:taop /data/commitlog/postgresql /tmp/data/commitlog/postgresql
COPY --from=commitlog-data --chown=taop:taop /data/commitlog/pgloader   /tmp/data/commitlog/pgloader

ARG HASHTAG_URL=""
RUN if [ -n "$HASHTAG_URL" ]; then \
      mkdir -p /tmp/data/hashtag && \
      curl -fSL --retry 3 -o /tmp/data/hashtag/tweets.csv "$HASHTAG_URL"; \
    else echo "HASHTAG_URL unset — skipping hashtag CSV fetch"; fi

ENV PGDATA=/tmp/pgdata \
    PGHOST=localhost \
    PGPORT=5432 \
    PGUSER=taop \
    PGPASSWORD=taop \
    PGDATABASE=taop \
    SCAN34_DIR=/tmp/data/scan34 \
    RATES_DIR=/tmp/data/rates \
    MAGIC_DIR=/tmp/data/magic \
    F1DB_DIR=/tmp/data/f1db \
    MOMA_DIR=/tmp/data/MoMA \
    OPENDATA_DIR=/tmp/data/opendata \
    EAV_DIR=/tmp/data/eav \
    SANDBOX_DIR=/tmp/data/sandbox \
    HASHTAG_DIR=/tmp/data/hashtag \
    HYDRORIVERS_DIR=/tmp/data/hydrorivers \
    NATURALEARTH_DIR=/tmp/data/naturalearth \
    NATURAL_EARTH_DIR=/tmp/data/natural_earth \
    OSM_LONDON_DIR=/tmp/data/osm-london \
    LASTFM_DIR=/tmp/data/lastfm \
    COUNTER_DIR=/tmp/data/counter \
    CHINOOK_SQL=/tmp/cdstore/Chinook_PostgreSql.sql \
    GEONAMES_DIR=/tmp/data/geonames \
    SHAKESPEARE_DIR=/tmp/data/shakespeare \
    SHAKESPEARE_PLAY_XML=/tmp/data/shakespeare/shakes/dream.xml \
    COMMITLOG_DIR=/tmp/data/commitlog

RUN set -eux; \
    \
    # Initialise a temporary postgres cluster
    mkdir -p "$PGDATA"; \
    chown postgres:postgres "$PGDATA"; \
    gosu postgres initdb \
        --pgdata="$PGDATA" \
        --username=postgres \
        --auth-local=trust \
        --auth-host=trust \
        --encoding=UTF8; \
    \
    # Trust all local connections so taop can connect without extra config.
    # Plain `psql -U postgres` (no -h) resolves "localhost" via getaddrinfo,
    # which returns ::1 (IPv6) before 127.0.0.1 in this build environment —
    # need both entries or the IPv6 attempt gets rejected before falling
    # back to IPv4.
    { echo "local all all trust"; \
      echo "host  all all 127.0.0.1/32 trust"; \
      echo "host  all all ::1/128 trust"; } > "$PGDATA/pg_hba.conf"; \
    \
    # Start postgres (pg_stat_statements must be preloaded at server start)
    gosu postgres pg_ctl -D "$PGDATA" \
        -o "-c listen_addresses=localhost -c shared_preload_libraries=pg_stat_statements" \
        -w start; \
    \
    # Bootstrap: role + database + extensions.  -d postgres is required here
    # even though it looks redundant: PGDATABASE=taop is already exported
    # (ENV above) for the taop load-data step further down, but the "taop"
    # database doesn't exist yet at this point — psql would otherwise pick
    # up PGDATABASE and fail with "database taop does not exist".
    #
    # SUPERUSER: in the real (non-seed) docker-compose flow, the official
    # entrypoint runs `initdb --username=taop` directly, making taop the
    # cluster's bootstrap superuser automatically (that's what an initdb
    # --username always is). This seed stage instead bootstraps a "postgres"
    # superuser via initdb and creates "taop" as a second role after the
    # fact — without SUPERUSER here that second role can't CREATE EXTENSION
    # postgis (naturalearth/hydrorivers/osm-london/natural-earth all do,
    # during load-data below), unlike its real-flow counterpart.
    psql -U postgres -d postgres -c "CREATE ROLE taop WITH LOGIN SUPERUSER PASSWORD 'taop'"; \
    psql -U postgres -d postgres -c "CREATE DATABASE taop OWNER taop"; \
    psql -U postgres -d taop -f /docker-entrypoint-initdb.d/01-extensions.sql; \
    \
    # Load all book datasets
    /usr/local/bin/taop load-data; \
    \
    # commitlog is intentionally excluded from load-data's automatic sweep
    # (*commands-to-skip* in load-data.lisp) because it's normally the
    # separate, opt-in `docker compose run --rm commitlog` service — invoke
    # it explicitly here so its rows end up in the seed dump too.
    /usr/local/bin/taop commitlog; \
    \
    # Dump the seeded database as gzipped SQL.
    # The postgres entrypoint auto-decompresses .sql.gz files in initdb.d
    # and pipes them through psql on first start of a fresh volume.
    pg_dump -U taop --no-owner --no-acl taop \
        | gzip -9 > /docker-entrypoint-initdb.d/02-taop-seed.sql.gz; \
    \
    # Stop postgres and clean up everything that doesn't belong in the image
    gosu postgres pg_ctl -D "$PGDATA" -w stop; \
    rm -rf "$PGDATA" /tmp/data /tmp/cdstore \
           /usr/local/bin/taop \
           /usr/src/taop

# ─────────────────────────────────────────────────────────────────────────────
# Final image: postgres-base + extension init script + seed dump
# ─────────────────────────────────────────────────────────────────────────────
FROM postgres-base

COPY --from=seed /docker-entrypoint-initdb.d/02-taop-seed.sql.gz \
                 /docker-entrypoint-initdb.d/02-taop-seed.sql.gz
