# deckshift-login - full-session DeckShift gaming, password at boot

Keeps DeckShift's gaming model exactly as designed - a **dedicated, full
gamescope session** (`gamescope-session-steam-nm`), switched by rewriting
SDDM's autologin session and restarting SDDM - but fixes the login behaviour:

| Event | Stock DeckShift | With this component |
|-------|-----------------|---------------------|
| Cold boot | autologin, no password ever | **normal SDDM password login** |
| Desktop → Gaming (`Super+Shift+S`) | autologin into gaming session | same (one-shot autologin) |
| Gaming → Desktop (`Super+Shift+R` / Steam > Exit to Desktop) | autologin back to desktop | same (one-shot autologin) |
| SDDM crash / manual restart | autologin | password login |

## How it works

Stock DeckShift keeps a **permanent** `[Autologin]` drop-in
(`/etc/sddm.conf.d/zz-gaming-session.conf`, `Relogin=true`) and its
`gaming-session-switch` helper just flips the `Session=` line - so the box
never shows a password screen again.

This component makes the autologin **one-shot**:

- `gaming-session-switch` (drop-in replacement, same path + interface, so
  DeckShift's `switch-to-gaming` / `switch-to-desktop` / `os-session-select`
  and the existing sudoers rule keep working) writes the autologin drop-in
  fresh on each switch (`Relogin=false`) **and arms a marker in `/run`**.
- `sddm-autologin-gate` runs as `ExecStartPre=` on `sddm.service` (systemd
  drop-in): marker present → consume it, keep the autologin for that single
  restart; marker absent (cold boot, crash, manual restart - `/run` is tmpfs)
  → delete the autologin drop-in, password greeter shows.

Also adds the `Super+Shift+S → /usr/local/bin/switch-to-gaming` Hyprland bind:
DeckShift appends its bind to `~/.config/hypr/bindings.conf`, an **Omarchy**
path that doesn't exist on caelestia, so on this system DeckShift silently
skips the keybind - this component adds it to
`~/.config/caelestia/hypr-user.conf` instead (replacing caelestia's
`Super+Shift+S` screenshot-freeze; region shots stay on
Print / Shift+Print / Super+Shift+Alt+S). No exit bind is needed on the
desktop side: exiting happens inside the gaming session (DeckShift's evdev
keybind monitor handles `Super+Shift+R`, and Steam > Power > Exit to Desktop
calls `/usr/lib/os-session-select`).

## Files

```
gaming-session-switch        -> /usr/local/bin/   (replaces DeckShift's; root 755)
switch-to-desktop            -> /usr/local/bin/   (replaces DeckShift's; root 755)
sddm-autologin-gate          -> /usr/local/bin/   (root 755)
deckshift-autologin-gate.conf-> /etc/systemd/system/sddm.service.d/
os-session-select            -> /usr/lib/         (DeckShift's original, restored
                                                   if something overwrote it)
install-deckshift-login.sh      idempotent installer (needs sudo)
```

**`deckshift.sh` itself is never modified** - this component only overlays
files that deckshift.sh has already installed (same paths, same interfaces,
the existing sudoers rules keep applying). That is the contract: the ISO
mimics Omarchy's SDDM setup, stock DeckShift installs onto it unchanged, and
this overlay is applied after it.

**Why `switch-to-desktop` is overlaid too**: DeckShift's original pkills gamescope *before* its final
`systemctl restart sddm`. Killing gamescope ends the login session, and
logind then kills the session's processes - including the script itself (it
runs inside the gaming session, launched by the keybind monitor) - so the
restart never executes. Stock DeckShift survives this because its permanent
`Relogin=true` autologin re-logs the user in anyway; with one-shot autologin
it stranded the user at the greeter. The overlay keeps all of DeckShift's
cleanup (power-profile restore, suspend unmask, Bluetooth, portal marker,
Steam shutdown) but queues the SDDM restart as a detached root job - the
same pattern DeckShift's own `os-session-select` uses, which is why Steam's
"Exit to Desktop" worked all along - and lets the service stop tear down
gamescope.

