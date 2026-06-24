#!/usr/bin/env bash
# Migration: Wi-Fi wrong-password recovery — patch NetworkConnection.qml so a
# bad saved password re-prompts instead of failing silently.
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/wifi-password-retry/install-wifi-password-retry.sh"
