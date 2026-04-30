#!/usr/bin/env bash
# Thin wrapper so shells without Flutter on PATH can still call it.
# Usage: ./scripts/flutter.sh <any flutter args>
set -euo pipefail

FLUTTER_BIN="${FLUTTER_BIN:-$HOME/develop/flutter/bin/flutter}"

if [[ ! -x "$FLUTTER_BIN" && ! -x "${FLUTTER_BIN}.bat" ]]; then
  echo "flutter not found at $FLUTTER_BIN — set FLUTTER_BIN env var" >&2
  exit 1
fi

exec "$FLUTTER_BIN" "$@"
