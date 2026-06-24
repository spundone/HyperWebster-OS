#!/usr/bin/env bash
# 1781474400-gaming-key-guard.sh
# Bake a SELF-GUARDING Super+Shift+S gaming bind: it enters DeckShift's gamescope
# session only if DeckShift is installed, and does nothing otherwise. Converges
# already-installed boxes by replacing the old UNGUARDED deckshift bind (which
# would break Super+Shift+S — restart SDDM into a missing session — when DeckShift
# is not installed). Self-contained, edits only the user's hypr-user.conf. Idempotent.
#
# >> Builder: the base ships the guarded bind via
#    omarchy-keys/omarchy-keys-user.conf, and the updated
#    deckshift-login/install-deckshift-login.sh no longer adds an unguarded bind.
#    This migration only fixes existing boxes.
set -euo pipefail

HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
GUARDED="bind = Super+Shift, S, exec, sh -c '[ -x /usr/local/bin/switch-to-gaming ] && [ -f /usr/share/wayland-sessions/gamescope-session-steam-nm.desktop ] && exec /usr/local/bin/switch-to-gaming'"

if [ ! -f "$HYPRUSER" ]; then
  echo "NOTE: $HYPRUSER absent; base provides the guarded Super+Shift+S bind."
  exit 0
fi

if grep -qF "sh -c '[ -x /usr/local/bin/switch-to-gaming" "$HYPRUSER"; then
  echo ":: Super+Shift+S already guarded — nothing to do."
elif grep -qxF "bind = Super+Shift, S, exec, /usr/local/bin/switch-to-gaming" "$HYPRUSER"; then
  tmp=$(mktemp)
  while IFS= read -r line; do
    if [ "$line" = "bind = Super+Shift, S, exec, /usr/local/bin/switch-to-gaming" ]; then
      printf '%s\n' "$GUARDED"
    else
      printf '%s\n' "$line"
    fi
  done < "$HYPRUSER" > "$tmp"
  cat "$tmp" > "$HYPRUSER"
  rm -f "$tmp"
  echo ":: guarded the existing Super+Shift+S gaming bind."
else
  cat >> "$HYPRUSER" <<EOF

# >>> deckshift gaming keys >>>
# Super+Shift+S = Gaming Mode IF DeckShift is installed; otherwise does nothing.
unbind = Super+Shift, S
$GUARDED
# <<< deckshift gaming keys <<<
EOF
  echo ":: added guarded Super+Shift+S gaming bind."
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland" || true
fi
