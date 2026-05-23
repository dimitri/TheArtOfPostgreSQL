#
# Devcontainer image for The Art of PostgreSQL.
#
# Stages 1 (base) and 2 (taop-build) are byte-for-byte identical to
# docker/taop.Dockerfile so that both docker/taop.Dockerfile and this file
# share the same GHA buildx cache (scope=taop-build).  The SBCL compilation
# and the commitlog git clones are therefore never repeated across workflows.
#

# ── Stage 1: base ────────────────────────────────────────────────────────────
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

# ── Stage 2: taop-build ───────────────────────────────────────────────────────
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
# Belt-and-suspenders: tooling/bin/taop is excluded by the root .dockerignore,
# but delete it here too so a stale host binary never silently skips make taop.
RUN rm -f ./bin/taop

RUN make taop
RUN sudo install -D -m 755 ./bin/taop /usr/local/bin/taop

USER taop

# ── Stage 2b: commitlog-data ──────────────────────────────────────────────────
#
# Clones the PostgreSQL and pgloader git repositories at image build time.
# Baking them in means `taop commitlog` runs inside the Codespace without any
# network access and without the multi-minute git-clone delay.
#
FROM base AS commitlog-data

COPY --chown=taop:taop data/ /data/

USER taop
WORKDIR /data/commitlog
RUN make postgres
RUN make pgloader

# ── Stage 3: devcontainer ─────────────────────────────────────────────────────
#
# Shell environment with every tool a reader needs:
#   taop      – load datasets, run book examples
#   psql      – interactive SQL (postgresql-client, from base)
#   regresql  – run query regression tests
#   python3   – run cdstore application (from base)
#
# No ENTRYPOINT: the devcontainer runtime (VS Code / Codespaces) attaches via
# /bin/sh, and the service is kept alive by `command: sleep infinity` in
# .devcontainer/docker-compose.yml.
#
FROM base AS devcontainer

# taop binary compiled in stage 2 (hits the shared GHA taop-build cache)
COPY --from=taop-build /usr/local/bin/taop /usr/local/bin/taop

# pubnames runtime assets needed by `taop pubnames` (matches docker/taop.Dockerfile)
COPY --from=taop-build \
    /usr/src/taop/build/quicklisp/local-projects/pubnames/ \
    /usr/src/taop/build/quicklisp/local-projects/pubnames/

# All datasets, including the PostgreSQL and pgloader git repos cloned in 2b.
# The taop *_DIR environment variables (set in docker-compose.yml) all point
# into /data/, so no path changes are needed.
COPY --from=commitlog-data --chown=taop:taop /data/ /data/

# Chinook SQL baked in at a stable path so CHINOOK_SQL=/data/Chinook_PostgreSql.sql
# works without referencing the live workspace checkout.
COPY --chown=taop:taop apps/cdstore/Chinook_PostgreSql.sql /data/Chinook_PostgreSql.sql

# Go toolchain + regresql.
# Copy from the official golang image rather than apt-get install golang-go
# (debian bookworm ships Go 1.19; regresql requires a more recent version).
# Use an explicit GOPATH under /tmp so the path is predictable regardless of
# which user is active during the build (root vs taop).
COPY --from=golang:1.23-bookworm /usr/local/go /usr/local/go
ENV PATH=/usr/local/go/bin:$PATH
RUN GOPATH=/tmp/gopath go install github.com/dimitri/regresql@latest && \
    install -m 755 /tmp/gopath/bin/regresql /usr/local/bin/regresql && \
    rm -rf /tmp/gopath

# Book psql prompt / formatting configuration
COPY psqlrc /home/taop/.psqlrc

# Standard Codespaces mount point; VS Code mounts the repo checkout here.
RUN mkdir -p /workspaces && chown taop:taop /workspaces

USER taop
WORKDIR /workspaces
