#!/bin/sh
# patch-theme-font.sh - keep Theme.fontFamily on JetBrainsMono Nerd Font.
#
# Earlier builds bound fontFamily to GlobalConfig.appearance.font.body.family
# (defaults to GoogleSansFlex). NsBar icons need a Nerd Font, so the top bar
# lost glyphs and looked "broken". Chrome stays on JetBrainsMono NF; Settings
# -> Appearance still writes GlobalConfig for Tokens / GTK / kitty.
set -eu

TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/services/Theme.qml}
[ -f "$TARGET" ] || { echo "Theme.qml not found at $TARGET - skipping"; exit 0; }

python3 - "$TARGET" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
orig = text
want = '    readonly property string fontFamily: "JetBrainsMono Nerd Font"'

# 1) Undo HyperWebster GlobalConfig body-font binding (any formatting).
pat_block = re.compile(
    r"(?:    // HyperWebster: fontFamily follows GlobalConfig[^\n]*\n)?"
    r"    readonly property string fontFamily: \{\n"
    r"        const f = GlobalConfig\.appearance\.font\.body\.family;\n"
    r"        return \(f && f\.length\) \? f : \"[^\"]+\";\n"
    r"    \}",
)
text2, n = pat_block.subn(want, text, count=1)
text = text2
if n:
    print(":: reverted GlobalConfig fontFamily binding")

# 2) Force any other fontFamily string assignment to JetBrainsMono NF.
pat_str = re.compile(
    r'    readonly property string fontFamily: "[^"]*"'
)
if pat_str.search(text):
    text2, n2 = pat_str.subn(want, text, count=1)
    text = text2
    if n2 and text != orig:
        print(":: forced Theme.fontFamily to JetBrainsMono Nerd Font")
elif "fontFamily:" not in text:
    print("WARNING: Theme.qml has no fontFamily - nothing to patch", file=sys.stderr)
    sys.exit(0)

# Drop unused Caelestia.Config import only if nothing else needs it.
if "GlobalConfig" not in text and "import Caelestia.Config\n" in text:
    text = text.replace("import Caelestia.Config\n", "", 1)

if text == orig and 'fontFamily: "JetBrainsMono Nerd Font"' in text:
    print(":: Theme.qml fontFamily already JetBrainsMono Nerd Font")
    sys.exit(0)

if text == orig:
    print("WARNING: Theme.qml fontFamily unchanged", file=sys.stderr)
    sys.exit(0)

path.write_text(text)
print(f":: restored {path} fontFamily to JetBrainsMono Nerd Font (nsbar icons)")
PY
