# omarchy-extras - curated Omarchy utilities for HyperWebster

Cherry-picked workflow pieces from [Omarchy](https://omarchy.org) that fit
HyperWebster's caelestia shell without porting Walker, Waybar, or the full
`omarchy` CLI dispatcher.

## What's included

| Piece | Omarchy equivalent | HyperWebster adaptation |
|-------|-------------------|-------------------------|
| `Super+Ctrl+S` | Share menu | `hyperwebster-share` → `omarchy-send` TUI |
| `Super+Ctrl+Period` | `omarchy transcode` | `hyperwebster-transcode` (fuzzel menus, not Walker) |
| `Super+Ctrl+Print` | OCR capture | `hyperwebster-ocr-capture` (grim + tesseract) |
| `Super+Ctrl+N` | Night light toggle | `hyperwebster-nightlight-toggle` (hyprsunset IPC) |
| `omarchy-transcode` shim | `omarchy-transcode` | Delegates to `hyperwebster-transcode` (bash aliases work) |
| `~/.XCompose` | Omarchy emoji compose | Same sequences; works in XWayland / Compose-key apps |

## Packages

New ISO installs pull **tesseract** (OCR) and **imagemagick** (picture transcode).
**ffmpeg** is already in the closure via CLIAmp.

## Install

```sh
sh ~/.local/share/hyperwebster/omarchy-extras/install-omarchy-extras.sh
```

Idempotent. Wired into `hyperwebster-update` as migration
`1781526000-omarchy-extras.sh`.

## Deliberately not ported

Walker/Elephant launcher, Waybar position keys, theme/background switchers,
Omarchy reminders, universal Super+C/V copy (conflicts with clipboard history),
`Super+Comma` dismiss-last (caelestia has clear-all only), monitor lid hooks
(desktop/TV box), and the full `omarchy` menu tree.
