#!/bin/sh
# install-monitor-control.sh — monitor management for HyperWebster.
#
#   - hyprmoncfg (AUR): TUI monitor layout editor + named profiles +
#     hotplug/lid auto-switching daemon (hyprmoncfgd, systemd user service)
#   - Super+Ctrl+H opens the layout editor in a floating terminal
#
# hyprmoncfg writes ~/.config/hypr/monitors.conf — the file the base config
# already sources from hypr-user.conf (same file nwg-displays uses).
# Safe to re-run (idempotent). Needs network + sudo.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"

# 1. AUR helper — bootstrap yay if none is present.
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

# 2. hyprmoncfg + the auto-switching daemon.
"$HELPER" -S --needed --noconfirm hyprmoncfg

# 3. Make sure the file hyprmoncfg writes is actually sourced (it refuses to
# write otherwise). The base hypr-user.conf already has this; belt and braces.
touch "$HOME/.config/hypr/monitors.conf"
if [ -f "$HYPRUSER" ] && ! grep -q 'monitors.conf' "$HYPRUSER"; then
  printf '\nsource = ~/.config/hypr/monitors.conf\n' >> "$HYPRUSER"
  echo ":: added monitors.conf source -> $HYPRUSER"
fi

# 4. Super+Ctrl+H bind (only if not already present).
if [ -f "$HYPRUSER" ]; then
  if grep -q 'hyprmoncfg' "$HYPRUSER"; then
    echo ":: bind already present in $HYPRUSER"
  else
    printf '\n' >> "$HYPRUSER"
    cat "$SRC/hyprland-monitor-control.conf" >> "$HYPRUSER"
    echo ":: appended Super+Ctrl+H bind -> $HYPRUSER"
  fi
else
  echo "NOTE: $HYPRUSER not found — add the lines from hyprland-monitor-control.conf manually."
fi

# 5. Enable the hotplug/lid daemon (user service, ships with the AUR package).
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user enable --now hyprmoncfgd 2>/dev/null \
    && echo ":: hyprmoncfgd enabled (hotplug/lid auto-switching)" \
    || echo "NOTE: could not enable hyprmoncfgd — run: systemctl --user enable --now hyprmoncfgd"
else
  echo "NOTE: no user systemd session — enable later with: systemctl --user enable --now hyprmoncfgd"
fi

# Apply immediately if Hyprland is running.
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland"
fi

echo "Done. Super+Ctrl+H opens the monitor layout editor; save profiles with 's'."
