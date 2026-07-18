#!/usr/bin/env bash
# Migration: System tools FileDialog must not be a PageBase child — it crashed
# the caelestia shell on start (Nexus compiles the page via PageCompRegistry).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?}"
SRC="$HYPERWEBSTER_SRC/system-tools"
[ -d "$SRC" ] || exit 0

if [ -x "$SRC/install-system-tools.sh" ]; then
  sh "$SRC/install-system-tools.sh" || true
elif [ -x "$SRC/patch-system-tools-page.sh" ]; then
  sudo sh "$SRC/patch-system-tools-page.sh" || true
fi

echo ":: System tools FileDialog moved inside layout — Ctrl+Super+Alt+R"
