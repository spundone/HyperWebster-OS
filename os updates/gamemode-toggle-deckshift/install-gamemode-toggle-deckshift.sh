#!/bin/sh
# install-gamemode-toggle-deckshift.sh — idempotent. REQUIRES ROOT (writes the
# package-owned shell file under /etc/xdg).
#
# Repoints the utilities "Game Mode" gamepad toggle to launch the DeckShift gaming
# session if DeckShift is installed; otherwise it does nothing. (Was caelestia's
# cosmetic Game Mode toggle — disable animations/blur/gaps.) See README.
#
# Toggles.qml is shipped by the `hyperwebster-shell` package (baked into the fork). The
# REAL fix is in the fork source — this fallback patch is for already-installed boxes
# and is reverted by the next hyperwebster-shell upgrade (which carries the fixed file).
# The builder bakes it into the fork and sets HYPERWEBSTER_SKIP_SHELL_PATCH to skip this.
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET=/etc/xdg/quickshell/caelestia/modules/utilities/cards/Toggles.qml

if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
    echo ":: skipping fallback shell patch (HYPERWEBSTER_SKIP_SHELL_PATCH — fork bakes the fix)"
    exit 0
fi

[ "$(id -u)" -eq 0 ] || { echo "must run as root (writes $TARGET)" >&2; exit 1; }

if [ ! -f "$TARGET" ]; then
    echo "WARNING: $TARGET not present — hyperwebster-shell not installed here; nothing to patch." >&2
    exit 0
fi

if cmp -s "$SELF_DIR/Toggles.qml" "$TARGET"; then
    echo ":: Game Mode toggle already up to date — nothing to do."
    exit 0
fi

# preserve the ORIGINAL (pre-HyperWebster) file only on the first patch, so re-running
# with a newer Toggles.qml (e.g. the hardened version) doesn't overwrite the backup
[ -f "$TARGET.prefix.bak" ] || cp -a "$TARGET" "$TARGET.prefix.bak"
install -m 0644 "$SELF_DIR/Toggles.qml" "$TARGET"
echo ":: patched $TARGET (backup: $TARGET.prefix.bak)"
echo ":: restart the shell to apply: Ctrl+Super+Alt+R, or log out/in."