The installer also **removes the withdrawn nested gaming-mode experiment**
(`hyperwebster-gaming-mode*` scripts, its launcher entry, and its
`# >>> gaming-mode (nested) >>>` bind block) if the box ever had it.

## Install (opt-in, post-install - in this order)

```sh
# 1. DeckShift first (gaming session, switch scripts, sudoers, keybind monitor)
sh ~/deckshift/deckshift.sh
# 2. then the login fix
sh ~/.local/share/hyperwebster/deckshift-login/install-deckshift-login.sh
```

**Re-run step 2 after any re-run of `deckshift.sh`** - deckshift.sh restores
its permanent-autologin `gaming-session-switch` and recreates the standing
autologin drop-in.

## Test

1. Reboot → SDDM **password** prompt (session: "Hyprland (uwsm-managed)").
2. `Super+Shift+S` → screen flickers (VT switch + SDDM restart) → Steam Big
   Picture in a full gamescope session. No password asked.
3. Steam > Power > Exit to Desktop (or `Super+Shift+R`) → back to the Hyprland
   desktop. No password asked.
4. Reboot again → password prompt is back (the switch autologin didn't stick).
5. `sudo systemctl restart sddm` from the desktop → password prompt (gate
   cleans up; nothing autologins outside a real switch).

## Known quirks

- SDDM remembers the **last session** per user, so after a reboot from inside
  Gaming Mode the greeter may preselect "Gaming Mode (ChimeraOS)" - pick
  "Hyprland (uwsm-managed)" from the session menu.
- The switch necessarily restarts the whole graphical session: open desktop
  apps close when entering Gaming Mode. That is inherent to DeckShift's
  full-session design (and why it works better for games than a nested
  window: gamescope owns the display, HDR/VRR/input pass through cleanly).

## Builder notes - how to put this in the ISO (opt-in, NOT pre-enabled)

1. **Bake the Omarchy-style SDDM setup - REQUIRED.** DeckShift's
   switching is built on SDDM; the ISO must boot to an SDDM password greeter
   with `hyprland-uwsm` as the default session and **no autologin baked**.
2. Copy `deckshift-login/` into the layer (lands at
   `~/.local/share/hyperwebster/deckshift-login/`) + the copy-list line in
   `hyperwebster-update/install-hyperwebster-update.sh`:
   ```sh
   [ -d "$SRC/deckshift-login" ] && cp -a "$SRC/deckshift-login" "$DEST/"
   ```
3. Ship migration `1781395200-deckshift-login.sh` as-is - it is
   **conditional**: it only (re-)applies where DeckShift is actually installed
   (`/usr/local/bin/switch-to-gaming` exists), so `hyperwebster-update` keeps
   opted-in boxes patched and is a no-op everywhere else.
4. Do **NOT** run deckshift.sh or this installer at build time, do **NOT**
   bake the `# >>> deckshift gaming keys >>>` block into the shipped
   `hypr-user.conf`, and do **NOT** bake steam/gamescope/DeckShift packages.
   Gaming stays opt-in: the user runs `deckshift.sh` then this installer.
5. Prerequisites already in the base: `[multilib]` + the `omarchy-*` shims
   (gaming-enablement) - deckshift.sh depends on both.
6. Drop the withdrawn `gaming-mode/` (nested) component entirely if any copy
   is still in the builder tree; this component supersedes it.
7. Document in `HyperWebster-keybindings.md`: `Super+Shift+S` = Gaming Mode
   **only after opting in** (until then it stays caelestia's
   screenshot-freeze); `Super+Shift+R` works inside Gaming Mode only.
8. Verify on a clean VM: install → password login; run deckshift.sh + this
   installer → switch in/out of Gaming Mode with no password; reboot →
   password login is back.
