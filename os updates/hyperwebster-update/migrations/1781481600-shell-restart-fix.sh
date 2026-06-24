#!/usr/bin/env bash
# 1781481600-shell-restart-fix.sh
# Make Ctrl+Super+Alt+R reliably restart the caelestia shell. The stock caelestia
# bind is `qs -c caelestia kill; sleep .1; caelestia shell -d` — the fixed 100 ms
# sleep often relaunches before the old instance releases its single-instance lock,
# so the shell doesn't fully come back.
# Override in hypr-user.conf to wait until the old instance stops answering IPC
# (it's gone), up to ~5s, then relaunch detached. Self-contained, edits only the
# user's hypr-user.conf, idempotent.
#
# >> Builder: the base ships this override via omarchy-keys/omarchy-keys-user.conf
#    (carried in this handoff). This migration only converges already-installed boxes.
set -euo pipefail

HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
if [ ! -f "$HYPRUSER" ]; then
  echo "NOTE: $HYPRUSER absent; base provides the robust restart bind."
  exit 0
fi

if grep -qF 'robust shell restart' "$HYPRUSER"; then
  echo ":: robust shell-restart bind already present — nothing to do."
else
  cat >> "$HYPRUSER" <<'EOF'

# >>> robust shell restart >>>
# Ctrl+Super+Alt+R restarts the caelestia shell. The stock bind used a fixed
# `sleep .1` between kill and relaunch, which often relaunched before the old
# instance released its single-instance lock. Wait until the old instance stops
# answering IPC (it's gone), up to ~5s, then relaunch detached.
unbind = Ctrl+Super+Alt, R
bindr = Ctrl+Super+Alt, R, exec, sh -c 'qs -c caelestia kill 2>/dev/null; for i in $(seq 1 50); do qs -c caelestia ipc show >/dev/null 2>&1 || break; sleep 0.1; done; setsid caelestia shell -d'
# <<< robust shell restart <<<
EOF
  echo ":: added robust Ctrl+Super+Alt+R shell-restart bind."
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland" || true
fi
