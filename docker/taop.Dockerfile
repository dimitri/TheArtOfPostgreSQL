FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    python3 \
    python3-pip \
    python3-psycopg2 \
    sbcl \
    curl \
    git \
    make \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# COPY data and queries in the taop container
COPY --chown=taop:taop queries/ /usr/src/taop/queries/
COPY --chown=taop:taop apps/cdstore/ /usr/src/taop/cdstore/
COPY --chown=taop:taop data/ /data/

# Prepare the commitlog data, fetch postgres and pgloader git repos
WORKDIR /data/commitlog

RUN make postgres

# Now build our own data loading tool (taop)
WORKDIR /usr/src/taop

RUN useradd -m taop && \
    usermod -aG sudo taop && \
    echo 'taop ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    chown -R taop:taop /usr/src/taop

USER taop
WORKDIR /usr/src/taop

COPY --chown=taop:taop tooling/ .

# split Common Lisp build operations to optimize for docker caching
RUN make quicklisp
RUN make pubnames
RUN make qload
RUN make taop
RUN sudo install -D -m 755 ./bin/taop /usr/local/bin/taop

# skip make clean, we need some of the files at run-time:
# /usr/src/taop/build/quicklisp/local-projects/pubnames/pub.xml

WORKDIR /usr/src/taop/queries

ENTRYPOINT ["taop"]
CMD ["--help"]
