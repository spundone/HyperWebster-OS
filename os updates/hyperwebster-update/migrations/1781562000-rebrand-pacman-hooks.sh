#!/usr/bin/env bash
# Migration: install pacman hooks so shell rebrand + page patches survive
# nosignal-shell upgrades (About/Services toggles, Updates, Additions, Wi-Fi).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sudo sh "$HYPERWEBSTER_SRC/shell-branding/install-shell-branding.sh"
sh "$HYPERWEBSTER_SRC/wifi-password-retry/install-wifi-password-retry.sh"
sh "$HYPERWEBSTER_SRC/additions-installer/install-additions-installer.sh"
