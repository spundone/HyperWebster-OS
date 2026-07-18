#!/usr/bin/env bash
# Migration: System tools FileDialog must not be a PageBase child — it crashed
# the caelestia shell on start (Nexus compiles the page via PageCompRegistry).
#
# Do NOT call install-system-tools.sh here: older/broken copies can fail with
# "hw_install_file: command not found" and abort --force-migrations. The layer
# already has the fixed QML; just push it into the live shell tree.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?}"
SRC="$HYPERWEBSTER_SRC/system-tools"
PAGE=/etc/xdg/quickshell/caelestia/modules/nexus/pages/SystemToolsPage.qml

[ -f "$SRC/SystemToolsPage.qml" ] || exit 0

if [ -f "$SRC/patch-system-tools-page.sh" ]; then
  # Patch may return non-zero under set -e greps even after a successful apply.
  sudo sh "$SRC/patch-system-tools-page.sh" || true
elif [ -d "$(dirname -- "$PAGE")" ]; then
  sudo install -Dm0644 "$SRC/SystemToolsPage.qml" "$PAGE" || true
fi

echo ":: System tools FileDialog moved inside layout - Ctrl+Super+Alt+R"
exit 0
