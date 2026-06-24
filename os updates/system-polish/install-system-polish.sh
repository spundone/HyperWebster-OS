#!/bin/sh
# install-system-polish.sh — HyperWebster polish bundle. Three parts:
#
#   A. Menu cleanup + printing
#      - hides clutter .desktop entries (avahi browsers, V4L test tools,
#        foot terminal trio, pinentry dialogs) via per-user overrides
#      - enables cups.socket so printing works (stack is installed but off)
#   B. Web-app installer: hyperwebster-webapp-install / hyperwebster-webapp-remove
#   C. First-login welcome notification pointing at the discoverability keys
#
# Safe to re-run (idempotent). sudo only needed for cups.socket.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
APPS="$HOME/.local/share/applications"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"

mkdir -p "$BIN" "$APPS"

# --- A1. hide menu clutter (user-level override shadows the system entry) ----
HIDDEN="avahi-discover bssh bvnc qv4l2 qvidcap foot footclient foot-server org.gnupg.pinentry-qt org.gnupg.pinentry-qt5 uuctl"
for id in $HIDDEN; do
  [ -f "/usr/share/applications/$id.desktop" ] || continue
  [ -f "$APPS/$id.desktop" ] && continue
  cat > "$APPS/$id.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Hidden by HyperWebster
NoDisplay=true
Hidden=true
EOF
  echo ":: hidden $id"
done
update-desktop-database "$APPS" 2>/dev/null || true

# --- A2. printing: socket-activated CUPS (zero cost until first print) -------
if command -v systemctl >/dev/null 2>&1 && [ -e /usr/lib/systemd/system/cups.socket ]; then
  if systemctl is-enabled cups.socket >/dev/null 2>&1; then
    echo ":: cups.socket already enabled"
  else
    sudo systemctl enable --now cups.socket && echo ":: cups.socket enabled (printing works now)"
  fi
fi

# --- B. web-app installer -----------------------------------------------------
install -m 0755 "$SRC/hyperwebster-webapp-install" "$BIN/hyperwebster-webapp-install"
install -m 0755 "$SRC/hyperwebster-webapp-remove"  "$BIN/hyperwebster-webapp-remove"
echo ":: installed hyperwebster-webapp-install / hyperwebster-webapp-remove -> $BIN"

# --- C. first-login welcome ----------------------------------------------------
install -m 0755 "$SRC/hyperwebster-welcome" "$BIN/hyperwebster-welcome"
if [ -f "$HYPRUSER" ]; then
  if grep -q 'hyperwebster-welcome' "$HYPRUSER"; then
    echo ":: welcome exec-once already present"
  else
    printf '\n# HyperWebster — one-time first-login welcome (stamps ~/.local/state/hyperwebster/welcomed)\nexec-once = ~/.local/bin/hyperwebster-welcome\n' >> "$HYPRUSER"
    echo ":: appended welcome exec-once -> $HYPRUSER"
  fi
else
  echo "NOTE: $HYPRUSER not found — add 'exec-once = ~/.local/bin/hyperwebster-welcome' manually."
fi

echo "Done. Try: hyperwebster-webapp-install \"YouTube\" https://youtube.com"
