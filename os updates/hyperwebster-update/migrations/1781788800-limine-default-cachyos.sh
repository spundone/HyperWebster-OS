#!/usr/bin/env bash
# Migration: Limine nested menu — default to / auto-boot linux-cachyos.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/limine-menu-simplify"
[ -f "$SRC/prefer-limine-cachyos.sh" ] || exit 0
sudo bash "$SRC/prefer-limine-cachyos.sh"
