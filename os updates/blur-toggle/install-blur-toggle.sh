#!/bin/sh
# install-blur-toggle.sh — optional frosted glass toggle. Idempotent.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="${HOME}/.local/bin"

install -d -m755 "$BIN"
install -m0755 "$HERE/hyperwebster-blur-toggle" "$BIN/hyperwebster-blur-toggle"
install -Dm0644 "$HERE/README.md" "${HOME}/.local/share/hyperwebster/blur-toggle/README.md" 2>/dev/null || true

echo "blur-toggle: run hyperwebster-blur-toggle enable for frosted glass"
