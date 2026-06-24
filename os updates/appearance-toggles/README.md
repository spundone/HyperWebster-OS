# appearance-toggles - shell corner rounding

Companion to `blur-toggle/` for desktop appearance mods exposed in
Settings → Additions.

## hyperwebster-rounding-toggle

Toggles rounded vs square corners independently of frosted glass blur:

```sh
hyperwebster-rounding-toggle enable    # caelestia-style rounding ramp + Hyprland $windowRounding=8
hyperwebster-rounding-toggle disable   # HyperWebster flat default (scale 0, square tokens)
hyperwebster-rounding-toggle toggle
hyperwebster-rounding-toggle status
```

Touches:

- `~/.config/caelestia/shell-tokens.json` — `appearance.rounding.*`
- `~/.config/caelestia/shell.json` — `appearance.rounding.scale`
- `~/.config/caelestia/hypr-vars.conf` — `$windowRounding`
- `~/.config/caelestia/hypr-user.conf` — optional Steam/gamescope rounding rules

Default on fresh install: **disabled** (flat HyperWebster look). Blur defaults
**on** via `hyperwebster-blur-toggle enable` at install.
