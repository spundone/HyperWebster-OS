#!/bin/sh
# install-cachyos-repo-switch.sh — idempotent. REQUIRES ROOT.
#
# Installs the CachyOS repo + kernel switch feature:
#   1. /usr/local/bin/hyperwebster-cachy-repo          (detect/status/bootstrap/enable/disable CLI)
#   2. /etc/sudoers.d/02-hyperwebster-cachy            (sudoless grant, validated first)
#   3. patches caelestia ServicesPage to show the toggle (via patch-servicespage.sh)
#
# Fresh HyperWebster installs already ship linux-cachyos + bootstrapped CachyOS
# repos. The toggle reverts to stock (disable) or re-enables + runs userspace -Suu.
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ "$(id -u)" -eq 0 ] || { echo "must run as root (writes /usr/local/bin + sudoers.d)" >&2; exit 1; }

# 1. CLI helper
install -m 0755 "$SELF_DIR/hyperwebster-cachy-repo" /usr/local/bin/hyperwebster-cachy-repo
echo ":: installed /usr/local/bin/hyperwebster-cachy-repo"

# 1b. standalone DB repair tool. A normal -Syu while
#     CachyOS is enabled pulls the CachyOS pacman, which stamps `%INSTALLED_DB%`
#     into the local DB; stock pacman then warns about it on every op. The
#     corrected helper above pins pacman durably (IgnorePkg) while enabled and
#     strips the field on disable, but ship the standalone repair tool too — and
#     one-shot-clean any contamination already present (no-op on a fresh box).
install -m 0755 "$SELF_DIR/hyperwebster-cachy-db-clean" /usr/local/bin/hyperwebster-cachy-db-clean
echo ":: installed /usr/local/bin/hyperwebster-cachy-db-clean"
if grep -lrx '%INSTALLED_DB%' /var/lib/pacman/local/*/desc >/dev/null 2>&1; then
    echo ":: local DB has %INSTALLED_DB% contamination — cleaning now…"
    /usr/local/bin/hyperwebster-cachy-db-clean || true
fi

# 2. sudoers drop-in — validate with `visudo -c` BEFORE it reaches /etc/sudoers.d
#    (a malformed sudoers can lock out sudo entirely). install to a temp path,
#    check, then move into place at mode 0440.
TMP_SUDO=$(mktemp /tmp/02-hyperwebster-cachy.XXXXXX)
install -m 0440 "$SELF_DIR/02-hyperwebster-cachy" "$TMP_SUDO"
if visudo -cf "$TMP_SUDO" >/dev/null 2>&1; then
    install -m 0440 -o root -g root "$TMP_SUDO" /etc/sudoers.d/02-hyperwebster-cachy
    echo ":: installed /etc/sudoers.d/02-hyperwebster-cachy (validated)"
else
    echo "ERROR: 02-hyperwebster-cachy failed visudo -c — NOT installing the sudoers drop-in." >&2
    echo "       (the toggle will prompt for a password instead of running passwordless)" >&2
fi
rm -f "$TMP_SUDO"

# 3. panel toggle (caelestia ServicesPage). Non-fatal if the shell isn't present.
# Skipped when HYPERWEBSTER_SKIP_SHELL_PATCH is set — the HyperWebster builder bakes
# CachyRepoToggleRow + the page insert into the pinned hyperwebster-shell fork, so
# the patch is redundant there. Migrations of old stock-caelestia boxes
# leave it unset and patch.
if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
    echo ":: skipping ServicesPage patch (HYPERWEBSTER_SKIP_SHELL_PATCH — fork bakes the toggle)"
elif [ -x "$SELF_DIR/patch-servicespage.sh" ]; then
    sh "$SELF_DIR/patch-servicespage.sh" || echo "WARNING: ServicesPage patch failed (CLI still usable from a terminal)" >&2
fi

echo ":: done. Toggle in Settings -> Services to revert to stock or re-enable CachyOS."
