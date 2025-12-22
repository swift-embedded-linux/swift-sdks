ARG DISTRIBUTION_NAME=ubuntu
ARG DISTRIBUTION_VERSION=jammy
FROM ${DISTRIBUTION_NAME}:${DISTRIBUTION_VERSION}

ARG EXTRA_PACKAGES
RUN apt-get update && apt-get -y upgrade && \
    apt-get -y install wget clang libsystemd-dev zlib1g-dev libcurl4-openssl-dev libxml2-dev ${EXTRA_PACKAGES} && \
    apt-get -y clean

ARG SWIFT_VERSION
ARG DISTRIBUTION_NAME=ubuntu
ARG DISTRIBUTION_VERSION=jammy
ARG ROOT_URL=https://github.com/swift-embedded-linux/armhf-debian/releases/download
ARG PACKAGE_NAME=swift-${SWIFT_VERSION}-RELEASE-${DISTRIBUTION_NAME}-${DISTRIBUTION_VERSION}-armv7-install.tar.gz
RUN wget ${ROOT_URL}/${SWIFT_VERSION}/${PACKAGE_NAME} && tar -xf ${PACKAGE_NAME} -C / && rm ${PACKAGE_NAME}
