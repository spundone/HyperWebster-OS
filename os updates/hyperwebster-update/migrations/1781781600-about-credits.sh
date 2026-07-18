#!/bin/sh
# Migration: Settings → About credits (upstream attribution + vibecoded note).
set -eu

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/shell-branding"
[ -d "$SRC" ] || SRC="$(CDPATH= cd -- "$(dirname -- "$0")/../../shell-branding" && pwd)"

sh "$SRC/install-shell-branding.sh"
