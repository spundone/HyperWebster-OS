#!/bin/sh
# install-super-clipboard.sh — bind Super+C/Super+V to universal copy/paste.
#
#   - super-copy / super-paste -> ~/.local/bin (class-aware sendshortcut)
#   - appends an idempotent block to ~/.config/caelestia/hypr-user.conf that:
#       * unbinds the stock Super+V (clipboard history)
#       * binds Super+C -> super-copy, Super+V -> super-paste
#   - clipboard history stays on Super+Ctrl+V (and Super+Alt+V delete-mode).
# Idempotent: safe to re-run; the conf block is added at most once.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
MARK='super-clipboard copy/paste'

mkdir -p "$BIN"
install -m 0755 "$SRC/super-copy"  "$BIN/super-copy"
install -m 0755 "$SRC/super-paste" "$BIN/super-paste"

if [ ! -f "$HYPRUSER" ]; then
  echo "NOTE: $HYPRUSER not found — add the Super+C/Super+V binds manually."
elif grep -q "$MARK" "$HYPRUSER"; then
  echo ":: binds already present in $HYPRUSER"
else
  cat >> "$HYPRUSER" <<'EOF'

# >>> super-clipboard copy/paste >>>
# Super+C / Super+V = universal copy/paste. Terminals get Ctrl+Shift+C/V,
# GUI apps get Ctrl+C/V (class-aware, via Hyprland sendshortcut).
# Clipboard history moves to Super+Ctrl+V; Super+Alt+V = history delete-mode.
unbind = SUPER, V
bind = SUPER, C, exec, super-copy                              # Copy (universal)
bind = SUPER, V, exec, super-paste                             # Paste (universal)
# <<< super-clipboard copy/paste <<<
EOF
  echo ":: appended Super+C/Super+V copy-paste binds -> $HYPRUSER"
fi

# Apply immediately if Hyprland is running.
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland"
fi

echo "Done. Super+C copies, Super+V pastes; history on Super+Ctrl+V."
