#!/usr/bin/env bash
# Migration: nosignal-update compat aliases + re-apply Updates/shell QML after
# nosignal-shell upgrades that ship upstream UpdatesPage.qml.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/update-alias/install-update-alias.sh"
sudo sh "$HYPERWEBSTER_SRC/shell-branding/install-shell-branding.sh"
sh "$HYPERWEBSTER_SRC/updates-panel/install-updates-panel.sh"
