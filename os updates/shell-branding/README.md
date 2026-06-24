# shell-branding

Rebrands the pinned `nosignal-shell` package for HyperWebster: Settings → About,
Updates, Additions, and Services toggles reference `hyperwebster-*` CLIs and state
paths instead of leftover `nosignal-*` names from the upstream fork.

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
