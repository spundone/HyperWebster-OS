#!/bin/sh
# HyperWebster layer migration — drive automount at boot.
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/drive-automount" ] || exit 0
sh "$SRC/drive-automount/install-drive-automount.sh"
