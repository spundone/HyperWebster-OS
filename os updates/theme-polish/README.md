# theme-polish — light/dark consistency

Tasteful fixes on top of the NoSignal / caelestia look:

1. **GTK + portal bridge** (`app-theme-awareness` enhancement): sets
   `gtk-theme` to `adw-gtk3` / `adw-gtk3-dark` alongside `color-scheme`.
2. **Light scheme fallback** (`scheme-shadotheme-light.json`) when dynamic
   generation fails in light mode.
3. **SDDM follows scheme changes**: a user `.path` unit watches
   `~/.local/state/caelestia/scheme.json` and runs `sudo sddm-theme-sync`
   (passwordless for `%wheel` via sudoers drop-in).

Chromium/Electron: set **Appearance → GTK** in browser settings for best results.
