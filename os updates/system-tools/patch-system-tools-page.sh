#!/bin/sh
# patch-system-tools-page.sh — register Settings → System tools in the shell.
# Idempotent. Runs as root (installer or pacman hook).
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NEXUS=${NEXUS:-/etc/xdg/quickshell/caelestia/modules/nexus}
COMPREG="$NEXUS/PageCompRegistry.qml"
PAGEREG="$NEXUS/PageRegistry.qml"
PAGES="$NEXUS/pages"

[ -d "$PAGES" ] || { echo "caelestia-shell not found at $NEXUS — nothing to patch"; exit 0; }

install -m 0644 "$SELF_DIR/SystemToolsPage.qml" "$PAGES/SystemToolsPage.qml"
echo ":: installed $PAGES/SystemToolsPage.qml"

# --- PageCompRegistry: insert before Updates --------------------------------
if [ -f "$COMPREG" ]; then
  if grep -q 'SystemToolsPage' "$COMPREG"; then
    echo ":: component registry already has SystemToolsPage"
  else
    cp -n "$COMPREG" "$COMPREG.pre-hyperwebster-system-tools" 2>/dev/null || true
    # Insert a System tools StackPage immediately before the Updates StackPage.
    perl -0pi -e 's/(\/\/ System\s*\n\s*Component \{\s*\n\s*\/\/ Updates[^\n]*\n)/\/\/ System\n        Component {\n            \/\/ System tools (HyperWebster)\n            StackPage {\n                Component {\n                    SystemToolsPage {}\n                }\n            }\n        },\n        Component {\n            \/\/ Updates\n/s' "$COMPREG"
    if grep -q 'SystemToolsPage' "$COMPREG"; then
      echo ":: patched $COMPREG (System tools registered)"
    else
      # Fallback: before any UpdatesPage reference
      perl -0pi -e 's/(Component \{\s*\n\s*\/\/ Updates[^\n]*\n\s*StackPage \{\s*\n\s*Component \{\s*\n\s*UpdatesPage)/Component {\n            \/\/ System tools (HyperWebster)\n            StackPage {\n                Component {\n                    SystemToolsPage {}\n                }\n            }\n        },\n        $1/s' "$COMPREG"
      if grep -q 'SystemToolsPage' "$COMPREG"; then
        echo ":: patched $COMPREG (System tools via UpdatesPage fallback)"
      else
        echo "WARNING: PageCompRegistry patch did not apply — update regex in $(basename "$0")" >&2
      fi
    fi
  fi
fi

# --- PageRegistry: insert menu entry before Updates -------------------------
if [ -f "$PAGEREG" ]; then
  if grep -q '"System tools"' "$PAGEREG" || grep -q 'qsTr("System tools")' "$PAGEREG"; then
    echo ":: menu entry already present"
  else
    cp -n "$PAGEREG" "$PAGEREG.pre-hyperwebster-system-tools" 2>/dev/null || true
    perl -0pi -e 's/(\/\/ System\s*\n\s*\{\s*\n\s*label: qsTr\("Updates"\),)/\/\/ System\n        {\n            label: qsTr("System tools"),\n            icon: "settings",\n            description: qsTr("Account, display, input, kernel"),\n            category: "system"\n        },\n        {\n            label: qsTr("Updates"),/s' "$PAGEREG"
    if grep -q 'qsTr("System tools")' "$PAGEREG"; then
      echo ":: patched $PAGEREG (System tools menu entry)"
    else
      echo "WARNING: PageRegistry patch did not apply — update regex in $(basename "$0")" >&2
    fi
  fi
fi
