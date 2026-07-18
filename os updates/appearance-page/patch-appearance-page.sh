#!/bin/sh
# patch-appearance-page.sh — install AppearanceSelect + hub button, register
# stack index 4 under Wallpaper & style. Idempotent. Runs as root (installer or
# pacman hook after nosignal-shell / caelestia-shell upgrades).
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NEXUS=/etc/xdg/quickshell/caelestia/modules/nexus
PAGES="$NEXUS/pages"
WALL="$PAGES/wallandstyle"
REG="$NEXUS/PageCompRegistry.qml"
HUB="$PAGES/WallpaperAndStyle.qml"
APP="$WALL/AppearanceSelect.qml"

[ -d "$PAGES" ] || { echo "caelestia-shell not found at $NEXUS — nothing to patch"; exit 0; }

# 1. Appearance sub-page (new file — pacman upgrades leave it alone once present,
#    but we always re-copy so content stays current).
install -d -m 0755 "$WALL"
install -m 0644 "$SELF_DIR/AppearanceSelect.qml" "$APP"
echo ":: installed $APP"

# 2. Hub: Wallpaper & style with Appearance button.
if [ -f "$SELF_DIR/WallpaperAndStyle.qml" ]; then
  cp -n "$HUB" "$HUB.pre-hyperwebster-appearance" 2>/dev/null || true
  install -m 0644 "$SELF_DIR/WallpaperAndStyle.qml" "$HUB"
  echo ":: installed $HUB (Appearance button)"
fi

# 3. Registry: add AppearanceSelect as Wallpaper & style stack index 4.
if [ -f "$REG" ]; then
  if grep -q 'AppearanceSelect' "$REG"; then
    echo ":: registry already has AppearanceSelect"
  else
    cp -n "$REG" "$REG.pre-hyperwebster-appearance" 2>/dev/null || true
    # Insert after ColourSelect {} inside the Wallpaper & style StackPage.
    perl -0pi -e 's/(Component \{\s*\n\s*ColourSelect \{\}\s*\n\s*\})/$1\n                Component {\n                    AppearanceSelect {}\n                }/s' "$REG"
    if grep -q 'AppearanceSelect' "$REG"; then
      echo ":: patched $REG (Appearance page registered as stack index 4)"
    else
      echo "WARNING: registry patch did not apply — upstream PageCompRegistry.qml changed shape." >&2
      echo "         AppearanceSelect.qml is installed; update the regex in $(basename "$0")." >&2
    fi
  fi
else
  echo "PageCompRegistry.qml missing — sub-page file installed only"
fi

# 4. Theme.fontFamily follows Settings → Appearance UI font.
if [ -x "$SELF_DIR/patch-theme-font.sh" ]; then
  sh "$SELF_DIR/patch-theme-font.sh" || true
fi
