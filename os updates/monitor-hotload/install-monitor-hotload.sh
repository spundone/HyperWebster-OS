#!/bin/sh
# install-monitor-hotload.sh — hot-apply saved hyprmoncfg profiles.
#
#   - hyprmoncfgd-rescan.path     -> watches ~/.config/hyprmoncfg/profiles
#   - hyprmoncfgd-rescan.service  -> oneshot: try-restart hyprmoncfgd
#
# Saving a profile in the Super+Ctrl+H TUI now applies within ~2s instead of
# at the next login/hotplug. Safe to re-run (idempotent). No sudo needed —
# everything is user-level.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
UNITS="$HOME/.config/systemd/user"

# The path unit's watch target must exist before the unit starts.
mkdir -p "$UNITS" "$HOME/.config/hyprmoncfg/profiles"

install -m 0644 "$SRC/hyprmoncfgd-rescan.path" "$UNITS/"
install -m 0644 "$SRC/hyprmoncfgd-rescan.service" "$UNITS/"

if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user enable --now hyprmoncfgd-rescan.path 2>/dev/null \
    && echo ":: hyprmoncfgd-rescan.path enabled (profiles dir watched)" \
    || echo "NOTE: enable later with: systemctl --user enable --now hyprmoncfgd-rescan.path"
else
  echo "NOTE: no user systemd session — enable the path unit after login."
fi

echo "Done. Saving a profile in the Super+Ctrl+H TUI now applies live."
