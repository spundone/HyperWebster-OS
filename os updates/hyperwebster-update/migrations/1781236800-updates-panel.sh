#!/usr/bin/env bash
# Migration: settings app Updates page — status checker + timer + QML patch.
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/updates-panel/install-updates-panel.sh"
