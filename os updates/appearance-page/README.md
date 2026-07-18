# Appearance settings page

Adds **Appearance** under Settings → Wallpaper & style, next to Wallpapers and
Colours. Continuous controls for corner radius, gaps, density, fonts, motion, and
glass shortcuts - plus one-tap presets.

## What you get

- Live corner-radius preview
- Presets: flat, mild, soft, pillowy, glass
- **UI font + monospace font** pickers (shell, GTK, kitty)
- Shell corner scale (0-200%) and window radius (0-32 px)
- Spacing / padding / font scales
- Hyprland gaps (inner, outer, workspace, single-window), opacity, border
- Animation duration and drawer deform
- Transparency toggles + blur / hypersmooth / zephyr shortcuts
- Link through to Colours & themes

Backend: `hyperwebster-appearance` (from `appearance-toggles/`). The Additions
"Rounded corners" toggle remains the simple on/off switch.

## Install

```sh
sh install-appearance-page.sh
```

Or via `hyperwebster-update` (migration `1781778000-appearance-page`).

Then **Ctrl+Super+Alt+R** to reload the shell.

## Layout

| File | Role |
|------|------|
| `AppearanceSelect.qml` | Settings sub-page (stack index 4) |
| `WallpaperAndStyle.qml` | Hub with Appearance button |
| `patch-appearance-page.sh` | Installs QML + patches `PageCompRegistry.qml` |
| `install-appearance-page.sh` | Copies to layer share, patches, pacman hook |
