#!/bin/sh
# install-zephyr-polish.sh - ship optional zephyr motion toggle (default off).
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="${HOME}/.local/bin"
LAYER="${HOME}/.local/share/hyperwebster/zephyr-polish"

mkdir -p "$BIN" "$LAYER"
install -m0755 "$HERE/hyperwebster-zephyr-polish" "$BIN/hyperwebster-zephyr-polish"
install -m0644 "$HERE/hypr-zephyr.conf" "$LAYER/hypr-zephyr.conf"
install -m0644 "$HERE/shell-tokens-zephyr.json" "$LAYER/shell-tokens-zephyr.json"
install -m0644 "$HERE/README.md" "$LAYER/README.md"

echo "zephyr-polish: optional — run: hyperwebster-zephyr-polish enable"
