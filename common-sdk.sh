

SWIFT_VERSION=$1
SWIFT_VERSION=$(echo $SWIFT_VERSION | xargs)
if [ -z $SWIFT_VERSION ]; then
    echo "Swift version is required! (e.g.: 6.2)"
    exit -1
fi

DISTRIBUTION=$2
DISTRIBUTION=$(echo $DISTRIBUTION | xargs)
if [ -z $DISTRIBUTION ]; then 
    echo "Distribution is required! (e.g.: ubuntu-jammy, rhel-ubi9)"
    exit -1
fi

TARGET_ARCH=$3
TARGET_ARCH=$(echo $TARGET_ARCH | xargs)
if [ -z $TARGET_ARCH ]; then
    echo "Target architecture is required! (e.g.: x86_64, aarch64, armv7)"
    exit -1
fi

# Take distribution and split into name and version
SPLIT=(${DISTRIBUTION//-/ })
DISTRIBUTION_NAME=${SPLIT[0]}
DISTRIBUTION_VERSION=${SPLIT[1]}

## MARK: Distribution Name 
case ${DISTRIBUTION_NAME} in
    "ubuntu" | "debian")
        DOCKERFILE="swift-debian.dockerfile"
        is_debian=true
        ;;
    "rhel")
        DOCKERFILE="swift-rhel.dockerfile"
        is_rhel=true
        ;;
    "amazonlinux2")
        DOCKERFILE="swift-rhel-old.dockerfile"
        is_rhel=true
        DISTRIBUTION_VERSION=$DISTRIBUTION_NAME
        ;;
    *)
        echo "Error: unsupported distribution ${DISTRIBUTION_NAME}"
        echo "Supported distributions are: ubuntu, debian, rhel, amazonlinux2"
        exit -1
        ;;
esac

## MARK: Distribution Version
GENERATOR_DISTRIBUTION_NAME=${DISTRIBUTION_NAME}
SWIFT_DISTRIBUTION_TAG=$DISTRIBUTION_VERSION
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
    "trixie")
        DOCKERFILE="swift-debian-unofficial.dockerfile"
        GENERATOR_DISTRIBUTION_VERSION="13"
        # Set Swift versions for downloading runtime
        SWIFT_PLATFORM="ubuntu24.04"
        SWIFT_BRANCH="swift-$SWIFT_VERSION-release"
        SWIFT_TAG="swift-$SWIFT_VERSION-RELEASE"
        ;;
    "ubi9")
        GENERATOR_DISTRIBUTION_NAME="rhel"
        GENERATOR_DISTRIBUTION_VERSION="ubi9"
        SWIFT_DISTRIBUTION_TAG="rhel-ubi9"
        ;;
    "amazonlinux2")
        # We use rhel-ubi9 to pass to the generator
        GENERATOR_DISTRIBUTION_NAME="rhel"
        GENERATOR_DISTRIBUTION_VERSION="ubi9"
        ;;
    *)
        DOCKERFILE="swift-unofficial.dockerfile"
        GENERATOR_DISTRIBUTION_VERSION=${DISTRIBUTION_VERSION}
esac

## MARK: Target Arch
case ${TARGET_ARCH} in
    "x86_64")
        LINUX_PLATFORM=amd64
        TARGET_TRIPLE=${TARGET_ARCH}-unknown-linux-gnu
        ;;
    "aarch64")
        LINUX_PLATFORM=arm64
        TARGET_TRIPLE=${TARGET_ARCH}-unknown-linux-gnu
        ;;
    "armv7")
        if [[ $is_rhel = true ]]; then
            echo "Error: RHEL-based distributions do NOT support armv7"
            exit -1
        fi

        LINUX_PLATFORM=armhf
        DOCKERFILE="swift-armv7.dockerfile"
        TARGET_TRIPLE=${TARGET_ARCH}-unknown-linux-gnueabihf
        ;;
    *)
        echo "Error: unsupported architecture ${TARGET_ARCH}"
        echo "Supported architectures are: x86_64, aarch64, armv7"
        exit -1
        ;;
esac

# MARK: SDK Name
if [ "$DISTRIBUTION_VERSION" != "$DISTRIBUTION_NAME" ]; then
    SDK_NAME=${SWIFT_VERSION}-RELEASE_${DISTRIBUTION_NAME}_${DISTRIBUTION_VERSION}_${TARGET_ARCH}
else
    SDK_NAME=${SWIFT_VERSION}-RELEASE_${SWIFT_DISTRIBUTION_TAG}_${TARGET_ARCH}
fi
