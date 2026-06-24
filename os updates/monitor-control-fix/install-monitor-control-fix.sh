#!/bin/sh
# install-monitor-control-fix.sh — make saved hyprmoncfg profiles actually apply.
#
# Root cause: hyprmoncfg checks ONLY the file given as --hypr-config for the
# `source = ...monitors.conf` line. On caelestia that line lives in
# hypr-user.conf; hyprland.conf pulls hypr-user.conf in indirectly (and via the
# $cConf variable), which hyprmoncfg does not follow — so it refuses to write
# monitors.conf ("not sourced by hyprland.conf") and the profile never applies.
#
# Fix: point both the daemon (hyprmoncfgd) and the Super+Ctrl+H TUI at
# --hypr-config hypr-user.conf with an absolute --monitors-conf. Idempotent.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
DROPIN_DIR="$HOME/.config/systemd/user/hyprmoncfgd.service.d"
MARK='monitor-control-fix: hyprmoncfg source verification'

# 1. Daemon drop-in: correct --hypr-config / --monitors-conf.
mkdir -p "$DROPIN_DIR"
cp "$SRC/hyprmoncfgd-override.conf" "$DROPIN_DIR/override.conf"
echo ":: installed hyprmoncfgd drop-in -> $DROPIN_DIR/override.conf"

# 2. TUI bind (Super+Ctrl+H): same flags so applying from the TUI works too.
if [ ! -f "$HYPRUSER" ]; then
  echo "NOTE: $HYPRUSER not found — rebind Super+Ctrl+H manually."
elif grep -qF "$MARK" "$HYPRUSER"; then
  echo ":: Super+Ctrl+H already rebound in $HYPRUSER"
else
  cat >> "$HYPRUSER" <<'EOF'

# >>> monitor-control-fix: hyprmoncfg source verification >>>
# hyprmoncfg only checks the --hypr-config file for the monitors.conf source
# line; on caelestia that line is in hypr-user.conf (hyprland.conf includes it
# indirectly). Point the TUI here; --monitors-conf must be absolute.
unbind = Super+Ctrl, H
bind = Super+Ctrl, H, exec, kitty --class TUI.float -e hyprmoncfg --hypr-config $HOME/.config/caelestia/hypr-user.conf --monitors-conf $HOME/.config/hypr/monitors.conf
# <<< monitor-control-fix: hyprmoncfg source verification <<<
EOF
  echo ":: rebound Super+Ctrl+H with --hypr-config/--monitors-conf"
fi

# 3. Reload systemd + restart the daemon so it re-applies with the fix.
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user restart hyprmoncfgd 2>/dev/null \
    && echo ":: hyprmoncfgd restarted" \
    || echo "NOTE: restart manually: systemctl --user restart hyprmoncfgd"
fi
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

echo "Done. Saved monitor profiles now apply (daemon on hotplug/startup + TUI)."
