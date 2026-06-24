#!/usr/bin/env bash
# Migration: drop the ~/Downloads keymap candidate from hyperwebster-keybinds-gen so
# the canonical layer copy is the sole implicit source. Idempotent,
# user-level — delegates to the component fix.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/cheatsheet-keymap-path/fix-cheatsheet-keymap-path.sh"
