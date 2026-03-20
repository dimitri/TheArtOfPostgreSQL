FROM postgres:16-alpine

USER postgres

COPY queries/ /usr/src/taop/queries/
COPY apps/cdstore/ /usr/src/taop/cdstore/
COPY data/ /data/
COPY psqlrc /var/lib/postgresql/.psqlrc

WORKDIR /usr/src/taop/queries
