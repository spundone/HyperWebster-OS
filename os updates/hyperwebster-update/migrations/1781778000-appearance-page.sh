#!/bin/sh
# Migration: Wallpaper & style → Appearance (corner radius, gaps, density, presets).
set -eu

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/appearance-page"
[ -d "$SRC" ] || SRC="$(CDPATH= cd -- "$(dirname -- "$0")/../../appearance-page" && pwd)"

sh "$SRC/install-appearance-page.sh"
