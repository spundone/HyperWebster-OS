#!/bin/sh
# install-chimera-deckify-gaming.sh — ship Deckify/Chimera helpers. Idempotent.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

install -Dm0755 "$HERE/hyperwebster-gaming-session" /usr/local/bin/hyperwebster-gaming-session
install -Dm0755 "$HERE/hyperwebster-deckify-install" /usr/local/bin/hyperwebster-deckify-install
install -Dm0644 "$HERE/README.md" /usr/local/share/hyperwebster/chimera-deckify-gaming/README.md
install -Dm0644 "$HERE/gamescope-hdr.env" /usr/local/share/hyperwebster/chimera-deckify-gaming/gamescope-hdr.env

echo "chimera-deckify-gaming: CLI helpers installed (run hyperwebster-deckify-install as user)"
