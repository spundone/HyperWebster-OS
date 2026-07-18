#!/bin/sh
# install-hyperwebster-update.sh — populate the on-system HyperWebster "repo" and expose the
# `hyperwebster-update` command. Simulates what the ISO bakes in: it copies the HyperWebster
# component sources + this update system into ~/.local/share/hyperwebster and symlinks
# the command onto PATH. Idempotent.
#
# (On the real ISO the build process places the same tree at the same path;
#  this script is the equivalent step for a from-Downloads rebuild.)
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)   # the Downloads root (parent of hyperwebster-update/)
DEST="$HOME/.local/share/hyperwebster"
BIN="$HOME/.local/bin"

mkdir -p "$DEST" "$BIN"

SRC_R=$(readlink -f "$SRC" 2>/dev/null || echo "$SRC")
DEST_R=$(readlink -f "$DEST" 2>/dev/null || echo "$DEST")

# Live layer checkout: SRC is already DEST — nothing to copy into itself.
if [ "$SRC_R" = "$DEST_R" ]; then
  echo "install-hyperwebster-update: layer already at $DEST — refreshing symlinks only"
  chmod +x "$DEST/hyperwebster-update/bin/hyperwebster-update" \
    "$DEST/hyperwebster-update/bin/pull-layer.sh" \
    "$DEST/hyperwebster-update/migrations/"*.sh 2>/dev/null || true
  ln -sf "$DEST/hyperwebster-update/bin/hyperwebster-update" "$BIN/hyperwebster-update"
  ln -sf "$DEST/hyperwebster-update/bin/pull-layer.sh" "$BIN/hyperwebster-layer-pull"
  echo "Installed HyperWebster update system -> $DEST"
  echo "  hyperwebster-update                              # snapshot + package upgrade + layer"
  exit 0
fi

# Component sources the migrations re-apply. Extend this list as changes are added.
hw_cp() {
  # hw_cp SRC DEST — skip when same inode/path
  [ -e "$1" ] || return 0
  _s=$(readlink -f "$1" 2>/dev/null || echo "$1")
  _d=
  [ -e "$2" ] && _d=$(readlink -f "$2" 2>/dev/null || echo "$2")
  [ -n "$_d" ] && [ "$_s" = "$_d" ] && return 0
  cp -a "$1" "$2"
}

COMPONENTS="install-keybinds-help.sh hyperwebster-keybinds hyperwebster-keybinds-gen hyprland-keybinds-help.conf HyperWebster-keybindings.md"
for c in $COMPONENTS; do
  [ -e "$SRC/$c" ] && hw_cp "$SRC/$c" "$DEST/"
