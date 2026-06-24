# chimera-deckify-gaming - ChimeraOS gamescope session (Deckify path)

Installs the **ChimeraOS gamescope session** stack on Arch via the community
AUR PKGBUILDs (`gamescope-session-git`, `gamescope-session-steam-git`).
This is the same session family used by [Arch Deckify](https://github.com/unlbslk/arch-deckify)
and ChimeraOS - not a separate proprietary repo (Chimera ships PKGBUILDs on the
AUR; CachyOS may mirror some packages once online).

## Quick install

Settings → Additions → **Deckify / Chimera Gaming**, or:

```sh
hyperwebster-deckify-install
sh ~/.local/share/hyperwebster/deckshift-login/install-deckshift-login.sh
```

The second step applies the password-at-boot gate (same overlay as DeckShift).

## Starman / Limine boot

Pick **Starman (Gaming / Steam)** in Limine. `hyperwebster.starman=1` arms
one-shot SDDM autologin into the detected gamescope session
(`gamescope-session-steam-nm` or `gamescope-session-steam`).

## DeckShift vs Deckify

| | DeckShift | Deckify / Chimera (this) |
|---|-----------|---------------------------|
| Session | `gamescope-session-steam-nm` | `gamescope-session-steam` |
| Install | `deckshift.sh` git repo | `hyperwebster-deckify-install` (AUR) |
| Switching | Same `gaming-session-switch` | Same helper (auto-detects session) |

Do not install both - pick one gaming stack.

## HDR / VRR

`gamescope-hdr.env` ships recommended env vars for amdgpu HDR/VRR on TV
displays. Pair with the `tv-gaming-display` hyprmoncfg profile on the desktop.

## Files

| File | Role |
|------|------|
| `hyperwebster-deckify-install` | User-facing installer (AUR + switch scripts) |
| `hyperwebster-gaming-session` | Resolve installed session desktop name |
| `gaming-session-switch` | SDDM one-shot autologin helper |
| `gamescope-hdr.env` | HDR/VRR environment defaults |
