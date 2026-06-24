#!/bin/sh
# install-display-manager-sddm.sh — switch the display manager from greetd to
# SDDM, so DeckShift's SDDM-based desktop<->gaming session switching works.
# Idempotent. Needs sudo. Takes effect on next reboot.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# 1. Install SDDM (+ xorg-server for the reliable X11 greeter; the Hyprland
#    session itself stays Wayland). For an X-free image use the Wayland greeter
#    instead (see sddm-10-hyperwebster.conf) and drop xorg-server here.
echo ":: installing sddm + xorg-server (sudo)..."
sudo pacman -S --needed --noconfirm sddm xorg-server

# 2. Config drop-in (default desktop session = the uwsm-managed Hyprland).
sudo install -D -m 0644 "$SRC/sddm-10-hyperwebster.conf" /etc/sddm.conf.d/10-hyperwebster.conf
echo ":: installed /etc/sddm.conf.d/10-hyperwebster.conf"

# 3. Swap the active display-manager service: greetd -> sddm.
if systemctl is-enabled greetd.service >/dev/null 2>&1; then
  sudo systemctl disable greetd.service
  echo ":: disabled greetd.service"
fi
sudo systemctl enable sddm.service
echo ":: enabled sddm.service (display-manager.service -> sddm)"

cat <<'EOF'
Done. Reboot to log in via SDDM.
 - At the SDDM session picker choose "Hyprland (uwsm-managed)" once; SDDM remembers it.
 - DeckShift's switch-to-gaming / switch-to-desktop then drive SDDM to flip
   between your desktop and the Gamescope/Steam session.
EOF
