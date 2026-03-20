# Build stage: compiles the taop binary
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