done
[ -d "$SRC/fish-to-bash" ] && hw_cp "$SRC/fish-to-bash" "$DEST/"
[ -d "$SRC/software-install" ] && hw_cp "$SRC/software-install" "$DEST/"
[ -d "$SRC/omarchy-keys" ] && hw_cp "$SRC/omarchy-keys" "$DEST/"
[ -d "$SRC/omarchy-extras" ] && hw_cp "$SRC/omarchy-extras" "$DEST/"
[ -d "$SRC/omarchy-launcher" ] && hw_cp "$SRC/omarchy-launcher" "$DEST/"
[ -d "$SRC/omadots-extras" ] && hw_cp "$SRC/omadots-extras" "$DEST/"
[ -d "$SRC/monitor-control" ] && hw_cp "$SRC/monitor-control" "$DEST/"
[ -d "$SRC/updates-panel" ] && hw_cp "$SRC/updates-panel" "$DEST/"
[ -d "$SRC/system-polish" ] && hw_cp "$SRC/system-polish" "$DEST/"
[ -d "$SRC/super-clipboard" ] && hw_cp "$SRC/super-clipboard" "$DEST/"
[ -d "$SRC/screenshots" ] && hw_cp "$SRC/screenshots" "$DEST/"
[ -d "$SRC/monitor-control-fix" ] && hw_cp "$SRC/monitor-control-fix" "$DEST/"
[ -d "$SRC/launcher-fix" ] && hw_cp "$SRC/launcher-fix" "$DEST/"
[ -d "$SRC/dashboard-key" ] && hw_cp "$SRC/dashboard-key" "$DEST/"
[ -d "$SRC/gaming-enablement" ] && hw_cp "$SRC/gaming-enablement" "$DEST/"
[ -d "$SRC/display-manager-sddm" ] && hw_cp "$SRC/display-manager-sddm" "$DEST/"
[ -d "$SRC/deckshift-login" ] && hw_cp "$SRC/deckshift-login" "$DEST/"
[ -d "$SRC/sddm-theme" ] && hw_cp "$SRC/sddm-theme" "$DEST/"
[ -d "$SRC/wifi-password-retry" ] && hw_cp "$SRC/wifi-password-retry" "$DEST/"
[ -d "$SRC/monitor-hotload" ] && hw_cp "$SRC/monitor-hotload" "$DEST/"
[ -d "$SRC/update-prompts-fix" ] && hw_cp "$SRC/update-prompts-fix" "$DEST/"
[ -d "$SRC/cheatsheet-tidy" ] && hw_cp "$SRC/cheatsheet-tidy" "$DEST/"
[ -d "$SRC/cliamp-music" ] && hw_cp "$SRC/cliamp-music" "$DEST/"
[ -d "$SRC/additions-installer" ] && hw_cp "$SRC/additions-installer" "$DEST/"
[ -d "$SRC/menu-cleanup" ] && hw_cp "$SRC/menu-cleanup" "$DEST/"
# Display, boot, and theming fixes
[ -d "$SRC/xdg-terminal-exec-handler" ] && hw_cp "$SRC/xdg-terminal-exec-handler" "$DEST/"
[ -d "$SRC/caelestia-lock-faillock" ] && hw_cp "$SRC/caelestia-lock-faillock" "$DEST/"
[ -d "$SRC/limine-uki-dead-entry" ] && hw_cp "$SRC/limine-uki-dead-entry" "$DEST/"
[ -d "$SRC/kernel-reboot-notify" ] && hw_cp "$SRC/kernel-reboot-notify" "$DEST/"
[ -d "$SRC/app-theme-awareness" ] && hw_cp "$SRC/app-theme-awareness" "$DEST/"
[ -d "$SRC/cheatsheet-keymap-path" ] && hw_cp "$SRC/cheatsheet-keymap-path" "$DEST/"
[ -d "$SRC/additions-extra" ] && hw_cp "$SRC/additions-extra" "$DEST/"
[ -d "$SRC/base-default-packages" ] && hw_cp "$SRC/base-default-packages" "$DEST/"
# Passwordless sudo toggle
[ -d "$SRC/sudo-timed-nopasswd" ] && hw_cp "$SRC/sudo-timed-nopasswd" "$DEST/"
[ -d "$SRC/starman-gaming-boot" ] && hw_cp "$SRC/starman-gaming-boot" "$DEST/"
[ -d "$SRC/luks-tpm-unlock" ] && hw_cp "$SRC/luks-tpm-unlock" "$DEST/"
[ -d "$SRC/chimera-deckify-gaming" ] && hw_cp "$SRC/chimera-deckify-gaming" "$DEST/"
[ -d "$SRC/cachyos-kernel-manager" ] && hw_cp "$SRC/cachyos-kernel-manager" "$DEST/"
[ -d "$SRC/tv-gaming-display" ] && hw_cp "$SRC/tv-gaming-display" "$DEST/"
[ -d "$SRC/launcher-raycast" ] && hw_cp "$SRC/launcher-raycast" "$DEST/"
[ -d "$SRC/blur-toggle" ] && hw_cp "$SRC/blur-toggle" "$DEST/"
[ -d "$SRC/appearance-toggles" ] && hw_cp "$SRC/appearance-toggles" "$DEST/"
[ -d "$SRC/appearance-page" ] && hw_cp "$SRC/appearance-page" "$DEST/"
[ -d "$SRC/colours-page" ] && hw_cp "$SRC/colours-page" "$DEST/"
[ -d "$SRC/glyphs-fix" ] && hw_cp "$SRC/glyphs-fix" "$DEST/"
[ -d "$SRC/cachyos-repo-switch" ] && hw_cp "$SRC/cachyos-repo-switch" "$DEST/"
[ -d "$SRC/theme-polish" ] && hw_cp "$SRC/theme-polish" "$DEST/"
[ -d "$SRC/drive-automount" ] && hw_cp "$SRC/drive-automount" "$DEST/"
[ -d "$SRC/gamemode-toggle-deckshift" ] && hw_cp "$SRC/gamemode-toggle-deckshift" "$DEST/"
[ -d "$SRC/iphone-tether" ] && hw_cp "$SRC/iphone-tether" "$DEST/"
[ -d "$SRC/notif-clear-fix" ] && hw_cp "$SRC/notif-clear-fix" "$DEST/"
[ -d "$SRC/btrfs-snapshot-manager" ] && hw_cp "$SRC/btrfs-snapshot-manager" "$DEST/"
[ -d "$SRC/hypersmooth-display" ] && hw_cp "$SRC/hypersmooth-display" "$DEST/"
[ -d "$SRC/zephyr-polish" ] && hw_cp "$SRC/zephyr-polish" "$DEST/"
[ -d "$SRC/distro-tools" ] && hw_cp "$SRC/distro-tools" "$DEST/"
[ -d "$SRC/input-remap" ] && hw_cp "$SRC/input-remap" "$DEST/"
[ -d "$SRC/omarchy-themes" ] && hw_cp "$SRC/omarchy-themes" "$DEST/"
[ -d "$SRC/lockscreen-polish" ] && hw_cp "$SRC/lockscreen-polish" "$DEST/"
[ -d "$SRC/system-tools" ] && hw_cp "$SRC/system-tools" "$DEST/"
[ -d "$SRC/shell-branding" ] && hw_cp "$SRC/shell-branding" "$DEST/"
[ -d "$SRC/update-alias" ] && hw_cp "$SRC/update-alias" "$DEST/"

# The update system itself.
hw_cp "$SRC/hyperwebster-update" "$DEST/"
chmod +x "$DEST/hyperwebster-update/bin/hyperwebster-update" \
  "$DEST/hyperwebster-update/bin/pull-layer.sh" \
  "$DEST/hyperwebster-update/migrations/"*.sh

# Expose the commands (symlinks resolve back to DEST so they find migrations).
ln -sf "$DEST/hyperwebster-update/bin/hyperwebster-update" "$BIN/hyperwebster-update"
ln -sf "$DEST/hyperwebster-update/bin/pull-layer.sh" "$BIN/hyperwebster-layer-pull"

echo "Installed HyperWebster update system -> $DEST"
echo "  hyperwebster-update                              # snapshot + package upgrade + layer"
echo "  hyperwebster-update --no-packages --no-snapshot  # apply the HyperWebster layer only"
