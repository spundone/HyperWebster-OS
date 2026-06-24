#!/bin/sh
# install-additions-installer.sh — Settings → Additions page: install
# optional software on demand from official sources (no AUR, no Flatpak).
#
#   - hyperwebster-additions        -> ~/.local/bin (status cache + installer runner)
#   - additions.json          -> stable on-system copy (the manifest)
#   - AdditionsPage.qml       -> patched into caelestia-shell (sudo)
#   - pacman hook             -> re-applies the patch after shell upgrades
#
# Safe to re-run (idempotent). Needs sudo for the QML patch + hook.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/hyperwebster/additions-installer"

# 1. Backend + manifest.
mkdir -p "$BIN" "$SHARE"
install -m 0755 "$SRC/hyperwebster-additions" "$BIN/hyperwebster-additions"
install -m 0644 "$SRC/additions.json" "$SHARE/additions.json"
install -m 0755 "$SRC/obs-extras.sh" "$SHARE/obs-extras.sh"

# 2. Stable on-system copies for the pacman hook to point at.
install -m 0644 "$SRC/AdditionsPage.qml" "$SHARE/AdditionsPage.qml"
install -m 0755 "$SRC/patch-additions-page.sh" "$SHARE/patch-additions-page.sh"

# 3. Apply the QML patch now.
sudo sh "$SHARE/patch-additions-page.sh"

# 4. Pacman hook: caelestia-shell upgrades revert both registries — re-patch.
HOOK=/etc/pacman.d/hooks/hyperwebster-additions-page.hook
sudo mkdir -p /etc/pacman.d/hooks
sudo tee "$HOOK" > /dev/null <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = hyperwebster-shell
Target = caelestia-shell

[Action]
Description = Re-applying HyperWebster Additions settings page...
When = PostTransaction
Exec = /bin/sh $SHARE/patch-additions-page.sh
EOF
echo ":: pacman hook installed -> $HOOK"

# 5. Seed the status cache so the page has data on first open.
"$BIN/hyperwebster-additions" status >/dev/null 2>&1 || true

echo "Done. Restart the shell (Ctrl+Super+Alt+R) to see Settings -> Additions."
