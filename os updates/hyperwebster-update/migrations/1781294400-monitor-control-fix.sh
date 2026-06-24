#!/usr/bin/env bash
# Migration: make saved hyprmoncfg monitor profiles actually apply
# (fix include-verification path for the daemon + Super+Ctrl+H TUI).
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/monitor-control-fix/install-monitor-control-fix.sh"
