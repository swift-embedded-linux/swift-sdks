#!/bin/bash

set -e

SDK_GENERATOR_BRANCH=${SDK_GENERATOR_BRANCH:=main}
SDK_GENERATOR_REPO=${SDK_GENERATOR_REPO:=https://github.com/swift-embedded-linux/swift-sdk-generator.git}
SDK_GENERATOR_DIR=${SDK_GENERATOR_DIR:=swift-sdk-generator}

echo "Starting up qemu emulation"
docker run --privileged --rm tonistiigi/binfmt --install all

# Dependencies
if [ "$(grep -Ei 'debian' /etc/os-release)" ]; then
  sudo apt install -y git-extras
fi

# Checkout
echo "Checking out $SDK_GENERATOR_REPO on branch $SDK_GENERATOR_BRANCH..."
git force-clone -b $SDK_GENERATOR_BRANCH $SDK_GENERATOR_REPO $SDK_GENERATOR_DIR || true
cd $SDK_GENERATOR_DIR

# Build
# Swift 6.4's Swift Build backend also needs the compiler flag to autolink
# Foundation's static dependencies.
swift build -c release --static-swift-stdlib -Xswiftc -static-stdlib

# Test
./.build/release/swift-sdk-generator --help
