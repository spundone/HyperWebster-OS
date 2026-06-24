#!/bin/sh
# Migration: document cachyos-kernel-manager (ships in BASE_PKGS on fresh ISOs).
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/cachyos-kernel-manager" ] || exit 0
install -Dm0644 "$SRC/cachyos-kernel-manager/README.md" \
  "${HOME}/.local/share/hyperwebster/cachyos-kernel-manager/README.md" 2>/dev/null || true
