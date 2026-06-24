#!/usr/bin/env bash
# Migration: searchable on-screen keybinding cheatsheet (Super+/).
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/install-keybinds-help.sh"
