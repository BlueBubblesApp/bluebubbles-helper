#!/bin/zsh
set -euo pipefail

dry_run=0
for argument in "$@"; do
    case "$argument" in
        --dry-run) dry_run=1 ;;
        *) print -u2 -- "Usage: zsh build-clang.sh [--dry-run]"; exit 2 ;;
    esac
done

root_dir=${0:A:h}
build_dir="$root_dir/build"
output="$build_dir/BlueBubblesHelper.dylib"

run() {
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
    if (( ! dry_run )); then
        "$@"
    fi
}

if (( dry_run )); then
    run xcrun --sdk macosx --show-sdk-path
    sdk_path=SDK_PATH
else
    print -r -- '+ xcrun --sdk macosx --show-sdk-path'
    sdk_path=$(xcrun --sdk macosx --show-sdk-path)
fi

sources=(
    BlueBubblesHelper/ZKSwizzle/ZKSwizzle.m
    BlueBubblesHelper/NetworkController.m
    BlueBubblesHelper/BlueBubblesHelper.m
    'Pods/Target Support Files/CocoaAsyncSocket/CocoaAsyncSocket-dummy.m'
    Pods/CocoaAsyncSocket/Source/GCD/GCDAsyncSocket.m
    Pods/CocoaAsyncSocket/Source/GCD/GCDAsyncUdpSocket.m
    'Pods/Target Support Files/Pods-BlueBubblesHelper DyLib/Pods-BlueBubblesHelper DyLib-dummy.m'
)

common_flags=(
    -isysroot "$sdk_path" -mmacosx-version-min=11.5
    -std=gnu11 -Os -fno-common -fblocks -fobjc-arc -fobjc-weak -fmodules
    "-fmodules-cache-path=$build_dir/module-cache"
    -DCOCOAPODS=1 -DNS_BLOCK_ASSERTIONS=1
    -I "$root_dir/Pods/CocoaAsyncSocket/Source/GCD"
    -I "$root_dir/Pods/Headers/Public"
    -I "$root_dir/Pods/Headers/Public/CocoaAsyncSocket"
    -I "$root_dir/Pods/Headers/Private"
    -I "$root_dir/Pods/Headers/Private/CocoaAsyncSocket"
    -I "$root_dir/BlueBubblesHelper/ZKSwizzle"
    -isystem "$root_dir/BlueBubblesHelper"
)

link_flags=(
    -isysroot "$sdk_path" -mmacosx-version-min=11.5
    -ObjC -undefined dynamic_lookup -flat_namespace
    -framework AppKit -framework Foundation -framework CoreServices -framework Security
    -framework CoreSpotlight -framework CoreLocation
    -install_name @rpath/BlueBubblesHelper.dylib
    -compatibility_version 1 -current_version 1
    -Wl,-rpath,@executable_path/../Frameworks
    -Wl,-rpath,@loader_path/../Frameworks
)

objects=()
compile_arch() {
    local arch="$1"
    local source_file object_file
    local -a source_flags
    objects=()
    run mkdir -p "$build_dir/$arch" "$build_dir/module-cache"
    for source_file in "${sources[@]}"; do
        case "$source_file" in
            BlueBubblesHelper/*)
                source_flags=(-include "$root_dir/BlueBubblesHelper/PrefixHeader.pch")
                ;;
            'Pods/Target Support Files/Pods-BlueBubblesHelper DyLib/'*)
                source_flags=(-DPOD_CONFIGURATION_RELEASE=1)
                ;;
            Pods/*)
                source_flags=(-DPOD_CONFIGURATION_RELEASE=1
                    -include "$root_dir/Pods/Target Support Files/CocoaAsyncSocket/CocoaAsyncSocket-prefix.pch")
                ;;
        esac
        object_file="$build_dir/$arch/${source_file:t:r}.o"
        run xcrun --sdk macosx clang "${common_flags[@]}" -arch "$arch" \
            "${source_flags[@]}" -c "$root_dir/$source_file" -o "$object_file"
        objects+=("$object_file")
    done
}

link_arch() {
    run xcrun --sdk macosx clang -dynamiclib -arch "$1" \
        "${link_flags[@]}" "${objects[@]}" -o "$output"
}

compile_arch arm64e
if ! link_arch arm64e; then
    print -u2 -- 'arm64e linking failed; the script will build an arm64 dylib instead.'
    compile_arch arm64
    link_arch arm64
fi

run codesign --force --sign - "$output"
run file "$output"
run xcrun --sdk macosx lipo -info "$output"
run codesign -dv "$output"
