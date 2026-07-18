#!/usr/bin/env bash
# Migration: prefer CachyOS gamescope-session; detect gamescope-session.desktop.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?}"

SRC="$HYPERWEBSTER_SRC/chimera-deckify-gaming"
[ -d "$SRC" ] || exit 0

# Refresh helpers (session resolver + installer + Super+Shift+S guard).
sudo sh "$SRC/install-chimera-deckify-gaming.sh"
# Also ship switch scripts so Super+Shift+S works once session exists.
sudo install -Dm0755 "$SRC/switch-to-gaming" /usr/local/bin/switch-to-gaming
sudo install -Dm0755 "$SRC/switch-to-desktop" /usr/local/bin/switch-to-desktop
sudo install -Dm0755 "$SRC/gaming-session-switch" /usr/local/bin/gaming-session-switch
sudo install -Dm0755 "$SRC/hyperwebster-gaming-session" /usr/local/bin/hyperwebster-gaming-session

# Widen Super+Shift+S to use hyperwebster-gaming-session (includes CachyOS).
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/hypr-user.conf"
MARKER="# HyperWebster: Super+Shift+S gamescope (CachyOS + Chimera)"
if [ -f "$CONF" ]; then
  if ! grep -qF "$MARKER" "$CONF" 2>/dev/null; then
    # Drop older guarded binds that only listed steam-*-nm desktops.
    tmp=$(mktemp)
    grep -v 'Super+Shift, S, exec.*switch-to-gaming' "$CONF" > "$tmp" || true
    {
      cat "$tmp"
      echo
      echo "$MARKER"
      echo "bind = Super+Shift, S, exec, sh -c '[ -x /usr/local/bin/switch-to-gaming ] && /usr/local/bin/hyperwebster-gaming-session >/dev/null 2>&1 && exec /usr/local/bin/switch-to-gaming'"
    } > "$CONF"
    rm -f "$tmp"
    echo ":: updated Super+Shift+S bind in $CONF"
  fi
fi

# If CachyOS session is already installed, stop here (no AUR conflict).
if pacman -Q gamescope-session-cachyos >/dev/null 2>&1; then
  echo ":: gamescope-session-cachyos present — session: $(/usr/local/bin/hyperwebster-gaming-session 2>/dev/null || echo missing)"
  echo ":: Re-run Additions → Deckify / Chimera if helpers were incomplete; Super+Shift+S should work now."
  exit 0
fi

echo ":: No gamescope-session-cachyos yet — install from Additions → Deckify / Chimera"
