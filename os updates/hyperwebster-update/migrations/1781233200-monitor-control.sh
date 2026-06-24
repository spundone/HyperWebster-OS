#!/usr/bin/env bash
# Migration: monitor control — hyprmoncfg + hyprmoncfgd daemon + Super+Ctrl+H.
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/monitor-control/install-monitor-control.sh"
