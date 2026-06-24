#!/bin/sh
# install-software-install.sh — HyperWebster software-installation story.
#
# What a user gets:
#   - yay      : AUR helper (the plumbing; bootstrapped from the AUR if missing)
#   - Shelly   : GUI package manager / app store (official repos + AUR + Flathub
#                + AppImage), package `shelly-bin`, binary `shelly-ui`, CLI `shelly`
#   - flatpak  : Flathub backend for Shelly, with the Flathub remote configured
#   - Super+I  : opens Shelly (bind appended to hypr-user.conf)
#
# Safe to re-run (idempotent). Needs network + sudo.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"

# 1. AUR helper — bootstrap yay if none is present (the base ships none).
HELPER=""
for h in yay paru; do
  command -v "$h" >/dev/null 2>&1 && { HELPER="$h"; break; }
done
if [ -z "$HELPER" ]; then
  echo ":: bootstrapping yay (yay-bin)"
  sudo pacman -S --needed --noconfirm git base-devel
  tmp=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  ( cd "$tmp/yay-bin" && makepkg -si --noconfirm )
  rm -rf "$tmp"
  HELPER=yay
fi

# 2. Shelly (prebuilt) + flatpak backend + appstream data (package icons/metadata).
"$HELPER" -S --needed --noconfirm shelly-bin flatpak archlinux-appstream-data

# 3. Flathub remote so Shelly's flatpak pages work out of the box.
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# 4. Super+I bind + tray notifier, only if not already present.
if [ -f "$HYPRUSER" ]; then
  if grep -q 'shelly-ui' "$HYPRUSER"; then
    echo ":: bind already present in $HYPRUSER"
  else
    printf '\n' >> "$HYPRUSER"
    cat "$SRC/hyprland-software-install.conf" >> "$HYPRUSER"
    echo ":: appended Super+I bind -> $HYPRUSER"
  fi
else
  echo "NOTE: $HYPRUSER not found — add the lines from hyprland-software-install.conf to your Hyprland user config."
fi

# Apply immediately if Hyprland is running.
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland"
fi

echo "Done. Super+I opens Shelly; 'yay -S <pkg>' works in the terminal."
