#!/usr/bin/env bash
# Migration: Super+Shift+S / Starman gamescope boot — passwordless SDDM restart.
# Root cause: sudoers only allowed gaming-session-switch; switch-to-gaming then
# ran `sudo -n systemctl restart sddm` which silently failed, so the session
# was armed but never entered. Starman also lacked a bare gamescope-session
# fallback when hyperwebster-gaming-session was missing.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?}"

SRC="$HYPERWEBSTER_SRC/chimera-deckify-gaming"
STARMAN="$HYPERWEBSTER_SRC/starman-gaming-boot"
[ -d "$SRC" ] || exit 0

# Helpers + sudoers (restart wrapper is the critical piece).
sudo sh "$SRC/install-chimera-deckify-gaming.sh"
sudo install -Dm0755 "$SRC/hyperwebster-restart-sddm" /usr/local/bin/hyperwebster-restart-sddm
sudo install -Dm0755 "$SRC/switch-to-gaming" /usr/local/bin/switch-to-gaming
sudo install -Dm0755 "$SRC/switch-to-desktop" /usr/local/bin/switch-to-desktop
sudo install -Dm0755 "$SRC/gaming-session-switch" /usr/local/bin/gaming-session-switch
sudo install -Dm0755 "$SRC/os-session-select" /usr/lib/os-session-select
sudo install -Dm0755 "$SRC/hyperwebster-gaming-session" /usr/local/bin/hyperwebster-gaming-session
if [ -x "$SRC/install-gaming-sudoers.sh" ]; then
  sudo sh "$SRC/install-gaming-sudoers.sh" || true
fi

# Refresh Starman arm (CachyOS gamescope-session fallback).
if [ -d "$STARMAN" ] && [ -x "$STARMAN/install-starman-gaming-boot.sh" ]; then
  sudo sh "$STARMAN/install-starman-gaming-boot.sh" || true
fi

# DeckShift overlay keeps one-shot gate + uses restart helper.
if [ -x "$HYPERWEBSTER_SRC/deckshift-login/install-deckshift-login.sh" ] \
   && [ -x /usr/local/bin/switch-to-gaming ] \
   && /usr/local/bin/hyperwebster-gaming-session >/dev/null 2>&1; then
  sh "$HYPERWEBSTER_SRC/deckshift-login/install-deckshift-login.sh" || true
fi

# Super+Shift+S bind with notify on miss (always rewrite).
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/hypr-user.conf"
if [ -f "$CONF" ]; then
  tmp=$(mktemp)
  grep -v 'Super+Shift, S, exec.*switch-to-gaming' "$CONF" > "$tmp" || true
  {
    cat "$tmp"
    echo
    echo "# HyperWebster: Super+Shift+S gamescope (SDDM restart fix)"
    cat <<'EOF'
bind = Super+Shift, S, exec, sh -c 'if ! [ -x /usr/local/bin/switch-to-gaming ]; then notify-send -u critical "Gaming Mode" "Helpers missing — Additions → Deckify / Chimera"; exit 1; fi; if ! /usr/local/bin/hyperwebster-gaming-session >/dev/null 2>&1; then notify-send -u critical "Gaming Mode" "No gamescope session — Additions → Deckify / Chimera"; exit 1; fi; exec /usr/local/bin/switch-to-gaming'
EOF
  } > "$CONF"
  rm -f "$tmp"
  echo ":: updated Super+Shift+S bind in $CONF"
fi
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

SESSION=$(/usr/local/bin/hyperwebster-gaming-session 2>/dev/null || true)
if [ -n "${SESSION:-}" ]; then
  echo ":: gamescope session ready: $SESSION"
  echo ":: Super+Shift+S should now restart SDDM into gaming (check: sudo -n hyperwebster-restart-sddm --check)."
else
  echo ":: No gamescope session desktop yet — run Additions → Deckify / Chimera, then Super+Shift+S."
fi
