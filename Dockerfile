# Multi-stage build for strfry relay with noteguard plugin

# Stage 1: Build strfry
FROM debian:bookworm-slim AS strfry-builder

RUN apt-get update && apt-get install -y \
    git \
    g++ \
    make \
    libssl-dev \
    zlib1g-dev \
    liblmdb-dev \
    libflatbuffers-dev \
    libsecp256k1-dev \
    libzstd-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone https://github.com/hoytech/strfry.git && \
    cd strfry && \
    git submodule update --init && \
    make setup-golpe && \
    make -j2

# Stage 2: Build noteguard
FROM rust:1.75-bookworm AS noteguard-builder

WORKDIR /build

RUN git clone https://github.com/damus-io/noteguard.git && \
    cd noteguard && \
    cargo build --release

# Stage 3: Runtime image
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    libssl3 \
    zlib1g \
    liblmdb0 \
    libsecp256k1-1 \
    libzstd1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy strfry binary and required files
COPY --from=strfry-builder /build/strfry/strfry /app/
COPY --from=strfry-builder /build/strfry/strfry.conf /app/

# Copy noteguard binary
COPY --from=noteguard-builder /build/noteguard/target/release/noteguard /app/

# Copy configuration files
COPY strfry.conf /app/
COPY noteguard.toml /app/

# Create data directory
RUN mkdir -p /app/strfry-db

# Expose relay port
EXPOSE 7777

CMD ["./strfry", "relay"]
