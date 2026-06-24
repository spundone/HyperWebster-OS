#!/usr/bin/env bash
# Migration: monitor hot-load — watch ~/.config/hyprmoncfg/profiles and
# re-apply on change, so TUI profile saves take effect live.
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/monitor-hotload/install-monitor-hotload.sh"
