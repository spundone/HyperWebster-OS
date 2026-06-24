#!/usr/bin/env bash
# Migration: Print = region screenshot; all screenshots saved to ~/Pictures/Screenshots.
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/screenshots/install-screenshots.sh"
