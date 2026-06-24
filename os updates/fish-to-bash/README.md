# HyperWebster - fish → bash migration (Omarchy bash setup)

Switches this Caelestia/HyperWebster box from the fish shell to **bash, configured to
match [Omarchy](https://github.com/basecamp/omarchy)**. Self-contained so it
survives a wipe - copy this folder back with the rest of Downloads and run the
installer.

## Install

```sh
sh ~/Downloads/fish-to-bash/install-fish-to-bash.sh
```

Idempotent. Open a **new** terminal afterwards to land in bash.

## What it does

| Step | Effect |
|------|--------|
| Vendor `bash/` tree | Copied verbatim from Omarchy to `~/.local/share/omarchy/default/bash/` (`rc`, `shell`, `aliases`, `envs`, `init`, `functions`, `inputrc`, `completions`, `fns/*`) |
| `~/.bashrc` | Omarchy's template; sources the tree above. Existing `~/.bashrc` backed up to `~/.bashrc.pre-omarchy` |
| kitty | `~/.config/kitty/kitty.conf`: `shell fish` → `shell bash` |
| foot | `~/.config/foot/foot.ini`: `shell=fish` → `shell=bash` |
| Hyprland helpers | `wsaction.fish` & `configs.fish` replaced with bash ports (same filenames, bash shebang) so the stock keybinds keep working |

## Why the layout matches Omarchy exactly

The vendored files are byte-for-byte Omarchy and live at Omarchy's own path
(`~/.local/share/omarchy/...`). That means: (a) the prompt/aliases/history/
completion behaviour is identical to Omarchy, and (b) you can refresh them from
upstream by re-copying `default/bash/` with no edits. `envs` sets
`OMARCHY_PATH` and prepends `~/.local/bin` to `PATH` (so the keybind-help
scripts resolve too). References to omarchy-only tools (`omarchy`, `mise`,
`opencode`, `tdl`, `gum`, …) are all guarded with `command -v` or are function
definitions, so missing tools are harmless until you actually call them.

## HyperWebster-specific additions (the only deviations from stock Omarchy)

- `~/.bashrc` exports `EDITOR=nvim` if unset (Omarchy sets this in `uwsm/env`,
  which we don't manage here).
- `~/.bashrc` runs `cat ~/.local/state/caelestia/sequences.txt` so the terminal
  picks up Caelestia's dynamic colour scheme.

## Notes / things that changed from the old fish config

- **`ga` / `gd` now mean Omarchy's git-worktree helpers**, not the old fish
  abbreviations (`git add .` / `git diff`). Other git shortcuts: `g`, `gcm`,
  `gcam`, `gcad`.
- **direnv** was hooked in the old fish config; Omarchy's bash doesn't include
  it. Add `eval "$(direnv hook bash)"` to the bottom of `~/.bashrc` if you want
  it back.
- The **fish package is left installed** (it may be pulled in as a Caelestia
  dependency). Nothing interactive uses it anymore. Remove it only after
  confirming nothing else needs it: `sudo pacman -Rns fish`.
- The fish config dir (`~/.config/fish`, a Caelestia symlink) is left in place
  but unused.

## Requirements

`bash`, and ideally `starship`, `zoxide`, `eza`, `fzf`, `bat` for the full
Omarchy experience (all guarded - bash works without them).
