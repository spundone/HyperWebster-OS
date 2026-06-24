#!/usr/bin/env bash
# Migration: rebrand nosignal-shell Settings pages for HyperWebster CLIs + About text.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sudo sh "$HYPERWEBSTER_SRC/shell-branding/install-shell-branding.sh"
