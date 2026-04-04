#
# Build stage: compiles the taop binary
#
FROM debian:bookworm-slim AS taop-build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    sbcl \
    curl \
    git \
    make \
    sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/taop

RUN useradd -m taop && \
    usermod -aG sudo taop && \
    echo 'taop ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    chown -R taop:taop /usr/src/taop

USER taop
WORKDIR /usr/src/taop

COPY --chown=taop:taop tooling ./

RUN make quicklisp
RUN make pubnames
RUN make qload
RUN make taop
RUN sudo install -D -m 755 ./bin/taop /usr/local/bin/taop

WORKDIR /usr/src/taop

#
# Final stage: taop container with data, queries, and apps
#
FROM taop-build AS taop

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    python3 \
    python3-pip \
    python3-psycopg2 \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=taop:taop queries/ /usr/src/taop/queries/
COPY --chown=taop:taop apps/cdstore/ /usr/src/taop/cdstore/
COPY --chown=taop:taop data/ /data/
COPY --chown=taop:taop starter-kit/ /starter-kit/

USER taop
WORKDIR /usr/src/taop/queries

ENTRYPOINT ["taop"]
CMD ["--help"]

#
# commitlog container: fetches git repos at build time
#
# Avoid dependency with taop builds.
#
FROM debian:bookworm-slim AS commitlog-data

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    python3 \
    python3-pip \
    python3-psycopg2 \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=taop:taop queries/ /usr/src/taop/queries/
COPY --chown=taop:taop apps/cdstore/ /usr/src/taop/cdstore/
COPY --chown=taop:taop data/ /data/

USER taop

# Fetch git repositories at build time
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

