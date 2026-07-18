# blur-toggle - optional frosted glass

HyperWebster can run a **flat** desktop (no blur) or Raycast-style frosted
panels. The NoSignal top bar is a Wayland layer with namespace **`nsbar`**
(popouts: **`nspanels`**). Blur layerrules must match those names — older
`caelestia-.*` rules never blurred the bar.

**ignore_alpha** must stay below `Theme.barBg` (~0.52–0.60). Hyprland skips
blur for pixels with opacity ≤ that threshold; caelestia's default
(`transparency.base - 0.03` ≈ 0.69) sat *above* the bar fill and made the
status bar look flat even with blur "on". Layer rules must be
`layerrule = blur on, match:namespace nsbar` — bare `blur,` is rejected
(`invalid field blur: missing a value`).

## Usage

```sh
hyperwebster-blur-toggle enable    # blur + transparency (rounding is separate)
hyperwebster-blur-toggle disable   # restore flat opaque panels
hyperwebster-blur-toggle toggle
hyperwebster-blur-toggle status
```

Touches:

- `~/.config/caelestia/hypr-vars.conf` - `$blurEnabled`, opacity
- `~/.config/caelestia/shell.json` - transparency block
- `~/.config/quickshell/overview/config.json` - overview glass
- `~/.config/caelestia/hypr-user.conf` - `nsbar` / `nspanels` layer blur rules
- `/etc/xdg/quickshell/caelestia/services/Colours.qml` - shell-driven blur keywords

State: `~/.local/state/hyperwebster/blur-enabled`

After enabling, restart the shell if needed: **Ctrl+Super+Alt+R**.
