#!/bin/sh
# Migration: empty MenuItem icons were rendering as "?" in Nexus Colours.
set -eu

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/glyphs-fix"
[ -d "$SRC" ] || SRC="$(CDPATH= cd -- "$(dirname -- "$0")/../../glyphs-fix" && pwd)"

sh "$SRC/install-glyphs-fix.sh"

# Refresh Colours page (uses check / palette icons in menus).
COLOURS="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/colours-page"
[ -d "$COLOURS" ] || COLOURS="$(CDPATH= cd -- "$(dirname -- "$0")/../../colours-page" && pwd)"
if [ -x "$COLOURS/install-colours-page.sh" ]; then
  sh "$COLOURS/install-colours-page.sh"
fi
