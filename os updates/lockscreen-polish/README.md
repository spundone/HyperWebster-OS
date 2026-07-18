# Lock screen polish

Makes the Caelestia session lock feel like HyperWebster: **real wallpaper blur**,
slow ken-burns motion, soft ambient orbs (screensaver-lite), frosted password
glass, and a **circular** profile photo (`~/.face`) with Starman as fallback.

## Why not hyprlock / mpvpaper?

Session lock already uses Wayland `ext-session-lock` via Quickshell. A second
locker or a video layer under the lock surface fights the compositor and can
break unlock. This layer stays on Caelestia PAM + `WlSessionLock`.

## Install

```sh
sh install-lockscreen-polish.sh
```

Then **Ctrl+Super+Alt+R** and lock with **Super+Ctrl+L**.

## Files

| File | Role |
|------|------|
| `LockSurface.qml` | Frosted lock UI |
| `patch-locksurface.sh` | Installs over `/etc/xdg/quickshell/caelestia/modules/lock/LockSurface.qml` |

Does not touch Plymouth / LUKS / TPM unlock (boot is separate).
