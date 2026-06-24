#!/bin/sh
# install-cheatsheet-tidy.sh — tidy the Super+K cheatsheet panel: key +
# action only, every line fits the panel.
#
# Ships full replacements of the keybinds-help scripts:
#   - hyperwebster-keybinds-gen  -> ~/.local/bin/  (no tag column, strips doc-only
#     parentheticals, truncates actions to the panel budget)
#   - hyperwebster-keybinds      -> ~/.local/bin/  (fuzzel width 72 -> 100, kept in
#     sync with the generator budget)
#
# Also refreshes the layer-root source copies when present, so a
# re-run of install-keybinds-help.sh cannot regress the panel.
# Safe to re-run (idempotent). No sudo needed.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
ROOT=$(dirname -- "$SRC")    # the layer root when run from the layer tree

mkdir -p "$BIN"
install -m 0755 "$SRC/hyperwebster-keybinds-gen" "$BIN/hyperwebster-keybinds-gen"
install -m 0755 "$SRC/hyperwebster-keybinds"     "$BIN/hyperwebster-keybinds"
echo ":: installed tidied cheatsheet scripts -> $BIN"

# Keep the keybinds-help source copies in step (they live flat at the layer root).
# Check both the tree this component sits in and the installed layer location,
# so running from a handoff folder still fixes the on-system layer copies.
for d in "$ROOT" "$HOME/.local/share/hyperwebster"; do
  for f in hyperwebster-keybinds-gen hyperwebster-keybinds; do
    if [ -f "$d/$f" ] && ! cmp -s "$SRC/$f" "$d/$f"; then
      install -m 0755 "$SRC/$f" "$d/$f"
      echo ":: refreshed layer copy -> $d/$f"
    fi
  done
done

# Refresh the cached list so the next Super+K shows the new format at once.
"$BIN/hyperwebster-keybinds-gen" > "$HOME/.local/share/hyperwebster/keybinds.list" 2>/dev/null || true

echo "Done. Super+K now shows key + action only, fitted to the panel."
