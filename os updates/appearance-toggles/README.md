# appearance-toggles - shell corner rounding + appearance CLI

Companion to `blur-toggle/` for desktop appearance mods. Simple on/off lives in
Settings → Additions; continuous knobs live in Wallpaper & style → Appearance.

## hyperwebster-rounding-toggle

Toggles rounded vs square corners independently of frosted glass blur:

```sh
hyperwebster-rounding-toggle enable    # caelestia-style rounding ramp + Hyprland $windowRounding=8
hyperwebster-rounding-toggle disable   # HyperWebster flat default (scale 0, square tokens)
hyperwebster-rounding-toggle toggle
hyperwebster-rounding-toggle status
```

## hyperwebster-appearance

Continuous controls used by the Appearance settings page:

```sh
hyperwebster-appearance get window-radius
hyperwebster-appearance set window-radius 12
hyperwebster-appearance set gaps-in 6
hyperwebster-appearance set rounding-scale 1.25
hyperwebster-appearance preset mild    # flat | mild | soft | pillowy | glass
hyperwebster-appearance status-json
hyperwebster-appearance ensure-rounding
```

Touches:

- `~/.config/caelestia/shell-tokens.json` — `appearance.rounding.*`
- `~/.config/caelestia/shell.json` — appearance scales / transparency
- `~/.config/caelestia/hypr-vars.conf` — `$windowRounding`, gaps, opacity, border
- `~/.config/caelestia/hypr-user.conf` — optional Steam/gamescope rounding rules

Default on fresh install: **disabled** (flat HyperWebster look). Blur defaults
**on** via `hyperwebster-blur-toggle enable` at install.
