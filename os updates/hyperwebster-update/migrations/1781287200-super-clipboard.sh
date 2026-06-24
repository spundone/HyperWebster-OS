#!/usr/bin/env bash
# Migration: universal Super+C copy / Super+V paste (clipboard history -> Super+Ctrl+V).
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/super-clipboard/install-super-clipboard.sh"
