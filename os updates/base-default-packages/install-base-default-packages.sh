#!/bin/sh
# install-base-default-packages.sh — idempotent. Needs root (pacman).
#
# Ensures packages that should be installed BY DEFAULT in the base build (not
# opt-in Additions). For the ISO, the builder should add these to the base
# package set; this covers already-installed systems via hyperwebster-update.
set -eu

# Base default packages (official repos; GPU-agnostic):
PKGS="github-cli"

if [ "$(id -u)" -eq 0 ]; then
  pacman -S --needed --noconfirm $PKGS
elif command -v sudo >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm $PKGS
else
  echo "need root to install: $PKGS" >&2
  exit 1
fi
echo "base default packages ensured: $PKGS"
