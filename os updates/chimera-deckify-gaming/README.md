# chimera-deckify-gaming - gamescope Steam Big Picture session

Installs a **Steam Big Picture / gamescope** session on HyperWebster.

## Package choice (important)

HyperWebster enables CachyOS repos. Prefer:

| Stack | Packages |
|-------|----------|
| **CachyOS (default)** | `gamescope-session-cachyos` → `/usr/share/wayland-sessions/gamescope-session.desktop` |
| Chimera AUR fallback | `gamescope-session-git` + `gamescope-session-steam-git` |

`gamescope-session-git` **conflicts** with `gamescope-session-cachyos`. The
installer never installs both. If you previously saw:

```text
gamescope-session-git and gamescope-session-cachyos are in conflict
```

re-run `hyperwebster-deckify-install` (or Additions → Deckify / Chimera) - it
keeps CachyOS and skips the AUR -git session packages.

## Quick install

Settings → Additions → **Deckify / Chimera Gaming**, or:

```sh
hyperwebster-deckify-install
```

## Starman / Limine boot

Pick **Starman (Gaming / Steam)** in Limine. `hyperwebster.starman=1` arms
one-shot SDDM autologin into the detected gamescope session
(`gamescope-session`, `gamescope-session-steam-nm`, or `gamescope-session-steam`).

## Switching

`Super+Shift+S` calls `hyperwebster-gaming-session` to find any installed
gamescope desktop, arms one-shot SDDM autologin, then restarts SDDM via
`hyperwebster-restart-sddm` (passwordless through sudoers). Without that
helper / sudoers rule the key appears to do nothing.

## HDR / VRR

`gamescope-hdr.env` ships recommended env vars for amdgpu HDR/VRR on TV
displays. Pair with the `tv-gaming-display` hyprmoncfg profile on the desktop.

## Files

| File | Role |
|------|------|
| `hyperwebster-deckify-install` | User-facing installer (CachyOS or AUR) |
| `hyperwebster-gaming-session` | Resolve installed session desktop name |
| `hyperwebster-restart-sddm` | Passwordless SDDM restart (sudoers-pinned) |
| `gaming-session-switch` | SDDM one-shot autologin helper |
| `install-gaming-sudoers.sh` | NOPASSWD for switch + restart helpers |
| `gamescope-hdr.env` | HDR/VRR environment defaults |

## Credit

- [CachyOS gamescope-session](https://github.com/CachyOS/gamescope-session)
- [Arch Deckify](https://github.com/unlbslk/arch-deckify) / ChimeraOS AUR session packages
