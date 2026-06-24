#!/usr/bin/env bash
# Workspace dispatcher helper — bash port of Caelestia's wsaction.fish.
# Installed to ~/.config/hypr/scripts/wsaction.fish (the path the stock
# keybinds.conf calls); runs as bash via this shebang.
# Usage: wsaction [-g] <dispatcher> <workspace>

group=0
if [[ "$1" == "-g" ]]; then
  group=1
  shift
fi

if [[ $# -ne 2 ]]; then
  echo "Wrong number of arguments. Usage: wsaction [-g] <dispatcher> <workspace>" >&2
  exit 1
fi

dispatcher="$1"
target="$2"
active_ws=$(hyprctl activeworkspace -j | jq -r '.id')

if (( group )); then
  # Move to the same slot within workspace group <target>
  hyprctl dispatch "$dispatcher" "$(( (target - 1) * 10 + active_ws % 10 ))"
else
  # Move to workspace <target> within the current group
  hyprctl dispatch "$dispatcher" "$(( (active_ws - 1) / 10 * 10 + target ))"
fi
