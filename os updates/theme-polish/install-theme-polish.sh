#!/bin/sh
# install-theme-polish.sh — light/dark consistency fixes. User + root parts.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
USER_HOME="${HYPERWEBSTER_USER_HOME:-${HOME:-/root}}"
UNITS="$USER_HOME/.config/systemd/user"

# User units: re-sync SDDM when scheme.json changes (sudoers allows NOPASSWD).
install -d -m 755 "$UNITS"
install -Dm0644 "$HERE/hyperwebster-sddm-sync.path"  "$UNITS/hyperwebster-sddm-sync.path"
install -Dm0644 "$HERE/hyperwebster-sddm-sync.service" "$UNITS/hyperwebster-sddm-sync.service"

if [ "$(id -u)" -eq 0 ] && [ -n "${HYPERWEBSTER_INSTALL_USER:-}" ]; then
  chown -R "$HYPERWEBSTER_INSTALL_USER:$HYPERWEBSTER_INSTALL_USER" "$USER_HOME/.config/systemd/user"
fi

if [ "$(id -u)" -ne 0 ] && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user enable --now hyperwebster-sddm-sync.path || true
fi

# Root: passwordless sddm-theme-sync for wheel.
if [ "$(id -u)" -eq 0 ]; then
  install -Dm0440 "$HERE/10-hyperwebster-sddm-sync" /etc/sudoers.d/10-hyperwebster-sddm-sync
  visudo -cf /etc/sudoers.d/10-hyperwebster-sddm-sync
  install -Dm0644 "$HERE/README.md" /usr/local/share/hyperwebster/theme-polish/README.md
fi

echo "theme-polish: SDDM auto-sync on scheme change enabled"
