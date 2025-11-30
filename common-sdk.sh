
TARGET_ARCH=${TARGET_ARCH:=x86_64}
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

# Take distribution and split into name and version
SPLIT=(${DISTRIBUTION//-/ })
DISTRIBUTION_NAME=${SPLIT[0]}
DISTRIBUTION_VERSION=${SPLIT[1]}
