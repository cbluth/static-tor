FROM docker.io/library/ubuntu:22.04 as build
SHELL ["/bin/bash", "-c"]
WORKDIR /usr/local/share/src
ENV DEBIAN_FRONTEND="noninteractive"

ENV ZLIB_VERSION="v1.2.12"
ENV TOR_VERSION="tor-0.4.7.8"
ENV OPENSSL_VERSION="OpenSSL_1_1_1q"
ENV LIBEVENT_VERSION="release-2.1.12-stable"

# tools
RUN apt update && \
    apt install --no-install-recommends -y \
        automake \
        autotools-dev \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg \
        libtool \
        pkg-config

# zlib
RUN git clone \
        --depth 1 \
        --branch ${ZLIB_VERSION} \
        https://github.com/madler/zlib \
        zlib && \
    pushd zlib && \
    ./configure --prefix=${PWD}/install && \
    make -j$(nproc) --silent && \
    make -j$(nproc) check && \
    make install && \
    popd

# openssl
RUN git clone \
        --depth 1 \
        --branch ${OPENSSL_VERSION} \
        https://github.com/openssl/openssl \
        openssl && \
    pushd openssl && \
    ./config \
        --prefix=${PWD}/install \
        no-dso \
        no-shared \
        && \
    make -j$(nproc) --silent && \
    make install && \
    popd

# libevent
RUN git clone \
        --depth 1 \
        --branch ${LIBEVENT_VERSION} \
        https://github.com/libevent/libevent \
        libevent && \
    pushd libevent && \
    ./autogen.sh && \
    ./configure \
        --with-pic \
        --enable-static \
        --disable-shared \
        --disable-samples \
        --disable-openssl \
        --prefix=${PWD}/install \
        && \
    make -j$(nproc) --silent && \
    make install && \
    popd

# tor
RUN git clone \
        --depth 1 \
        --branch ${TOR_VERSION} \
        https://github.com/torproject/tor \
        tor && \
    pushd tor && \
    ./autogen.sh && \
    ./configure \
        --prefix=/usr/local \
        --disable-manpage \
        --disable-asciidoc \
        --enable-static-tor \
        --enable-static-zlib \
        --disable-html-manual \
        --enable-static-openssl \
        --enable-static-libevent \
        --with-zlib-dir=${PWD}/../zlib/install \
        --with-openssl-dir=${PWD}/../openssl/install \
        --with-libevent-dir=${PWD}/../libevent/install \
        && \
    make -j$(nproc) --silent && \
    make -j$(nproc) check && \
    make install && \
    popd

# torsocks
ENV TORSOCKS_VERSION="master"
RUN git clone \
        --depth 1 \
        --branch ${TORSOCKS_VERSION} \
        https://git.torproject.org/torsocks.git \
        torsocks && \
    pushd torsocks && \
    ./autogen.sh && \
    ./configure \
        --prefix=/usr/local \
        --enable-static=yes \
        && \
    make -j$(nproc) --silent && \
    make -j$(nproc) check && \
    make install && \
    popd

FROM docker.io/library/ubuntu:22.04
COPY --from=build \
    /usr/local/bin/* /usr/local/bin/
COPY --from=build \
    /usr/local/lib/torsocks /usr/local/lib/torsocks
