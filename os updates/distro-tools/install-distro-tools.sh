#!/bin/sh
# install-distro-tools.sh - maintenance menu + keybind.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="${HOME}/.local/bin"
LAYER="${HOME}/.local/share/hyperwebster/distro-tools"
HYPRUSER="${HOME}/.config/caelestia/hypr-user.conf"
MARK_BEGIN='# >>> distro-tools >>>'
MARK_END='# <<< distro-tools <<<'

mkdir -p "$BIN" "$LAYER"
install -m0755 "$HERE/hyperwebster-maint" "$BIN/hyperwebster-maint"
install -m0644 "$HERE/README.md" "$LAYER/README.md"

if [ -f "$HYPRUSER" ] && ! grep -qF "$MARK_BEGIN" "$HYPRUSER"; then
  cat >> "$HYPRUSER" <<EOF

$MARK_BEGIN
bind = Super+Ctrl+Shift, M, exec, hyperwebster-maint
$MARK_END
EOF
  echo ":: appended maintenance menu keybind -> $HYPRUSER"
fi

echo "distro-tools: Super+Ctrl+Shift+M or hyperwebster-maint"
