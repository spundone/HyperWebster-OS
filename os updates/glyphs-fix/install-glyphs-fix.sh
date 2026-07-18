#!/bin/sh
# install-glyphs-fix.sh — empty MenuItem icons no longer show "?" in Nexus.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SHARE="$HOME/.local/share/hyperwebster/glyphs-fix"

if [ -f "$SRC/../hyperwebster-update/lib/hw-install-file.sh" ]; then
  # shellcheck source=/dev/null
  . "$SRC/../hyperwebster-update/lib/hw-install-file.sh"
else
  hw_install_file() {
    _s=$1; _d=$2; _m=${3:-0644}
    [ -f "$_s" ] || return 0
    mkdir -p "$(dirname -- "$_d")"
    install -m "$_m" "$_s" "$_d"
  }
fi

mkdir -p "$SHARE"
hw_install_file "$SRC/patch-glyphs.sh" "$SHARE/patch-glyphs.sh" 0755
hw_install_file "$SRC/README.md" "$SHARE/README.md" 0644

if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
  echo ":: skipping Glyphs patch (HYPERWEBSTER_SKIP_SHELL_PATCH)"
else
  sudo sh "$SHARE/patch-glyphs.sh"
fi

HOOK=/etc/pacman.d/hooks/hyperwebster-glyphs-fix.hook
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
Description = Re-applying HyperWebster Glyphs empty-icon fix...
When = PostTransaction
Exec = /bin/sh $SHARE/patch-glyphs.sh
EOF
echo ":: pacman hook installed -> $HOOK"
echo "Done. Restart the shell (Ctrl+Super+Alt+R) to refresh icons."
