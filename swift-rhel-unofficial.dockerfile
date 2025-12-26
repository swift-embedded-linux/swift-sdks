ARG DISTRIBUTION_NAME=fedora
ARG DISTRIBUTION_VERSION=39
FROM ${DISTRIBUTION_NAME}:${DISTRIBUTION_VERSION}
ARG EXTRA_PACKAGES
RUN dnf -y update && \
    dnf -y install \
        tar gzip \
        systemd-devel \
        glibc-headers \
        libcurl-devel \
        libxml2-devel \
        python3-devel \
        libstdc++-devel \
        libstdc++-static \
        ${EXTRA_PACKAGES}

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
    ARCH_NAME="$(rpm --eval '%{_arch}')"; \
    url=; \
    case "${ARCH_NAME##*-}" in \
        'x86_64') \
            OS_ARCH_SUFFIX=''; \
            ;; \
        'aarch64') \
            OS_ARCH_SUFFIX='-aarch64'; \
            ;; \
        *) echo >&2 "error: unsupported architecture: '$ARCH_NAME'"; exit 1 ;; \
    *) echo >&2 "error: unsupported architecture: '$ARCH_NAME'"; exit 1 ;; \
    esac; \
    SWIFT_WEBDIR="$SWIFT_WEBROOT/$SWIFT_BRANCH/$(echo $SWIFT_PLATFORM | tr -d .)$OS_ARCH_SUFFIX" \
    && SWIFT_BIN_URL="$SWIFT_WEBDIR/$SWIFT_TAG/$SWIFT_TAG-$SWIFT_PLATFORM$OS_ARCH_SUFFIX.tar.gz" \
    && echo $SWIFT_BIN_URL \
    # - Grab curl here so we cache better up above
    # - Download the GPG keys, Swift toolchain, and toolchain signature, and verify.
    && curl -fsSL "$SWIFT_BIN_URL" -o swift.tar.gz \
    # - Unpack the toolchain, set libs permissions, and clean up.
    && tar -xzf swift.tar.gz --directory / --strip-components=1 \
    && chmod -R o+r /usr/lib/swift

# Print Installed Swift Version
RUN swift --version
