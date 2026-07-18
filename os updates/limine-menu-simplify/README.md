# limine-menu-simplify

Keeps the Limine boot menu to two primary entries when possible:

1. **HyperWebster · hyperarch (Arch Linux)** - UKI desktop (default)
2. **Starman (Gaming / Steam)** - same UKI with `hyperwebster.starman=1`

**Snapshots** still appear when limine-snapper has any. Manual kernel fallbacks,
the nested auto `HyperWebster` group clutter, and the in-menu **EFI fallback**
row are removed. Firmware can still boot `\EFI\BOOT\BOOTX64.EFI` on disk; that
path is just not listed inside Limine.

## Nested menus (linux-cachyos / linux)

If `limine-update` still builds a HyperWebster directory with kernel children,
`prefer-limine-cachyos.sh` sets:

- `default_entry: <Parent>/linux-cachyos` (path form) so timeout boots CachyOS
- `/+Parent` so the submenu is expanded and that kernel is highlighted

Without that, Limine highlights the directory itself - Enter does not boot.

## Apply on an installed system

```sh
sudo bash ~/.local/share/hyperwebster/limine-menu-simplify/prefer-limine-cachyos.sh
# or full simplify:
sudo bash ~/.local/share/hyperwebster/limine-menu-simplify/simplify-limine-menu.sh
# or via hyperwebster-update (migration)
hyperwebster-update
```

Recovery if the UKI is missing: boot a Snapshots entry (if present) or the live USB.
