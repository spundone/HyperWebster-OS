#!/usr/bin/env bash
# Migration: remap HyperWebster keybindings to Omarchy's defaults.
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/omarchy-keys/install-omarchy-keys.sh"
