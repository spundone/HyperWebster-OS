#!/bin/sh
# install-luks-tpm-unlock.sh — ship TPM LUKS enrollment helper + sd-encrypt
# guidance. Idempotent. Needs root for /usr/local/bin install.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

install -Dm0755 "$HERE/hyperwebster-luks-tpm-enroll" /usr/local/bin/hyperwebster-luks-tpm-enroll
install -Dm0644 "$HERE/README.md" /usr/local/share/hyperwebster/luks-tpm-unlock/README.md

# Ensure sd-encrypt is used when LUKS is present (TPM tokens need systemd in initramfs).
if [ -f /etc/crypttab ] && grep -qE '^[^#[:space:]].*luks' /etc/crypttab 2>/dev/null; then
  if [ -f /etc/mkinitcpio.conf ]; then
    hooks_changed=0
    if grep -qE '^HOOKS=.*\bencrypt\b' /etc/mkinitcpio.conf; then
      echo ":: migrating mkinitcpio encrypt hook -> sd-encrypt (systemd TPM unlock)"
      sed -i '/^HOOKS=/ s/\bencrypt\b/sd-encrypt/' /etc/mkinitcpio.conf
      hooks_changed=1
    elif ! grep -qE '^HOOKS=.*\bsd-encrypt\b' /etc/mkinitcpio.conf; then
      echo ":: adding sd-encrypt hook before filesystems (systemd TPM unlock)"
      sed -i '/^HOOKS=/ s/\bfilesystems\b/sd-encrypt filesystems/' /etc/mkinitcpio.conf
      hooks_changed=1
    fi
    if [ "$hooks_changed" -eq 1 ] && command -v mkinitcpio >/dev/null 2>&1; then
      /usr/bin/mkinitcpio -P 2>/dev/null \
        || mkinitcpio -P \
        || echo "WARNING: mkinitcpio -P failed — rebuild initramfs manually" >&2
    fi
  fi
fi

echo "luks-tpm-unlock: installed hyperwebster-luks-tpm-enroll"
