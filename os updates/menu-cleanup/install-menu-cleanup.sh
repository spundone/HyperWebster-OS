#!/bin/sh
# install-menu-cleanup.sh — hide launcher entries that should not appear.
# Currently: uuctl (uwsm's user-unit
# manager — a dmenu utility, not an app; ships a desktop entry via the uwsm
# package).
#
# Same mechanism as system-polish A1: a user-level override shadows the
# system entry. Safe to re-run (idempotent). No sudo.
set -eu

APPS="$HOME/.local/share/applications"
HIDDEN="uuctl"

mkdir -p "$APPS"
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

echo "Done. Launcher no longer lists: $HIDDEN"
