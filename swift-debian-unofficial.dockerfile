ARG DISTRIBUTION_NAME=debian
ARG DISTRIBUTION_VERSION=bullseye
FROM ${DISTRIBUTION_NAME}:${DISTRIBUTION_VERSION}
ARG EXTRA_PACKAGES
RUN apt-get update && apt-get -y upgrade && \
    apt-get -y install wget clang libsystemd-dev zlib1g-dev libcurl4-openssl-dev libxml2-dev ${EXTRA_PACKAGES} && \
    apt-get -y clean

# Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little
ARG SWIFT_PLATFORM
ARG SWIFT_BRANCH
ARG SWIFT_TAG
ARG SWIFT_WEBROOT=https://download.swift.org

ENV SWIFT_PLATFORM=$SWIFT_PLATFORM \
    SWIFT_BRANCH=$SWIFT_BRANCH \
    SWIFT_TAG=$SWIFT_TAG \
    SWIFT_WEBROOT=$SWIFT_WEBROOT

RUN set -e; \
    ARCH_NAME="$(dpkg --print-architecture)"; \
    url=; \
    case "${ARCH_NAME##*-}" in \
    'amd64') \
    OS_ARCH_SUFFIX=''; \
    ;; \
    'arm64') \
    OS_ARCH_SUFFIX='-aarch64'; \
    ;; \
    *) echo >&2 "error: unsupported architecture: '$ARCH_NAME'"; exit 1 ;; \
    esac; \
    SWIFT_WEBDIR="$SWIFT_WEBROOT/$SWIFT_BRANCH/$(echo $SWIFT_PLATFORM | tr -d .)$OS_ARCH_SUFFIX" \
    && SWIFT_BIN_URL="$SWIFT_WEBDIR/$SWIFT_TAG/$SWIFT_TAG-$SWIFT_PLATFORM$OS_ARCH_SUFFIX.tar.gz" \
    && echo $SWIFT_BIN_URL \
    # - Grab curl here so we cache better up above
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -q update && apt-get -q install -y curl && rm -rf /var/lib/apt/lists/* \
    # - Download the GPG keys, Swift toolchain, and toolchain signature, and verify.
    && curl -fsSL "$SWIFT_BIN_URL" -o swift.tar.gz \
    # - Unpack the toolchain, set libs permissions, and clean up.
    && tar -xzf swift.tar.gz --directory / --strip-components=1 \
    && chmod -R o+r /usr/lib/swift \
    && apt-get purge --auto-remove -y curl

# Print Installed Swift Version
RUN swift --version
