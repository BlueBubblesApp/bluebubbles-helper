#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$HOME/Tools/bluebubbles-helper-src/FaceTime/MacOS-11+}"
KNOWN_GOOD="${KNOWN_GOOD:-/Applications/BlueBubbles.app/Contents/Resources/appResources/private-api/macos11/BlueBubblesFaceTimeHelper.dylib.before-helper-autoaccept-20260706-235342}"
DST_MACOS11="${DST_MACOS11:-/Applications/BlueBubbles.app/Contents/Resources/appResources/private-api/macos11/BlueBubblesFaceTimeHelper.dylib}"
DST_FACETIME="${DST_FACETIME:-/Applications/BlueBubbles.app/Contents/Resources/appResources/private-api/facetime/BlueBubblesFaceTimeHelper.dylib}"
BB_LOG="${BB_LOG:-$HOME/Library/Logs/bluebubbles-server/main.log}"
BB_CONFIG_DB="${BB_CONFIG_DB:-$HOME/Library/Application Support/bluebubbles-server/config.db}"
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
ARCHS_REQUIRED=(x86_64 arm64 arm64e)
SYMBOLS_REQUIRED=(
  admit-any-pending-member
  get-conversation-state
  incomingPendingConversations
  ft-call-status-changed
)

usage() {
  cat <<'USAGE'
Usage:
  build-universal-facetime-helper.sh [--install] [--restart-validate] [--android-validate] [--fix-android-dns]

Validation gates:
  - Build generic macOS release with x86_64 arm64 arm64e.
  - Refuse helpers much smaller than the known-good universal helper.
  - Verify expected FaceTime symbols/strings and codesign.
  - On install, copy the same helper to both BlueBubbles FaceTime locations.
  - With --restart-validate, restart BlueBubbles and require both helper pings:
    com.apple.MobileSMS and Anonymous.
  - With --android-validate, verify the current Cloudflare tunnel from ADB.
  - With --fix-android-dns, keep Android Private DNS enabled with Cloudflare
    DNS, flush resolver state, bounce Wi-Fi, then validate the current tunnel
    from ADB.
USAGE
}

INSTALL=0
RESTART_VALIDATE=0
ANDROID_VALIDATE=0
FIX_ANDROID_DNS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install) INSTALL=1 ;;
    --restart-validate) RESTART_VALIDATE=1 ;;
    --android-validate) ANDROID_VALIDATE=1 ;;
    --fix-android-dns)
      FIX_ANDROID_DNS=1
      ANDROID_VALIDATE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
  shift
done

require_archs() {
  local file="$1"
  local arch_info
  arch_info="$(lipo -info "$file")"
  for arch in "${ARCHS_REQUIRED[@]}"; do
    if ! grep -q "$arch" <<<"$arch_info"; then
      echo "Refusing helper: missing architecture $arch in $file" >&2
      echo "$arch_info" >&2
      exit 2
    fi
  done
}

require_size_floor() {
  local file="$1"
  if [[ ! -f "$KNOWN_GOOD" ]]; then
    echo "Known-good helper not found; skipping size floor: $KNOWN_GOOD" >&2
    return
  fi

  local built_size known_size min_size
  built_size="$(stat -f%z "$file")"
  known_size="$(stat -f%z "$KNOWN_GOOD")"
  min_size=$(( known_size * 60 / 100 ))
  if (( built_size < min_size )); then
    echo "Refusing helper: size $built_size is below $min_size bytes" >&2
    echo "Known-good helper size is $known_size bytes: $KNOWN_GOOD" >&2
    exit 3
  fi
}

require_symbols() {
  local file="$1"
  local symbol
  for symbol in "${SYMBOLS_REQUIRED[@]}"; do
    if ! strings "$file" | grep -q "$symbol"; then
      echo "Refusing helper: missing expected symbol/string $symbol" >&2
      exit 4
    fi
  done
}

validate_helper_file() {
  local file="$1"
  [[ -f "$file" ]] || { echo "Missing helper: $file" >&2; exit 1; }
  require_archs "$file"
  require_size_floor "$file"
  require_symbols "$file"
  codesign --verify --verbose=2 "$file"
}

server_password() {
  sqlite3 "$BB_CONFIG_DB" "SELECT value FROM config WHERE name='password';"
}

latest_tunnel_url() {
  perl -ne 'print "$1\n" if /(https:\/\/[a-z0-9-]+\.trycloudflare\.com)/' "$BB_LOG" | tail -n 1
}

