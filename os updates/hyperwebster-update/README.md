# HyperWebster - update mechanism (`hyperwebster-update`)

HyperWebster ships a forward-only migration system modeled on Omarchy's `omarchy-update`.

## The model

| Concern | How it's handled |
|---------|------------------|
| Official + AUR packages | `hyperwebster-update` runs `pacman -Syu` via an AUR helper (bootstraps **yay** if none is installed) |
| Safety | Takes a **snapper** snapshot first (when btrfs/snapper is present) |
| The HyperWebster layer | **Pulled from GitHub** (`main` branch) into `~/.local/share/hyperwebster/`, then **forward-only migrations** call each component installer |
| Caelestia dotfiles | Opt-in `--caelestia` (upstream git remote); off by default |
| Offline / ISO snapshot | `--no-pull` skips the GitHub fetch |

## Layout

```
hyperwebster-update/
├── bin/hyperwebster-update            # the command
├── bin/pull-layer.sh                  # GitHub layer refresh (also: hyperwebster-layer-pull)
├── migrations/                        # forward-only, timestamped, idempotent
└── install-hyperwebster-update.sh     # populates ~/.local/share/hyperwebster + PATH symlinks
```

`install-hyperwebster-update.sh` copies the HyperWebster sources from a dev checkout to
`~/.local/share/hyperwebster/`. On the ISO the same tree is baked from
`hyperwebster-layer.tar.gz` at install time.

## Migrations

A migration is a timestamped `*.sh` file. `hyperwebster-update` runs every migration
whose name is not yet recorded in `~/.local/state/hyperwebster/applied`, then records
it. They run with `HYPERWEBSTER_SRC` / `HYPERWEBSTER_LAYER` pointing at the layer root.
Each must be **idempotent** (safe to re-run).

**Adding a change:** drop the component (with its installer) into the tree, add a new
`migrations/<epoch>-<name>.sh`, and add the component to `install-hyperwebster-update.sh`.

## Usage

```sh
hyperwebster-update                              # pull layer + snapshot + packages + migrations
hyperwebster-update -y                           # non-interactive
hyperwebster-update --pull-only -y               # layer refresh + migrations only
hyperwebster-update --no-packages --no-snapshot  # migrations only (no pull unless you omit --no-pull)
hyperwebster-update --no-pull                    # offline: packages + migrations against local layer
hyperwebster-layer-pull                          # refresh ~/.local/share/hyperwebster only
hyperwebster-update --caelestia                  # also git-pull the Caelestia dotfiles
```

Layer source URL: `~/.config/hyperwebster/layer-source.conf` or `HYPERWEBSTER_LAYER_URL`.

Version stamp: `~/.local/state/hyperwebster/layer-version`

After migrations that touch the shell, restart: **Ctrl+Super+Alt+R**.

## First-time install (dev checkout)

```sh
sh ~/Downloads/hyperwebster-update/install-hyperwebster-update.sh
hyperwebster-update --pull-only -y
```

## Requirements

`bash`, `curl`, `tar`, `sudo`, `git`, `base-devel` (for yay bootstrap), and `snapper`
(optional, for snapshots). `rsync` recommended for clean layer sync.
