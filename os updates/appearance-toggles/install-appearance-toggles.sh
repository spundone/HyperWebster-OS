#!/bin/sh
# install-appearance-toggles.sh — rounded-corner toggle + continuous appearance CLI.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="${HOME}/.local/bin"
LAYER="${HOME}/.local/share/hyperwebster/appearance-toggles"

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

install -d -m755 "$BIN" "$LAYER"
hw_install_file "$HERE/hyperwebster-rounding-toggle" "$BIN/hyperwebster-rounding-toggle" 0755
hw_install_file "$HERE/hyperwebster-appearance" "$BIN/hyperwebster-appearance" 0755
hw_install_file "$HERE/rounding-tokens.json" "$LAYER/rounding-tokens.json" 0644
hw_install_file "$HERE/README.md" "$LAYER/README.md" 0644

echo "appearance-toggles: hyperwebster-rounding-toggle {enable|disable|toggle|status}"
echo "appearance-toggles: hyperwebster-appearance {get|set|preset|status-json|ensure-rounding}"
