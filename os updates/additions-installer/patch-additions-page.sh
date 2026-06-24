#!/bin/sh
# patch-additions-page.sh — register the HyperWebster Additions page in
# caelestia-shell. Runs as root (via sudo from the installer, or via the
# pacman hook after every caelestia-shell upgrade, which reverts both
# registry files). Idempotent.
#
# What it does:
#   1. copies AdditionsPage.qml (next to this script) into the shell's
#      pages/ dir (untracked file — pacman upgrades leave it alone)
#   2. swaps the REMAINING "System" PlaceholderComp in PageCompRegistry.qml
#      (the Plugins stub) for a StackPage hosting AdditionsPage.
#      REQUIRES the Updates-page patch to be applied first — before it,
#      the first placeholder is the Updates stub, and this patch would grab
#      the wrong slot (guarded below).
#   3. relabels the menu entry in PageRegistry.qml: "Plugins" → "Additions".
#
# NEXUS is overridable for testing the regexes against copies.
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NEXUS=${NEXUS:-/etc/xdg/quickshell/caelestia/modules/nexus}
COMPREG="$NEXUS/PageCompRegistry.qml"
PAGEREG="$NEXUS/PageRegistry.qml"

[ -f "$COMPREG" ] || { echo "caelestia-shell not found at $NEXUS — nothing to patch"; exit 0; }

install -m 0644 "$SELF_DIR/AdditionsPage.qml" "$NEXUS/pages/AdditionsPage.qml"

# --- component registry: Plugins placeholder -> AdditionsPage ---------------
if grep -q 'AdditionsPage' "$COMPREG"; then
  echo ":: component registry already patched"
elif ! grep -q 'UpdatesPage' "$COMPREG"; then
  echo "WARNING: Updates patch not applied — the first placeholder" >&2
  echo "         is the Updates stub, not Plugins. Run the updates-panel patch" >&2
  echo "         first, then re-run $(basename "$0")." >&2
else
  cp -n "$COMPREG" "$COMPREG.pre-hyperwebster-additions"
  perl -0pi -e 's/Component \{\s*\n\s*PlaceholderComp \{\}\s*\n\s*\},/Component {\n            \/\/ Additions (HyperWebster)\n            StackPage {\n                Component {\n                    AdditionsPage {}\n                }\n            }\n        },/' "$COMPREG"
  if grep -q 'AdditionsPage' "$COMPREG"; then
    echo ":: patched $COMPREG (Additions page registered)"
  else
    echo "WARNING: patch did not apply — upstream PageCompRegistry.qml changed" >&2
    echo "         shape. The Additions page is installed but not registered;" >&2
    echo "         update the regex in $(basename "$0")." >&2
  fi
fi

# --- menu registry: relabel Plugins -> Additions -----------------------------
if [ -f "$PAGEREG" ]; then
  if grep -q '"Additions"' "$PAGEREG"; then
    echo ":: menu entry already relabeled"
  else
    cp -n "$PAGEREG" "$PAGEREG.pre-hyperwebster-additions"
    perl -pi -e 's/label: qsTr\("Plugins"\),/label: qsTr("Additions"),/; s/description: qsTr\("Manage plugins"\),/description: qsTr("Layer toggles and optional software"),/' "$PAGEREG"
    if grep -q '"Additions"' "$PAGEREG"; then
      echo ":: relabeled menu entry Plugins -> Additions"
    else
      echo "WARNING: relabel did not apply (upstream PageRegistry.qml changed)." >&2
      echo "         Cosmetic only — the page still works under the old label." >&2
    fi
  fi
fi
