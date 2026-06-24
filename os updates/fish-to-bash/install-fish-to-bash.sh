#!/bin/sh
# install-fish-to-bash.sh — migrate this HyperWebster box from fish to bash, matching
# the Omarchy bash setup. Everything ships in this folder so it survives a wipe.
#
# Applies:
#   1. Vendors Omarchy's default/bash tree -> ~/.local/share/omarchy/default/bash
#   2. Installs ~/.bashrc (Omarchy template + Caelestia colour-scheme line)
#   3. Points kitty + foot at bash
#   4. Replaces the two Hyprland helper scripts with bash ports (kept at their
#      .fish paths so the stock keybinds.conf / hyprland.conf keep working)
#
# Idempotent (safe to re-run). Backs up an existing ~/.bashrc once.
# Does NOT remove the fish package — see README.md.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OMARCHY_BASH="$HOME/.local/share/omarchy/default/bash"

# 1. Vendor the Omarchy bash tree.
mkdir -p "$OMARCHY_BASH/fns"
for f in rc shell aliases envs init functions inputrc completions; do
  cp "$SRC/bash/$f" "$OMARCHY_BASH/$f"
done
cp "$SRC/bash/fns/"* "$OMARCHY_BASH/fns/"
echo "vendored Omarchy bash tree -> $OMARCHY_BASH"

# 2. Install ~/.bashrc (back up any existing one, once).
if [ -f "$HOME/.bashrc" ] && [ ! -f "$HOME/.bashrc.pre-omarchy" ]; then
  cp "$HOME/.bashrc" "$HOME/.bashrc.pre-omarchy"
  echo "backed up existing ~/.bashrc -> ~/.bashrc.pre-omarchy"
fi
cp "$SRC/bashrc" "$HOME/.bashrc"
echo "installed ~/.bashrc"

# 3. Terminals -> bash.
KITTY="$HOME/.config/kitty/kitty.conf"
if [ -f "$KITTY" ]; then
  if grep -q '^shell ' "$KITTY"; then
    sed -i 's/^shell .*/shell bash/' "$KITTY"
  else
    printf '\nshell bash\n' >> "$KITTY"
  fi
  echo "kitty -> bash"
fi
FOOT="$HOME/.config/foot/foot.ini"
if [ -f "$FOOT" ]; then
  if grep -q '^shell=' "$FOOT"; then
    sed -i 's/^shell=.*/shell=bash/' "$FOOT"
  else
    sed -i '1i shell=bash' "$FOOT"
  fi
  echo "foot -> bash"
fi

# 4. Hyprland helper scripts -> bash (keep the .fish filenames the config calls).
SCRIPTS="$HOME/.config/hypr/scripts"
if [ -d "$SCRIPTS" ]; then
  install -m 0755 "$SRC/hypr-wsaction.bash" "$SCRIPTS/wsaction.fish"
  install -m 0755 "$SRC/hypr-configs.bash"  "$SCRIPTS/configs.fish"
  echo "Hyprland helper scripts -> bash"
fi

# 5. Reload Hyprland if running.
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo "reloaded Hyprland"
fi

echo "Done. Open a NEW terminal to land in bash."
