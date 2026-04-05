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

#
# Final stage: taop container with data, queries, and apps
#
FROM debian:bookworm-slim AS taop

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
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

USER taop

COPY --chown=taop:taop queries/ /usr/src/taop/queries/
COPY --chown=taop:taop apps/cdstore/ /usr/src/taop/cdstore/
COPY --chown=taop:taop data/ /data/
COPY --chown=taop:taop starter-kit/ /starter-kit/

COPY --from=taop-build /usr/local/bin/taop /usr/local/bin/taop

# also install the runtime files needed for the pubnames dataset
COPY --from=taop-build /usr/src/taop/build/quicklisp/local-projects/pubnames/ /usr/src/taop/build/quicklisp/local-projects/pubnames/

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

