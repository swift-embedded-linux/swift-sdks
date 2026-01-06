#!/bin/bash

set -e

source ./common-sdk.sh

SDK_GENERATOR_PATH=./swift-sdk-generator/.build/release/swift-sdk-generator
IMAGE_TAG=${IMAGE_TAG:=swift-sysroot:${SWIFT_VERSION}-${SWIFT_DISTRIBUTION_TAG}}

echo "Starting up qemu emulation"
docker run --privileged --rm tonistiigi/binfmt --install all

echo "Building ${IMAGE_TAG} image for ${LINUX_PLATFORM}..."
echo "Extra Packages: ${EXTRA_PACKAGES}"
docker build \
    --network=host \
    --platform linux/${LINUX_PLATFORM} \
    --tag ${IMAGE_TAG} \
    --build-arg SWIFT_PLATFORM=${SWIFT_PLATFORM} \
    --build-arg SWIFT_BRANCH=${SWIFT_BRANCH} \
    --build-arg SWIFT_VERSION=${SWIFT_VERSION} \
    --build-arg SWIFT_DISTRIBUTION_TAG=${SWIFT_DISTRIBUTION_TAG} \
    --build-arg SWIFT_TAG=${SWIFT_TAG} \
    --build-arg DISTRIBUTION_NAME=${DISTRIBUTION_NAME} \
    --build-arg DISTRIBUTION_VERSION=${DISTRIBUTION_VERSION} \
    --build-arg EXTRA_PACKAGES=${EXTRA_PACKAGES} \
    --file docker/${DOCKERFILE} \
    .

echo "Building Swift ${SWIFT_VERSION} ${SWIFT_DISTRIBUTION_TAG} SDK for ${TARGET_ARCH}..."
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
