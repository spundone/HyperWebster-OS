# HyperWebster — update mechanism (`hyperwebster-update`)

HyperWebster had no update path. This adds one, modeled on Omarchy's `omarchy-update`
but adapted to the fact that **there is no central HyperWebster git repo**.

## The model

| Concern | How it's handled |
|---------|------------------|
| Official + AUR packages | `hyperwebster-update` runs `pacman -Syu` via an AUR helper (bootstraps **yay** if none is installed — the base currently ships none) |
| Safety | Takes a **snapper** snapshot first (btrfs is present) |
| The HyperWebster layer (overrides/scripts) | Re-applied idempotently by **forward-only migrations** — each migration just calls a component's installer |
| Caelestia dotfiles | Opt-in `--caelestia` (its repo has an upstream remote); off by default to avoid clobbering local overrides |
| **New layer changes** | Delivered in a **new ISO** (rebuilt from these notes) — there is no live fetch channel. A running box stays current on packages and re-applies the layer; it gets *new* layer features by reinstalling. |

## Layout

```
hyperwebster-update/
├── bin/hyperwebster-update            # the command
├── migrations/                  # forward-only, timestamped, idempotent
│   ├── 1781049600-keybind-help.sh       -> install-keybinds-help.sh
│   ├── 1781053200-fish-to-bash.sh       -> fish-to-bash/install-fish-to-bash.sh
│   ├── 1781222400-software-install.sh   -> software-install/install-software-install.sh
│   ├── 1781226000-omarchy-keys.sh       -> omarchy-keys/install-omarchy-keys.sh
│   ├── 1781229600-omadots-extras.sh     -> omadots-extras/install-omadots-extras.sh
│   ├── 1781233200-monitor-control.sh    -> monitor-control/install-monitor-control.sh
│   ├── 1781236800-updates-panel.sh      -> updates-panel/install-updates-panel.sh
│   └── 1781240400-system-polish.sh      -> system-polish/install-system-polish.sh
└── install-hyperwebster-update.sh     # populates ~/.local/share/hyperwebster + PATH symlink
```

`install-hyperwebster-update.sh` copies the HyperWebster sources from this Downloads tree to
`~/.local/share/hyperwebster/` (the on-system "repo") and symlinks `hyperwebster-update` into
`~/.local/bin`. On the real ISO the build process bakes the same tree to the
same path, so the command works identically.

## Migrations

A migration is a timestamped `*.sh` file. `hyperwebster-update` runs every migration
whose name isn't yet recorded in `~/.local/state/hyperwebster/applied`, then records
it. They run with `HYPERWEBSTER_SRC` pointing at the repo root so they can call the
component installers. Each must be **idempotent** (safe to re-run).

**Adding a change:** drop the component (with its installer) into the HyperWebster
tree, add a new `migrations/<epoch>-<name>.sh` that calls its installer, and add
the component to the `COMPONENTS` list in `install-hyperwebster-update.sh`.

## Usage

```sh
hyperwebster-update                              # snapshot + full package upgrade + layer
hyperwebster-update -y                           # non-interactive
hyperwebster-update --no-packages --no-snapshot  # re-apply the HyperWebster layer only
hyperwebster-update --caelestia                  # also git-pull the Caelestia dotfiles
```

## First-time install (or after an ISO rebuild)

```sh
sh ~/Downloads/hyperwebster-update/install-hyperwebster-update.sh
hyperwebster-update --no-packages --no-snapshot   # apply the layer without touching packages
```

## Requirements

`bash`, `sudo`, `git`, `base-devel` (for the yay bootstrap), and `snapper`
(optional, for snapshots).
