#!/bin/sh
# install-sudo-timed-nopasswd.sh — idempotent. REQUIRES ROOT.
#
# Installs the time-boxed passwordless-sudo ("sudoless") feature:
#   1. /usr/local/bin/hyperwebster-sudo-toggle           (enable/disable/status CLI)
#   2. hyperwebster-sudoless-boot-clean.service (enabled) (reboot safety net)
#   3. patches caelestia ServicesPage to show the toggle (via patch-servicespage.sh)
#
# Does NOT enable sudoless — that's a deliberate user action via the toggle.
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ "$(id -u)" -eq 0 ] || { echo "must run as root (writes /usr/local/bin + systemd)" >&2; exit 1; }

# 1. CLI
install -m 0755 "$SELF_DIR/hyperwebster-sudo-toggle" /usr/local/bin/hyperwebster-sudo-toggle
echo ":: installed /usr/local/bin/hyperwebster-sudo-toggle"

# 2. boot-time safety net
install -m 0644 "$SELF_DIR/hyperwebster-sudoless-boot-clean.service" \
    /etc/systemd/system/hyperwebster-sudoless-boot-clean.service
# daemon-reload is a no-op (and errors) in an install chroot with no running
# manager — never let it abort the install. `enable` works offline (it only
# creates the wants/ symlink), so the service is armed on the booted system.
systemctl daemon-reload >/dev/null 2>&1 || true
systemctl enable hyperwebster-sudoless-boot-clean.service >/dev/null 2>&1 || true
echo ":: installed + enabled hyperwebster-sudoless-boot-clean.service"

# 3. panel toggle (caelestia ServicesPage). Non-fatal if the shell isn't present.
# Skipped when HYPERWEBSTER_SKIP_SHELL_PATCH is set — the HyperWebster builder bakes
# SudoToggleRow into the pinned hyperwebster-shell fork, so the patch is redundant
# there. Migrations of old stock-caelestia boxes leave it unset and patch.
if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
    echo ":: skipping ServicesPage patch (HYPERWEBSTER_SKIP_SHELL_PATCH — fork bakes the toggle)"
elif [ -x "$SELF_DIR/patch-servicespage.sh" ]; then
    sh "$SELF_DIR/patch-servicespage.sh" || echo "WARNING: ServicesPage patch failed (CLI still usable from a terminal)" >&2
fi

echo ":: done. Toggle it in Settings -> Services, or: sudo hyperwebster-sudo-toggle enable"
