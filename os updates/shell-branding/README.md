# shell-branding

Rebrands the pinned `nosignal-shell` package for HyperWebster: Settings → About,
Updates, Additions, and Services toggles reference `hyperwebster-*` CLIs and state
paths instead of leftover `nosignal-*` names from the upstream fork.

## About page

`AboutPage.qml` overlays Settings → About with:

- Starman / HyperWebster hero (`hyperwebster-logo.png`)
- Personal-use vibecoded disclaimer
- **Credits** - tappable rows for NoSignal OS, caelestia, Omarchy, CachyOS,
  Hyprland, Chimera/Deckify, Limine, Tailscale, and more
- Link to full `docs/CREDITS.md` on GitHub

`hyperwebster-logo.png` is the circular Starman mark. The patch always installs
it to `…/quickshell/caelestia/assets/hyperwebster-logo.png` (overwriting any
renamed NoSignal placeholder from older images).

## Apply on an installed system

```sh
hyperwebster-update --no-packages --no-snapshot
```

Or manually:

```sh
sudo sh ~/.local/share/hyperwebster/shell-branding/install-shell-branding.sh
```

Restart the shell (`Ctrl+Super+Alt+R`) after patching.

## Pacman hook

`install-shell-branding.sh` writes `/etc/pacman.d/hooks/hyperwebster-shell-branding.hook`
so branding is re-applied after every `nosignal-shell`, `caelestia-shell`, or
`hyperwebster-shell` upgrade. Updates, Additions, and Wi-Fi recovery have their
own hooks in the respective layer components.
