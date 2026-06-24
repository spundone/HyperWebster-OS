#!/bin/sh
# patch-updates-page.sh — register the HyperWebster Updates page in caelestia-shell.
# Runs as root (via sudo from the installer, or via the pacman hook after every
# caelestia-shell upgrade, which reverts PageCompRegistry.qml). Idempotent.
#
# What it does:
#   1. copies UpdatesPage.qml (next to this script) into the shell's pages/ dir
#      (an untracked file — pacman upgrades leave it alone)
#   2. swaps the FIRST "System" PlaceholderComp in PageCompRegistry.qml (the
#      Updates stub) for a StackPage hosting UpdatesPage
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NEXUS=/etc/xdg/quickshell/caelestia/modules/nexus
REG="$NEXUS/PageCompRegistry.qml"

[ -f "$REG" ] || { echo "caelestia-shell not found at $NEXUS — nothing to patch"; exit 0; }

# Always overlay HyperWebster QML — nosignal-shell upgrades ship upstream
# UpdatesPage.qml with nosignal-update even when the registry still references it.
install -m 0644 "$SELF_DIR/UpdatesPage.qml" "$NEXUS/pages/UpdatesPage.qml"
echo ":: installed $NEXUS/pages/UpdatesPage.qml"

if grep -q 'UpdatesPage' "$REG"; then
  echo ":: registry already patched"
  exit 0
fi

cp -n "$REG" "$REG.pre-hyperwebster"

perl -0pi -e 's/(\/\/ System\s*\n\s*)Component \{\s*\n\s*PlaceholderComp \{\}\s*\n\s*\},/$1Component {\n            \/\/ Updates (HyperWebster)\n            StackPage {\n                Component {\n                    UpdatesPage {}\n                }\n            }\n        },/' "$REG"

if grep -q 'UpdatesPage' "$REG"; then
  echo ":: patched $REG (Updates page registered)"
else
  echo "WARNING: patch did not apply — upstream PageCompRegistry.qml changed shape." >&2
  echo "         The Updates page is installed but not registered; update the regex" >&2
  echo "         in $(basename "$0") for the new caelestia-shell version." >&2
fi
