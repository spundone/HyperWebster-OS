#!/bin/sh
# install-app-theme-awareness.sh — idempotent. User-level (no root).
#
# External apps (Chrome, Electron, Firefox, GTK, Qt) don't follow
# the desktop theme because nothing publishes a color-scheme preference — the
# portal reports "no preference" (0). This installs a sync that mirrors
# Caelestia's light/dark mode to the freedesktop appearance portal + GTK, and
# units that re-run it on every scheme change.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
UNITS="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
PORTAL="${XDG_CONFIG_HOME:-$HOME/.config}/xdg-desktop-portal"

install -Dm0755 "$HERE/hyperwebster-app-theme-sync"   "$BIN/hyperwebster-app-theme-sync"
install -Dm0644 "$HERE/hyperwebster-app-theme.service" "$UNITS/hyperwebster-app-theme.service"
install -Dm0644 "$HERE/hyperwebster-app-theme.path"    "$UNITS/hyperwebster-app-theme.path"
echo "installed sync script + user units"

# portals.conf: only create if the user doesn't already have one (don't clobber)
if [ ! -e "$PORTAL/portals.conf" ]; then
  install -Dm0644 "$HERE/portals.conf" "$PORTAL/portals.conf"
  echo "installed $PORTAL/portals.conf (Settings=gtk)"
else
  echo "note: $PORTAL/portals.conf exists — leaving it; ensure it has org.freedesktop.impl.portal.Settings=gtk"
fi

# enable the watcher + run an initial sync (needs a running user systemd bus)
if systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user enable --now hyperwebster-app-theme.path hyperwebster-app-theme.service || true
  echo "enabled hyperwebster-app-theme.{path,service}"
else
  echo "note: no user systemd bus here — units installed; they start at next login"
  "$BIN/hyperwebster-app-theme-sync" || true
fi

echo "app-theme-awareness: ok"
