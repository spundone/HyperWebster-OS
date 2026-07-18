#!/bin/sh
# patch-theme-nsbar-blur.sh — Theme.barBg follows transparency for visible frost.
# When transparency is on, drop bar alpha so wallpaper blur reads clearly.
# Idempotent.
set -eu

TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/services/Theme.qml}
[ -f "$TARGET" ] || { echo "Theme.qml not found at $TARGET — skipping"; exit 0; }

# Always re-apply barBg (marker may exist from the 0.52 ghostly variant).
if ! grep -q 'readonly property color barBg:' "$TARGET" 2>/dev/null; then
  echo "WARNING: Theme.qml has no barBg — nothing to patch" >&2
  exit 0
fi

cp -n "$TARGET" "$TARGET.pre-hyperwebster-barbg" 2>/dev/null || true

python3 - "$TARGET" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
# Replace any HyperWebster barBg block or the stock 0.60 line.
pat = re.compile(
    r"(?:    // HyperWebster: barBg follows transparency.*?\n)?"
    r"    readonly property color barBg: Qt\.rgba\(15 / 255, 18 / 255, 24 / 255, [^\n]+\)",
    re.DOTALL,
)
new = (
    "    // HyperWebster: barBg alpha stays ~0.60 (readable chrome); frost comes from\n"
    "    // Hyprland ignore_alpha 0.40 on nsbar (see blur-toggle).\n"
    "    readonly property color barBg: Qt.rgba(15 / 255, 18 / 255, 24 / 255, Colours.transparency.enabled ? 0.60 : 0.92)"
)
if not pat.search(text):
    print("WARNING: Theme.qml barBg shape changed — patch skipped", file=sys.stderr)
    sys.exit(0)
path.write_text(pat.sub(new, text, count=1))
print(f":: patched {path} (barBg 0.60 glass / 0.92 solid)")
PY
