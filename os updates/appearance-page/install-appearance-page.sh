#!/bin/sh
# install-appearance-page.sh — Settings → Wallpaper & style → Appearance.
#
# Corner radius, gaps, density, motion, transparency shortcuts, and presets.
# Needs hyperwebster-appearance (from appearance-toggles) on PATH.
#
# Safe to re-run (idempotent). Needs sudo for the QML overlay + pacman hook.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SHARE="$HOME/.local/share/hyperwebster/appearance-page"

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

# Ensure the CLI backend is present (rounding toggle + continuous knobs).
if [ -x "$SRC/../appearance-toggles/install-appearance-toggles.sh" ]; then
  sh "$SRC/../appearance-toggles/install-appearance-toggles.sh"
elif [ -x "$HOME/.local/share/hyperwebster/appearance-toggles/install-appearance-toggles.sh" ]; then
  sh "$HOME/.local/share/hyperwebster/appearance-toggles/install-appearance-toggles.sh"
fi

mkdir -p "$SHARE"
hw_install_file "$SRC/AppearanceSelect.qml" "$SHARE/AppearanceSelect.qml" 0644
hw_install_file "$SRC/WallpaperAndStyle.qml" "$SHARE/WallpaperAndStyle.qml" 0644
hw_install_file "$SRC/patch-appearance-page.sh" "$SHARE/patch-appearance-page.sh" 0755
hw_install_file "$SRC/patch-theme-font.sh" "$SHARE/patch-theme-font.sh" 0755
hw_install_file "$SRC/README.md" "$SHARE/README.md" 0644

if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
  echo ":: skipping Appearance QML patch (HYPERWEBSTER_SKIP_SHELL_PATCH)"
else
  sudo sh "$SHARE/patch-appearance-page.sh"
  sudo sh "$SHARE/patch-theme-font.sh" || true
fi

HOOK=/etc/pacman.d/hooks/hyperwebster-appearance-page.hook
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
Description = Re-applying HyperWebster Appearance settings page...
When = PostTransaction
Exec = /bin/sh $SHARE/patch-appearance-page.sh
EOF
echo ":: pacman hook installed -> $HOOK"

echo "Done. Restart the shell (Ctrl+Super+Alt+R) to see Settings → Wallpaper & style → Appearance."
