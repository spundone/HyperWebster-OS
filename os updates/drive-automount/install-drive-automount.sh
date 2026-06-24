#!/bin/sh
# install-drive-automount.sh — idempotent. Needs root.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

install -Dm0755 "$HERE/hyperwebster-drive-automount" /usr/local/bin/hyperwebster-drive-automount
install -Dm0644 "$HERE/hyperwebster-drive-automount.service" \
  /etc/systemd/system/hyperwebster-drive-automount.service
install -Dm0644 "$HERE/README.md" /usr/local/share/hyperwebster/drive-automount/README.md
install -d -m 755 /mnt

systemctl daemon-reload
systemctl enable hyperwebster-drive-automount.service
echo "drive-automount: enabled (non-system drives -> /mnt/<label>)"
