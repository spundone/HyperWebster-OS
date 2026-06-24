#!/usr/bin/env bash
# Migration: Super+Space reliably opens/keeps the launcher (drawers IPC, not
# the interrupt-prone global). Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/launcher-fix/install-launcher-fix.sh"
