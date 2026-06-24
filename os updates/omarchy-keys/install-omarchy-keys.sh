#!/bin/sh
# install-omarchy-keys.sh — remap HyperWebster keybindings to Omarchy's defaults
# Idempotent.
#
#   - omarchy-keys-vars.conf -> appended to ~/.config/caelestia/hypr-vars.conf
#     ($kb* variable remaps; that file is sourced before keybinds.conf)
#   - omarchy-keys-user.conf -> appended to ~/.config/caelestia/hypr-user.conf
#     (unbinds + extra binds; that file is parsed last)
#   - the existing overview bind moves Super+Tab -> Super+Grave
#     (Super+Tab becomes "next workspace", as in Omarchy)
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HYPRVARS="$HOME/.config/caelestia/hypr-vars.conf"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
MARK='Omarchy default keybindings'

append_once() {
  # append_once <fragment> <target>
  if [ ! -f "$2" ]; then
    echo "NOTE: $2 not found — append the lines from $(basename "$1") manually."
    return 0
  fi
  if grep -q "$MARK" "$2"; then
    echo ":: already present in $2"
  else
    printf '\n' >> "$2"
    cat "$1" >> "$2"
    echo ":: appended $(basename "$1") -> $2"
  fi
}

append_once "$SRC/omarchy-keys-vars.conf" "$HYPRVARS"
append_once "$SRC/omarchy-keys-user.conf" "$HYPRUSER"

# Move the overview sidecar off Super+Tab (now "next workspace") onto Super+Grave.
if [ -f "$HYPRUSER" ] && grep -q 'bind = Super, Tab, exec, qs ipc -c overview' "$HYPRUSER"; then
  sed -i 's|bind = Super, Tab, exec, qs ipc -c overview|bind = Super, Grave, exec, qs ipc -c overview|' "$HYPRUSER"
  echo ":: overview bind moved Super+Tab -> Super+Grave"
fi

# Apply immediately if Hyprland is running.
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland"
fi

echo "Done. Keys now follow Omarchy defaults — press Super+K for the cheatsheet."
