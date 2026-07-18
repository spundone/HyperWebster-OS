#!/usr/bin/env bash
# Migration: recover broken colours / light-mode Nexus / missing bar glyphs.
# White Wallpaper & style = scheme mode light (Material You surface). Flat bar
# glyphs ("A") = Theme.fontFamily on GoogleSansFlex. Re-assert dark + NF chrome.
set +e
: "${HYPERWEBSTER_SRC:?}"

APP="$HYPERWEBSTER_SRC/appearance-page"
BLUR="$HYPERWEBSTER_SRC/blur-toggle"

# 1. Force dark Material You (Nexus window fill follows scheme mode).
if command -v caelestia >/dev/null 2>&1; then
  caelestia scheme set --notify -m dark 2>/dev/null \
    || caelestia scheme set -m dark 2>/dev/null \
    || true
fi
SCHEME="$HOME/.local/state/caelestia/scheme.json"
if [ -f "$SCHEME" ] && command -v jq >/dev/null 2>&1; then
  tmp=$(mktemp)
  jq '.mode = "dark"' "$SCHEME" > "$tmp" && mv "$tmp" "$SCHEME"
  echo ":: scheme.json mode=dark"
elif [ -f "$SCHEME" ]; then
  sed -i 's/"mode"[[:space:]]*:[[:space:]]*"light"/"mode": "dark"/' "$SCHEME"
  echo ":: scheme.json mode forced dark (sed)"
fi

# 2. Wallpaper on + transparency glass defaults in shell.json.
SHELLJSON="$HOME/.config/caelestia/shell.json"
if [ -f "$SHELLJSON" ] && command -v jq >/dev/null 2>&1; then
  tmp=$(mktemp)
  jq '
    .background = (.background // {})
    | .background.wallpaperEnabled = true
    | .appearance = (.appearance // {})
    | .appearance.transparency = (.appearance.transparency // {})
    | .appearance.transparency.enabled = true
    | .appearance.transparency.base = (.appearance.transparency.base // 0.72)
    | .appearance.transparency.layers = (.appearance.transparency.layers // 0.35)
  ' "$SHELLJSON" > "$tmp" && mv "$tmp" "$SHELLJSON"
  echo ":: shell.json wallpaper + transparency enabled"
fi

# 3. Bar Nerd Font + blur patches.
if [ -f "$APP/patch-theme-font.sh" ]; then
  sudo sh "$APP/patch-theme-font.sh"
fi
if [ -f "$BLUR/patch-theme-nsbar-size.sh" ]; then
  sudo sh "$BLUR/patch-theme-nsbar-size.sh"
fi
if [ -f "$BLUR/patch-theme-nsbar-blur.sh" ]; then
  sudo sh "$BLUR/patch-theme-nsbar-blur.sh"
fi
if [ -f "$BLUR/patch-colours-nsbar-blur.sh" ]; then
  sudo sh "$BLUR/patch-colours-nsbar-blur.sh"
fi
if [ -f "$BLUR/hyperwebster-blur-toggle" ]; then
  install -m 0755 "$BLUR/hyperwebster-blur-toggle" "$HOME/.local/bin/hyperwebster-blur-toggle" 2>/dev/null || true
  sh "$BLUR/hyperwebster-blur-toggle" enable
fi

printf '%s\n' ":: colour/config recovery done - toggle Dark theme ON if Nexus still white"
echo ":: then: Ctrl+Super+Alt+R  (or: qs -c caelestia kill; caelestia shell -d)"
exit 0
