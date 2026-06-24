#!/bin/sh
# Migration: maintenance menu + shortcuts.
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/distro-tools" ] || exit 0
sh "$SRC/distro-tools/install-distro-tools.sh"
