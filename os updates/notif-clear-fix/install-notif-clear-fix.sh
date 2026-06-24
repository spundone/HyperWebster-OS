#!/bin/sh
# install-notif-clear-fix.sh — idempotent. REQUIRES ROOT (writes the package-owned
# shell file under /etc/xdg).
#
# Fixes the HyperWebster notifications popout "Clear" button, which did nothing
# (called n.notification?.dismiss() instead of n.close(); see README).
#
# NsNotifications.qml is shipped by the `hyperwebster-shell` package (baked into the
# fork). The REAL fix is in the fork source — this fallback patch is for already-
# installed boxes and is reverted by the next hyperwebster-shell upgrade (which will
# carry the fixed file). The builder bakes the fix into the fork and sets
# HYPERWEBSTER_SKIP_SHELL_PATCH so this step is skipped there.
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET=/etc/xdg/quickshell/caelestia/modules/nsbar/panels/NsNotifications.qml

if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
    echo ":: skipping fallback shell patch (HYPERWEBSTER_SKIP_SHELL_PATCH — fork bakes the fix)"
    exit 0
fi

[ "$(id -u)" -eq 0 ] || { echo "must run as root (writes $TARGET)" >&2; exit 1; }

if [ ! -f "$TARGET" ]; then
    echo "WARNING: $TARGET not present — hyperwebster-shell not installed here; nothing to patch." >&2
    exit 0
fi

if grep -q 'Notifs.list.slice()' "$TARGET"; then
    echo ":: NsNotifications Clear already fixed — nothing to do."
    exit 0
fi

cp -a "$TARGET" "$TARGET.prefix.bak"
install -m 0644 "$SELF_DIR/NsNotifications.qml" "$TARGET"
echo ":: patched $TARGET (backup: $TARGET.prefix.bak)"
echo ":: reload the shell to apply: 'caelestia shell -d' restart, or log out/in."
