#!/bin/sh
# HyperWebster layer migration — install Starman Limine gaming boot hook.
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/starman-gaming-boot" ] || exit 0
sh "$SRC/starman-gaming-boot/install-starman-gaming-boot.sh"
