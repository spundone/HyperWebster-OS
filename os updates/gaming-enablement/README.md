# gaming-enablement — multilib repo + omarchy-pkg-add shim

Makes Omarchy-targeted Steam/gaming install scripts (e.g. **DeckShift**) work on
HyperWebster. Two gaps were blocking them:

1. **`[multilib]` was disabled** in `/etc/pacman.conf` — the 32-bit repo every
   `lib32-*` package (Steam, Wine, gaming libs) lives in. Without it, pacman/yay
   can't see those packages at all.
2. **`omarchy-pkg-add` doesn't exist** on HyperWebster — it ships `yay`/Shelly, not the
   Omarchy CLI helpers, so scripts die at `omarchy-pkg-add: command not found`.

## What it does

- Uncomments the `[multilib]` block in `/etc/pacman.conf` (leaving
  `[multilib-testing]` alone) and runs `pacman -Sy`.
- Installs **Omarchy CLI shims** → `~/.local/bin` (HyperWebster ships yay + the
  caelestia launcher, not the Omarchy helpers DeckShift expects):

  | Shim | HyperWebster behaviour |
  |------|------------------|
  | `omarchy-pkg-add` | `yay -S --needed --noconfirm "$@"` (idempotent installs) |
  | `omarchy-install-gaming-steam` | `yay -S steam` + best-effort first launch (needs multilib) |
  | `omarchy-hw-nvidia-gsp` | exit 0 if an NVIDIA GPU is present (modern/GSP branch) |
  | `omarchy-hw-nvidia-without-gsp` | exit 1 (defaults to modern branch; see note) |
  | `omarchy-restart-walker` | no Walker here — refresh desktop DB, succeed |

  The NVIDIA shims default any present card to the modern (`nvidia-utils`)
  branch; pre-Turing cards need `nvidia-580xx-*` by hand. On this AMD+Intel box
  both correctly report "no NVIDIA".

## Install

```sh
sh install-gaming-enablement.sh     # needs sudo for the pacman.conf edit + sync
```

After this, `./deckshift.sh` (and similar) find their deps and proceed. Note:
DeckShift also *optionally* calls `omarchy-install-gaming-steam`,
`omarchy-hw-nvidia-gsp`, `omarchy-restart-walker` — those are `command -v`-guarded
in the script, so they're skipped harmlessly (only `omarchy-pkg-add` was fatal).

## Builder notes

For a gaming-capable ISO:
- **Enable `[multilib]` in the image's `/etc/pacman.conf` by default** (uncomment
  the two lines) and sync in the build.
- **Ship `omarchy-pkg-add`** in `~/.local/bin` (or `/usr/local/bin`). Consider
  shipping the other commonly-referenced Omarchy helpers
  (`omarchy-install-gaming-steam`, `omarchy-hw-nvidia-*`, `omarchy-restart-walker`)
  as shims if broad Omarchy-script compatibility is wanted.
- This pairs naturally with shipping `gamemode` / `lib32-*` Steam deps in the
  base if gaming is a first-class use case.

This is a **package/repo-config delta** (unlike the other changes) — it touches
the package list / pacman.conf rather than dropping a self-contained component.
