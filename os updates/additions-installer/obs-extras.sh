#!/bin/sh
# obs-extras.sh — OBS Studio with the right hardware encoders for THIS box.
# The Additions page ships on every install and GPUs differ (AMD / Intel /
# NVIDIA, any mix — e.g. AMD discrete + Intel iGPU), so the
# encoder runtime packages are DETECTED per machine, not hardcoded.
#
#   obs-extras.sh check     exit 0 only if OBS + everything this box's GPUs
#                           need is installed (drives the Additions row state)
#   obs-extras.sh install   install OBS + the detected encoder runtimes
#
# Per-vendor encoder support on Arch:
#   AMD    — VAAPI (H.264/HEVC/AV1) ships inside mesa (base system): no extra
#            package since the libva-mesa-driver merge.
#   Intel  — intel-media-driver (VAAPI) + vpl-gpu-rt (QuickSync/QSV runtime).
#   NVIDIA — NVENC comes with the proprietary driver (nvidia-utils or a
#            legacy branch). Deliberately NOT auto-installed here: the driver
#            branch is a system-level decision (see gaming-enablement's
#            NVIDIA notes) — we print a pointer instead.
set -eu

gpus=$(lspci -nn 2>/dev/null | grep -Ei 'vga|3d|display' || true)

needed=""
case "$gpus" in *[Ii]ntel*) needed="intel-media-driver vpl-gpu-rt" ;; esac

check() {
  pacman -Q obs-studio >/dev/null 2>&1 || return 1
  for p in $needed; do
    pacman -Q "$p" >/dev/null 2>&1 || return 1
  done
  return 0
}

do_install() {
  # shellcheck disable=SC2086 — $needed is a deliberate word-split list
  sudo pacman -S --needed --noconfirm obs-studio $needed
  case "$gpus" in
    *[Aa][Mm][Dd]*|*ATI*)
      echo ":: AMD GPU: VAAPI encoders ship in mesa — already present." ;;
  esac
  case "$gpus" in
    *[Nn][Vv][Ii][Dd][Ii][Aa]*)
      if pacman -Q nvidia-utils >/dev/null 2>&1; then
        echo ":: NVIDIA GPU: NVENC available via the installed driver."
      else
        echo "NOTE: NVIDIA GPU detected but no proprietary driver — NVENC needs"
        echo "      it (nvidia-utils, or a legacy branch for pre-Turing cards)."
      fi ;;
  esac
  [ -n "$needed" ] && echo ":: Intel GPU: VAAPI + QuickSync runtimes installed."
  echo ":: restart OBS to pick up new encoders."
}

case "${1:-}" in
  check)   check ;;
  install) do_install ;;
  *)       echo "usage: obs-extras.sh check|install" >&2; exit 2 ;;
esac
