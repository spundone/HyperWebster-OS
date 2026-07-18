# Omarchy themes for HyperWebster

Brings Omarchy's theme catalog + community git installs + wallpaper theme
generation into HyperWebster's **caelestia** colour system (not a second
Waybar/Walker theme engine).

## What you get

| Feature | How |
|---------|-----|
| Extra stock themes | matte-black, hackerman, miasma, kanagawa, osaka-jade, ethereal, lumon, vantablack, ristretto, retro-82, flexoki-light, white, last-horizon, solitude |
| Overlap with caelestia | tokyo-night → `tokyonight`, rose-pine → `rosepine`, catppuccin / nord / gruvbox / everforest already present |
| Community Omarchy packs | `hyperwebster-theme install <git-url>` (same repos as [Extra themes](https://learn.omacom.io/2/the-omarchy-manual/90/extra-themes)) |
| Wallpaper generator | `hyperwebster-theme generate [image] [name]` — applies Material You **dynamic** from the image, then snapshots a named user scheme (needs the caelestia user-scheme overlay to appear in Colours) |

| Colours settings UI | Settings → Wallpaper & style → Colours |
| Hotkey | `Super+Ctrl+Shift+Space` (Omarchy theme-picker chord) |

## Layout

| Path | Role |
|------|------|
| `~/.local/share/caelestia/schemes/<name>/` | User schemes visible to `caelestia scheme list` |
| `~/.config/omarchy/themes/<name>/` | Kept Omarchy pack layout (git pull / community tools) |
| `/etc/xdg/...` Colours page | Install / generate / remove actions |

## Credit

- [Omarchy themes](https://learn.omacom.io/2/the-omarchy-manual/52/themes) & [extra themes](https://learn.omacom.io/2/the-omarchy-manual/90/extra-themes)
- [keyd](https://github.com/rvaiya/keyd) is separate; this layer is colour schemes only
- Wallpapers from Omarchy packs are optional on install (not mirrored into the ISO)
