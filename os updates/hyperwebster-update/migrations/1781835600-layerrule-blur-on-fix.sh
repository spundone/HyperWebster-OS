#!/usr/bin/env bash
# Migration: fix invalid `layerrule = blur,` (missing on/off) that Hyprland
# rejects with "invalid field blur: missing a value" and leaves the bar flat.
set +e
: "${HYPERWEBSTER_SRC:?}"

BLUR="$HYPERWEBSTER_SRC/blur-toggle"
if [ -f "$BLUR/hyperwebster-blur-toggle" ]; then
  # Refresh installed copy then rewrite hypr-user.conf + live keywords.
  install -m 0755 "$BLUR/hyperwebster-blur-toggle" "$HOME/.local/bin/hyperwebster-blur-toggle" 2>/dev/null \
    || sudo install -m 0755 "$BLUR/hyperwebster-blur-toggle" /usr/local/bin/hyperwebster-blur-toggle
fi
if [ -f "$BLUR/patch-colours-nsbar-blur.sh" ]; then
  sudo sh "$BLUR/patch-colours-nsbar-blur.sh"
fi
if command -v hyperwebster-blur-toggle >/dev/null 2>&1; then
  hyperwebster-blur-toggle enable
elif [ -f "$BLUR/hyperwebster-blur-toggle" ]; then
  sh "$BLUR/hyperwebster-blur-toggle" enable
fi

printf '%s\n' ":: layerrule blur on restored - hyprctl reload / Ctrl+Super+Alt+R"
exit 0
