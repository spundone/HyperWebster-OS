# app-theme-awareness

User-level, no root.

## Goal
Make external apps (Chrome/Chromium, Electron, Firefox, GTK, Qt) **follow
Caelestia's light/dark mode** automatically - dark when Caelestia is dark.

## Why they don't today
Modern apps read one signal: `org.freedesktop.appearance` → `color-scheme`,
published by **xdg-desktop-portal**. By default that value is **0
("no preference")** because nothing sets it - `gsettings
org.gnome.desktop.interface color-scheme` is `'default'`. So every app defaults
to light. All portal pieces are already installed (`xdg-desktop-portal`,
`-gtk`, `-hyprland`); `libadwaita` is present.

## How this works
- **`hyperwebster-app-theme-sync`**: reads `caelestia scheme get` ("Mode: dark|
  light") and sets:
  - `gsettings org.gnome.desktop.interface color-scheme` → `prefer-dark` /
    `prefer-light`. xdg-desktop-portal-gtk republishes this as the freedesktop
    appearance `color-scheme`, which **Chrome, Electron, Firefox, GTK4/libadwaita
    and Qt6 honor** (UI + web `prefer-color-scheme`).
  - `gtk-application-prefer-dark-theme` in `gtk-3.0`/`gtk-4.0` `settings.ini`
    for legacy GTK3 apps that ignore the portal.
- **`hyperwebster-app-theme.path` + `.service`** (user units, mirroring HyperWebster's
  `hyprmoncfgd-rescan.path`): watch `~/.local/state/caelestia/scheme.json` and
  re-run the sync on every scheme change, and run it once at login. So flipping
  Caelestia light↔dark flips the apps live.
- **`portals.conf`**: pins the Settings portal backend to `gtk` (keeping
  Hyprland's portal default for screencast), so the appearance value is served
  reliably. Installed only if the user has no `portals.conf`.

`install-app-theme-awareness.sh` does all of it idempotently - entirely
user-level (no root, no pacman hook).

## Per-app notes
- **Chrome/Chromium (Wayland):** follows the portal automatically. If the UI
  stays light, set `chrome://settings` → Appearance → **GTK / "Use system"**.
- **Qt:** `QT_QPA_PLATFORMTHEME=qtengine` is already set; Qt6 honors the portal.
  Old Qt5 apps may need a dark qt5ct/Kvantum style (out of scope).
- **GTK3 dark fidelity:** prefer-dark uses Adwaita's built-in dark rendering. For
  a fuller dark GTK3 theme the builder can add `gnome-themes-extra` (ships
  `Adwaita-dark`) - optional.

## Builder integration
Ship the sync script in the layer bin, the two user units (enabled by default,
like the other HyperWebster user units), and seed `portals.conf`. Ideally Caelestia
itself could set `color-scheme` when its scheme flips; until then these units
bridge it. Mode is read from `caelestia scheme get`, so it tracks the dynamic
Material scheme.

## Verify (after install)
```
caelestia scheme set -m light   # or via the Caelestia UI
gsettings get org.gnome.desktop.interface color-scheme   # -> 'prefer-light'
caelestia scheme set -m dark
gsettings get org.gnome.desktop.interface color-scheme   # -> 'prefer-dark'
# Chrome/GTK apps follow within a moment.
```

## Files
- `hyperwebster-app-theme-sync` - mode → portal/GTK sync.
- `hyperwebster-app-theme.service` / `.path` - login run + watch-on-change.
- `portals.conf` - Settings backend = gtk.
- `install-app-theme-awareness.sh` - idempotent user-level installer.
- `migrations/1781442000-app-theme-awareness.sh` - delegates to it.
