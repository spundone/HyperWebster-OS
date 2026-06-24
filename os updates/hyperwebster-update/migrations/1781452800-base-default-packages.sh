#!/usr/bin/env bash
# Migration: ensure base default packages (github-cli, ...) are installed on an
# existing box. The ISO ships them in the base package set. Idempotent (root).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sudo sh "$HYPERWEBSTER_SRC/base-default-packages/install-base-default-packages.sh"
