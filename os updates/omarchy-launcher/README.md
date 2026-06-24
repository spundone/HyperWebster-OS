# omarchy-launcher - Omarchy install menu for HyperWebster

Cherry-picks the **Install** workflow from [Omarchy](https://omarchy.org)'s
`Super+Alt+Space` control menu (`omarchy-menu`), adapted for caelestia/HyperWebster:

- **fuzzel** for hierarchical menus (same pattern as `hyperwebster-maint`,
  `hyperwebster-transcode`)
- **fzf** for fuzzy package/AUR pickers (same as Omarchy's `omarchy-pkg-install`)

## Keybind

| Key | Action |
|-----|--------|
| `Super+Alt+Space` | `hyperwebster-omarchy-menu` (install/control menu) |
| `F10` | Settings (caelestia nexus — moved off Super+Alt+Space) |

`Super+Space` stays the app launcher. `Super+I` still opens Shelly.

## What's included

| Menu path | Omarchy equivalent | HyperWebster |
|-----------|-------------------|--------------|
| Install → Package | `omarchy-pkg-install` | `hyperwebster-pkg-install` (fzf + pacman) |
| Install → AUR | `omarchy-pkg-aur-install` | `hyperwebster-pkg-aur-install` (fzf + yay) |
| Install → Web app | `omarchy-webapp-install` | `hyperwebster-webapp-install` prompt |
| Install → Editor / Browser / Gaming | curated one-shots | `omarchy-pkg-add` / yay shims |
| Install → Quick picks | common apps | Steam, Firefox, OBS, … |
| Remove → Package | `omarchy-pkg-remove` | `hyperwebster-pkg-remove` |
| App store | (Omarchy uses menus) | Shelly (`Super+I` alias in menu) |
| Settings / Maintenance | Setup / system tools | caelestia nexus / `hyperwebster-maint` |
| Learn → Keybindings | `omarchy-menu-keybindings` | `hyperwebster-keybinds` |

## Deliberately not ported

Full Omarchy menu tree (Style, Setup, Update, Trigger, System power menu,
Walker/Waybar toggles, theme/background switchers). Those stay in caelestia
Settings, `hyperwebster-maint`, or dedicated HyperWebster keys.

## Install

```sh
sh ~/.local/share/hyperwebster/omarchy-launcher/install-omarchy-launcher.sh
```

Idempotent. Wired into `hyperwebster-update` as migration
`1781580000-omarchy-launcher.sh`.

## CLI

```sh
hyperwebster-omarchy-menu           # main menu
hyperwebster-omarchy-menu install   # jump to Install
hyperwebster-pkg-install            # official repo picker (terminal)
hyperwebster-pkg-aur-install        # AUR picker (terminal)
hyperwebster-pkg-remove             # remove installed packages
```

## Credit

Install menu structure and package pickers adapted from
[basecamp/omarchy](https://github.com/basecamp/omarchy) (`bin/omarchy-menu`,
`bin/omarchy-pkg-install`, `bin/omarchy-pkg-aur-install`).
