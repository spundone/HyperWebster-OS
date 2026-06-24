#!/usr/bin/env bash
# Migration: Super+D toggles the dashboard/calendar (communication -> Super+Shift+D).
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/dashboard-key/install-dashboard-key.sh"
