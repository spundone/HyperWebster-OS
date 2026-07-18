#!/bin/sh
# patch-theme-font.sh — Theme.fontFamily follows GlobalConfig UI font.
# Idempotent. Without this, nsbar/lock stay on hardcoded JetBrainsMono.
set -eu

TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/services/Theme.qml}
[ -f "$TARGET" ] || { echo "Theme.qml not found at $TARGET — skipping"; exit 0; }

if grep -q 'HyperWebster: fontFamily follows GlobalConfig' "$TARGET" 2>/dev/null; then
  echo ":: Theme.qml fontFamily already config-aware"
  exit 0
fi

if ! grep -q 'readonly property string fontFamily:' "$TARGET" 2>/dev/null; then
  echo "WARNING: Theme.qml has no fontFamily — nothing to patch" >&2
  exit 0
fi

cp -n "$TARGET" "$TARGET.pre-hyperwebster-font" 2>/dev/null || true

# Ensure Caelestia.Config is imported for GlobalConfig.
if ! grep -q 'import Caelestia.Config' "$TARGET" 2>/dev/null; then
  python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
needle = "import qs.services\n"
if needle in text:
    text = text.replace(needle, needle + "import Caelestia.Config\n", 1)
elif "import QtQuick\n" in text:
    text = text.replace("import QtQuick\n", "import QtQuick\nimport Caelestia.Config\n", 1)
else:
    text = "import Caelestia.Config\n" + text
path.write_text(text)
print(f":: added Caelestia.Config import to {path}")
PY
fi

python3 - "$TARGET" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = re.compile(
    r'    readonly property string fontFamily: "[^"]*"'
)
new = '''    // HyperWebster: fontFamily follows GlobalConfig (Settings → Appearance).
    readonly property string fontFamily: {
        const f = GlobalConfig.appearance.font.body.family;
        return (f && f.length) ? f : "JetBrainsMono Nerd Font";
    }'''
if not old.search(text):
    print("WARNING: Theme.qml fontFamily shape changed — patch skipped", file=sys.stderr)
    sys.exit(0)
path.write_text(old.sub(new, text, count=1))
print(f":: patched {path} (fontFamily follows GlobalConfig)")
PY
