#!/bin/sh
# patch-colours-nsbar-blur.sh — point Colours.reloadHyprRules at nsbar/nspanels
# with an ignore_alpha that stays below Theme.barBg (~0.60). Idempotent.
set -eu

TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/services/Colours.qml}
[ -f "$TARGET" ] || { echo "Colours.qml not found at $TARGET — skipping"; exit 0; }

# Already correct (nsbar list + blur on/off value + capped ignore_alpha).
# Bare "blur," without on/off is invalid on Hyprland 0.55+ ("missing a value").
if grep -q '"nsbar"' "$TARGET" 2>/dev/null \
   && grep -q 'transparency.enabled ? "on" : "off"' "$TARGET" 2>/dev/null \
   && grep -q 'Math.min(0.40' "$TARGET" 2>/dev/null; then
  echo ":: Colours.qml already targets nsbar blur (blur on/off, ignore_alpha capped)"
  exit 0
fi

cp -n "$TARGET" "$TARGET.pre-hyperwebster-nsbar-blur" 2>/dev/null || true

python3 - "$TARGET" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()

new_fn = '''    function reloadHyprRules(): void {
        // HyperWebster: NoSignal NsBar uses nsbar / nspanels.
        // ignore_alpha must stay below Theme.barBg (~0.60) or the bar fill is
        // skipped for blur. Hyprland requires "blur on|off" (bare blur is invalid).
        const on = transparency.enabled ? "on" : "off";
        const alpha = Math.min(0.40, Math.max(0, transparency.base - 0.03));
        const nss = ["nsbar", "nspanels", "caelestia-drawers"];
        const msgs = [];
        for (let i = 0; i < nss.length; i++) {
            const ns = nss[i];
            msgs.push(`keyword layerrule blur ${on}, match:namespace ${ns}`);
            msgs.push(`keyword layerrule ignore_alpha ${alpha}, match:namespace ${ns}`);
        }
        Hypr.extras.batchMessage(msgs);
    }'''

pat = re.compile(
    r"    function reloadHyprRules\(\): void \{.*?\n    \}",
    re.DOTALL,
)
if not pat.search(text):
    print("WARNING: Colours.qml reloadHyprRules not found — patch skipped", file=sys.stderr)
    sys.exit(0)

path.write_text(pat.sub(new_fn, text, count=1))
print(f":: patched {path} (nsbar/nspanels blur on/off, ignore_alpha capped at 0.40)")
PY
