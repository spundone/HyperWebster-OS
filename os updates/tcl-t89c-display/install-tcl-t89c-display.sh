#!/bin/sh
# install-tcl-t89c-display.sh — ship TCL T89C TV hyprmoncfg profile + HDR hints.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HYPRUSER="${HOME}/.config/caelestia/hypr-user.conf"
PROFILE_DIR="${HOME}/.config/hyprmoncfg/profiles"
LAYER="${HOME}/.local/share/hyperwebster/tcl-t89c-display"
MARK='tcl-t89c-display: TV HDR/VRR profile'

mkdir -p "$PROFILE_DIR" "$LAYER"
install -m0644 "$HERE/profiles/tcl-t89c-tv" "$PROFILE_DIR/tcl-t89c-tv"
install -m0644 "$HERE/hypr-tcl-t89c.conf" "$LAYER/hypr-tcl-t89c.conf"
install -m0644 "$HERE/README.md" "$LAYER/README.md"

if [ -f "$HYPRUSER" ] && ! grep -qF "$MARK" "$HYPRUSER"; then
  cat >> "$HYPRUSER" <<EOF

# >>> tcl-t89c-display: TV HDR/VRR profile >>>
# hyprmoncfg apply tcl-t89c-tv — edit HDMI output in the profile first.
source = $LAYER/hypr-tcl-t89c.conf
# <<< tcl-t89c-display: TV HDR/VRR profile <<<
EOF
  echo ":: appended TCL T89C hypr fragment to $HYPRUSER"
fi

echo "tcl-t89c-display: profile installed — run: hyprmoncfg apply tcl-t89c-tv"
