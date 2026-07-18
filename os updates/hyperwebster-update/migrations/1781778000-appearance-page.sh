#!/bin/sh
# Migration: Wallpaper & style → Appearance (corner radius, gaps, density, presets)
# and Additions page radius steppers under Rounded corners.
set -eu

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/appearance-page"
[ -d "$SRC" ] || SRC="$(CDPATH= cd -- "$(dirname -- "$0")/../../appearance-page" && pwd)"

sh "$SRC/install-appearance-page.sh"

# Refresh Additions QML so Appearance section shows shell/window radius steppers.
ADD="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/additions-installer"
[ -d "$ADD" ] || ADD="$(CDPATH= cd -- "$(dirname -- "$0")/../../additions-installer" && pwd)"
if [ -x "$ADD/install-additions-installer.sh" ]; then
  sh "$ADD/install-additions-installer.sh"
elif [ -f "$ADD/patch-additions-page.sh" ]; then
  sudo sh "$ADD/patch-additions-page.sh" || true
fi
