# display-manager-sddm — switch greetd → SDDM (for DeckShift gaming mode)

DeckShift's desktop↔gaming-mode switching is built on **SDDM**: `switch-to-gaming`
rewrites SDDM's config to point at the Gamescope/Steam session and restarts SDDM
to auto-log into it (and back). HyperWebster ships **greetd + tuigreet**, which has no
equivalent, so this change replaces the display manager with SDDM.

## What it does

- Installs `sddm` (+ `xorg-server` for the reliable X11 greeter — the Hyprland
  **session** stays Wayland; only SDDM's greeter uses X).
- Installs `/etc/sddm.conf.d/10-hyperwebster.conf` (X11 greeter, Numlock on, notes on
  the preferred session).
- Disables `greetd.service`, enables `sddm.service`. **Takes effect on reboot.**

## Critical: preserve the uwsm session

greetd launched Hyprland via uwsm:
`uwsm start -e -D Hyprland hyprland.desktop`. The matching session entry is
**`/usr/share/wayland-sessions/hyprland-uwsm.desktop`** ("Hyprland
(uwsm-managed)"). Under SDDM, pick **that** session, not plain
`hyprland.desktop` (which runs `start-hyprland` directly and loses the
uwsm/systemd-managed session caelestia relies on). SDDM remembers the last
session per user.

## Install (live)

```sh
sh install-display-manager-sddm.sh     # sudo; reboot afterwards
```

To revert: `sudo systemctl disable sddm; sudo systemctl enable greetd`.

## Builder notes — display-manager swap (package + service delta)

This is **not** a no-delta change. For the ISO:

- **Packages:** add `sddm` (+ `xorg-server` if using the X11 greeter, OR `weston`
  if using the Wayland greeter — pick one). Remove `greetd`, `greetd-tuigreet`,
  `greetd-agreety` from the image package list (or keep as fallback).
- **Services:** enable `sddm.service` instead of `greetd.service` in the image.
- **Greeter display server (decision):**
  - *X11 greeter* (this component's default): most reliable, but adds
    `xorg-server` to an otherwise Wayland-only image.
  - *Wayland greeter*: keeps the image X-free — set `DisplayServer=wayland` +
    `[Wayland] CompositorCommand=weston --shell=kiosk` and add `weston`.
- **Session default:** ensure `hyprland-uwsm.desktop` is the preferred desktop
  session (uwsm launch — matches the old greetd `--cmd`). Don't let plain
  `hyprland.desktop` win.
- **Login behaviour:** greetd here did **not** autologin (tuigreet prompts).
  SDDM keeps a password prompt unless `[Autologin]` is set. DeckShift configures
  its own autologin/session entries on top — let it.
- **DeckShift autologin (interaction to know about):** DeckShift writes
  `/etc/sddm.conf.d/zz-gaming-session.conf` with `[Autologin] User=… /
  Session=hyprland-uwsm / Relogin=true`. Once DeckShift runs, this **overrides
  the password prompt** — the box boots straight into the desktop, and the
  desktop↔gaming switch flips `Session=` then restarts SDDM (autologin, no
  greeter). That's the intended Steam-Deck-style behaviour. If the ISO wants a
  password on normal boots, ship a higher-priority SDDM drop-in or adjust
  DeckShift's `gaming-session-switch` to only autologin while in gaming mode.
- Pairs with gaming-enablement (multilib + omarchy-pkg-add). Together
  these two make HyperWebster DeckShift/Steam-Deck capable.
- The base's plymouth/limine boot splash is unaffected.
