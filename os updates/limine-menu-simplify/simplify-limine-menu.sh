#!/bin/bash
# simplify-limine-menu.sh — shrink Limine to desktop UKI + Starman (+ Snapshots).
# Idempotent. REQUIRES ROOT. Backs up limine.conf and /etc/default/limine first.
#
# Drops manual protocol:linux fallbacks, nested auto OS clutter drivers
# (ENABLE_LIMINE_FALLBACK / FIND_BOOTLOADERS), and rewrites the menu seed so
# limine-entry-tool targets the desktop entry via machine-id comment.
#
# Do NOT `source` /etc/default/limine — it uses bash array syntax that can abort
# a POSIX `sh` invocation and break hyperwebster-update migrations.
set -euo pipefail

ESP_PATH=/boot
UKI_NAME=hyperwebster
DEFAULTS=/etc/default/limine

[ "$(id -u)" -eq 0 ] || { echo "must run as root" >&2; exit 1; }

# Parse limine defaults without sourcing (array += lines are not safe to .).
if [ -f "$DEFAULTS" ]; then
  esp_line=$(grep -E '^ESP_PATH=' "$DEFAULTS" | head -1 || true)
  if [ -n "$esp_line" ]; then
    ESP_PATH=${esp_line#ESP_PATH=}
    ESP_PATH=${ESP_PATH#\"}
    ESP_PATH=${ESP_PATH%\"}
  fi
  uki_line=$(grep -E '^CUSTOM_UKI_NAME=' "$DEFAULTS" | head -1 || true)
  if [ -n "$uki_line" ]; then
    UKI_NAME=${uki_line#CUSTOM_UKI_NAME=}
    UKI_NAME=${UKI_NAME#\"}
    UKI_NAME=${UKI_NAME%\"}
  fi
fi
[ -n "${ESP_PATH:-}" ] || ESP_PATH=/boot
[ -n "${UKI_NAME:-}" ] || UKI_NAME=hyperwebster

CONF="$ESP_PATH/limine.conf"
MACHINE_ID=$(tr -d '[:space:]' </etc/machine-id 2>/dev/null || true)

[ -f "$CONF" ] || { echo "no $CONF — skipping (not a Limine install)"; exit 0; }
[ -n "$MACHINE_ID" ] || { echo "no /etc/machine-id — skipping"; exit 0; }

# Resolve UKI path: prefer CUSTOM_UKI_NAME, else first *_linux.efi on the ESP.
UKI_REL="/EFI/Linux/${UKI_NAME}_linux.efi"
UKI_ABS="$ESP_PATH$UKI_REL"
if [ ! -f "$UKI_ABS" ]; then
  found=$(find "$ESP_PATH/EFI/Linux" -maxdepth 1 -type f \( -name '*_linux.efi' -o -name '*_Linux.efi' \) 2>/dev/null | head -1 || true)
  if [ -n "$found" ]; then
    UKI_ABS=$found
    UKI_REL=${UKI_ABS#"$ESP_PATH"}
    echo ":: using UKI $UKI_REL"
  else
    echo "WARNING: no UKI under $ESP_PATH/EFI/Linux — writing menu with $UKI_REL (create UKI via limine-update)" >&2
  fi
fi

stamp=$(date +%Y%m%d%H%M%S)
cp -a "$CONF" "$CONF.bak.$stamp"
[ -f "$DEFAULTS" ] && cp -a "$DEFAULTS" "$DEFAULTS.bak.$stamp"

# Preserve LUKS/root cmdline from the current desktop (or Starman) entry.
extract_cmdline() {
  awk '
    /^\/HyperWebster/ && /hyperarch|Arch Linux/ { inblk=1; next }
    /^\/Starman/ { if (!found) inblk=1; next }
    inblk && /^[^[:space:]\/]/ { inblk=0 }
    inblk && /^[[:space:]]*cmdline:[[:space:]]*/ {
      sub(/^[[:space:]]*cmdline:[[:space:]]*/, "")
      gsub(/[[:space:]]*hyperwebster\.starman=1/, "")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      print
      found=1
      exit
    }
  ' "$CONF"
}

CMDLINE=$(extract_cmdline || true)
if [ -z "$CMDLINE" ] && [ -f "$DEFAULTS" ]; then
  CMDLINE=$(grep -E '^KERNEL_CMDLINE\[default\]\+=' "$DEFAULTS" | head -1 \
    | sed 's/^KERNEL_CMDLINE\[default\]+=//' | sed 's/^"//;s/"$//' || true)
fi
[ -n "$CMDLINE" ] || CMDLINE="rw quiet splash"

# Quiet limine-entry-tool: no EFI-fallback menu row, no bootloader scan clutter.
if [ -f "$DEFAULTS" ]; then
  tmp=$(mktemp)
  awk '
    BEGIN { saw_fb=0; saw_find=0; saw_order=0 }
    /^ENABLE_LIMINE_FALLBACK=/ { print "ENABLE_LIMINE_FALLBACK=no"; saw_fb=1; next }
    /^FIND_BOOTLOADERS=/ { print "FIND_BOOTLOADERS=no"; saw_find=1; next }
    /^BOOT_ORDER=/ { print "BOOT_ORDER=\"*, Snapshots\""; saw_order=1; next }
    { print }
    END {
      if (!saw_fb) print "ENABLE_LIMINE_FALLBACK=no"
      if (!saw_find) print "FIND_BOOTLOADERS=no"
      if (!saw_order) print "BOOT_ORDER=\"*, Snapshots\""
    }
  ' "$DEFAULTS" > "$tmp"
  mv "$tmp" "$DEFAULTS"
else
  cat > "$DEFAULTS" <<EOF
TARGET_OS_NAME="HyperWebster"
ESP_PATH="$ESP_PATH"
KERNEL_CMDLINE[default]+="$CMDLINE"
ENABLE_UKI=yes
CUSTOM_UKI_NAME="$UKI_NAME"
ENABLE_LIMINE_FALLBACK=no
FIND_BOOTLOADERS=no
BOOT_ORDER="*, Snapshots"
MAX_SNAPSHOT_ENTRIES=5
SNAPSHOT_FORMAT_CHOICE=5
EOF
fi

TIMEOUT=$(grep -E '^timeout:' "$CONF" | head -1 | awk '{print $2}' || true)
[ -n "$TIMEOUT" ] || TIMEOUT=10
BRANDING=$(grep -E '^interface_branding:' "$CONF" | head -1 | sed 's/^interface_branding:[[:space:]]*//' || true)
[ -n "$BRANDING" ] || BRANDING="HyperWebster · hyperarch"

cat > "$CONF" <<EOF
timeout: $TIMEOUT
default_entry: 1
interface_branding: $BRANDING

/HyperWebster · hyperarch (Arch Linux)
    comment: machine-id=$MACHINE_ID
    protocol: efi
    path: boot():$UKI_REL
    cmdline: $CMDLINE

/Starman (Gaming / Steam)
    protocol: efi
    path: boot():$UKI_REL
    cmdline: $CMDLINE hyperwebster.starman=1
EOF

sync

if command -v limine-update >/dev/null 2>&1; then
  echo ":: running limine-update to refresh UKI / Snapshots entries..."
  limine-update || echo ":: limine-update failed — manual menu seed is in place" >&2
else
  echo ":: limine-update not found — menu seed written; install limine-mkinitcpio-hook to refresh"
fi

# limine-update may recreate a nested HyperWebster group (linux-cachyos / linux).
# Point default_entry at the cachyos leaf and expand the parent so timeout boots it.
SELF_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [ -x "$SELF_DIR/prefer-limine-cachyos.sh" ]; then
  bash "$SELF_DIR/prefer-limine-cachyos.sh" || true
fi

echo "Limine menu simplified: desktop + Starman (backups: *.$stamp)"
