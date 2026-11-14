#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$ROOT_DIR/BlueBubblesHelper.xcworkspace"
SCHEME="BlueBubblesHelper DyLib"
BUILD_DIR="$ROOT_DIR/.build/universal"
DIST_DIR="$ROOT_DIR/dist"
PRODUCT="BlueBubblesFindMyHelper.dylib"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

export DEVELOPER_DIR

if ! cmp -s "$ROOT_DIR/Podfile.lock" "$ROOT_DIR/Pods/Manifest.lock"; then
    printf 'Podfile.lock and Pods/Manifest.lock differ; run pod install before building.\n' >&2
    exit 1
fi

build_architecture() {
    local architecture="$1"
    local derived_data="$BUILD_DIR/$architecture"

    xcodebuild \
        -quiet \
        -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination "generic/platform=macOS" \
        -derivedDataPath "$derived_data" \
        ARCHS="$architecture" \
        ONLY_ACTIVE_ARCH=NO \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        build
}

mkdir -p "$DIST_DIR"
build_architecture x86_64
build_architecture arm64

X86_PRODUCT="$BUILD_DIR/x86_64/Build/Products/Release/$PRODUCT"
ARM_PRODUCT="$BUILD_DIR/arm64/Build/Products/Release/$PRODUCT"
OUTPUT="$DIST_DIR/$PRODUCT"

lipo -create "$X86_PRODUCT" "$ARM_PRODUCT" -output "$OUTPUT"
lipo "$OUTPUT" -verify_arch x86_64 arm64

INSTALL_NAME="$(otool -D "$OUTPUT" | tail -n 1 | xargs)"
EXPECTED_INSTALL_NAME="@rpath/$PRODUCT"
if [[ "$INSTALL_NAME" != "$EXPECTED_INSTALL_NAME" ]]; then
    printf 'Unexpected install name: %s (expected %s)\n' "$INSTALL_NAME" "$EXPECTED_INSTALL_NAME" >&2
    exit 1
fi

printf 'Built %s (%s)\n' "$OUTPUT" "$(lipo -archs "$OUTPUT")"
