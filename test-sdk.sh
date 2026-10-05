#!/bin/bash

set -e

source ./common-sdk.sh

TEST_PROJECT=${TEST_PROJECT:=test-project}
BUILD_PROFILE=${BUILD_PROFILE:=debug}

EXTRA_FLAGS=$4

BUILDER_TAG=swift-builder:${SWIFT_IMAGE_VERSION}
echo "Building ${BUILDER_TAG} image to be used to compile test-project..."
docker build \
    --build-arg SWIFT_IMAGE_VERSION=${SWIFT_IMAGE_VERSION} \
    --build-arg USER=${USER} \
    --build-arg UID=${UID} \
    --tag ${BUILDER_TAG} \
    --file docker/swift-builder.dockerfile \
    .

SWIFT_SDK_COMMAND="experimental-swift-sdk"
if [[ $SWIFT_VERSION == *"6."* ]]; then
    SWIFT_SDK_COMMAND="swift-sdk"
fi

PACKAGE_PATH="--package-path ${TEST_PROJECT}"
echo "Testing ${SDK_NAME} by building test-project in ${BUILD_PROFILE} mode with extra flags: ${EXTRA_FLAGS}"
swift package clean ${PACKAGE_PATH}
docker run --rm \
    --user ${USER} \
    --volume $(pwd):/src \
    --workdir /src \
    ${BUILDER_TAG} \
    /bin/bash -c "swift build \
        -c ${BUILD_PROFILE} \
        ${PACKAGE_PATH} \
        --${SWIFT_SDK_COMMAND}s-path swift-sdk-generator/Bundles \
        --${SWIFT_SDK_COMMAND} ${SDK_NAME} ${EXTRA_FLAGS}"

while IFS= read -r -d '' OUTPUT_BINARY; do
    # Object files and shared libraries can also have executable permissions.
    BINARY_INFO=$(LC_ALL=C file -Lb "$OUTPUT_BINARY")
    [[ "$BINARY_INFO" == ELF*executable* ]] || continue

    echo -n "Built Binary Info: "
    file "$OUTPUT_BINARY"
    echo -n "Built Binary Size: "
    du -hs "$OUTPUT_BINARY"
    echo "Required Libraries:"
    readelf -d "$OUTPUT_BINARY" | grep "Shared library:" | sed -n 's/.*\[\(.*\)\].*/- \1/p'
done < <(find -L "${TEST_PROJECT}/.build/${BUILD_PROFILE}" -maxdepth 1 -type f -executable -print0)
