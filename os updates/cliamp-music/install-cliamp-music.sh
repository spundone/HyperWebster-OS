#!/bin/sh
# install-cliamp-music.sh — CLIAmp as the default music player.
#
#   - cliamp                 -> installed from the [omarchy] repo (sudo)
#   - cliamp.desktop         -> ~/.local/share/applications (launch in kitty)
#   - XDG MIME defaults      -> audio/* opens CLIAmp (omarchy mimetypes style)
#   - Super+M                -> launch-or-focus CLIAmp, floating
#                               (Super+Shift+M keeps the shell music panel)
#   - keymap doc             -> Super+M row updated
#
# Safe to re-run (idempotent). Needs sudo only for the package install.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APPS="$HOME/.local/share/applications"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
KEYMAP="$HOME/.local/share/hyperwebster/HyperWebster-keybindings.md"

# 1. Package (prebuilt in the [omarchy] repo — no AUR build).
if ! command -v cliamp >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm cliamp
fi

# 2. Desktop entry (ours wins over any packaged one — same desktop id).
mkdir -p "$APPS"
install -m 0644 "$SRC/cliamp.desktop" "$APPS/cliamp.desktop"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" || true

# 3. Default player for audio files (mirrors omarchy's mimetypes.sh style).
if command -v xdg-mime >/dev/null 2>&1; then
  for m in audio/mpeg audio/mp4 audio/x-m4a audio/aac audio/flac audio/x-flac \
           audio/ogg audio/x-vorbis+ogg audio/x-opus+ogg audio/wav audio/x-wav \
           audio/webm; do
    xdg-mime default cliamp.desktop "$m"
  done
  echo ":: audio/* now opens CLIAmp"
fi

# 4. Super+M bind + float rule (marked block, end of hypr-user.conf).
if [ -f "$HYPRUSER" ]; then
  if grep -q '>>> cliamp music player >>>' "$HYPRUSER"; then
    echo ":: hypr-user.conf already has the cliamp block"
  else
    printf '\n' >> "$HYPRUSER"
    cat "$SRC/hyprland-cliamp.conf" >> "$HYPRUSER"
    echo ":: Super+M -> CLIAmp (block appended to hypr-user.conf)"
  fi
  command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true
else
  echo "NOTE: $HYPRUSER not found — append hyprland-cliamp.conf to your Hyprland user config."
fi

# 5. Keymap doc (single source of truth for the Super+K cheatsheet).
if [ -f "$KEYMAP" ] && ! grep -q 'CLIAmp' "$KEYMAP"; then
  sed -i 's#^| `Super+M` | Music (alias) |#| `Super+M` | Music player — CLIAmp, floating (default for audio files) |#' "$KEYMAP"
  grep -q 'CLIAmp' "$KEYMAP" \
    && echo ":: keymap doc updated (Super+M row)" \
    || echo "NOTE: keymap doc row not found — document Super+M manually in $KEYMAP"
fi

echo "Done. Super+M opens CLIAmp; audio files open in it by default."
