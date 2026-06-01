FROM ubuntu:22.04

ARG SDK_KEY
ENV SDK_KEY=${SDK_KEY}

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget git gcc g++ make cmake curl libssl-dev libcurl4-openssl-dev libtomcrypt-dev libtommath-dev zlib1g-dev

WORKDIR /parse_flyrecord

COPY . .

WORKDIR /parse_flyrecord/dji-flightrecord-kit/build/Ubuntu/FRSample
RUN sh generate.sh

ENTRYPOINT ["./FRSample"]