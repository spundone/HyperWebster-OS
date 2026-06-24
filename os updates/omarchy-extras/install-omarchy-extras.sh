#!/bin/sh
# install-omarchy-extras.sh — Omarchy utility workflows adapted for HyperWebster.
# Idempotent.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
MARK='Omarchy-inspired utility keybinds'

mkdir -p "$BIN"
install -m0755 "$SRC/hyperwebster-omarchy-extras-toggle" "$BIN/hyperwebster-omarchy-extras-toggle"
for script in hyperwebster-share hyperwebster-transcode hyperwebster-ocr-capture \
              hyperwebster-nightlight-toggle omarchy-transcode; do
  install -m 0755 "$SRC/$script" "$BIN/$script"
done
echo ":: installed omarchy-extras scripts -> $BIN"

# XCompose emoji sequences (Omarchy default/xcompose).
if [ ! -f "$HOME/.XCompose" ] || grep -q 'HyperWebster omarchy-extras' "$HOME/.XCompose" 2>/dev/null; then
  {
    echo '# HyperWebster omarchy-extras — sourced from Omarchy default/xcompose'
    cat "$SRC/xcompose"
  } > "$HOME/.XCompose"
  echo ":: installed ~/.XCompose"
else
  echo ":: ~/.XCompose already customised — left as-is"
fi

# Export for XWayland / Compose-key apps (idempotent profile drop).
PROFILE_DROP="$HOME/.config/environment.d/99-hyperwebster-compose.conf"
mkdir -p "$(dirname "$PROFILE_DROP")"
if [ ! -f "$PROFILE_DROP" ]; then
  cat > "$PROFILE_DROP" <<'ENV'
# HyperWebster — Omarchy-style XCompose sequences (XWayland apps).
XCOMPOSEFILE=$HOME/.XCompose
ENV
  echo ":: wrote $PROFILE_DROP"
fi

if [ ! -f "$HYPRUSER" ]; then
  echo "NOTE: $HYPRUSER not found — append omarchy-extras-keys.conf manually."
elif grep -qF '# >>> hyperwebster-omarchy-extras >>>' "$HYPRUSER" 2>/dev/null \
     || grep -q 'hyperwebster-share' "$HYPRUSER" 2>/dev/null; then
  echo ":: keybinds already present in $HYPRUSER"
else
  {
    printf '\n# >>> hyperwebster-omarchy-extras >>>\n'
    cat "$SRC/omarchy-extras-keys.conf"
    printf '\n# <<< hyperwebster-omarchy-extras <<<\n'
  } >> "$HYPRUSER"
  echo ":: appended omarchy-extras keybinds -> $HYPRUSER"
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland"
fi

echo "Done. Super+Ctrl+S share · Super+Ctrl+. transcode · Super+Ctrl+Print OCR · Super+Ctrl+N night light."
