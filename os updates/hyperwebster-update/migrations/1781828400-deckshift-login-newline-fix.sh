#!/usr/bin/env bash
# Migration: fix deckshift-login install script (missing newline made the
# gaming-mode.desktop path execute as a command → exit 127) and continue the
# force-migrations chain so later nsbar/font/blur restores can run.
set +e
: "${HYPERWEBSTER_SRC:?}"

SRC="$HYPERWEBSTER_SRC/deckshift-login"
if [ -x /usr/local/bin/switch-to-gaming ] && [ -f "$SRC/install-deckshift-login.sh" ]; then
  sh "$SRC/install-deckshift-login.sh"
else
  echo ":: DeckShift not installed — skipping deckshift-login repair"
fi

printf '%s\n' ":: deckshift-login install newline fixed - continuing migrations"
exit 0
