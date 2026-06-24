#!/bin/sh
# install-launcher-raycast.sh — Raycast-like caelestia launcher defaults.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="${HOME}/.local/bin"
DEST="${HOME}/.local/share/hyperwebster/launcher-raycast"

install -d -m755 "$BIN" "$DEST"
install -m0755 "$HERE/hyperwebster-launcher-raycast" "$BIN/hyperwebster-launcher-raycast"
install -m0644 "$HERE/launcher-shell.fragment.json" "$DEST/launcher-shell.fragment.json"
install -Dm0644 "$HERE/README.md" "$DEST/README.md"

"$BIN/hyperwebster-launcher-raycast" || echo "NOTE: merge skipped (jq or shell.json missing)"

echo "launcher-raycast: Super+Space opens fuzzy keyboard-first launcher"
