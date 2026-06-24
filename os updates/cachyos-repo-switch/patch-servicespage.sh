#!/bin/sh
# patch-servicespage.sh — add the "CachyOS repositories" toggle to the caelestia
# Settings -> Services page. Runs as root (installer, or the pacman hook after a
# caelestia-shell upgrade reverts ServicesPage.qml). Idempotent.
#
#   1. install CachyRepoToggleRow.qml into nexus/common/ (untracked -> survives upgrades)
#   2. insert `CachyRepoToggleRow {}` after the "Smart colour scheme" ToggleRow in
#      ServicesPage.qml (same anchor the sudo toggle uses; both land together)
#
# HyperWebster bakes both the component and the page insert into the pinned
# hyperwebster-shell fork, so this patch is only for migration of older
# stock-caelestia installs (run by the hyperwebster-update migration).
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NEXUS=${NEXUS:-/etc/xdg/quickshell/caelestia/modules/nexus}
COMMON="$NEXUS/common"
PAGE="$NEXUS/pages/ServicesPage.qml"

[ -f "$PAGE" ] || { echo "caelestia ServicesPage not found at $PAGE — nothing to patch"; exit 0; }

# 1. component type (auto-discovered via `import qs.modules.nexus.common`)
install -m 0644 "$SELF_DIR/CachyRepoToggleRow.qml" "$COMMON/CachyRepoToggleRow.qml"

# 2. insert the row (idempotent)
if grep -q 'CachyRepoToggleRow' "$PAGE"; then
    echo ":: ServicesPage already has the CachyOS toggle"
    exit 0
fi
grep -q 'smartScheme = checked' "$PAGE" || {
    echo "WARNING: anchor (Smart colour scheme ToggleRow) not found in ServicesPage — skipping insert" >&2
    exit 0
}

cp -n "$PAGE" "$PAGE.pre-hyperwebster-cachy" 2>/dev/null || true
perl -0pi -e 's/(onToggled: GlobalConfig\.services\.smartScheme = checked\n\s*\})/$1\n\n        CachyRepoToggleRow {\n            Layout.fillWidth: true\n        }/' "$PAGE"

if grep -q 'CachyRepoToggleRow' "$PAGE"; then
    echo ":: patched ServicesPage (CachyOS toggle added)"
else
    echo "WARNING: ServicesPage insert did not take; restoring" >&2
    [ -f "$PAGE.pre-hyperwebster-cachy" ] && cp "$PAGE.pre-hyperwebster-cachy" "$PAGE"
    exit 1
fi
