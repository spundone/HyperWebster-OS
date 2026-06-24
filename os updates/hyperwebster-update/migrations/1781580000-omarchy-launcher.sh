#!/bin/sh
# Migration: Omarchy Super+Alt+Space install menu.
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/omarchy-launcher" ] || exit 0
sh "$SRC/omarchy-launcher/install-omarchy-launcher.sh"
