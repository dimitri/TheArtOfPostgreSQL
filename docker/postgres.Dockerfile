# PostgreSQL + PostGIS server image for the lab, additionally extended with the
# Citus HyperLogLog (hll) extension built from source.
#
# Built from plain debian:bookworm-slim + the PGDG apt repo (apt.postgresql.org)
# rather than FROM postgis/postgis: that image is Debian 11 "bullseye", which
# (a) only ships arch-forced-amd64 (no arm64 manifest, so it's always QEMU-
# emulated on Apple Silicon even though PGDG itself publishes native arm64
# packages), and (b) only has sbcl 2.1.1 in its own apt repo, too old to
# compile taop's CFFI dependency (needs SB-ALIEN:DEFINE-ALIEN-CALLABLE) --
# relevant for docker/seeded-postgres.Dockerfile, which needs the taop
# binary and this image's Postgres to share one filesystem and therefore one
# OS/glibc. Building our own on bookworm keeps everything on one consistent,
# natively-multi-arch base instead of straddling two Debian releases.
#
# The docker-entrypoint.sh / docker-ensure-initdb.sh / gosu step-down tooling
# is copied from the official postgres image rather than reimplemented --
# PGDATA initialization, docker-entrypoint-initdb.d handling, and signal
# forwarding are exactly the kind of edge cases not worth re-solving by hand.
ARG POSTGRES_VERSION=16
ARG POSTGIS_VERSION=3.4

FROM postgres:${POSTGRES_VERSION}-bookworm AS pg-entrypoint

FROM debian:bookworm-slim

ARG POSTGRES_VERSION=16
ARG POSTGIS_VERSION=3.4
ARG HLL_VERSION=v2.18
# PGDG's apt package names always use the bare major number, e.g.
# postgresql-19 -- but the official postgres image (and this Dockerfile's
# POSTGRES_VERSION/pg-entrypoint stage above) tags pre-release builds as
# "19beta3-bookworm", not "19-bookworm". PG_MAJOR defaults to POSTGRES_VERSION
# (the common case once a version is GA) but must be overridden to the bare
# major, e.g. `--build-arg PG_MAJOR=19`, while POSTGRES_VERSION is still a
# betaN/rcN tag.
ARG PG_MAJOR=${POSTGRES_VERSION}

# explicitly set user/group IDs, matching the official postgres image
# (see https://github.com/docker-library/postgres/issues/274)
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
# only carries PostgreSQL 15. The trailing "${PG_MAJOR}" component (in
# addition to "main") matters during a beta cycle: PGDG publishes
# pre-release packages for the in-development major to a separate
# per-version component before they graduate to "main" at GA (confirmed by
# inspecting the official postgres:19beta3-bookworm image's own
# sources.list, which enables "main 19" for exactly this reason) --
# harmless to always include, since it's simply empty for a GA major.
RUN install -d /usr/share/postgresql-common/pgdg && \
    curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail \
        https://www.postgresql.org/media/keys/ACCC4CF8.asc && \
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main ${PG_MAJOR}" \
        > /etc/apt/sources.list.d/pgdg.list

ENV PG_MAJOR=${PG_MAJOR}
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

# citusdata/postgresql-hll's source hasn't been updated for PG 19's
# internal API changes yet (FuncnameGetCandidates() gained a parameter,
# and its -Werror build treats PG19's stricter C headers as fatal) --
# best-effort like plxslt above: build it if it compiles for this major,
# otherwise skip and leave `hll` uncreated (ch. 51's HyperLogLog queries
# will fail with "extension \"hll\" is not available" on this PG_MAJOR
# until upstream catches up).
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        git build-essential "postgresql-server-dev-${PG_MAJOR}"; \
    git clone --depth 1 --branch "${HLL_VERSION}" \
        https://github.com/citusdata/postgresql-hll.git /tmp/hll; \
    if make -C /tmp/hll with_llvm=no \
        PG_CONFIG="/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config"; then \
        make -C /tmp/hll with_llvm=no \
            PG_CONFIG="/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config" install; \
    else \
        echo "postgresql-hll does not build against PG ${PG_MAJOR} -- skipping (see comment above)"; \
    fi; \
    rm -rf /tmp/hll; \
    apt-get purge -y --auto-remove git build-essential "postgresql-server-dev-${PG_MAJOR}"; \
    rm -rf /var/lib/apt/lists/*

# ip4r (queries/08-extensions/50-geolocation-ip4r) is a PGDG package, not a
# stock contrib module — needs its own install, then just CREATE EXTENSION
# (done by docker-entrypoint-initdb.d/01-extensions.sql below).
RUN apt-get update && \
    apt-get install -y --no-install-recommends "postgresql-${PG_MAJOR}-ip4r" && \
    rm -rf /var/lib/apt/lists/*

# Runs once, only against a freshly-initialized (empty) data directory — see
# docker/initdb/01-extensions.sql for why these are needed and which one
# (plxslt) is intentionally left out.
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
