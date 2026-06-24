#!/usr/bin/env bash
# Migration: ship additions.json manifest + seed status cache (blank Additions page fix).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
env HYPERWEBSTER_SKIP_SHELL_PATCH=1 sh "$HYPERWEBSTER_SRC/additions-installer/install-additions-installer.sh"
"$HOME/.local/bin/hyperwebster-additions" status >/dev/null 2>&1 || true
