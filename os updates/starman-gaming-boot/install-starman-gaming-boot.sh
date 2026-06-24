#!/bin/sh
# install-starman-gaming-boot.sh — idempotent. Needs root.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

install -Dm0755 "$HERE/hyperwebster-starman-arm" /usr/local/bin/hyperwebster-starman-arm
install -Dm0644 "$HERE/hyperwebster-starman-boot.service" \
  /etc/systemd/system/hyperwebster-starman-boot.service
install -Dm0644 "$HERE/README.md" /usr/local/share/hyperwebster/starman-gaming-boot/README.md

systemctl daemon-reload
systemctl enable hyperwebster-starman-boot.service
echo "starman-gaming-boot: enabled (Limine entry hyperwebster.starman=1)"
