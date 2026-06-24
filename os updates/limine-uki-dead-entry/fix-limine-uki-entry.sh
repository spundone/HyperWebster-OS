#!/bin/sh
# fix-limine-uki-entry.sh — idempotent. REQUIRES ROOT.
#
# With ENABLE_UKI=yes, limine removes /boot/vmlinuz-linux and
# /boot/initramfs-linux.img (UKI-only), but the installer-seeded first entry
# "/HyperWebster (Arch Linux)" in limine.conf still uses `protocol: linux` ->
# boot():/vmlinuz-linux. That entry is the default auto-boot target and now
# dead-boots to a TTY. This converts it to a `protocol: efi` entry that boots
# the UKI, keeping the same label (so it stays first = default) and cmdline.
#
# Idempotent: if the entry is already protocol:efi (no vmlinuz path), it's a
# no-op. Always backs up limine.conf first. Refuses if the UKI is missing.
#
# NOTE: the durable fix belongs in the ISO installer's seeded limine.conf /
# limine config — see README. This repairs an already-installed system.
set -eu

ESP_PATH=/boot
UKI_NAME=hyperwebster
[ -r /etc/default/limine ] && . /etc/default/limine 2>/dev/null || true
[ -n "${ESP_PATH:-}" ] || ESP_PATH=/boot
[ -n "${CUSTOM_UKI_NAME:-}" ] && UKI_NAME="$CUSTOM_UKI_NAME"

CONF="$ESP_PATH/limine.conf"
UKI_REL="/EFI/Linux/${UKI_NAME}_linux.efi"
UKI_ABS="$ESP_PATH$UKI_REL"

[ "$(id -u)" -eq 0 ] || { echo "must run as root (edits $CONF)" >&2; exit 1; }
[ -f "$CONF" ]    || { echo "no $CONF" >&2; exit 1; }
[ -f "$UKI_ABS" ] || { echo "UKI not found at $UKI_ABS — aborting (won't point at a missing file)" >&2; exit 1; }

# Already fixed? (the seeded entry no longer references vmlinuz)
if ! grep -q 'path: boot():/vmlinuz-linux' "$CONF"; then
  echo "limine.conf has no dead vmlinuz entry — nothing to do"
  exit 0
fi

cp -a "$CONF" "$CONF.bak.$(date +%Y%m%d%H%M%S)"

# Rewrite ONLY the manual entry's body: protocol:linux + vmlinuz + module_path
# lines become protocol:efi + UKI path. Keeps the `cmdline:` line as-is.
awk -v uki="$UKI_REL" '
  /^\/HyperWebster \(Arch Linux\)/ { print; inblk=1; next }
  inblk && /^[^[:space:]]/      { inblk=0 }            # next top-level entry ends the block
  inblk && /^[[:space:]]*protocol:[[:space:]]*linux/ { print "    protocol: efi"; next }
  inblk && /^[[:space:]]*path:[[:space:]]*boot\(\):\/vmlinuz-linux/ { print "    path: boot():" uki; next }
  inblk && /^[[:space:]]*module_path:/ { next }        # drop ucode/initramfs modules (UKI is self-contained)
  { print }
' "$CONF" > "$CONF.tmp"

# sanity: must still contain our UKI path and no vmlinuz path
grep -q "path: boot():$UKI_REL" "$CONF.tmp" && ! grep -q 'boot():/vmlinuz-linux' "$CONF.tmp" \
  || { echo "rewrite sanity check failed — leaving $CONF untouched" >&2; rm -f "$CONF.tmp"; exit 1; }

mv "$CONF.tmp" "$CONF"
sync
echo "fixed: '/HyperWebster (Arch Linux)' now protocol:efi -> $UKI_REL (backup kept)"
