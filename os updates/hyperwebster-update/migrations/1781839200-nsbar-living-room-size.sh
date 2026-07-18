#!/usr/bin/env bash
# Migration: fix hairline nsbar on 4K TVs (scale 1 + 38px bar) and ensure
# layerrule blur on + JetBrainsMono NF chrome.
set +e
: "${HYPERWEBSTER_SRC:?}"

BLUR="$HYPERWEBSTER_SRC/blur-toggle"
TV="$HYPERWEBSTER_SRC/tv-gaming-display"
APP="$HYPERWEBSTER_SRC/appearance-page"

# 1. Living-room Theme chrome (taller bar, larger type).
if [ -f "$BLUR/patch-theme-nsbar-size.sh" ]; then
  sudo sh "$BLUR/patch-theme-nsbar-size.sh"
fi
if [ -f "$APP/patch-theme-font.sh" ]; then
  sudo sh "$APP/patch-theme-font.sh"
fi
if [ -f "$BLUR/patch-theme-nsbar-blur.sh" ]; then
  sudo sh "$BLUR/patch-theme-nsbar-blur.sh"
fi
if [ -f "$BLUR/patch-colours-nsbar-blur.sh" ]; then
  sudo sh "$BLUR/patch-colours-nsbar-blur.sh"
fi

# 2. Refresh blur toggle binary + rewrite valid `blur on` rules.
if [ -f "$BLUR/hyperwebster-blur-toggle" ]; then
  install -m 0755 "$BLUR/hyperwebster-blur-toggle" "$HOME/.local/bin/hyperwebster-blur-toggle" 2>/dev/null || true
  sh "$BLUR/hyperwebster-blur-toggle" enable
fi

# 3. Bump 4K TV profile + live monitors.conf scale 1 → 1.5 when obviously 4K@1.
if [ -f "$TV/profiles/tv-gaming-4k" ]; then
  mkdir -p "$HOME/.config/hyprmoncfg/profiles"
  cp -f "$TV/profiles/tv-gaming-4k" "$HOME/.config/hyprmoncfg/profiles/tv-gaming-4k"
fi
MONCONF="$HOME/.config/hypr/monitors.conf"
if [ -f "$MONCONF" ]; then
  # monitor=NAME,3840x2160@...,POS,1,...  → scale 1.5
  if grep -qE '3840x2160[^,]*,[^,]*, *1([,]|$)' "$MONCONF"; then
    sed -i -E 's/(3840x2160@[^,]*,[^,]*,) *1([,]|$)/\11.5\2/g' "$MONCONF"
    echo ":: bumped 4K monitor scale 1 -> 1.5 in $MONCONF"
  fi
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

printf '%s\n' ":: living-room nsbar (taller chrome + 4K scale 1.5) - Ctrl+Super+Alt+R"
echo ":: if still tiny: hyprctl monitors  # last number is scale; set 1.5 or 2 via Super+Ctrl+H"
exit 0
