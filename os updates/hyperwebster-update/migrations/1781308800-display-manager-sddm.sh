#!/usr/bin/env bash
# Migration: switch display manager greetd -> SDDM (DeckShift gaming-mode
# session switching). NOT no-op: installs packages, swaps services, needs reboot.
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/display-manager-sddm/install-display-manager-sddm.sh"
