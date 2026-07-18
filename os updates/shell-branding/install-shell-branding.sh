#!/bin/sh
# install-shell-branding.sh — apply HyperWebster branding to the installed shell.
# Idempotent. Safe in chroot (patch only; no user session needed).
# Always runs the QML overlay as root when targeting /etc (package-owned files).
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

run_patch() {
  # ISO / fork builds set SHELL_ROOT to a writable checkout — no sudo needed.
  if [ -n "${SHELL_ROOT:-}" ]; then
    SHELL_ROOT="$SHELL_ROOT" sh "$SELF_DIR/patch-shell-branding.sh"
  elif [ "$(id -u)" -eq 0 ]; then
    sh "$SELF_DIR/patch-shell-branding.sh"
  else
    sudo sh "$SELF_DIR/patch-shell-branding.sh"
  fi
}

run_patch

# Re-apply branding after every shell package upgrade (nosignal-shell overwrites
# package-owned QML under /etc/xdg/quickshell/caelestia).
HOOK=/etc/pacman.d/hooks/hyperwebster-shell-branding.hook
install_hook() {
  mkdir -p /etc/pacman.d/hooks
  tee "$HOOK" > /dev/null <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = hyperwebster-shell
Target = caelestia-shell
Target = nosignal-shell

[Action]
Description = Re-applying HyperWebster shell branding...
When = PostTransaction
Exec = /bin/sh $SELF_DIR/patch-shell-branding.sh
EOF
  echo "shell-branding: pacman hook installed -> $HOOK"
}

if [ "$(id -u)" -eq 0 ]; then
  install_hook
else
  sudo mkdir -p /etc/pacman.d/hooks
  sudo tee "$HOOK" > /dev/null <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = hyperwebster-shell
Target = caelestia-shell
Target = nosignal-shell

[Action]
Description = Re-applying HyperWebster shell branding...
When = PostTransaction
Exec = /bin/sh $SELF_DIR/patch-shell-branding.sh
EOF
  echo "shell-branding: pacman hook installed -> $HOOK"
fi

echo "shell-branding: restart the shell (Ctrl+Super+Alt+R) to refresh Settings → About."
