#!/bin/sh
# patch-glyphs.sh — fix empty MenuItem icons rendering as "?" and map "check".
# Idempotent. Runs as root against the installed caelestia/nosignal shell.
set -eu

NEXUS=${NEXUS:-/etc/xdg/quickshell/caelestia}
GLYPHS=${GLYPHS:-$NEXUS/services/Glyphs.qml}

[ -f "$GLYPHS" ] || { echo "Glyphs.qml not found at $GLYPHS — skipping"; exit 0; }

python3 - "$GLYPHS" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
orig = text
marker = "HYPERWEBSTER_GLYPHS_EMPTY_ICON"

# 1) Empty icon name → "" (not question-mark fallback)
old_get = """    function get(name: string): string {
        return root.map[name] ?? root.cp(0xf128);
    }"""
new_get = f"""    function get(name: string): string {{
        // {marker}
        if (!name)
            return "";
        return root.map[name] ?? root.cp(0xf128);
    }}"""

if marker in text:
    print(f":: {path.name} already has empty-icon fix")
elif old_get in text:
    text = text.replace(old_get, new_get, 1)
    print(f":: patched get() empty-icon handling in {path}")
else:
    # Tolerate minor whitespace drift
    import re
    pat = re.compile(
        r"function get\(name: string\): string \{\s*"
        r"return root\.map\[name\] \?\? root\.cp\(0xf128\);\s*\}",
        re.M,
    )
    if pat.search(text) and marker not in text:
        text, n = pat.subn(new_get.strip(), text, count=1)
        if n:
            print(f":: patched get() (regex) in {path}")
        else:
            print(f"WARNING: get() shape changed in {path}", file=sys.stderr)
    else:
        print(f"WARNING: get() shape changed in {path}", file=sys.stderr)

# 2) Ensure "check" is mapped for SelectRow / MenuItem selection marks
if '"check":' in text or "'check':" in text:
    print(f":: check glyph already present in {path.name}")
else:
    import re
    m = re.search(r'(\n    \}\n\n    function get\()', text)
    if m:
        text = text[: m.start()] + ',\n        "check": root.cp(0xf00c)\n' + text[m.start() + 1 :]
        text = text.replace(',,\n        "check"', ',\n        "check"')
        print(f":: added check glyph to {path}")
    else:
        print(f"WARNING: could not insert check glyph in {path}", file=sys.stderr)

if text != orig:
    bak = path.with_suffix(path.suffix + ".pre-hyperwebster-glyphs")
    if not bak.exists():
        bak.write_text(orig)
    path.write_text(text)
    print(f":: wrote {path}")
else:
    print(f":: {path.name} unchanged")
PY
