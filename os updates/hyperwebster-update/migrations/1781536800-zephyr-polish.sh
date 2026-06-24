#!/bin/sh
# Migration: optional zephyr motion toggle (ships disabled).
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/zephyr-polish" ] || exit 0
sh "$SRC/zephyr-polish/install-zephyr-polish.sh"
