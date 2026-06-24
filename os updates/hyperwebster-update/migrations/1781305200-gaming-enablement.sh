#!/usr/bin/env bash
# Migration: enable multilib + install omarchy-pkg-add shim (Steam/gaming script
# compatibility). Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/gaming-enablement/install-gaming-enablement.sh"
