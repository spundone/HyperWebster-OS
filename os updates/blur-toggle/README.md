# blur-toggle - optional frosted glass

HyperWebster defaults to a **flat, restrained** desktop (no blur). This component
adds `hyperwebster-blur-toggle` to enable Raycast-style frosted panels when you
want them.

## Usage

```sh
hyperwebster-blur-toggle enable    # blur + transparency (rounding is separate)
hyperwebster-blur-toggle disable   # restore flat opaque panels
hyperwebster-blur-toggle toggle
hyperwebster-blur-toggle status
```

Touches:

- `~/.config/caelestia/hypr-vars.conf` - `$blurEnabled`, opacity, rounding
- `~/.config/caelestia/shell.json` - transparency block
- `~/.config/caelestia/shell-tokens.json` - corner radii
- `~/.config/quickshell/overview/config.json` - overview glass
- `~/.config/caelestia/hypr-user.conf` - caelestia layer blur rules

State: `~/.local/state/hyperwebster/blur-enabled`
