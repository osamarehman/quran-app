#!/usr/bin/env bash
# Static analyze + tests. Run before commit.
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/flutter.sh analyze
./scripts/flutter.sh test
