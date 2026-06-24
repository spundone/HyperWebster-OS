#!/bin/sh
# patch-hyperwebster-update.sh — stop yay's interactive menus from stalling
# hyperwebster-update. Idempotent; no sudo (the script is user-owned).
#
# Symptom: mid-update, yay shows its "Packages to exclude" upgrade menu
# (and clean-build/diff menus when AUR packages build). A bare `==>`
# prompt after a wall of output reads as a hang — the user already
# answered the only prompt they expected ("Update HyperWebster now? [y/N]").
#
# Fix: pre-answer all four yay menus with None. The pacman
# "Proceed with installation? [Y/n]" confirm is unaffected, and
# -y/--noconfirm behaviour is unchanged.
set -eu

TARGET=${TARGET:-$HOME/.local/share/hyperwebster/hyperwebster-update/bin/hyperwebster-update}

[ -f "$TARGET" ] || { echo "hyperwebster-update not found at $TARGET — nothing to patch"; exit 0; }

if grep -q 'answerupgrade' "$TARGET"; then
  echo ":: hyperwebster-update already patched"
  exit 0
fi

cp -n "$TARGET" "$TARGET.pre-menus-fix"

perl -0pi -e 's/  log "upgrading packages with \$HELPER"\n  "\$HELPER" -Syu \$nc\n/  # yay menus (exclude\/clean\/diff\/edit PKGBUILD) look like a hang mid-update —\n  # pre-answer them with None. The pacman proceed confirm still appears.\n  local menus=""\n  [ "\$HELPER" = yay ] \&\& menus="--answerupgrade None --answerclean None --answerdiff None --answeredit None"\n  log "upgrading packages with \$HELPER"\n  "\$HELPER" -Syu \$menus \$nc\n/' "$TARGET"

if grep -q 'answerupgrade' "$TARGET" && bash -n "$TARGET"; then
  echo ":: patched $TARGET (yay menus pre-answered)"
else
  echo "WARNING: patch did not apply cleanly — restoring backup." >&2
  cp "$TARGET.pre-menus-fix" "$TARGET"
  echo "         update_packages() in hyperwebster-update changed shape; update the" >&2
  echo "         regex in $(basename "$0")." >&2
  exit 1
fi
