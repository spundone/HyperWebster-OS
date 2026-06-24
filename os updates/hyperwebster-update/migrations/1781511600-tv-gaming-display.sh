#!/bin/sh
# Migration: 4K HDR TV display profile.
set -eu
SRC="${HOME}/.local/share/hyperwebster"
[ -d "$SRC/tv-gaming-display" ] || exit 0
sh "$SRC/tv-gaming-display/install-tv-gaming-display.sh"
