#!/bin/sh
# install-keybinds-help.sh — install the HyperWebster on-screen keybinding cheatsheet.
#
# This component lives entirely in this folder (Downloads) so it survives a
# system wipe. Run this after rebuilding to put the pieces back in place:
#   - hyperwebster-keybinds-gen, hyperwebster-keybinds  -> ~/.local/bin/
#   - HyperWebster-keybindings.md (source of truth) -> ~/.local/share/hyperwebster/
#   - Super+/ and Super+F1 binds -> ~/.config/caelestia/hypr-user.conf
#
# Safe to re-run (idempotent). Deps: awk, fuzzel, optional wl-copy.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/hyperwebster"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"

mkdir -p "$BIN" "$SHARE"

install -m 0755 "$SRC/hyperwebster-keybinds-gen" "$BIN/hyperwebster-keybinds-gen"
install -m 0755 "$SRC/hyperwebster-keybinds"     "$BIN/hyperwebster-keybinds"
echo "installed scripts -> $BIN"

# Canonical copy of the single source of truth, so the help works even if the
# Downloads doc is later moved/removed.
if [ -f "$SRC/HyperWebster-keybindings.md" ]; then
  cp "$SRC/HyperWebster-keybindings.md" "$SHARE/HyperWebster-keybindings.md"
  echo "installed keymap doc -> $SHARE/HyperWebster-keybindings.md"
fi

# Add the binds, only if not already present.
if [ -f "$HYPRUSER" ]; then
  if grep -q 'hyperwebster-keybinds' "$HYPRUSER"; then
    echo "binds already present in $HYPRUSER"
  else
    printf '\n' >> "$HYPRUSER"
    cat "$SRC/hyprland-keybinds-help.conf" >> "$HYPRUSER"
    echo "appended binds -> $HYPRUSER"
  fi
else
  echo "NOTE: $HYPRUSER not found — add the lines from hyprland-keybinds-help.conf to your Hyprland user config."
fi

# PATH sanity.
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "NOTE: $BIN is not on PATH — add it (e.g. in ~/.bash_profile)." ;;
esac

# Apply immediately if Hyprland is running.
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo "reloaded Hyprland"
fi

echo "Done. Press Super+/ to open the cheatsheet."
