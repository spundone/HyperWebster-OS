#!/bin/sh
# install-tv-gaming-display.sh - ship 4K HDR TV hyprmoncfg profile + HDR hints.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HYPRUSER="${HOME}/.config/caelestia/hypr-user.conf"
PROFILE_DIR="${HOME}/.config/hyprmoncfg/profiles"
LAYER="${HOME}/.local/share/hyperwebster/tv-gaming-display"
MARK='tv-gaming-display: TV HDR/VRR profile'

mkdir -p "$PROFILE_DIR" "$LAYER"
install -m0644 "$HERE/profiles/tv-gaming-4k" "$PROFILE_DIR/tv-gaming-4k"
install -m0644 "$HERE/hypr-tv-gaming.conf" "$LAYER/hypr-tv-gaming.conf"
install -m0644 "$HERE/README.md" "$LAYER/README.md"

if [ -f "$HYPRUSER" ] && ! grep -qF "$MARK" "$HYPRUSER"; then
  cat >> "$HYPRUSER" <<EOF

# >>> tv-gaming-display: TV HDR/VRR profile >>>
# hyprmoncfg apply tv-gaming-4k - edit HDMI output in the profile first.
source = $LAYER/hypr-tv-gaming.conf
# <<< tv-gaming-display: TV HDR/VRR profile <<<
EOF
  echo ":: appended TV gaming hypr fragment to $HYPRUSER"
fi

echo "tv-gaming-display: profile installed - run: hyprmoncfg apply tv-gaming-4k"
