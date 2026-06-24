#!/bin/sh
# Migration: TCL T89C TV display profile.
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/tcl-t89c-display" ] || exit 0
sh "$SRC/tcl-t89c-display/install-tcl-t89c-display.sh"
