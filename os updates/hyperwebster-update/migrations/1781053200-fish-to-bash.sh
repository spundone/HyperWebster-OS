#!/usr/bin/env bash
# Migration: switch the interactive shell from fish to bash (Omarchy bash setup).
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/fish-to-bash/install-fish-to-bash.sh"
