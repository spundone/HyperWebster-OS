#!/bin/sh
# patch-servicespage.sh — add the "Passwordless sudo (15 min)" toggle to the
# caelestia Settings -> Services page. Runs as root (installer, or the pacman
# hook after every caelestia-shell upgrade, which reverts ServicesPage.qml).
# Idempotent.
#
#   1. install SudoToggleRow.qml into nexus/common/ (untracked -> survives upgrades)
#   2. insert `SudoToggleRow {}` after the "Smart colour scheme" ToggleRow in
#      ServicesPage.qml (re-applied by the hook each upgrade)
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NEXUS=${NEXUS:-/etc/xdg/quickshell/caelestia/modules/nexus}
COMMON="$NEXUS/common"
PAGE="$NEXUS/pages/ServicesPage.qml"

[ -f "$PAGE" ] || { echo "caelestia ServicesPage not found at $PAGE — nothing to patch"; exit 0; }

# 1. component type (auto-discovered via `import qs.modules.nexus.common`)
install -m 0644 "$SELF_DIR/SudoToggleRow.qml" "$COMMON/SudoToggleRow.qml"

# 2. insert the row (idempotent)
if grep -q 'SudoToggleRow' "$PAGE"; then
    echo ":: ServicesPage already has the sudo toggle"
    exit 0
fi
grep -q 'smartScheme = checked' "$PAGE" || {
    echo "WARNING: anchor (Smart colour scheme ToggleRow) not found in ServicesPage — skipping insert" >&2
    exit 0
}

cp -n "$PAGE" "$PAGE.pre-hyperwebster-sudoless" 2>/dev/null || true
perl -0pi -e 's/(onToggled: GlobalConfig\.services\.smartScheme = checked\n\s*\})/$1\n\n        SudoToggleRow {\n            Layout.fillWidth: true\n        }/' "$PAGE"

if grep -q 'SudoToggleRow' "$PAGE"; then
    echo ":: patched ServicesPage (sudo toggle added)"
else
    echo "WARNING: ServicesPage insert did not take; restoring" >&2
    [ -f "$PAGE.pre-hyperwebster-sudoless" ] && cp "$PAGE.pre-hyperwebster-sudoless" "$PAGE"
    exit 1
fi
