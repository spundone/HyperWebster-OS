#!/usr/bin/env bash
# Migration: Settings → Appearance font family pickers + Theme.fontFamily binding.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?}"

APP="$HYPERWEBSTER_SRC/appearance-page"
TOG="$HYPERWEBSTER_SRC/appearance-toggles"

if [ -d "$TOG" ] && [ -x "$TOG/install-appearance-toggles.sh" ]; then
  sh "$TOG/install-appearance-toggles.sh" || true
fi

if [ -d "$APP" ] && [ -x "$APP/install-appearance-page.sh" ]; then
  sh "$APP/install-appearance-page.sh" || true
fi

echo ":: Appearance fonts — Settings → Wallpaper & style → Appearance → Typography"
echo ":: Ctrl+Super+Alt+R to apply; install a chosen font package if it is missing"
