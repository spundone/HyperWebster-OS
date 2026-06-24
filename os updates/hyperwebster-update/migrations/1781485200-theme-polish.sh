#!/bin/sh
# HyperWebster layer migration — theme polish (SDDM sync + sudoers).
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/theme-polish" ] || exit 0
sh "$SRC/theme-polish/install-theme-polish.sh"
