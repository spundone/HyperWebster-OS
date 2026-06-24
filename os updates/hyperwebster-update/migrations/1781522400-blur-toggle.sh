#!/bin/sh
# Migration: optional frosted glass blur toggle.
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/blur-toggle" ] || exit 0
sh "$SRC/blur-toggle/install-blur-toggle.sh"
