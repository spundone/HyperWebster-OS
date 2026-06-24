#!/usr/bin/env bash
# Migration: tidy the Super+K cheatsheet — key + action columns only, no doc
# noise, every line fits the fuzzel panel.
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/cheatsheet-tidy/install-cheatsheet-tidy.sh"
