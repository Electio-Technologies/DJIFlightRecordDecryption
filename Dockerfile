# ---- build stage ----
# Trixie ships protobuf 3.21.12, which the committed *.pb.cc need.
FROM debian:trixie-slim AS builder

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        libssl-dev \
        libcurl4-openssl-dev \
        libtomcrypt-dev \
        libtommath-dev \
        libprotobuf-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /parse_flyrecord

COPY . .

RUN cd build && sh generate.sh

# ---- runtime stage ----
FROM debian:trixie-slim AS runtime

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libtomcrypt1 \
        libtommath1 \
        libprotobuf32t64 \
        libcurl4t64 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /parse_flyrecord/FRSample .

# Usage: docker run --rm -e SDK_KEY=... -v "$(pwd):/data" <img> /data/flightlog.txt
ENTRYPOINT ["./FRSample"]
