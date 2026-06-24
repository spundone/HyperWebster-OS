#!/bin/sh
# install-wifi-password-retry.sh — let users recover from a wrong Wi-Fi
# password.
#
#   - patch-network-connection.sh -> ~/.local/share/hyperwebster/wifi-password-retry/
#     (stable on-system copy; the pacman hook points here)
#   - NetworkConnection.qml        -> patched in caelestia-shell (sudo)
#   - pacman hook                  -> re-applies the patch after shell upgrades
#
# Safe to re-run (idempotent). Needs sudo for the QML patch + hook.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SHARE="$HOME/.local/share/hyperwebster/wifi-password-retry"

# 1. Stable on-system copy of the patch (the pacman hook points here).
mkdir -p "$SHARE"
install -m 0755 "$SRC/patch-network-connection.sh" "$SHARE/patch-network-connection.sh"

# 2. Apply the QML patch now.
sudo sh "$SHARE/patch-network-connection.sh"

# 3. Pacman hook: caelestia-shell upgrades revert NetworkConnection.qml — re-patch.
HOOK=/etc/pacman.d/hooks/hyperwebster-wifi-password-retry.hook
sudo mkdir -p /etc/pacman.d/hooks
sudo tee "$HOOK" > /dev/null <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = hyperwebster-shell
Target = caelestia-shell
Target = nosignal-shell

[Action]
Description = Re-applying HyperWebster Wi-Fi wrong-password recovery patch...
When = PostTransaction
Exec = /bin/sh $SHARE/patch-network-connection.sh
EOF
echo ":: pacman hook installed -> $HOOK"

echo "Done. Restart the shell (Ctrl+Super+Alt+R) to pick up the patch."
