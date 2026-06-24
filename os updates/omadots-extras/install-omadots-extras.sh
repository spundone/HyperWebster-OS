#!/bin/sh
# install-omadots-extras.sh — developer polish from omadots.
# Cherry-picked configs from https://github.com/omacom-io/omadots (the Omarchy
# team's shared dotfiles), adapted to layer cleanly on HyperWebster:
#
#   starship.toml      -> ~/.config/starship.toml   (replaces Caelestia symlink)
#   tmux.conf          -> ~/.config/tmux/tmux.conf
#   btop.conf          -> ~/.config/btop/btop.conf  (replaces Caelestia symlink)
#   omadots.gitconfig  -> ~/.config/git/ + git include.path (identity untouched)
#   LazyVim starter    -> ~/.config/nvim            (ONLY if absent — never rm -rf)
#
# Unlike omadots' own install.sh, nothing here overwrites ~/.bashrc or deletes
# an existing nvim config. Safe to re-run (idempotent).
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# install_cfg <source> <dest>: skip if identical; back up a real file once;
# replace a Caelestia symlink outright (re-linking it restores stock).
install_cfg() {
  src="$1"; dest="$2"
  if [ -e "$dest" ] && cmp -s "$src" "$dest"; then
    echo ":: $(basename "$dest") already in place"
    return 0
  fi
  if [ -L "$dest" ]; then
    rm "$dest"                      # Caelestia symlink — don't write through it
  elif [ -f "$dest" ] && [ ! -e "$dest.pre-omadots" ]; then
    cp "$dest" "$dest.pre-omadots"
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo ":: installed $(basename "$dest")"
}

# btop: ~/.config/btop may be a symlinked DIRECTORY into the Caelestia repo.
if [ -L "$HOME/.config/btop" ]; then
  rm "$HOME/.config/btop"
  mkdir -p "$HOME/.config/btop"
fi

install_cfg "$SRC/starship.toml" "$HOME/.config/starship.toml"
install_cfg "$SRC/tmux.conf"     "$HOME/.config/tmux/tmux.conf"
install_cfg "$SRC/btop.conf"     "$HOME/.config/btop/btop.conf"

# Git: behaviors + aliases via include; the user's identity/overrides stay in
# their own global config.
install_cfg "$SRC/omadots.gitconfig" "$HOME/.config/git/omadots.gitconfig"
if git config --global --get-all include.path 2>/dev/null | grep -q 'omadots.gitconfig'; then
  echo ":: git include already configured"
else
  git config --global include.path "$HOME/.config/git/omadots.gitconfig"
  echo ":: added git include.path -> omadots.gitconfig"
fi

# LazyVim (omadots' nvim setup) — only into an empty slot, never over an
# existing config (omadots' own installer does rm -rf here; we don't).
if [ -e "$HOME/.config/nvim" ]; then
  echo ":: ~/.config/nvim exists — leaving it alone"
else
  git clone --depth 1 https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
  echo ":: installed LazyVim starter"
fi

echo "Done. Deps to have installed: starship, tmux, btop, neovim, fzf, bat, eza, zoxide."
