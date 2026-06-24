#!/usr/bin/env bash
#
# Shared helpers to locate or download a stock Arch Linux ISO for HyperWebster builds.
# Sourced by hyperwebster.sh and scripts/build-in-container.sh.
#
# Environment:
#   HYPERWEBSTER_ARCH_ISO          — explicit path to stock ISO
#   HYPERWEBSTER_ARCH_ISO_URL      — override download URL (single mirror)
#   HYPERWEBSTER_SKIP_ISO_DOWNLOAD — set to 1 to fail fast when ISO is missing
#
set -euo pipefail

# Minimum plausible size for a current archlinux-x86_64.iso (~1.3 GB typical).
readonly HYPERWEBSTER_ARCH_ISO_MIN_BYTES=$((500 * 1024 * 1024))

hyperwebster_default_arch_iso_urls() {
  if [ -n "${HYPERWEBSTER_ARCH_ISO_URL:-}" ]; then
    printf '%s\n' "$HYPERWEBSTER_ARCH_ISO_URL"
    return 0
  fi
  cat <<'EOF'
https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso
https://mirror.rackspace.com/archlinux/iso/latest/archlinux-x86_64.iso
https://mirrors.kernel.org/archlinux/iso/latest/archlinux-x86_64.iso
EOF
}

hyperwebster_find_stock_iso() {
  local script_dir="$1"
  local iso

  if [ -n "${HYPERWEBSTER_ARCH_ISO:-}" ]; then
    if [ -f "$HYPERWEBSTER_ARCH_ISO" ]; then
      printf '%s\n' "$HYPERWEBSTER_ARCH_ISO"
      return 0
    fi
    echo "ERROR: HYPERWEBSTER_ARCH_ISO=$HYPERWEBSTER_ARCH_ISO not found" >&2
    return 1
  fi

  shopt -s nullglob
  for iso in "$script_dir"/archlinux-*.iso; do
    [[ "$(basename "$iso")" == *HyperWebster* ]] && continue
    shopt -u nullglob
    printf '%s\n' "$iso"
    return 0
  done
  shopt -u nullglob
  return 1
}

hyperwebster_iso_download_valid() {
  local file="$1"
  [ -f "$file" ] || return 1
  local size
  size="$(wc -c <"$file" | tr -d ' ')"
  [ "$size" -ge "$HYPERWEBSTER_ARCH_ISO_MIN_BYTES" ]
}

hyperwebster_download_arch_iso() {
  local dest_dir="$1"
  local dest="$dest_dir/archlinux-x86_64.iso"
  local partial="$dest.partial"
  local url tried=0

  if hyperwebster_iso_download_valid "$dest"; then
    printf '%s\n' "$dest"
    return 0
  fi

  if [ -f "$partial" ] && ! hyperwebster_iso_download_valid "$partial"; then
    echo "==> Removing incomplete Arch ISO download ($(basename "$partial"))..." >&2
    rm -f "$partial"
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is required to download the Arch ISO automatically." >&2
    echo "       Install curl or place archlinux-*.iso in $dest_dir" >&2
    return 1
  fi

  while IFS= read -r url || [ -n "$url" ]; do
    [ -z "$url" ] && continue
    tried=$((tried + 1))
    echo "==> Downloading Arch Linux ISO from:" >&2
    echo "    $url" >&2
    if curl -fL --progress-bar -C - -o "$partial" "$url"; then
      if hyperwebster_iso_download_valid "$partial"; then
        mv -f "$partial" "$dest"
        printf '%s\n' "$dest"
        return 0
      fi
      echo "WARNING: Download from $url failed size check; trying next mirror..." >&2
      rm -f "$partial"
    else
      echo "WARNING: Download from $url failed; trying next mirror..." >&2
      rm -f "$partial"
    fi
  done < <(hyperwebster_default_arch_iso_urls)

  if [ "$tried" -eq 0 ]; then
    echo "ERROR: No Arch ISO download URL configured." >&2
  else
    echo "ERROR: Could not download a valid Arch ISO (network or mirror issue)." >&2
    echo "       Place archlinux-*.iso in $dest_dir or set HYPERWEBSTER_ARCH_ISO." >&2
  fi
  return 1
}

hyperwebster_ensure_stock_iso() {
  local script_dir="$1"
  local found

  if found="$(hyperwebster_find_stock_iso "$script_dir")"; then
    printf '%s\n' "$found"
    return 0
  fi

  if [ "${HYPERWEBSTER_SKIP_ISO_DOWNLOAD:-0}" = "1" ]; then
    echo "ERROR: No stock Arch ISO found in $script_dir" >&2
    echo >&2
    echo "Download the latest from https://archlinux.org/download/ and put it" >&2
    echo "in this folder (filename must start with 'archlinux-')." >&2
    echo "Or unset HYPERWEBSTER_SKIP_ISO_DOWNLOAD to enable auto-download." >&2
    return 1
  fi

  echo "==> No stock Arch ISO found in $script_dir" >&2
  echo "==> Fetching the latest Arch Linux ISO automatically..." >&2
  echo "    (set HYPERWEBSTER_SKIP_ISO_DOWNLOAD=1 to require a local ISO)" >&2
  echo >&2
  hyperwebster_download_arch_iso "$script_dir"
}
