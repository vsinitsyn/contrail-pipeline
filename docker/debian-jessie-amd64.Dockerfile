FROM debian:jessie

ARG artifactory_url
ARG timestamp

ENV ARTIFACTORY_URL $artifactory_url
ENV TIMESTAMP $timestamp

## Configure APT mirror
# TODO: remove this while building from customized image with
# apt-transport-https and curl already installed
RUN if [ -z "${ARTIFACTORY_URL}" ]; then \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y curl && \
    ;else \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https curl && \
        echo | openssl s_client -showcerts -connect `echo $ARTIFACTORY_URL | cut -d '/' -f 3` 2>/dev/null | awk '/BEGIN CERTIFICATE/{print;flag=1;next}/END CERTIFICATE/{print;flag=0}flag' >/usr/local/share/ca-certificates/artifactory.crt && \
        update-ca-certificates && \
        echo "deb ${ARTIFACTORY_URL}/in-debian-${TIMESTAMP} jessie main" >/etc/apt/sources.list && \
        echo "deb ${ARTIFACTORY_URL}/in-debian-${TIMESTAMP} jessie-updates main" >>/etc/apt/sources.list && \
        echo "deb ${ARTIFACTORY_URL}/in-debian-security-${TIMESTAMP} jessie/updates main" >>/etc/apt/sources.list && \
    ;fi; \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install requirements for Contrail build
RUN apt-get update && apt-get install -y \
        build-essential \
        python-dev \
        scons \
        unzip \
        vim-nox \
        wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
