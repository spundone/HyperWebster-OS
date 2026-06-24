#!/usr/bin/env bash
# 1781478000-gamemode-toggle-deckshift.sh
# Repoint the utilities "Game Mode" gamepad toggle to launch the DeckShift gaming
# session (if installed; else do nothing) instead of caelestia's cosmetic Game
# Mode. Patches the package-owned hyperwebster-shell file on already-installed boxes.
# Idempotent. Requires a shell restart (Ctrl+Super+Alt+R) to take effect — qs -n
# does not hot-reload; the installer prints that reminder.
#
# >> Builder: the REAL fix is in the hyperwebster-shell FORK source
#    (modules/utilities/cards/Toggles.qml). Bake the corrected file there and set
#    HYPERWEBSTER_SKIP_SHELL_PATCH for the build so this fallback patch is skipped.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sudo sh "$HYPERWEBSTER_SRC/gamemode-toggle-deckshift/install-gamemode-toggle-deckshift.sh"