restart_bluebubbles_and_validate() {
  local pw info seen
  pkill -x BlueBubbles 2>/dev/null || true
  pkill -f '/Applications/BlueBubbles.app' 2>/dev/null || true
  pkill -x FaceTime 2>/dev/null || true
  sleep 3
  open -a BlueBubbles

  for _ in {1..45}; do
    pw="$(server_password 2>/dev/null || true)"
    if [[ -n "$pw" ]] && curl -fsS "http://127.0.0.1:1234/api/v1/server/info?password=$pw" >/tmp/bluebubbles-server-info.json 2>/dev/null; then
      info="$(cat /tmp/bluebubbles-server-info.json)"
      echo "$info"
      break
    fi
    sleep 1
  done

  for _ in {1..45}; do
    seen="$(tail -n 240 "$BB_LOG" | grep -E 'Received Ping from Private API Helper via (com\.apple\.MobileSMS|Anonymous)' || true)"
    if grep -q 'via com.apple.MobileSMS' <<<"$seen" && grep -q 'via Anonymous' <<<"$seen"; then
      echo "Validated both helper clients:"
      echo "$seen" | tail -n 4
      return
    fi
    sleep 1
  done

  echo "Did not see both helper pings. Recent helper logs:" >&2
  tail -n 240 "$BB_LOG" | grep -Ei 'Private API Helper connected|Received Ping|FaceTimeDylibPlugin|MessagesDylibPlugin|Socket Closed' | tail -n 80 >&2
  exit 5
}

validate_tunnel_from_mac() {
  local pw url
  pw="$(server_password)"
  url="$(latest_tunnel_url)"
  [[ -n "$url" ]] || { echo "No Cloudflare tunnel URL found in $BB_LOG" >&2; exit 6; }
  echo "Validating tunnel from Mac: $url"
  curl -fsS --connect-timeout 10 --max-time 20 "$url/api/v1/server/info?password=$pw" >/dev/null
}

validate_tunnel_from_android() {
  local pw url host
  [[ -x "$ADB" ]] || { echo "ADB not found or not executable: $ADB" >&2; exit 7; }
  "$ADB" devices | grep -q $'\tdevice' || { echo "No ADB device connected" >&2; exit 7; }

  pw="$(server_password)"
  url="$(latest_tunnel_url)"
  [[ -n "$url" ]] || { echo "No Cloudflare tunnel URL found in $BB_LOG" >&2; exit 6; }
  host="${url#https://}"

  if (( FIX_ANDROID_DNS )); then
    "$ADB" shell settings put global private_dns_mode hostname || true
    "$ADB" shell settings put global private_dns_specifier 1dot1dot1dot1.cloudflare-dns.com || true
    "$ADB" shell cmd netd resolver flushdefaultif 2>/dev/null || true
    "$ADB" shell cmd netd resolver flushif wlan0 2>/dev/null || true
    "$ADB" shell svc wifi disable
    sleep 2
    "$ADB" shell svc wifi enable
    sleep 12
  fi

  echo "Validating Android DNS and tunnel: $host"
  "$ADB" shell ping -c 1 -W 4 "$host" >/dev/null
  "$ADB" shell curl -sS --connect-timeout 10 --max-time 20 "$url/api/v1/server/info?password=$pw" | grep -q '"status":200'
}

cd "$ROOT"

xcodebuild \
  -workspace BlueBubblesFaceTimeHelper.xcworkspace \
  -scheme BlueBubblesFaceTimeHelper \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  ONLY_ACTIVE_ARCH=NO \
  ARCHS="${ARCHS_REQUIRED[*]}" \
  VALID_ARCHS="${ARCHS_REQUIRED[*]}" \
  EXCLUDED_ARCHS='' \
  clean build

BUILT="$(find "$HOME/Library/Developer/Xcode/DerivedData" \
  -path '*BlueBubblesFaceTimeHelper*/Build/Products/Release/BlueBubblesFaceTimeHelper.dylib' \
  -print -quit)"

if [[ -z "$BUILT" || ! -f "$BUILT" ]]; then
  echo "Could not find built BlueBubblesFaceTimeHelper.dylib" >&2
  exit 1
fi

validate_helper_file "$BUILT"

echo "Built helper: $BUILT"
ls -lh "$BUILT"
file "$BUILT"
lipo -info "$BUILT"
shasum -a 256 "$BUILT"

if (( INSTALL )); then
  ts="$(date +%Y%m%d-%H%M%S)"
  cp "$DST_MACOS11" "$DST_MACOS11.before-script-install-$ts"
  cp "$DST_FACETIME" "$DST_FACETIME.before-script-install-$ts"
  cp "$BUILT" "$DST_MACOS11"
  cp "$BUILT" "$DST_FACETIME"
  xattr -d com.apple.quarantine "$DST_MACOS11" 2>/dev/null || true
  xattr -d com.apple.quarantine "$DST_FACETIME" 2>/dev/null || true
  validate_helper_file "$DST_MACOS11"
  validate_helper_file "$DST_FACETIME"
  if ! cmp -s "$DST_MACOS11" "$DST_FACETIME"; then
    echo "Installed helper copies differ between macos11 and facetime paths" >&2
    exit 8
  fi
  echo "Installed helper to:"
  echo "  $DST_MACOS11"
  echo "  $DST_FACETIME"
fi

if (( RESTART_VALIDATE )); then
  restart_bluebubbles_and_validate
  validate_tunnel_from_mac
fi

if (( ANDROID_VALIDATE )); then
  validate_tunnel_from_android
fi
