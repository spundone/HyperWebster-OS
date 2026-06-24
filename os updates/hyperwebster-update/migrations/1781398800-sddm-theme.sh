#!/usr/bin/env bash
# Migration: SDDM greeter theme matching the desktop scheme/wallpaper/font.
# Idempotent — delegates to the component installer (which also runs the
# initial sddm-theme-sync against the user's current scheme).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/sddm-theme/install-sddm-theme.sh"
