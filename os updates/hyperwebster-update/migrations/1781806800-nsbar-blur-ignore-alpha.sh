#!/usr/bin/env bash
# Migration: fix nsbar frost — ignore_alpha was above Theme.barBg alpha.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?}"
SRC="$HYPERWEBSTER_SRC/blur-toggle"
[ -d "$SRC" ] || exit 0

sh "$SRC/install-blur-toggle.sh"

STATE="${HOME}/.local/state/hyperwebster/blur-enabled"
if [ ! -f "$STATE" ] || [ "$(cat "$STATE" 2>/dev/null || true)" = "1" ]; then
  hyperwebster-blur-toggle enable || true
else
  true
fi

echo ":: nsbar blur: ignore_alpha capped at 0.45 + Theme.barBg transparency"
echo ":: Ctrl+Super+Alt+R if the top bar is still flat"
