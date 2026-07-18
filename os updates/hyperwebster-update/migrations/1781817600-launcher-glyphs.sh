#!/usr/bin/env bash
# Migration: map Super+Space launcher action icons (calculate, colors, casino, …).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?}"
SRC="$HYPERWEBSTER_SRC/glyphs-fix"
[ -d "$SRC" ] || exit 0
sh "$SRC/install-glyphs-fix.sh"
echo ":: launcher glyphs — Ctrl+Super+Alt+R then Super+Space > to verify"
