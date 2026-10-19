#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="${1:?Pass an output directory}"
mkdir -p "$build_dir"
build_dir="$(cd "$build_dir" && pwd)"
helper_dir="$repo_dir/Messages/MacOS-11+/BlueBubblesHelper"
socket_dir="$repo_dir/Messages/MacOS-11+/Pods/CocoaAsyncSocket/Source/GCD"
# Compile only: do not run the Xcode project's development injection/build hooks.
clang -dynamiclib -arch arm64 -arch arm64e -fobjc-arc -fblocks -fmodules \
  -fmodules-cache-path="$build_dir/modules" \
  -Wno-deprecated-declarations -Wno-nullability-completeness -Wno-incompatible-pointer-types \
  -I "$helper_dir" -I "$helper_dir/ZKSwizzle" -I "$socket_dir" \
  -include "$helper_dir/PrefixHeader.pch" \
  "$helper_dir/BlueBubblesHelper.m" "$helper_dir/NetworkController.m" "$helper_dir/EmojiTapbackSupport.m" \
  "$helper_dir/ZKSwizzle/ZKSwizzle.m" "$socket_dir/GCDAsyncSocket.m" \
  -framework Cocoa -framework CoreServices -framework Security -framework CoreSpotlight -framework CoreLocation \
  -undefined dynamic_lookup -flat_namespace -install_name @loader_path/BlueBubblesHelper.dylib \
  -o "$build_dir/BlueBubblesHelper.dylib"
codesign --force --sign - "$build_dir/BlueBubblesHelper.dylib"
lipo -info "$build_dir/BlueBubblesHelper.dylib"
