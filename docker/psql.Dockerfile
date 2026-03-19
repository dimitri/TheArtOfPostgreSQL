FROM postgres:16-alpine

COPY queries/ /usr/src/taop/queries/
COPY apps/cdstore/ /usr/src/taop/cdstore/
COPY data/ /data/
COPY psqlrc /home/postgres/.psqlrc

WORKDIR /usr/src/taop/queries
