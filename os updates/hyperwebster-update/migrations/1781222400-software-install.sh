#!/usr/bin/env bash
# Migration: software installation — yay (AUR helper) + Shelly GUI store on
# Super+I + flatpak/Flathub. Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/software-install/install-software-install.sh"
