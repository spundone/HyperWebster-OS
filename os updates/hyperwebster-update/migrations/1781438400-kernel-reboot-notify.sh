#!/usr/bin/env bash
# Migration: install hyperwebster-reboot-check + the pacman kernel-change hook and
# wire the check into hyperwebster-update, so the user is told to reboot after a
# kernel update. Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/kernel-reboot-notify/install-kernel-reboot-notify.sh"
