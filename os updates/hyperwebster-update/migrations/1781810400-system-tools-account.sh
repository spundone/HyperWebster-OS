#!/usr/bin/env bash
# Migration: Settings → System tools + circular lock avatar / ~/.face.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?}"

# Lock: circular clip + prefer ~/.face
if [ -d "$HYPERWEBSTER_SRC/lockscreen-polish" ]; then
  sh "$HYPERWEBSTER_SRC/lockscreen-polish/install-lockscreen-polish.sh" || true
fi

# Settings page
if [ -d "$HYPERWEBSTER_SRC/system-tools" ]; then
  sh "$HYPERWEBSTER_SRC/system-tools/install-system-tools.sh" || true
fi

echo ":: System tools + circular lock avatar — Ctrl+Super+Alt+R, then Settings → System tools"
