#!/usr/bin/env bash
# Migration: System tools FileDialog must not be a PageBase child — it crashed
# the caelestia shell on start (Nexus compiles the page via PageCompRegistry).
#
# Never abort the migration chain: older install helpers and set -e greps have
# produced spurious non-zero exits even after a successful QML apply.
set +e
: "${HYPERWEBSTER_SRC:?}"
SRC="$HYPERWEBSTER_SRC/system-tools"
PAGE=/etc/xdg/quickshell/caelestia/modules/nexus/pages/SystemToolsPage.qml

[ -f "$SRC/SystemToolsPage.qml" ] || exit 0

if [ -f "$SRC/patch-system-tools-page.sh" ]; then
  sudo sh "$SRC/patch-system-tools-page.sh"
elif [ -d "$(dirname -- "$PAGE")" ]; then
  sudo install -Dm0644 "$SRC/SystemToolsPage.qml" "$PAGE"
fi

printf '%s\n' ":: System tools FileDialog moved inside layout - Ctrl+Super+Alt+R"
exit 0
