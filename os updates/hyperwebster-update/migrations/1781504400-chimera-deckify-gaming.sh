#!/bin/sh
# Migration: Chimera / Deckify gaming helpers.
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/chimera-deckify-gaming" ] || exit 0
sudo sh "$SRC/chimera-deckify-gaming/install-chimera-deckify-gaming.sh"
