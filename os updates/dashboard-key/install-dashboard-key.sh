#!/bin/sh
# install-dashboard-key.sh — Super+D toggles the dashboard (calendar + widgets).
# Idempotent.
#
# The dashboard (which holds caelestia's calendar) was reachable only by
# hovering the top screen edge. This adds a keybind. Super+D was caelestia's
# `$kbCommunication` (communication special-workspace toggle), so that moves to
# Super+Shift+D — nothing is lost.
set -eu

HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
MARK='dashboard-key: Super+D dashboard'

if [ ! -f "$HYPRUSER" ]; then
  echo "NOTE: $HYPRUSER not found — add the Super+D bind manually."
elif grep -qF "$MARK" "$HYPRUSER"; then
  echo ":: Super+D already bound in $HYPRUSER"
else
  cat >> "$HYPRUSER" <<'EOF'

# >>> dashboard-key: Super+D dashboard >>>
# Super+D toggles the dashboard (calendar + media/perf widgets), previously
# reachable only by hovering the top edge. Super+D was the communication
# special-workspace toggle ($kbCommunication) — moved to Super+Shift+D.
unbind = Super, D
bind = Super, D, exec, qs -c caelestia ipc call drawers toggle dashboard   # Dashboard / calendar
bind = Super+Shift, D, exec, caelestia toggle communication                # Communication workspace (moved from Super+D)
# <<< dashboard-key: Super+D dashboard <<<
EOF
  echo ":: bound Super+D -> dashboard; communication -> Super+Shift+D"
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland"
fi

echo "Done. Super+D opens the calendar/dashboard; Super+Shift+D = communication."
