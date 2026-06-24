#!/usr/bin/env bash
# Migration: fix the Super+J "toggle window split" bind. Hyprland 0.54+
# removed the direct `togglesplit` dispatcher (it must go via `layoutmsg`),
# so the original omarchy-keys fragment produced a red "Invalid dispatcher"
# banner at every config reload and a dead bind. Idempotent.
set -euo pipefail

HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
if [ -f "$HYPRUSER" ] && grep -qE '^bind = Super, J, togglesplit,' "$HYPRUSER"; then
  sed -i 's|^bind = Super, J, togglesplit,.*|bind = Super, J, layoutmsg, togglesplit                        # Toggle window split (Hyprland 0.54+ needs layoutmsg)|' "$HYPRUSER"
  echo ":: fixed Super+J togglesplit bind -> layoutmsg"
else
  echo ":: togglesplit bind already fixed (or fragment absent)"
fi

# Apply immediately if Hyprland is running.
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland"
fi
