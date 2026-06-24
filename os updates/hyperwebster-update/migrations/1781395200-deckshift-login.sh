#!/usr/bin/env bash
# Migration: deckshift-login — full-session DeckShift gaming with a password
# at boot (one-shot autologin per desktop<->gaming switch).
#
# Gaming is OPT-IN: this migration only (re-)applies the fix where DeckShift
# is actually installed; everywhere else it is a no-op. Users opt in with:
#   sh ~/deckshift/deckshift.sh
#   sh ~/.local/share/hyperwebster/deckshift-login/install-deckshift-login.sh
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"

if [ -x /usr/local/bin/switch-to-gaming ]; then
  sh "$HYPERWEBSTER_SRC/deckshift-login/install-deckshift-login.sh"
else
  echo ":: DeckShift not installed on this machine — skipping (opt-in component)"
fi
