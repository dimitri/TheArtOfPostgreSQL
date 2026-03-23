# Final stage: taop container with data, queries, and apps
ARG BUILD_IMAGE=taop-build
FROM ${BUILD_IMAGE}

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
