FROM rust:1.81-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        pkg-config \
        libssl-dev \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN cargo build --release

RUN useradd --create-home grimoire && \
    mkdir -p /notes && \
    chown -R grimoire:grimoire /notes

USER grimoire
ENV GRIMOIRE_DIR=/notes
VOLUME ["/notes"]

CMD ["./target/release/grimoire"]
