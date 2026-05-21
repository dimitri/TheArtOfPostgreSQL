ARG POSTGRES_VERSION=16
FROM postgres:${POSTGRES_VERSION}-alpine

USER postgres

COPY queries/ /usr/src/taop/queries/
COPY apps/cdstore/ /usr/src/taop/cdstore/
COPY data/ /data/
COPY starter-kit/ /starter-kit/
COPY psqlrc /var/lib/postgresql/.psqlrc

WORKDIR /usr/src/taop/queries
