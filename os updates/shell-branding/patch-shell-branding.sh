#!/bin/sh
# patch-shell-branding.sh — rebrand nosignal-shell QML + packaging for HyperWebster.
#
# Run against:
#   - a nosignal-shell git checkout (ISO build: SHELL_ROOT=path/to/fork)
#   - an installed shell tree (NEXUS=/etc/xdg/quickshell/caelestia)
#
# Idempotent (safe to re-run).
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SHELL_ROOT=${SHELL_ROOT:-}
NEXUS=${NEXUS:-/etc/xdg/quickshell/caelestia}

patch_file() {
  f="$1"
  [ -f "$f" ] || return 0
  if grep -q 'hyperwebster/additions-status.json' "$f" 2>/dev/null \
     || grep -q 'text: "HyperWebster"' "$f" 2>/dev/null; then
    return 0
  fi
  cp -n "$f" "$f.pre-hyperwebster-branding" 2>/dev/null || true
  sed -i \
    -e 's|/nosignal/|/hyperwebster/|g' \
    -e 's|nosignal-additions|hyperwebster-additions|g' \
    -e 's|nosignal-update-check|hyperwebster-update-check|g' \
    -e 's|nosignal-update|hyperwebster-update|g' \
    -e 's|nosignal-sudo-toggle|hyperwebster-sudo-toggle|g' \
    -e 's|nosignal-sudo|hyperwebster-sudo|g' \
    -e 's|nosignal-cachy-repo|hyperwebster-cachy-repo|g' \
    -e 's|NoSignal layer|HyperWebster layer|g' \
    -e 's|nosignal-update|hyperwebster-update|g' \
    -e 's|nosignal-logo\.png|hyperwebster-logo.png|g' \
    -e 's|text: "NoSignal"|text: "HyperWebster"|g' \
    -e 's|text: "V1"|text: "hyperarch"|g' \
    -e 's|qsTr("NoSignal layer")|qsTr("HyperWebster layer")|g' \
    -e 's|qsTr("Idempotent migrations applied by nosignal-update")|qsTr("Idempotent migrations applied by hyperwebster-update")|g' \
    "$f"
}

if [ -n "$SHELL_ROOT" ] && [ -d "$SHELL_ROOT" ]; then
  NEXUS_MODULES="$SHELL_ROOT/modules/nexus"
  PKG="$SHELL_ROOT/packaging/PKGBUILD"
  ASSETS="$SHELL_ROOT/assets"
else
  NEXUS_MODULES="$NEXUS"
  PKG=""
  ASSETS="$NEXUS/../assets"
fi

for f in \
  "$NEXUS_MODULES/pages/AboutPage.qml" \
  "$NEXUS_MODULES/pages/AdditionsPage.qml" \
  "$NEXUS_MODULES/pages/UpdatesPage.qml" \
  "$NEXUS_MODULES/common/SudoToggleRow.qml" \
  "$NEXUS_MODULES/common/CachyRepoToggleRow.qml"
do
  patch_file "$f"
done

if [ -n "$PKG" ] && [ -f "$PKG" ]; then
  cp -n "$PKG" "$PKG.pre-hyperwebster-branding" 2>/dev/null || true
  sed -i \
    -e 's|DDISTRIBUTOR="NoSignal (package: $_pkgname)"|DDISTRIBUTOR="HyperWebster (package: $_pkgname)"|' \
    -e 's|pkgdesc="NoSignal desktop shell|pkgdesc="HyperWebster desktop shell|' \
    "$PKG"
fi

# About page logo: reuse Starman Plymouth art when vendored, else keep nosignal asset renamed.
if [ -d "$ASSETS" ]; then
  if [ -f "$SELF_DIR/hyperwebster-logo.png" ]; then
    install -m 0644 "$SELF_DIR/hyperwebster-logo.png" "$ASSETS/hyperwebster-logo.png"
  elif [ -f "$ASSETS/nosignal-logo.png" ] && [ ! -f "$ASSETS/hyperwebster-logo.png" ]; then
    cp -n "$ASSETS/nosignal-logo.png" "$ASSETS/hyperwebster-logo.png"
  fi
fi

echo "shell-branding: patched $(basename "${SHELL_ROOT:-$NEXUS}")"
