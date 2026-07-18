# glyphs-fix

Nexus SelectRow / Menu dropdowns use `icon: ""` for unselected rows. Stock
`Glyphs.get("")` fell back to a question-mark Nerd Font glyph, so every inactive
option in Settings → Colours (Material variant, scheme, flavour) showed **?**.

## Fix

`patch-glyphs.sh` updates `/etc/xdg/quickshell/caelestia/services/Glyphs.qml`:

1. `get("")` returns empty string (no icon)
2. Adds `"check"` → FA checkmark for the selected row

## Apply

```sh
sh install-glyphs-fix.sh
# or via hyperwebster-update migration
```

Then **Ctrl+Super+Alt+R**.
