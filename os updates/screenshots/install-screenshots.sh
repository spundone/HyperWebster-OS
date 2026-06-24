#!/bin/sh
# install-screenshots.sh — Print = region screenshot; all screenshots saved to
# ~/Pictures/Screenshots AND copied to clipboard. Idempotent.
#
#   - hyperwebster-screenshot      -> ~/.local/bin
#   - swappy save_dir        -> ~/Pictures/Screenshots (caelestia region/freeze
#                               binds pipe into swappy; this makes them save there)
#   - hypr-user.conf binds:  Print = region, Super+Print = full screen
#     (the stock Print = full-screen-to-clipboard bind is unbound first)
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
SWAPPY="$HOME/.config/swappy/config"
PICS="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
MARK='hyperwebster screenshots'

mkdir -p "$BIN" "$PICS"
install -m 0755 "$SRC/hyperwebster-screenshot" "$BIN/hyperwebster-screenshot"

# swappy save dir (only write if absent or previously written by us; don't
# clobber a user's hand-tuned config).
if [ ! -f "$SWAPPY" ] || grep -q "HyperWebster: make swappy" "$SWAPPY"; then
  mkdir -p "$(dirname "$SWAPPY")"
  cp "$SRC/swappy-config" "$SWAPPY"
  echo ":: swappy save_dir -> $PICS"
else
  echo ":: swappy config already customised — left as-is (set save_dir to $PICS yourself if wanted)"
fi

# Hyprland binds.
if [ ! -f "$HYPRUSER" ]; then
  echo "NOTE: $HYPRUSER not found — add the Print binds manually."
elif grep -q "$MARK" "$HYPRUSER"; then
  echo ":: binds already present in $HYPRUSER"
else
  cat >> "$HYPRUSER" <<'EOF'

# >>> hyperwebster screenshots >>>
# Print = select a region (crosshair) -> clipboard + ~/Pictures/Screenshots.
# Shift+Print = whole screen. Both also save a PNG; swappy (region/freeze
# binds) saves to the same folder. unbind removes the stock full-screen Print.
# (Super+Print stays the color picker / hyprpicker -a.)
unbind = , Print
bind = , Print, exec, hyperwebster-screenshot region                # Screenshot: region
bind = SHIFT, Print, exec, hyperwebster-screenshot full             # Screenshot: full screen
# <<< hyperwebster screenshots <<<
EOF
  echo ":: appended Print/Super+Print screenshot binds -> $HYPRUSER"
fi

# Apply immediately if Hyprland is running.
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland"
fi

echo "Done. Print = region screenshot; saved to $PICS and copied to clipboard."
