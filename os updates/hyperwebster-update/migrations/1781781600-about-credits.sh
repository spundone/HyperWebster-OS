#!/bin/sh
# Migration: Settings → About credits (upstream attribution + vibecoded note).
# Retries the shell-branding overlay with sudo (package-owned QML under /etc).
set -eu

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/shell-branding"
[ -d "$SRC" ] || SRC="$(CDPATH= cd -- "$(dirname -- "$0")/../../shell-branding" && pwd)"

# Prefer a fresh pull of AboutPage.qml from the layer share when present.
if [ -f "$HOME/.local/share/hyperwebster/shell-branding/AboutPage.qml" ]; then
  SRC="$HOME/.local/share/hyperwebster/shell-branding"
fi

sh "$SRC/install-shell-branding.sh"
