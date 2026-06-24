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

# Component sources the migrations re-apply. Extend this list as changes are added.
COMPONENTS="install-keybinds-help.sh hyperwebster-keybinds hyperwebster-keybinds-gen hyprland-keybinds-help.conf HyperWebster-keybindings.md"
for c in $COMPONENTS; do
  [ -e "$SRC/$c" ] && cp -a "$SRC/$c" "$DEST/"
done
[ -d "$SRC/fish-to-bash" ] && cp -a "$SRC/fish-to-bash" "$DEST/"
[ -d "$SRC/software-install" ] && cp -a "$SRC/software-install" "$DEST/"
[ -d "$SRC/omarchy-keys" ] && cp -a "$SRC/omarchy-keys" "$DEST/"
[ -d "$SRC/omadots-extras" ] && cp -a "$SRC/omadots-extras" "$DEST/"
[ -d "$SRC/monitor-control" ] && cp -a "$SRC/monitor-control" "$DEST/"
[ -d "$SRC/updates-panel" ] && cp -a "$SRC/updates-panel" "$DEST/"
[ -d "$SRC/system-polish" ] && cp -a "$SRC/system-polish" "$DEST/"
[ -d "$SRC/super-clipboard" ] && cp -a "$SRC/super-clipboard" "$DEST/"
[ -d "$SRC/screenshots" ] && cp -a "$SRC/screenshots" "$DEST/"
[ -d "$SRC/monitor-control-fix" ] && cp -a "$SRC/monitor-control-fix" "$DEST/"
[ -d "$SRC/launcher-fix" ] && cp -a "$SRC/launcher-fix" "$DEST/"
[ -d "$SRC/dashboard-key" ] && cp -a "$SRC/dashboard-key" "$DEST/"
[ -d "$SRC/gaming-enablement" ] && cp -a "$SRC/gaming-enablement" "$DEST/"
[ -d "$SRC/display-manager-sddm" ] && cp -a "$SRC/display-manager-sddm" "$DEST/"
[ -d "$SRC/deckshift-login" ] && cp -a "$SRC/deckshift-login" "$DEST/"
[ -d "$SRC/sddm-theme" ] && cp -a "$SRC/sddm-theme" "$DEST/"
[ -d "$SRC/wifi-password-retry" ] && cp -a "$SRC/wifi-password-retry" "$DEST/"
[ -d "$SRC/monitor-hotload" ] && cp -a "$SRC/monitor-hotload" "$DEST/"
[ -d "$SRC/update-prompts-fix" ] && cp -a "$SRC/update-prompts-fix" "$DEST/"
[ -d "$SRC/cheatsheet-tidy" ] && cp -a "$SRC/cheatsheet-tidy" "$DEST/"
[ -d "$SRC/cliamp-music" ] && cp -a "$SRC/cliamp-music" "$DEST/"
[ -d "$SRC/additions-installer" ] && cp -a "$SRC/additions-installer" "$DEST/"
[ -d "$SRC/menu-cleanup" ] && cp -a "$SRC/menu-cleanup" "$DEST/"
# Display, boot, and theming fixes
[ -d "$SRC/xdg-terminal-exec-handler" ] && cp -a "$SRC/xdg-terminal-exec-handler" "$DEST/"
[ -d "$SRC/caelestia-lock-faillock" ] && cp -a "$SRC/caelestia-lock-faillock" "$DEST/"
[ -d "$SRC/limine-uki-dead-entry" ] && cp -a "$SRC/limine-uki-dead-entry" "$DEST/"
[ -d "$SRC/kernel-reboot-notify" ] && cp -a "$SRC/kernel-reboot-notify" "$DEST/"
[ -d "$SRC/app-theme-awareness" ] && cp -a "$SRC/app-theme-awareness" "$DEST/"
[ -d "$SRC/cheatsheet-keymap-path" ] && cp -a "$SRC/cheatsheet-keymap-path" "$DEST/"
[ -d "$SRC/additions-extra" ] && cp -a "$SRC/additions-extra" "$DEST/"
[ -d "$SRC/base-default-packages" ] && cp -a "$SRC/base-default-packages" "$DEST/"
# Passwordless sudo toggle
[ -d "$SRC/sudo-timed-nopasswd" ] && cp -a "$SRC/sudo-timed-nopasswd" "$DEST/"
[ -d "$SRC/starman-gaming-boot" ] && cp -a "$SRC/starman-gaming-boot" "$DEST/"
[ -d "$SRC/luks-tpm-unlock" ] && cp -a "$SRC/luks-tpm-unlock" "$DEST/"
[ -d "$SRC/chimera-deckify-gaming" ] && cp -a "$SRC/chimera-deckify-gaming" "$DEST/"
[ -d "$SRC/cachyos-kernel-manager" ] && cp -a "$SRC/cachyos-kernel-manager" "$DEST/"
[ -d "$SRC/tcl-t89c-display" ] && cp -a "$SRC/tcl-t89c-display" "$DEST/"
[ -d "$SRC/launcher-raycast" ] && cp -a "$SRC/launcher-raycast" "$DEST/"
[ -d "$SRC/blur-toggle" ] && cp -a "$SRC/blur-toggle" "$DEST/"
[ -d "$SRC/cachyos-repo-switch" ] && cp -a "$SRC/cachyos-repo-switch" "$DEST/"
[ -d "$SRC/theme-polish" ] && cp -a "$SRC/theme-polish" "$DEST/"
[ -d "$SRC/drive-automount" ] && cp -a "$SRC/drive-automount" "$DEST/"

# The update system itself.
cp -a "$SRC/hyperwebster-update" "$DEST/"
chmod +x "$DEST/hyperwebster-update/bin/hyperwebster-update" "$DEST/hyperwebster-update/migrations/"*.sh

# Expose the command (symlink resolves back to DEST so it finds its migrations).
ln -sf "$DEST/hyperwebster-update/bin/hyperwebster-update" "$BIN/hyperwebster-update"

echo "Installed HyperWebster update system -> $DEST"
echo "  hyperwebster-update                              # snapshot + package upgrade + layer"
echo "  hyperwebster-update --no-packages --no-snapshot  # apply the HyperWebster layer only"
