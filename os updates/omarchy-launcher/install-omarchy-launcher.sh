#!/bin/sh
# install-omarchy-launcher.sh — Omarchy Super+Alt+Space install menu for HyperWebster.
# Idempotent.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
LAYER="$HOME/.local/share/hyperwebster/omarchy-launcher"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
MARK_BEGIN='# >>> hyperwebster-omarchy-launcher >>>'
MARK_END='# <<< hyperwebster-omarchy-launcher <<<'

mkdir -p "$BIN" "$LAYER"
for script in hyperwebster-omarchy-menu hyperwebster-pkg-install \
              hyperwebster-pkg-aur-install hyperwebster-pkg-remove; do
  install -m 0755 "$SRC/$script" "$BIN/$script"
done
install -m 0644 "$SRC/README.md" "$LAYER/README.md"
install -m 0644 "$SRC/omarchy-launcher-keys.conf" "$LAYER/omarchy-launcher-keys.conf"
echo ":: installed omarchy-launcher scripts -> $BIN"

if [ ! -f "$HYPRUSER" ]; then
  echo "NOTE: $HYPRUSER not found — append omarchy-launcher-keys.conf manually."
elif grep -qF "$MARK_BEGIN" "$HYPRUSER" 2>/dev/null \
     || grep -q 'hyperwebster-omarchy-menu' "$HYPRUSER" 2>/dev/null; then
  # Refresh bind if an older image still pointed Super+Alt+Space at nexus.
  if grep -q 'Super+Alt, Space, global, caelestia:nexus' "$HYPRUSER" 2>/dev/null; then
    sed -i 's|^bind = Super+Alt, Space, global, caelestia:nexus|# moved to F10 — see hyperwebster-omarchy-launcher|' "$HYPRUSER"
    if ! grep -q 'hyperwebster-omarchy-menu' "$HYPRUSER" 2>/dev/null; then
      {
        printf '\n%s\n' "$MARK_BEGIN"
        cat "$SRC/omarchy-launcher-keys.conf"
        printf '%s\n' "$MARK_END"
      } >> "$HYPRUSER"
      echo ":: upgraded Super+Alt+Space bind -> $HYPRUSER"
    fi
  else
    echo ":: keybinds already present in $HYPRUSER"
  fi
else
  {
    printf '\n%s\n' "$MARK_BEGIN"
    cat "$SRC/omarchy-launcher-keys.conf"
    printf '%s\n' "$MARK_END"
  } >> "$HYPRUSER"
  # Drop the pre-launcher nexus bind when upgrading from an older hypr-user.conf.
  sed -i 's|^bind = Super+Alt, Space, global, caelestia:nexus|# moved to F10 — see hyperwebster-omarchy-launcher|' "$HYPRUSER" 2>/dev/null || true
  echo ":: appended omarchy-launcher keybinds -> $HYPRUSER"
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland"
fi

echo "Done. Super+Alt+Space install menu · F10 Settings · hyperwebster-omarchy-menu"
