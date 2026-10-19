#!/bin/bash
set -euo pipefail
task_repo="$(cd "$(dirname "$0")/.." && pwd)"
task_build="$(mktemp -d)"
trap 'rm -rf "$task_build"' EXIT
clang -fobjc-arc -framework Foundation \
 "$task_repo/Messages/MacOS-11+/BlueBubblesHelper/EmojiTapbackSupport.m" \
 "$task_repo/tests/EmojiTapbackSupportTests.m" -o "$task_build/emoji-support-tests"
"$task_build/emoji-support-tests"
