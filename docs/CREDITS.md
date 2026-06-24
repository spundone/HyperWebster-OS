# Credits & acknowledgements

HyperWebster OS is a personal fork built on top of excellent upstream work.
This project bundles, themes, and installs these projects — it does not replace
them. Please support the originals; each remains under its own licence.

## Direct lineage

- **[NoSignal OS](https://github.com/28allday/NoSignal-OS)** — upstream ISO
  builder and layer architecture this fork started from.
- **hyperarch** — earlier personal experiment by the same maintainer; naming
  and design intent carry forward as HyperWebster / Starman.

## Base system & desktop

- **[Arch Linux](https://archlinux.org)** — base distribution and live ISO.
- **[Hyprland](https://hyprland.org)** — Wayland compositor.
- **[caelestia](https://github.com/caelestia-dots/caelestia)** — dotfiles,
  shell UX, and theming engine (installed shell is a pinned fork of
  [nosignal-shell](https://github.com/28allday/nosignal-shell)).
- **[Quickshell](https://quickshell.outfoxxed.me)** — shell runtime.
- **[SDDM](https://github.com/sddm/sddm)** — display manager; greeter theme
  derived from the caelestia palette.

## Boot, snapshots & encryption

- **[Limine](https://github.com/limine-bootloader/limine)** — UEFI bootloader.
- **[snapper](https://github.com/openSUSE/snapper)** + **snap-pac** — btrfs
  snapshots on package transactions.
- **[Omarchy](https://omarchy.org)** — keybinding layout inspiration and
  prebuilt `[omarchy]` repo for Limine snapshot tooling.
- **cryptsetup / LUKS** — full-disk encryption (Arch `base` ecosystem).

## Gaming

- **[DeckShift](https://github.com/28allday/DeckShift)** — desktop ↔ gamescope
  Steam session switching (opt-in post-install).
- **gamescope** + **Steam** — gaming session stack (user-installed via DeckShift).

## Hardware detection & tuning

- **[CachyOS](https://github.com/CachyOS/CachyOS)** — `linux-cachyos` kernel (default),
  pacman repositories, and repo bootstrap tooling (`cachyos-repo.tar.xz` stanzas).
- **[CachyOS `chwd`](https://github.com/CachyOS/chwd)** — GPU detection
  *method* (PCI scan → vendor → driver set), reimplemented natively in the
  builder.
- **[CachyOS-Settings](https://github.com/CachyOS/CachyOS-Settings)** — curated
  sysctl + I/O scheduler rules vendored as plain text.
- **[Omarchy installer shims](https://github.com/28allday)** — gaming package
  helpers (`omarchy-pkg-add`, etc.).

## Themes, icons & fonts

- **adw-gtk-theme** — GTK light/dark bridge for external apps.
- **Papirus** — icon theme.
- **JetBrains Mono Nerd Font**, **Material Symbols**, **Noto** — typography.
- **Google Sans Flex** (caelestia shell asset) — SDDM greeter font.

## Terminal & utilities

- **[fastfetch](https://github.com/fastfetch-cli/fastfetch)** — system info.
- **[starship](https://starship.rs)** — shell prompt (caelestia integration).
- **[Shelly](https://github.com/caelestia-dots/shelly)** — software store UI.

## Maintainer

HyperWebster / Starman branding, wallpaper art, layer overrides, LUKS installer
flow, Starman boot entry, and theme polish are maintained by **Spandan**
as a personal distro flavor.

## Licence

MIT — see [LICENSE](../LICENSE). Wallpaper art ships with the ISO under the
same licence where applicable.
