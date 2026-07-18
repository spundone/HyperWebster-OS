# glyphs-fix

Fixes **?** icons in:

1. Nexus SelectRow / Menu dropdowns (`Glyphs.get("")` used to fall back to ?)
2. Super+Space launcher actions (`calculate`, `colors`, `casino`, `light_mode`, …)

Stock NoSignal `Glyphs.qml` only maps a subset of Material Symbol names to Nerd
Font codepoints. Unmapped names show a question mark.

## Fix

`patch-glyphs.sh` updates `/etc/xdg/quickshell/caelestia/services/Glyphs.qml`:

1. `get("")` returns empty string (no icon)
2. Adds `"check"` for selected menu rows
3. Adds launcher action glyphs from `launcherconfig.hpp`

## Apply

```sh
sh install-glyphs-fix.sh
# or via hyperwebster-update migration
```

Then **Ctrl+Super+Alt+R**.
