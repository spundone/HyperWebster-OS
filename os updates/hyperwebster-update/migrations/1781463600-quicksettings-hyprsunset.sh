#!/usr/bin/env bash
# 1781463600-quicksettings-hyprsunset.sh
# The Quick Settings "Night Light" tile drives hyprsunset (the placebo toggle was
# wired to the real process). New ISOs ship hyprsunset in the base; ensure it is
# present on already-installed boxes so Night Light works after the shell upgrade.
# (The Airplane + VPN-removal changes are pure hyperwebster-shell QML, delivered by
# the shell package upgrade — nothing to migrate for those.) Idempotent.
set -euo pipefail
if ! pacman -Qq hyprsunset >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm hyprsunset \
        || echo "WARNING: could not install hyprsunset — Night Light will no-op until it is installed" >&2
fi
