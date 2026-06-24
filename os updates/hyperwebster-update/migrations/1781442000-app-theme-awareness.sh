#!/usr/bin/env bash
# Migration: make external apps (Chrome/Electron/Firefox/GTK/Qt) follow
# Caelestia's light/dark mode via the freedesktop appearance portal + a watcher
# Idempotent, user-level — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/app-theme-awareness/install-app-theme-awareness.sh"
