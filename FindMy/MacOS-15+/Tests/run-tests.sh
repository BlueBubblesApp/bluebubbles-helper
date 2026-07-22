#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/BlueBubblesHelper"
SOCKET_DIR="$ROOT_DIR/Pods/CocoaAsyncSocket/Source/GCD"
BUILD_DIR="$ROOT_DIR/.build/tests"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

export DEVELOPER_DIR
mkdir -p "$BUILD_DIR"

SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
xcrun --sdk macosx clang \
    -fobjc-arc \
    -fmodules \
    -Wall \
    -Wextra \
    -Werror \
    -Wno-deprecated-declarations \
    -isysroot "$SDKROOT" \
    -mmacosx-version-min=15.0 \
    -I "$SOURCE_DIR" \
    -I "$SOCKET_DIR" \
    "$SOURCE_DIR/FindMyFriendPayload.m" \
    "$SOURCE_DIR/FindMyFriendsRefreshCoordinator.m" \
    "$SOURCE_DIR/ServerConnection.m" \
    "$SOCKET_DIR/GCDAsyncSocket.m" \
    "$ROOT_DIR/Tests/FindMyFriendsTests.m" \
    -framework Foundation \
    -framework Security \
    -framework CFNetwork \
    -o "$BUILD_DIR/FindMyFriendsTests"

"$BUILD_DIR/FindMyFriendsTests"
