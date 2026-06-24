#!/bin/sh
# Migration: tailscale preloaded — enable daemon if package present.
set -eu
if pacman -Qq tailscale >/dev/null 2>&1; then
  sudo systemctl enable tailscaled.service 2>/dev/null || true
  echo "tailscale: tailscaled enabled (connect with: sudo tailscale up)"
fi
