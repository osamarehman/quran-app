#!/usr/bin/env bash
# Build a debug APK for the running emulator/device.
#   ./scripts/build-apk.sh              -> debug, all ABIs
#   ./scripts/build-apk.sh release      -> release build, all ABIs
#   ./scripts/build-apk.sh debug x64    -> debug build, x86_64 only (faster on emulator)
set -euo pipefail
cd "$(dirname "$0")/.."

mode="${1:-debug}"
abi="${2:-}"

args=("build" "apk" "--$mode")
case "$abi" in
  x64|x86_64)   args+=("--target-platform=android-x64") ;;
  arm|arm64)    args+=("--target-platform=android-arm64") ;;
  "")           ;;
  *)            echo "unknown abi: $abi" >&2; exit 1 ;;
esac

exec ./scripts/flutter.sh "${args[@]}"
