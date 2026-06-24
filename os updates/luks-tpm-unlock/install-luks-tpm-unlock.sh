#!/bin/sh
# install-luks-tpm-unlock.sh — ship TPM LUKS helpers, Plymouth passphrase UX,
# and sd-encrypt hook guidance. Idempotent. Needs root for /usr/local/bin install.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

install -Dm0755 "$HERE/hyperwebster-luks-tpm-enroll" /usr/local/bin/hyperwebster-luks-tpm-enroll
install -Dm0755 "$HERE/hyperwebster-luks-tpm-status" /usr/local/bin/hyperwebster-luks-tpm-status
install -Dm0644 "$HERE/README.md" /usr/local/share/hyperwebster/luks-tpm-unlock/README.md

# Refresh HyperWebster Plymouth theme when installed (graphical LUKS passphrase).
if [ -d /usr/share/plymouth/themes/hyperwebster ] && [ -f "$HERE/plymouth/hyperwebster.script" ]; then
  install -Dm0644 "$HERE/plymouth/hyperwebster.script" \
    /usr/share/plymouth/themes/hyperwebster/hyperwebster.script
  install -Dm0644 "$HERE/plymouth/hyperwebster.plymouth" \
    /usr/share/plymouth/themes/hyperwebster/hyperwebster.plymouth
  if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme hyperwebster 2>/dev/null || true
  fi
fi

hooks_changed=0
rebuild_initramfs=0

# Ensure sd-encrypt + plymouth when LUKS is present (TPM tokens need systemd in initramfs).
if [ -f /etc/crypttab ] && grep -qE '^[^#[:space:]].*luks' /etc/crypttab 2>/dev/null; then
  if [ -f /etc/mkinitcpio.conf ]; then
    if grep -qE '^HOOKS=.*\bencrypt\b' /etc/mkinitcpio.conf; then
      echo ":: migrating mkinitcpio encrypt hook -> sd-encrypt (systemd TPM unlock)"
      sed -i '/^HOOKS=/ s/\bencrypt\b/sd-encrypt/' /etc/mkinitcpio.conf
      hooks_changed=1
    elif ! grep -qE '^HOOKS=.*\bsd-encrypt\b' /etc/mkinitcpio.conf; then
      echo ":: adding sd-encrypt hook before filesystems (systemd TPM unlock)"
      sed -i '/^HOOKS=/ s/\bfilesystems\b/sd-encrypt filesystems/' /etc/mkinitcpio.conf
      hooks_changed=1
    fi
    if ! grep -qE '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf; then
      if grep -qE '^HOOKS=.*\bsystemd\b' /etc/mkinitcpio.conf; then
        echo ":: adding plymouth hook after systemd (graphical LUKS passphrase)"
        sed -i '/^HOOKS=/ s/\bsystemd\b/systemd plymouth/' /etc/mkinitcpio.conf
        hooks_changed=1
      elif grep -qE '^HOOKS=.*\budev\b' /etc/mkinitcpio.conf; then
        sed -i '/^HOOKS=/ s/\budev\b/udev plymouth/' /etc/mkinitcpio.conf
        hooks_changed=1
      fi
    fi
    # Plymouth must run before sd-encrypt for graphical passphrase (not TTY fallback).
    if grep -qE '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf \
       && grep -qE '^HOOKS=.*\bsd-encrypt\b' /etc/mkinitcpio.conf; then
      plymouth_idx=$(grep -E '^HOOKS=' /etc/mkinitcpio.conf | sed 's/.*HOOKS=(//;s/).*//' | tr ' ' '\n' | grep -n '^plymouth$' | cut -d: -f1)
      encrypt_idx=$(grep -E '^HOOKS=' /etc/mkinitcpio.conf | sed 's/.*HOOKS=(//;s/).*//' | tr ' ' '\n' | grep -n '^sd-encrypt$' | cut -d: -f1)
      if [ -n "$plymouth_idx" ] && [ -n "$encrypt_idx" ] && [ "$plymouth_idx" -gt "$encrypt_idx" ]; then
        echo ":: reordering hooks: plymouth before sd-encrypt"
        current=$(grep -E '^HOOKS=' /etc/mkinitcpio.conf | sed 's/^HOOKS=(//;s/)$//')
        # shellcheck disable=SC2086
        set -- $current
        new_hooks=""
        for h; do
          [ "$h" = plymouth ] && continue
          new_hooks="$new_hooks $h"
          [ "$h" = systemd ] && new_hooks="$new_hooks plymouth"
        done
        # If systemd not in hooks, insert plymouth before sd-encrypt
        case " $new_hooks " in
          *" plymouth "*) ;;
          *)
            new_hooks=$(echo "$new_hooks" | sed 's/ sd-encrypt/ plymouth sd-encrypt/')
            ;;
        esac
        sed -i "s|^HOOKS=.*|HOOKS=(${new_hooks# })|" /etc/mkinitcpio.conf
        hooks_changed=1
      fi
    fi
  fi
fi

if [ "$hooks_changed" -eq 1 ]; then
  rebuild_initramfs=1
fi

# Plymouth theme refresh also needs initramfs rebuild.
if [ -d /usr/share/plymouth/themes/hyperwebster ] && [ -f "$HERE/plymouth/hyperwebster.script" ]; then
  rebuild_initramfs=1
fi

if [ "$rebuild_initramfs" -eq 1 ] && command -v mkinitcpio >/dev/null 2>&1; then
  echo ":: rebuilding initramfs"
  /usr/bin/mkinitcpio -P 2>/dev/null \
    || mkinitcpio -P \
    || echo "WARNING: mkinitcpio -P failed — rebuild initramfs manually" >&2
  if command -v limine-update >/dev/null 2>&1; then
    limine-update 2>/dev/null || true
  fi
fi

echo "luks-tpm-unlock: installed hyperwebster-luks-tpm-enroll + hyperwebster-luks-tpm-status"
