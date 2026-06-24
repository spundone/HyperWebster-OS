#!/usr/bin/env bash
# Migration: CLIAmp as the default music player — package, audio MIME
# defaults, Super+M launch-or-focus.
# Idempotent — delegates to the component installer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/cliamp-music/install-cliamp-music.sh"
