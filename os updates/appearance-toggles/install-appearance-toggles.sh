#!/bin/sh
# install-appearance-toggles.sh — shell blur companion: rounded-corner toggle.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="${HOME}/.local/bin"
LAYER="${HOME}/.local/share/hyperwebster/appearance-toggles"

install -d -m755 "$BIN" "$LAYER"
install -m0755 "$HERE/hyperwebster-rounding-toggle" "$BIN/hyperwebster-rounding-toggle"
install -m0644 "$HERE/rounding-tokens.json" "$LAYER/rounding-tokens.json"
install -m0644 "$HERE/README.md" "$LAYER/README.md" 2>/dev/null || true

echo "appearance-toggles: hyperwebster-rounding-toggle {enable|disable|toggle|status}"
