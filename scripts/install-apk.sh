#!/usr/bin/env bash
# Install the most recent debug APK on the running emulator/device.
set -euo pipefail
cd "$(dirname "$0")/.."

apk="build/app/outputs/flutter-apk/app-debug.apk"
if [[ ! -f "$apk" ]]; then
  echo "APK not found at $apk — run ./scripts/build-apk.sh first" >&2
  exit 1
fi

exec ./scripts/flutter.sh install
