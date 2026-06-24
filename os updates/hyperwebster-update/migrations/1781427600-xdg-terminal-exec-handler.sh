#!/usr/bin/env bash
# Migration: ship an xdg-terminal-exec handler (shim + xdg-terminals.list) so
# app2unit's hardcoded terminal handler resolves and Terminal=true apps launch
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/xdg-terminal-exec-handler/install-xdg-terminal-exec-handler.sh"
