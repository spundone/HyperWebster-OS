#!/bin/sh
# install-gaming-enablement.sh — enable the multilib repo + install the
# omarchy-pkg-add shim, so Omarchy-targeted Steam/gaming install scripts (e.g.
# DeckShift) work on HyperWebster. Idempotent. Needs sudo for the pacman.conf edit and
# database sync (it will prompt).
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"

# 1. Enable [multilib] — the 32-bit repo every lib32-* package lives in.
if pacman-conf --repo-list 2>/dev/null | grep -qx multilib; then
  echo ":: [multilib] already enabled"
else
  echo ":: enabling [multilib] in /etc/pacman.conf (sudo)..."
  # Uncomment ONLY the [multilib] block (leaves [multilib-testing] alone).
  sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
  sudo pacman -Sy
  echo ":: [multilib] enabled and databases synced"
fi

# 2. Omarchy CLI shims (HyperWebster ships yay/caelestia, not the Omarchy helpers).
mkdir -p "$BIN"
for shim in omarchy-pkg-add omarchy-install-gaming-steam \
            omarchy-hw-nvidia-gsp omarchy-hw-nvidia-without-gsp \
            omarchy-restart-walker; do
  install -m 0755 "$SRC/$shim" "$BIN/$shim"
  echo ":: installed $shim -> $BIN/$shim"
done

echo "Done. multilib + Omarchy shims ready — re-run your gaming installer."
