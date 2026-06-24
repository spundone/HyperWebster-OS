# zephyr-polish - optional animation flair

Cherry-picks tasteful motion from [zephyr](https://github.com/flickowoa/zephyr)
without undoing HyperWebster's flat default. **Disabled on install** - enable when
you want overshoot workspace/window motion:

```sh
hyperwebster-zephyr-polish enable
```

## Adopted from zephyr

- Hyprland `overshoot` bezier (`.23, 1.23, .61, 1.08`) on windows/workspaces
- Slightly longer shell `animDurations` for expressive spatial transitions
- Workspace slidefade tuned to zephyr's slide feel

## Skipped (incompatible or too busy)

- Custom Quickshell bar (rope/geom workspace cells) - different shell architecture
- Video wallpaper / visualiser - conflicts with flat default
- foot term server / Alt+Space screenshot binds - keybind conflicts
- Heavy glow/blur bar effects - HyperWebster stays flat unless blur-toggle is on

## Toggle

`hyperwebster-zephyr-polish {enable|disable|status|toggle}`
