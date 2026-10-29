#!/bin/bash

set -e

./build-sdk.sh "$@"

./test-sdk.sh "$@" "--build-tests"
./test-sdk.sh "$@" "--static-swift-stdlib"
BUILD_PROFILE=release ./test-sdk.sh "$@"
