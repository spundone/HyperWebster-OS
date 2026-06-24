#!/usr/bin/env bash
# Ensure the HyperWebster user-override files exist — bash port of configs.fish.
# Installed to ~/.config/hypr/scripts/configs.fish (the path hyprland.conf
# exec's at startup); runs as bash via this shebang.
# Usage: configs <config-dir>

reload=false
dir="$1"

[[ -d "$dir" ]] || mkdir -p "$dir"

if [[ ! -f "$dir/hypr-vars.conf" ]]; then
  touch "$dir/hypr-vars.conf"
  reload=true
fi

if [[ ! -f "$dir/hypr-user.conf" ]]; then
  touch "$dir/hypr-user.conf"
  reload=true
fi

$reload && hyprctl reload
