# sddm-theme - login screen matching the desktop (palette, wallpaper, font)

A small Qt6 QML SDDM greeter theme ("caelestia") that mirrors the desktop:

- **Colours** come from the caelestia Material scheme
  (`~/.local/state/caelestia/scheme.json`) - surface card, primary login
  button, error colour, all from the live palette.
- **Background** is the user's current wallpaper (copied into the theme -
  the greeter runs as the `sddm` user and cannot read the user's home).
- **Font** is the exact font the shell uses: **Google Sans Flex**, loaded by
  file path from the shell's bundled asset
  (`/etc/xdg/quickshell/caelestia/assets/google-sans-flex/…ttf`), falling
  back to **Rubik** (system-installed) if that file moves.

Layout: big clock + date, centered card with username/password, primary
"Log in" button, a session cycler line ("Session: … ⟳", click to cycle),
and Sleep/Restart/Shut down text buttons bottom-right (only shown when SDDM
reports the action is allowed). Pure QtQuick - no QtQuick.Controls styles,
no SddmComponents, so there are no style dependencies to break.

**Gaming sessions are hidden from the greeter.** Gaming Mode is entered from
the desktop only (`Super+Shift+S` → DeckShift switch); logging
into a gamescope session from the login screen would bypass that flow. The
cycler filters out any session matching `gaming|gamescope|steam|big picture`
(covers "Gaming Mode (ChimeraOS)" and both "Steam Big Picture" entries), and
if SDDM's remembered last session is a gamescope one (it is, right after a
reboot from Gaming Mode) the selection snaps to the first desktop session
instead of preselecting it.

## Files

```
caelestia/Main.qml          the theme (pure QtQuick, Qt6)
caelestia/metadata.desktop  theme metadata (QtVersion=6)
caelestia/theme.conf        default colours = foam-sea scheme
sddm-theme-sync             -> /usr/local/bin (root): regenerates theme.conf +
                            background from the live scheme/wallpaper
install-sddm-theme.sh       idempotent installer (needs sudo)
```

Theme installs to `/usr/share/sddm/themes/caelestia`; selected via the
drop-in `/etc/sddm.conf.d/20-sddm-theme.conf` (`[Theme] Current=caelestia`).
Remove that drop-in to fall back to SDDM's default greeter.

## Install / test

```sh
sh install-sddm-theme.sh          # installs + runs the initial sync (sudo)
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/caelestia   # preview, no logout
sudo sddm-theme-sync              # re-sync after changing wallpaper
```

Verified in test mode on the box (renders correctly, no QML errors).

## Keeping it in sync with wallpaper changes

The greeter is a snapshot: it matches the scheme as of the last
`sddm-theme-sync`. The installer runs one sync; after the user changes
wallpaper the login screen keeps the old look until `sudo sddm-theme-sync`
is run again. Good follow-up for the builder: hook the sync into the
wallpaper-change path (e.g. a polkit-less systemd path unit watching the
scheme state file, or a sudoers rule + caelestia hook) - left out here to
keep the component simple and safe.

## Builder notes - how to put this in the ISO

1. Integrate the standard way: component → layer
   (`~/.local/share/hyperwebster/sddm-theme/`), migration
   `1781398800-sddm-theme.sh` → `hyperwebster-update/migrations/`, copy-list line:
   ```sh
   [ -d "$SRC/sddm-theme" ] && cp -a "$SRC/sddm-theme" "$DEST/"
   ```
2. **Bake the theme into the image** (this one IS applied at build time,
   unlike the opt-in Gaming Mode): theme dir to `/usr/share/sddm/themes/caelestia`, sync
   script to `/usr/local/bin/`, the `20-sddm-theme.conf` drop-in to
   `/etc/sddm.conf.d/`.
3. **Seed the background at build time**: copy the default wallpaper
   (foam-sea.png) to
   `/usr/share/sddm/themes/caelestia/backgrounds/wallpaper.png`. The shipped
   `theme.conf` already carries the foam-sea palette, so the greeter matches
   the default desktop on first boot before any user sync has run.
4. The theme requires the caelestia shell's Google Sans Flex asset path; if
   the shell tree moves under the project rename, update `fontFile=` in
   `theme.conf` (sync script too) - Rubik fallback covers any breakage.
5. No package delta (qt6 QML comes with sddm; `jq` already in base).
6. Verify on a clean VM: first boot greeter = foam-sea background, Material
   card, Google Sans font; change wallpaper in the desktop → run
   `sudo sddm-theme-sync` → greeter follows.
