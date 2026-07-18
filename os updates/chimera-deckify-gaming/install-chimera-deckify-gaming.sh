#!/bin/sh
# install-chimera-deckify-gaming.sh — ship Deckify/Chimera helpers. Idempotent.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

install -Dm0755 "$HERE/hyperwebster-gaming-session" /usr/local/bin/hyperwebster-gaming-session
install -Dm0755 "$HERE/hyperwebster-deckify-install" /usr/local/bin/hyperwebster-deckify-install
install -Dm0755 "$HERE/hyperwebster-restart-sddm" /usr/local/bin/hyperwebster-restart-sddm
install -Dm0755 "$HERE/switch-to-gaming" /usr/local/bin/switch-to-gaming
install -Dm0755 "$HERE/switch-to-desktop" /usr/local/bin/switch-to-desktop
install -Dm0755 "$HERE/gaming-session-switch" /usr/local/bin/gaming-session-switch
install -Dm0755 "$HERE/os-session-select" /usr/lib/os-session-select
install -Dm0644 "$HERE/README.md" /usr/local/share/hyperwebster/chimera-deckify-gaming/README.md
install -Dm0644 "$HERE/gamescope-hdr.env" /usr/local/share/hyperwebster/chimera-deckify-gaming/gamescope-hdr.env

# sudoers for session arm + SDDM restart (needed for Super+Shift+S).
if [ -x "$HERE/install-gaming-sudoers.sh" ]; then
  sh "$HERE/install-gaming-sudoers.sh" || true
fi

echo "chimera-deckify-gaming: helpers installed (run hyperwebster-deckify-install as user for packages)"
