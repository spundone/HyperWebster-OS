#!/bin/sh
# Migration: Raycast-like launcher defaults.
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/launcher-raycast" ] || exit 0
sh "$SRC/launcher-raycast/install-launcher-raycast.sh"
