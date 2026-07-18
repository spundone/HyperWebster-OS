#!/bin/sh
# install-system-tools.sh — Settings → System tools (account photo + apps).
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SHARE="$HOME/.local/share/hyperwebster/system-tools"

if [ -f "$SRC/../hyperwebster-update/lib/hw-install-file.sh" ]; then
  # shellcheck source=/dev/null
  . "$SRC/../hyperwebster-update/lib/hw-install-file.sh"
else
  hw_install_file() {
    _s=$1; _d=$2; _m=${3:-0644}
    [ -f "$_s" ] || return 0
    _sr=$(readlink -f "$_s" 2>/dev/null || echo "$_s")
    _dr=
    [ -e "$_d" ] && _dr=$(readlink -f "$_d" 2>/dev/null || echo "$_d")
    if [ -n "$_dr" ] && [ "$_sr" = "$_dr" ]; then
      chmod "$_m" "$_d" 2>/dev/null || true
      return 0
    fi
    mkdir -p "$(dirname -- "$_d")"
    install -m "$_m" "$_s" "$_d"
  }
fi

mkdir -p "$SHARE"
hw_install_file "$SRC/SystemToolsPage.qml" "$SHARE/SystemToolsPage.qml" 0644
hw_install_file "$SRC/patch-system-tools-page.sh" "$SHARE/patch-system-tools-page.sh" 0755
hw_install_file "$SRC/README.md" "$SHARE/README.md" 0644

if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
  echo ":: skipping System tools registry patch (HYPERWEBSTER_SKIP_SHELL_PATCH)"
else
  sudo sh "$SHARE/patch-system-tools-page.sh"
fi

HOOK=/etc/pacman.d/hooks/hyperwebster-system-tools.hook
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
Description = Re-applying HyperWebster System tools Settings page...
When = PostTransaction
Exec = /bin/sh $SHARE/patch-system-tools-page.sh
EOF
echo ":: pacman hook -> $HOOK"
echo "Done. Open Settings → System tools. Ctrl+Super+Alt+R if Nexus was already open."
