#!/bin/sh
# patch-theme-font.sh — keep Theme.fontFamily on JetBrainsMono Nerd Font.
#
# Earlier builds bound fontFamily to GlobalConfig.appearance.font.body.family
# (defaults to GoogleSansFlex). NsBar icons need a Nerd Font, so the top bar
# lost glyphs and looked "broken". Chrome stays on JetBrainsMono NF; Settings
# → Appearance still writes GlobalConfig for Tokens / GTK / kitty.
set -eu

TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/services/Theme.qml}
[ -f "$TARGET" ] || { echo "Theme.qml not found at $TARGET — skipping"; exit 0; }

# Undo the GlobalConfig body-font binding if a previous migration applied it.
if grep -q 'HyperWebster: fontFamily follows GlobalConfig' "$TARGET" 2>/dev/null; then
  python3 - "$TARGET" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
pat = re.compile(
    r"    // HyperWebster: fontFamily follows GlobalConfig \(Settings → Appearance\)\.\n"
    r"    readonly property string fontFamily: \{\n"
    r"        const f = GlobalConfig\.appearance\.font\.body\.family;\n"
    r"        return \(f && f\.length\) \? f : \"JetBrainsMono Nerd Font\";\n"
    r"    \}"
)
rep = '    readonly property string fontFamily: "JetBrainsMono Nerd Font"'
if not pat.search(text):
    # Broader fallback: any multi-line fontFamily block mentioning GlobalConfig.
    pat = re.compile(
        r"    readonly property string fontFamily: \{\n"
        r"        const f = GlobalConfig\.appearance\.font\.body\.family;\n"
        r"        return \(f && f\.length\) \? f : \"JetBrainsMono Nerd Font\";\n"
        r"    \}"
    )
if not pat.search(text):
    print("WARNING: could not revert GlobalConfig fontFamily binding", file=sys.stderr)
    sys.exit(0)
text = pat.sub(rep, text, count=1)
# Drop unused Caelestia.Config import only if nothing else needs it.
if "GlobalConfig" not in text and "import Caelestia.Config\n" in text:
    text = text.replace("import Caelestia.Config\n", "", 1)
path.write_text(text)
print(f":: restored {path} fontFamily to JetBrainsMono Nerd Font (nsbar icons)")
PY
  exit 0
fi

if grep -q 'readonly property string fontFamily: "JetBrainsMono Nerd Font"' "$TARGET" 2>/dev/null; then
  echo ":: Theme.qml fontFamily already JetBrainsMono Nerd Font"
  exit 0
fi

echo ":: Theme.qml fontFamily left unchanged (not the GlobalConfig binding)"
