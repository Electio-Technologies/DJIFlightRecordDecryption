FROM ubuntu:26.04

ARG SDK_KEY
ENV SDK_KEY=${SDK_KEY}

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y gcc g++ make cmake curl libssl-dev libcurl4-openssl-dev libtomcrypt-dev libtommath-dev libprotobuf-dev

WORKDIR /parse_flyrecord

COPY . .

RUN cd build && sh generate.sh

ENTRYPOINT ["./FRSample"]