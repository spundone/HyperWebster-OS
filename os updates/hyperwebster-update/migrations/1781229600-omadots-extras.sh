#!/usr/bin/env bash
# Migration: omadots developer polish — starship/tmux/btop/git configs + LazyVim.
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/omadots-extras/install-omadots-extras.sh"
