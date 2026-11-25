# Dockerfile for cpuminer (minerd)
#
# usage: docker run --rm ghcr.io/bsv-blockchain/cpuminer:<tag> --url <url> --userpass <user:pass> [options]
#
# Two stages: the toolchain (gcc, automake, kernel headers) stays in the build
# stage; the runtime stage carries only minerd and the libraries it links.

FROM ubuntu:24.04 AS build

RUN apt-get update -qq && \
    apt-get install -qqy --no-install-recommends \
        automake \
        ca-certificates \
        gcc \
        libc6-dev \
        libcurl4-openssl-dev \
        make && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN ./autogen.sh && \
    ./configure CFLAGS="-O3" && \
    make -j"$(nproc)" && \
    strip minerd

FROM ubuntu:24.04

RUN apt-get update -qq && \
    apt-get install -qqy --no-install-recommends \
        ca-certificates \
        libcurl4t64 && \
    rm -rf /var/lib/apt/lists/* && \
    useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin miner

COPY --from=build /src/minerd /usr/local/bin/minerd

USER 10001

ENTRYPOINT ["minerd"]
