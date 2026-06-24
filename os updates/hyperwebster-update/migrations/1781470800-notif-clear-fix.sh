#!/usr/bin/env bash
# 1781470800-notif-clear-fix.sh
# The HyperWebster notifications popout (bell) "Clear" button did nothing — it called
# n.notification?.dismiss() instead of the wrapper's close(), so cards never left
# the list (and it was a no-op for disk-restored notifications). Patches the
# installed hyperwebster-shell file on already-installed boxes. Idempotent.
#
# >> Builder: the REAL fix is in the hyperwebster-shell FORK source
#    (modules/nsbar/panels/NsNotifications.qml). Bake the corrected file there and
#    set HYPERWEBSTER_SKIP_SHELL_PATCH for the build so this fallback patch is skipped.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sudo sh "$HYPERWEBSTER_SRC/notif-clear-fix/install-notif-clear-fix.sh"
