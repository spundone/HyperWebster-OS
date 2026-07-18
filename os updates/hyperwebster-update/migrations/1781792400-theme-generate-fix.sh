#!/bin/sh
# Migration: wallpaper theme generate must not fail on caelestia -n wallpaper.
set -eu

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/omarchy-themes"
[ -d "$SRC" ] || SRC="$(CDPATH= cd -- "$(dirname -- "$0")/../../omarchy-themes" && pwd)"

sh "$SRC/install-omarchy-themes.sh"

# Best-effort: enable user scheme discovery so generated names appear in Colours.
if [ -f "$SRC/patch-caelestia-scheme-overlay.sh" ]; then
  sudo sh "$SRC/patch-caelestia-scheme-overlay.sh" || true
fi
