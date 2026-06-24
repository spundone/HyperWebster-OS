#!/usr/bin/env bash
# Migration: Settings → Additions page — install optional software (DeckShift,
# Spotify, Once, Obsidian, OBS, Claude Code, Codex, opencode) on demand from
# official sources. Idempotent — delegates to the installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/additions-installer/install-additions-installer.sh"
