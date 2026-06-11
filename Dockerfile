# ---- build stage ----
# Trixie to match the python:3.11-slim runtime (same Debian release => ABI-matched
# shared libs). Trixie ships protobuf 3.21.12, which the committed *.pb.cc need.
# FROM debian:trixie-slim AS builder
FROM databricksruntime/standard:17.3-LTS AS builder

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
# FROM python:3.11-slim AS runtime
FROM databricksruntime/standard:17.3-LTS AS runtime

# FRSample bakes in the project's own static libs (FlightRecordEngine /
# FlightRecordStandardizationCpp), but links the third-party deps dynamically
# (find_library / protobuf::libprotobuf / CURL_LIBRARIES all resolve to .so),
# so the runtime image still needs these shared objects. Package names verified
# on python:3.11-slim (Debian 13 trixie); libssl3 and libstdc++6 ship in the base.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libtomcrypt1 \
        libtommath1 \
        libprotobuf32t64 \
        libcurl4t64 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /parse_flyrecord/FRSample .
COPY --from=builder /parse_flyrecord/python/frsample.py .
COPY sample-flightlog.txt .

ARG SDK_KEY="--"
ENV SDK_KEY=${SDK_KEY}

ENV PYTHONPATH=/app
ENV FRSAMPLE_BIN=/app/FRSample

# The Python wrapper drives FRSample and always prints JSON to stdout
# (`{}` plus a stderr message on failure).
# Usage: docker run --rm -e SDK_KEY=... -v "$(pwd):/data" <img> /data/flight.txt
ENTRYPOINT ["python3", "/app/frsample.py"]
