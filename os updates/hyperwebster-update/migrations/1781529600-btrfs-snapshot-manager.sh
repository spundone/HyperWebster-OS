#!/bin/sh
# Migration: CachyOS-style btrfs snapshot GUI + timeline timers.
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/btrfs-snapshot-manager" ] || exit 0
sh "$SRC/btrfs-snapshot-manager/install-btrfs-snapshot-manager.sh"
sudo sh "$SRC/btrfs-snapshot-manager/install-btrfs-snapshot-manager.sh" 2>/dev/null || true
