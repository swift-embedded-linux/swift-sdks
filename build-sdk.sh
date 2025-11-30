#!/bin/bash

set -e

source ./common-sdk.sh

SDK_GENERATOR_PATH=./swift-sdk-generator/.build/release/swift-sdk-generator

## Determine dockerfile to use
IMAGE_TAG=${IMAGE_TAG:=swift-sysroot:${SWIFT_VERSION}-${DISTRIBUTION_VERSION}}
case ${DISTRIBUTION_NAME} in
    "ubuntu" | "debian")
        DOCKERFILE="swift-debian.dockerfile"
        is_debian=true
        ;;
    "rhel")
        DOCKERFILE="swift-rhel.dockerfile"
        is_rhel=true
        ;;
    *)
        echo "Error: unsupported distribution ${DISTRIBUTION_NAME}"
        exit -1
        ;;
esac

## Determine generator distribution version, override any custom fields that are needed
GENERATOR_DISTRIBUTION_NAME=${DISTRIBUTION_NAME}
case ${DISTRIBUTION_VERSION} in
    "focal")
        GENERATOR_DISTRIBUTION_VERSION="20.04"
        ;;
    "jammy")
        GENERATOR_DISTRIBUTION_VERSION="22.04"
        ;;
    "noble")
        GENERATOR_DISTRIBUTION_VERSION="24.04"
        ;;
    "bullseye")
        DOCKERFILE="swift-debian-unofficial.dockerfile"
        GENERATOR_DISTRIBUTION_VERSION="11"
        # Set Swift versions for downloading runtime
        SWIFT_PLATFORM="ubuntu20.04"
        SWIFT_BRANCH="swift-$SWIFT_VERSION-release"
        SWIFT_TAG="swift-$SWIFT_VERSION-RELEASE"
        ;;
    "bookworm")
        GENERATOR_DISTRIBUTION_VERSION="12"
        # Some bookworm containers are missing this package..."
        EXTRA_PACKAGES="libstdc++-12-dev ${EXTRA_PACKAGES}"
        ;;
    "ubi9")
        GENERATOR_DISTRIBUTION_NAME="rhel"
        GENERATOR_DISTRIBUTION_VERSION="ubi9"
        ;;
    *)
        DOCKERFILE="swift-unofficial.dockerfile"
        GENERATOR_DISTRIBUTION_VERSION=${DISTRIBUTION_VERSION}
esac

## Determine target platform, triple and binutils to use
BINUTILS_NAME=""
case ${TARGET_ARCH} in
    "x86_64")
        LINUX_PLATFORM=amd64
        TARGET_TRIPLE=${TARGET_ARCH}-unknown-linux-gnu
        BINUTILS_NAME="x86_64-linux-gnu"
        ;;
    "aarch64")
        LINUX_PLATFORM=arm64
        TARGET_TRIPLE=${TARGET_ARCH}-unknown-linux-gnu
        BINUTILS_NAME="aarch64-linux-gnu"
        ;;
    "armv7")
        if [[ $is_rhel = true ]]; then
            echo "Error: RHEL-based distributions do NOT support armv7"
            exit -1
        fi

        LINUX_PLATFORM=armhf
        DOCKERFILE="swift-armv7.dockerfile"
        TARGET_TRIPLE=${TARGET_ARCH}-unknown-linux-gnueabihf
        BINUTILS_NAME="arm-linux-gnueabihf"
        ;;
    *)
        echo "Error: unsupported architecture ${TARGET_ARCH}"
        echo "Supported architectures are: x86_64, aarch64, armv7"
        exit -1
        ;;
esac

echo "Starting up qemu emulation"
docker run --privileged --rm tonistiigi/binfmt --install all

echo "Building ${IMAGE_TAG} image for ${LINUX_PLATFORM}..."
echo "Extra Packages: ${EXTRA_PACKAGES}"
docker build \
    --platform linux/${LINUX_PLATFORM} \
    --tag ${IMAGE_TAG} \
    --build-arg SWIFT_PLATFORM=${SWIFT_PLATFORM} \
    --build-arg SWIFT_BRANCH=${SWIFT_BRANCH} \
    --build-arg SWIFT_VERSION=${SWIFT_VERSION} \
    --build-arg SWIFT_TAG=${SWIFT_TAG} \
    --build-arg DISTRIBUTION_NAME=${DISTRIBUTION_NAME} \
    --build-arg DISTRIBUTION_VERSION=${DISTRIBUTION_VERSION} \
    --build-arg EXTRA_PACKAGES=${EXTRA_PACKAGES} \
    --file ${DOCKERFILE} \
    .

SDK_NAME=${SWIFT_VERSION}-RELEASE_${DISTRIBUTION_NAME}_${DISTRIBUTION_VERSION}_${TARGET_ARCH}

echo "Building Swift ${SWIFT_VERSION} ${DISTRIBUTION_NAME}-${DISTRIBUTION_VERSION} SDK for ${TARGET_ARCH}..."
${SDK_GENERATOR_PATH} make-linux-sdk \
    --swift-version ${SWIFT_VERSION}-RELEASE \
    --sdk-name ${SDK_NAME} \
    --with-docker \
    --from-container-image ${IMAGE_TAG} \
    --distribution-name ${GENERATOR_DISTRIBUTION_NAME} \
    --distribution-version ${GENERATOR_DISTRIBUTION_VERSION} \
    --target ${TARGET_TRIPLE}

# Determine some paths
ARTIFACTS_DIR=${PWD}/artifacts
BUNDLES_DIR=swift-sdk-generator/Bundles
SDK_DIR=$SDK_NAME.artifactbundle
SDK_SYSROOT_DIR=$SDK_DIR/$SDK_NAME/$TARGET_TRIPLE/*.sdk

# Build package
# case ${DISTRIBUTION_NAME} in
#     "ubuntu" | "debian")
#         SWIFT_VERSION=${SWIFT_VERSION} \
#         DISTRIBUTION_NAME=${DISTRIBUTION_NAME} \
#         DISTRIBUTION_VERSION=${DISTRIBUTION_VERSION} \
#         LINUX_PLATFORM=${LINUX_PLATFORM} \
#         SDK_SYSROOT_PATH=${BUNDLES_DIR}/${SDK_SYSROOT_DIR} \
#         STRIP_BINARY="${BINUTILS_NAME}-strip" \
#         ./build-deb.sh
#         ;;
# esac

# Compress SDK as the final step
cd $BUNDLES_DIR
mkdir -p $ARTIFACTS_DIR
echo "Compressing SDK into artifacts/$SDK_DIR.tar.gz archive..."
tar -czf $ARTIFACTS_DIR/$SDK_DIR.tar.gz $SDK_DIR
