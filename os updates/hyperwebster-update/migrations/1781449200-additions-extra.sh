#!/usr/bin/env bash
# Migration: merge the 7 extra Settings->Additions items (Ollama, LM Studio,
# Dropbox, Tailscale, Pinta, Kdenlive, Pi) into an installed manifest. No-op on
# a fresh ISO (it already ships the 15-item manifest). Idempotent, user-level.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/additions-extra/merge-additions.sh"
