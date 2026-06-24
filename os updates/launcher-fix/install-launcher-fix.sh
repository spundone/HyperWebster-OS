#!/bin/sh
# install-launcher-fix.sh — make Super+Space reliably open and KEEP the app
# launcher open. Idempotent.
#
# Bug: omarchy-keys binds `Super, Space -> global, caelestia:launcher`. But caelestia
# runs a custom `global` submap where `bindin = Super, catchall ->
# launcherInterrupt` fires on ANY key pressed with Super — including Space. The
# native launcher toggles on RELEASE only `if (!launcherInterrupted)`, so the
# Space that opens it also trips the interrupt and it won't stay.
#
# Fix: open the launcher via the drawer-toggle IPC directly, which is
# independent of the launcherInterrupted state machine.
set -eu

HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
MARK='launcher-fix: Super+Space via drawers IPC'

if [ ! -f "$HYPRUSER" ]; then
  echo "NOTE: $HYPRUSER not found — rebind Super+Space manually."
elif grep -qF "$MARK" "$HYPRUSER"; then
  echo ":: Super+Space already fixed in $HYPRUSER"
else
  cat >> "$HYPRUSER" <<'EOF'

# >>> launcher-fix: Super+Space via drawers IPC >>>
# Toggle the launcher drawer directly (bypasses caelestia's launcherInterrupt,
# which Space trips via the `Super, catchall` interrupt bind). Native Super-tap
# still opens the launcher as before.
unbind = Super, Space
bind = Super, Space, exec, qs -c caelestia ipc call drawers toggle launcher   # Launch apps
# <<< launcher-fix: Super+Space via drawers IPC <<<
EOF
  echo ":: rebound Super+Space -> drawers toggle launcher"
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland"
fi

echo "Done. Super+Space opens the launcher and it stays open."
