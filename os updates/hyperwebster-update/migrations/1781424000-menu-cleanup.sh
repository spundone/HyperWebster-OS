#!/usr/bin/env bash
# Migration: hide uuctl from the launcher — menu clutter. Idempotent —
# delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/menu-cleanup/install-menu-cleanup.sh"
