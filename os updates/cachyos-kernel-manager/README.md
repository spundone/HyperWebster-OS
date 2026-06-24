# cachyos-kernel-manager

HyperWebster ships **`cachyos-kernel-manager`** from the CachyOS repository out of
the box (alongside `linux-cachyos`). Launch it from the application menu or:

```sh
cachyos-kernel-manager
```

Use it to install alternate CachyOS kernel variants (`linux-cachyos-lts`,
`linux-cachyos-bore`, etc.) or build custom kernels. Limine entries update via
`limine-mkinitcpio-hook` after package installs.

Settings → Services → **CachyOS kernel & repos** still controls userspace repo
conversion via `hyperwebster-cachy-repo`.
