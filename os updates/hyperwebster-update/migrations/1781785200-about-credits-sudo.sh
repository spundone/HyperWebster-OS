#!/bin/sh
# Migration: re-apply About credits after sudo fix for shell-branding overlays.
# Previous 1781781600 often failed with permission denied on /etc QML installs.
set -eu

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/shell-branding"
[ -d "$SRC" ] || SRC="$(CDPATH= cd -- "$(dirname -- "$0")/../../shell-branding" && pwd)"

sh "$SRC/install-shell-branding.sh"
