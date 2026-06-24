#!/bin/sh
# 1781492400-cachyos-kernel-default.sh
# HyperWebster now ships linux-cachyos + CachyOS repos OOB. Refresh the toggle
# CLI/UI, then enable CachyOS on boxes that still run stock-only (needs network).
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
sudo env HYPERWEBSTER_SKIP_SHELL_PATCH=1 sh "$SRC/cachyos-repo-switch/install-cachyos-repo-switch.sh"
if command -v hyperwebster-cachy-repo >/dev/null 2>&1 \
   && ! hyperwebster-cachy-repo status >/dev/null 2>&1; then
  echo "==> Enabling CachyOS kernel + repos (migration)..."
  sudo hyperwebster-cachy-repo enable || echo "WARNING: enable failed — retry from Settings when online." >&2
fi
