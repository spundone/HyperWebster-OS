# HyperWebster - omadots developer polish

Cherry-picked configs from [omadots](https://github.com/omacom-io/omadots)
- the Omarchy team's shared personal
dotfiles. **Not** part of the Omarchy distro itself; this is the layer the
Omarchy people run on top of it. Complements their bash setup and
their keybindings.

## What's vendored (verbatim)

| File | Installs to | What it gives |
|------|-------------|----------------|
| `starship.toml` | `~/.config/starship.toml` | minimal cyan prompt: dir + git branch/status |
| `tmux.conf` | `~/.config/tmux/tmux.conf` | Ctrl+Space prefix, vi copy-mode, Alt+1-9 windows, Alt+Enter splits, top status bar |
| `btop.conf` | `~/.config/btop/btop.conf` | their btop look (6 lines, TTY theme) |
| `omadots.gitconfig` | `~/.config/git/omadots.gitconfig` | git aliases (`co`,`br`,`ci`,`st`) + sane behaviors: `pull.rebase`, `push.autoSetupRemote`, histogram diffs, `rerere`, branch/tag sorting. **Contains no user identity** - wired in via `git config --global include.path`, so the user's own `.gitconfig` stays theirs |
| (cloned at install) | `~/.config/nvim` | LazyVim starter - omadots' nvim setup |

## Deliberate adaptations vs omadots' own install.sh

Their installer is destructive; ours is not:

- **No `~/.bashrc` overwrite** - the HyperWebster bashrc (Omarchy bash + Caelestia
  colour-scheme line) stays. We skip omadots' `~/.config/shell/` tree entirely:
  it's the same content we already vendored from Omarchy's `default/bash`,
  minus aliases that assume their stack (opencode, codex, tdl, mise, try).
- **No `rm -rf ~/.config/nvim`** - LazyVim is installed only if no nvim config
  exists.
- **Caelestia symlinks handled**: on HyperWebster, `~/.config/starship.toml` and
  `~/.config/btop` are symlinks into `~/.local/share/caelestia/`. The installer
  removes the symlink and installs a real file (writing *through* the symlink
  would dirty the Caelestia git clone). Re-creating the symlink restores stock.
- Skipped: `mise` config (mise not shipped), `opencode.json` (opencode not
  shipped), `shell/` (covered by the HyperWebster bash setup).

## Install

```sh
sh ~/Downloads/omadots-extras/install-omadots-extras.sh
```

Idempotent; backs up any pre-existing real config once to `*.pre-omadots`.
Also wired into `hyperwebster-update` as migration `1781229600-omadots-extras.sh`.

## Packaging

Add to the package list: **tmux, neovim, fzf, bat, zoxide** (currently missing
on the base) - starship, btop, eza are already present. These also satisfy
the HyperWebster bash setup's "ideally" deps. Bake the four config files to the same paths and
pre-clone LazyVim starter (without `.git`) into the skeleton, or just run this
installer post-install.
