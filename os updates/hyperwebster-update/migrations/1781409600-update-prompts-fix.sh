#!/usr/bin/env bash
# Migration: hyperwebster-update flow — pre-answer yay's interactive menus so the
# update no longer looks stuck at "Packages to exclude".
# Idempotent — delegates to the component patcher.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/update-prompts-fix/patch-hyperwebster-update.sh"
