#!/bin/sh
# install-sddm-theme.sh — SDDM greeter themed to match the desktop (Material
# palette from the caelestia scheme, the shell's Google Sans Flex font, and
# the current wallpaper as background). Idempotent. Needs sudo.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
THEME=/usr/share/sddm/themes/caelestia

# 1. Theme files.
sudo install -d -m 0755 "$THEME" "$THEME/backgrounds"
sudo install -m 0644 "$SRC/caelestia/Main.qml"         "$THEME/Main.qml"
sudo install -m 0644 "$SRC/caelestia/metadata.desktop" "$THEME/metadata.desktop"
# Default theme.conf only if none exists yet (sync overwrites it anyway).
[ -f "$THEME/theme.conf" ] || sudo install -m 0644 "$SRC/caelestia/theme.conf" "$THEME/theme.conf"
echo ":: installed SDDM theme to $THEME"

# 2. Sync script + initial sync from the current scheme/wallpaper (best
#    effort: if there is no scheme yet — e.g. at image build time — the
#    shipped foam-sea defaults in theme.conf apply, but the background still
#    needs to be provided; see README builder notes).
sudo install -m 0755 "$SRC/sddm-theme-sync" /usr/local/bin/sddm-theme-sync
if sudo /usr/local/bin/sddm-theme-sync; then
  :
else
  echo "NOTE: initial sync failed (no caelestia scheme yet?) — shipped defaults kept."
  if [ ! -e "$THEME/backgrounds/wallpaper.png" ] && [ -f "$HOME/Pictures/Wallpapers/hyperwebster/foam-sea.png" ]; then
    sudo install -m 0644 "$HOME/Pictures/Wallpapers/hyperwebster/foam-sea.png" "$THEME/backgrounds/wallpaper.png"
    echo ":: seeded foam-sea.png as the greeter background"
  fi
fi

# 3. Point SDDM at the theme (drop-in, doesn't touch 10-hyperwebster.conf).
if [ ! -f /etc/sddm.conf.d/20-sddm-theme.conf ]; then
  sudo tee /etc/sddm.conf.d/20-sddm-theme.conf > /dev/null << 'EOF'
# Greeter theme matching the desktop scheme (sddm-theme component).
# Remove this file to fall back to SDDM's default greeter.
[Theme]
Current=caelestia
EOF
  echo ":: set SDDM theme to 'caelestia'"
fi

echo "Done. Preview without logging out:"
echo "  sddm-greeter-qt6 --test-mode --theme $THEME"
echo "Re-sync after a wallpaper change:  sudo sddm-theme-sync"
