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
sh ~/.local/share/hyperwebster/shell-branding/install-shell-branding.sh
```

Restart the shell (`Ctrl+Super+Alt+R`) after patching.
