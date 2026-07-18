#!/bin/sh
# patch-theme-nsbar-blur.sh — Theme.barBg follows transparency for visible frost.
# When transparency is on, drop bar alpha so wallpaper blur reads clearly.
# Idempotent.
set -eu

TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/services/Theme.qml}
[ -f "$TARGET" ] || { echo "Theme.qml not found at $TARGET — skipping"; exit 0; }

if grep -q 'HyperWebster: barBg follows transparency' "$TARGET" 2>/dev/null; then
  echo ":: Theme.qml barBg already transparency-aware"
  exit 0
fi

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
old = re.compile(
    r"    readonly property color barBg: Qt\.rgba\(15 / 255, 18 / 255, 24 / 255, 0\.60\)"
)
new = """    // HyperWebster: barBg follows transparency so Hyprland blur reads through
    // the glass (alpha stays above ignore_alpha 0.45 from blur-toggle).
    readonly property color barBg: Qt.rgba(15 / 255, 18 / 255, 24 / 255, Colours.transparency.enabled ? 0.52 : 0.88)"""
if not old.search(text):
    print("WARNING: Theme.qml barBg shape changed — patch skipped", file=sys.stderr)
    sys.exit(0)
path.write_text(old.sub(new, text, count=1))
print(f":: patched {path} (barBg transparency-aware)")
PY
