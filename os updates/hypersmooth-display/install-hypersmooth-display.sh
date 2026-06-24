#!/bin/sh
# install-hypersmooth-display.sh - high-refresh Hyprland + shell token tuning.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HYPRUSER="${HOME}/.config/caelestia/hypr-user.conf"
SHELLTOKENS="${HOME}/.config/caelestia/shell-tokens.json"
LAYER="${HOME}/.local/share/hyperwebster/hypersmooth-display"
MARK_BEGIN='# >>> hypersmooth-display >>>'
MARK_END='# <<< hypersmooth-display <<<'

mkdir -p "$LAYER"
install -m0644 "$HERE/hypr-hypersmooth.conf" "$LAYER/hypr-hypersmooth.conf"
install -m0644 "$HERE/shell-tokens.fragment.json" "$LAYER/shell-tokens.fragment.json"
install -m0644 "$HERE/README.md" "$LAYER/README.md"

if [ -f "$HYPRUSER" ] && ! grep -qF "$MARK_BEGIN" "$HYPRUSER"; then
  cat >> "$HYPRUSER" <<EOF

$MARK_BEGIN
source = $LAYER/hypr-hypersmooth.conf
$MARK_END
EOF
  echo ":: appended hypersmooth hypr fragment -> $HYPRUSER"
fi

if command -v jq >/dev/null 2>&1 && [ -f "$SHELLTOKENS" ] && [ -f "$LAYER/shell-tokens.fragment.json" ]; then
  tmp=$(mktemp)
  jq -s '.[0] * .[1]' "$SHELLTOKENS" "$LAYER/shell-tokens.fragment.json" > "$tmp" && mv "$tmp" "$SHELLTOKENS"
  echo ":: merged hypersmooth animDurations into $SHELLTOKENS"
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

echo "hypersmooth-display: tuned for 120/144 Hz (vfr + snappier shell animations)"
