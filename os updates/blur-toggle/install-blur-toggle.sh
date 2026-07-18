#!/bin/sh
# install-blur-toggle.sh — optional frosted glass toggle. Idempotent.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="${HOME}/.local/bin"
SHARE="${HOME}/.local/share/hyperwebster/blur-toggle"

if [ -f "$HERE/../hyperwebster-update/lib/hw-install-file.sh" ]; then
  # shellcheck source=/dev/null
  . "$HERE/../hyperwebster-update/lib/hw-install-file.sh"
else
  hw_install_file() {
    _s=$1; _d=$2; _m=${3:-0644}
    [ -f "$_s" ] || return 0
    _sr=$(readlink -f "$_s" 2>/dev/null || echo "$_s")
    _dr=
    [ -e "$_d" ] && _dr=$(readlink -f "$_d" 2>/dev/null || echo "$_d")
    if [ -n "$_dr" ] && [ "$_sr" = "$_dr" ]; then
      chmod "$_m" "$_d" 2>/dev/null || true
      return 0
    fi
    mkdir -p "$(dirname -- "$_d")"
    install -m "$_m" "$_s" "$_d"
  }
fi

install -d -m755 "$BIN" "$SHARE"
hw_install_file "$HERE/hyperwebster-blur-toggle" "$BIN/hyperwebster-blur-toggle" 0755
hw_install_file "$HERE/README.md" "$SHARE/README.md" 0644
hw_install_file "$HERE/patch-colours-nsbar-blur.sh" "$SHARE/patch-colours-nsbar-blur.sh" 0755
hw_install_file "$HERE/patch-theme-nsbar-blur.sh" "$SHARE/patch-theme-nsbar-blur.sh" 0755

# Patch shell so transparency toggles hit nsbar and bar fill lets blur through.
run_patch() {
  name=$1
  if [ "$(id -u)" -eq 0 ]; then
    sh "$SHARE/$name" || sh "$HERE/$name"
  else
    sudo sh "$SHARE/$name" 2>/dev/null || sudo sh "$HERE/$name" || true
  fi
}
run_patch patch-colours-nsbar-blur.sh
run_patch patch-theme-nsbar-blur.sh

echo "blur-toggle: run hyperwebster-blur-toggle enable for frosted glass"
