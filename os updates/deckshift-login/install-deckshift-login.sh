#!/bin/sh
# install-deckshift-login.sh — full-session DeckShift gaming with a password
# at boot. Keeps DeckShift's design (dedicated gamescope session, switched via
# SDDM restart) but makes the autologin ONE-SHOT: it only fires for the
# desktop<->gaming switch itself; every cold boot shows the password greeter.
#
# OPT-IN, POST-INSTALL component: the ISO ships this folder in the layer but
# does NOT run it. Order on the installed system:
#   1. run deckshift.sh (installs the gaming session, switch scripts, sudoers)
#   2. run THIS script (patches the login behaviour + adds the Hyprland bind)
# Re-run this script after any re-run of deckshift.sh (deckshift.sh restores
# its permanent-autologin versions of these files).
#
# Needs sudo for: /usr/local/bin, /usr/lib, /etc/systemd, /etc/sddm.conf.d.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
MARK='deckshift gaming keys'

# 0. DeckShift must already be installed.
if [ ! -x /usr/local/bin/switch-to-gaming ] || [ ! -f /usr/share/wayland-sessions/gamescope-session-steam-nm.desktop ]; then
  echo "ERROR: DeckShift is not installed (run deckshift.sh first, then re-run this)."
  exit 1
fi

# 1. Replace the session-switch helper with the one-shot-autologin version.
sudo install -m 0755 "$SRC/gaming-session-switch" /usr/local/bin/gaming-session-switch
echo ":: patched gaming-session-switch (one-shot autologin per switch)"

# 2. Install the SDDM start gate (script + sddm.service drop-in).
sudo install -m 0755 "$SRC/sddm-autologin-gate" /usr/local/bin/sddm-autologin-gate
sudo install -d -m 0755 /etc/systemd/system/sddm.service.d
sudo install -m 0644 "$SRC/deckshift-autologin-gate.conf" /etc/systemd/system/sddm.service.d/deckshift-autologin-gate.conf
sudo systemctl daemon-reload
echo ":: installed sddm autologin gate (password greeter on every cold boot)"

# 3. Drop the standing autologin drop-in; from now on it only exists
#    transiently between "switch requested" and "SDDM restarted".
if [ -f /etc/sddm.conf.d/zz-gaming-session.conf ]; then
  sudo rm -f /etc/sddm.conf.d/zz-gaming-session.conf
  echo ":: removed standing SDDM autologin drop-in"
fi

# 4. Ensure /usr/lib/os-session-select is DeckShift's handler (restores it if
#    the withdrawn nested-gaming experiment overwrote it).
if ! cmp -s "$SRC/os-session-select" /usr/lib/os-session-select 2>/dev/null; then
  sudo install -m 0755 "$SRC/os-session-select" /usr/lib/os-session-select
  echo ":: restored DeckShift os-session-select (Steam Exit to Desktop)"
fi

# 4b. Overlay switch-to-desktop: DeckShift's original pkills gamescope before
#     its final `systemctl restart sddm`; the session teardown kills the
#     script (it runs inside the gaming session) and the restart never fires —
#     with one-shot autologin that strands the user at the greeter. Our
#     version queues the restart as a detached root job instead (the proven
#     os-session-select pattern), so Super+Shift+R returns to the desktop.
sudo install -m 0755 "$SRC/switch-to-desktop" /usr/local/bin/switch-to-desktop
echo ":: overlaid switch-to-desktop (queued SDDM restart, fixes Super+Shift+R exit)"

# 5. Remove the withdrawn nested-gaming-mode bits if this box ever had them.
rm -f "$HOME/.local/bin/hyperwebster-gaming-mode" "$HOME/.local/bin/hyperwebster-gaming-mode-exit" \
      "$HOME/.local/share/applications/gaming-mode.desktop"
if [ -f "$HYPRUSER" ] && grep -qF 'gaming-mode (nested)' "$HYPRUSER"; then
  sed -i '/# >>> gaming-mode (nested) >>>/,/# <<< gaming-mode (nested) <<</d' "$HYPRUSER"
  echo ":: removed withdrawn nested gaming-mode binds"
fi

# 6. Hyprland bind: Super+Shift+S -> switch-to-gaming. The BASE config now ships a
#    self-guarding Super+Shift+S bind (omarchy-keys-user.conf) that launches the
#    gaming session only if DeckShift is installed and does nothing otherwise, so
#    this installer no longer adds the bind itself. We only add a GUARDED bind as a
#    fallback if no switch-to-gaming bind exists at all (e.g. an older base without
#    it) — never the old unguarded form, which would break Super+Shift+S on a box
#    where the gaming session is missing. Exit from Gaming Mode is handled INSIDE
#    the session (DeckShift's Super+Shift+R monitor, or Steam > Power > Exit).
if [ ! -f "$HYPRUSER" ]; then
  echo "NOTE: $HYPRUSER not found — base provides the guarded Super+Shift+S bind."
elif grep -qF 'switch-to-gaming' "$HYPRUSER"; then
  echo ":: gaming keybind already present (base provides the guarded Super+Shift+S)"
else
  cat >> "$HYPRUSER" << 'EOF'

# >>> deckshift gaming keys >>>
# Super+Shift+S = Gaming Mode IF DeckShift is installed; otherwise does nothing.
# Self-guards on the gaming session file + switch-to-gaming helper. Exit happens
# inside the session (Super+Shift+R, or Steam > Power > Exit to Desktop).
unbind = Super+Shift, S
bind = Super+Shift, S, exec, sh -c '[ -x /usr/local/bin/switch-to-gaming ] && [ -f /usr/share/wayland-sessions/gamescope-session-steam-nm.desktop ] && exec /usr/local/bin/switch-to-gaming'
# <<< deckshift gaming keys <<<
EOF
  echo ":: added guarded Super+Shift+S -> switch-to-gaming (base bind was absent)"
fi
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

echo "Done. Cold boot = password login. Super+Shift+S = Gaming Mode (full session);"
echo "Super+Shift+R or Steam > Exit to Desktop returns without a login screen."
