#!/usr/bin/env bash
# Migration: system polish — menu cleanup, cups.socket, web-app installer,
# first-login welcome. Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/system-polish/install-system-polish.sh"
