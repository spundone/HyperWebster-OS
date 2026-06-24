#!/bin/sh
# Migration: 120/144 Hz hypersmooth UI tuning.
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/hypersmooth-display" ] || exit 0
sh "$SRC/hypersmooth-display/install-hypersmooth-display.sh"
