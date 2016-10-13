FROM debian:jessie

ARG artifactory_url
ARG timestamp

ENV ARTIFACTORY_URL $artifactory_url
ENV TIMESTAMP $timestamp

## Configure APT mirror
RUN [ "x${ARTIFACTORY_URL}" != "x" ] || exit 0 \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo | openssl s_client -showcerts -connect `echo $ARTIFACTORY_URL | cut -d '/' -f 3` 2>/dev/null | awk '/BEGIN CERTIFICATE/{print;flag=1;next}/END CERTIFICATE/{print;flag=0}flag' >/usr/local/share/ca-certificates/artifactory.crt \
    && update-ca-certificates \
    && echo "deb ${ARTIFACTORY_URL}/in-debian-${TIMESTAMP} jessie main" >/etc/apt/sources.list \
    && echo "deb ${ARTIFACTORY_URL}/in-debian-${TIMESTAMP} jessie-updates main" >>/etc/apt/sources.list \
    && echo "deb ${ARTIFACTORY_URL}/in-debian-security-${TIMESTAMP} jessie/updates main" >>/etc/apt/sources.list \
    && wget -O - ${ARTIFACTORY_URL}/in-tcpcloud-apt-${TIMESTAMP}/public.gpg | apt-key add - \
    && echo "deb ${ARTIFACTORY_URL}/in-tcpcloud-apt-${TIMESTAMP}/debian/ jessie extra" >>/etc/apt/sources.list

# Install requirements for Contrail build
RUN apt-get update && apt-get install -y \
        build-essential \
        git \
        vim-nox \
        wget \
        scons \
        libxml2-utils \
        python-lxml \
        autoconf \
        automake \
        libtool-bin \
        patch \
        unzip \
        pkg-config \
        javahelper \
        ant \
        python-setuptools \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
