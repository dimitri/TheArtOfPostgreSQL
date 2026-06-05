# PostgreSQL server image for the lab, extended with the Citus HyperLogLog
# (hll) extension built from source.  The official postgres:*-alpine image
# ships pg_config, the server headers and PGXS but no compiler, so we add
# build-base + git in a throwaway virtual package, compile hll, then drop the
# build tools.  hll is C++, so libstdc++ is kept as a runtime dependency.
#
# with_llvm=no skips JIT bitcode generation, which avoids pulling clang/llvm.
ARG POSTGRES_VERSION=16
FROM postgres:${POSTGRES_VERSION}-alpine

ARG HLL_VERSION=v2.18

RUN set -eux; \
    apk add --no-cache libstdc++; \
    apk add --no-cache --virtual .hll-build git build-base; \
    git clone --depth 1 --branch "${HLL_VERSION}" \
        https://github.com/citusdata/postgresql-hll.git /tmp/hll; \
    make -C /tmp/hll PG_CONFIG=/usr/local/bin/pg_config with_llvm=no; \
    make -C /tmp/hll PG_CONFIG=/usr/local/bin/pg_config with_llvm=no install; \
    rm -rf /tmp/hll; \
    apk del .hll-build
