#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/BlueBubblesHelper"
SOCKET_DIR="$ROOT_DIR/Pods/CocoaAsyncSocket/Source/GCD"
BUILD_DIR="$ROOT_DIR/.build/tests"
MODULE_CACHE_DIR="$BUILD_DIR/module-cache"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

export DEVELOPER_DIR
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR"
export SWIFT_MODULECACHE_PATH="$MODULE_CACHE_DIR"
mkdir -p "$BUILD_DIR" "$MODULE_CACHE_DIR"

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
    "$SOURCE_DIR/FindMyDevicesDataSourceCapture.m" \
    "$SOURCE_DIR/FindMyDevicesRefreshCoordinator.m" \
    "$SOURCE_DIR/FindMyFriendsRefreshCoordinator.m" \
    "$SOURCE_DIR/ServerConnection.m" \
    "$SOCKET_DIR/GCDAsyncSocket.m" \
    "$ROOT_DIR/Tests/FindMyFriendsTests.m" \
    -framework Foundation \
    -framework Security \
    -framework CFNetwork \
    -o "$BUILD_DIR/FindMyFriendsTests"

"$BUILD_DIR/FindMyFriendsTests"

xcrun --sdk macosx swiftc \
    -warnings-as-errors \
    -sdk "$SDKROOT" \
    "$SOURCE_DIR/FindMyDeviceSnapshot.swift" \
    "$ROOT_DIR/Tests/FindMyDeviceSnapshotTests.swift" \
    -o "$BUILD_DIR/FindMyDeviceSnapshotTests"

"$BUILD_DIR/FindMyDeviceSnapshotTests"
