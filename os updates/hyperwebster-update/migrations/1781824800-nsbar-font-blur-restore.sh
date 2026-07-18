#!/usr/bin/env bash
# Migration: restore nsbar Nerd Font chrome + numeric Hyprland blur rules.
# The GlobalConfig body-font Theme binding swapped JetBrainsMono NF for
# GoogleSansFlex (broken bar icons). Blur keywords used on/off instead of 1/0.
set +e
: "${HYPERWEBSTER_SRC:?}"

APP="$HYPERWEBSTER_SRC/appearance-page"
BLUR="$HYPERWEBSTER_SRC/blur-toggle"

if [ -f "$APP/patch-theme-font.sh" ]; then
  sudo sh "$APP/patch-theme-font.sh"
fi

if [ -d "$BLUR" ]; then
  [ -f "$BLUR/patch-colours-nsbar-blur.sh" ] && sudo sh "$BLUR/patch-colours-nsbar-blur.sh"
  [ -f "$BLUR/patch-theme-nsbar-blur.sh" ] && sudo sh "$BLUR/patch-theme-nsbar-blur.sh"
  if [ -x "$BLUR/hyperwebster-blur-toggle" ] || [ -f "$BLUR/hyperwebster-blur-toggle" ]; then
    sh "$BLUR/hyperwebster-blur-toggle" enable
  elif command -v hyperwebster-blur-toggle >/dev/null 2>&1; then
    hyperwebster-blur-toggle enable
  fi
fi

# Ensure System tools page stays on the FileDialog-inside-layout revision.
SYS="$HYPERWEBSTER_SRC/system-tools"
if [ -f "$SYS/patch-system-tools-page.sh" ]; then
  sudo sh "$SYS/patch-system-tools-page.sh"
fi

printf '%s\n' ":: nsbar font + blur restored - Ctrl+Super+Alt+R"
exit 0
