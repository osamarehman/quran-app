#!/usr/bin/env bash
# Build + launch debug app. Defaults to the first connected Android device or
# emulator-5554. Pass an explicit -d <id> to override.
#   ./scripts/run.sh                    -> auto-pick Android device
#   ./scripts/run.sh -d chrome          -> run on Chrome
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ $# -eq 0 ]]; then
  exec ./scripts/flutter.sh run -d emulator-5554
fi
exec ./scripts/flutter.sh run "$@"
