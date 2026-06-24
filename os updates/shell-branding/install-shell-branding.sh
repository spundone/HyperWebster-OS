#!/bin/sh
# install-shell-branding.sh — apply HyperWebster branding to the installed shell.
# Idempotent. Safe in chroot (patch only; no user session needed).
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sh "$SELF_DIR/patch-shell-branding.sh"
echo "shell-branding: restart the shell (Ctrl+Super+Alt+R) to refresh Settings → About."
