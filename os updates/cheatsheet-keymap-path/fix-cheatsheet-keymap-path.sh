#!/bin/sh
# fix-cheatsheet-keymap-path.sh — idempotent. User-level (no root).
#
# The Super+K cheatsheet generator resolves its keymap doc from
# $HOME/Downloads/HyperWebster-keybindings.md *before* the canonical
# $HOME/.local/share/hyperwebster/HyperWebster-keybindings.md. A stale copy left in
# ~/Downloads would silently shadow the real keymap. The hyperwebster-keybinds
# header comment also still claims the doc lives in ~/Downloads.
#
# Fix: drop the ~/Downloads candidate from hyperwebster-keybinds-gen (the $1 arg and
# $HYPERWEBSTER_KEYMAP_MD env override remain for dev use), and correct the comment.
# Edits the real files behind the ~/.local/bin symlinks. Re-runnable.
set -eu

resolve() { command -v "$1" >/dev/null 2>&1 && readlink -f -- "$(command -v "$1")"; }
GEN=$(resolve hyperwebster-keybinds-gen || true)
NK=$(resolve hyperwebster-keybinds || true)

# 1. hyperwebster-keybinds-gen: remove the ~/Downloads candidate line.
if [ -n "${GEN:-}" ] && grep -q 'Downloads/HyperWebster-keybindings.md' "$GEN"; then
  tmp=$(mktemp)
  awk '
    /for cand in "\$HOME\/Downloads\/HyperWebster-keybindings\.md"/ { print "  for cand in \\"; next }
    { print }
  ' "$GEN" > "$tmp"
  # sanity: canonical path still present, Downloads gone, still parses
  if grep -q '\.local/share/hyperwebster/HyperWebster-keybindings.md' "$tmp" \
     && ! grep -q 'Downloads/HyperWebster-keybindings.md' "$tmp" \
     && sh -n "$tmp" 2>/dev/null; then
    cat "$tmp" > "$GEN"; echo "patched: $GEN (dropped ~/Downloads candidate)"
  else
    echo "WARN: gen rewrite failed sanity — left $GEN untouched" >&2
  fi
  rm -f "$tmp"
else
  echo "hyperwebster-keybinds-gen already canonical (or not found) — skipped"
fi

# 2. hyperwebster-keybinds: fix the header comment path.
if [ -n "${NK:-}" ] && grep -q '~/Downloads/HyperWebster-keybindings.md' "$NK"; then
  sed -i 's#~/Downloads/HyperWebster-keybindings.md#~/.local/share/hyperwebster/HyperWebster-keybindings.md#g' "$NK"
  echo "patched: $NK (comment path corrected)"
else
  echo "hyperwebster-keybinds comment already correct (or not found) — skipped"
fi

# refresh the cached cheatsheet list so the change takes effect immediately
[ -n "${GEN:-}" ] && "$GEN" > "$HOME/.local/share/hyperwebster/keybinds.list.tmp" 2>/dev/null \
  && mv "$HOME/.local/share/hyperwebster/keybinds.list.tmp" "$HOME/.local/share/hyperwebster/keybinds.list" 2>/dev/null || true

echo "cheatsheet-keymap-path: ok"
