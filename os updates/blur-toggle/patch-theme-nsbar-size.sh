#!/bin/sh
# patch-theme-nsbar-size.sh - living-room readable nsbar chrome on 4K TVs.
# Stock NoSignal uses 38px / 12pt - fine on a desk monitor, hairline from the couch
# when Hyprland monitor scale is 1 on 3840x2160. Idempotent.
set -eu

TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/services/Theme.qml}
[ -f "$TARGET" ] || { echo "Theme.qml not found at $TARGET - skipping"; exit 0; }

if grep -q 'HyperWebster: living-room nsbar chrome' "$TARGET" 2>/dev/null; then
  echo ":: Theme.qml nsbar chrome already living-room sized"
  exit 0
fi

cp -n "$TARGET" "$TARGET.pre-hyperwebster-barsize" 2>/dev/null || true

python3 - "$TARGET" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
orig = text

# Ensure chrome font stays Nerd Font (icons).
text2, n = re.subn(
    r'    // HyperWebster: fontFamily follows GlobalConfig \(Settings → Appearance\)\.\n'
    r'    readonly property string fontFamily: \{\n'
    r'        const f = GlobalConfig\.appearance\.font\.body\.family;\n'
    r'        return \(f && f\.length\) \? f : "JetBrainsMono Nerd Font";\n'
    r'    \}',
    '    readonly property string fontFamily: "JetBrainsMono Nerd Font"',
    text,
    count=1,
)
text = text2
if n:
    print(":: reverted GlobalConfig fontFamily binding")

def replace_int(src: str, name: str, value: int, block_hint: str = "") -> str:
    # Match "readonly property int NAME: N" possibly with trailing comment.
    pat = re.compile(rf'(readonly property int {re.escape(name)}:\s*)\d+(\s*//[^\n]*)?')
    if not pat.search(src):
        print(f"WARNING: Theme.{name} not found - skipped", file=sys.stderr)
        return src
    return pat.sub(rf'\g<1>{value}\2', src, count=1)

text = replace_int(text, "bar", 16)          # Theme.font.bar
text = replace_int(text, "panelTitle", 16)
text = replace_int(text, "body", 14)
text = replace_int(text, "bodySmall", 13)
text = replace_int(text, "label", 12)
text = replace_int(text, "meta", 12)
text = replace_int(text, "barHeight", 52)    # Theme.size.barHeight
text = replace_int(text, "barIcon", 22)

# Marker comment near barHeight
if "HyperWebster: living-room nsbar chrome" not in text:
    text = text.replace(
        "readonly property int barHeight:",
        "// HyperWebster: living-room nsbar chrome (4K TV readable at scale 1-1.5)\n        readonly property int barHeight:",
        1,
    )

if text == orig and "HyperWebster: living-room nsbar chrome" not in text:
    print("WARNING: Theme.qml size patch made no changes", file=sys.stderr)
    sys.exit(0)

path.write_text(text)
print(f":: patched {path} (barHeight 52, bar font 16, living-room chrome)")
PY
