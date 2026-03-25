FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y curl ca-certificates tar bash && \
    rm -rf /var/lib/apt/lists/*

ARG ABCHAIN=abcore
ARG NETWORK=mainnet
ARG USE_AB_BLOCKCHAIN_VERSION=""
ARG USE_AB_DEPLOY_VERSION=""

ENV ABCHAIN=${ABCHAIN}
ENV NETWORK=${NETWORK}
ENV USE_AB_BLOCKCHAIN_VERSION=${USE_AB_BLOCKCHAIN_VERSION}
ENV USE_AB_DEPLOY_VERSION=${USE_AB_DEPLOY_VERSION}

WORKDIR /opt/ab

COPY download.sh /opt/ab/download.sh
COPY ab.sh /opt/ab/ab.sh
RUN chmod +x /opt/ab/download.sh /opt/ab/ab.sh && /opt/ab/download.sh
