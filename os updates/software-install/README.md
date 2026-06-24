# HyperWebster — software installation

The base ships `pacman` only: no AUR helper and no GUI store, even though ~750
of the base packages come from the AUR. HyperWebster gives users a complete way
to install software.

## The model

| Layer | Tool | Who it's for |
|-------|------|--------------|
| Plumbing | **yay** (AUR helper) | terminal users: `yay -S <pkg>`, `yay <search>`; also what `hyperwebster-update` uses for upgrades |
| App store | **Shelly** (`shelly-bin`) | everyone: GUI package manager on `Super+I` — official repos + AUR + Flathub + AppImage in one UI |
| Flatpak backend | **flatpak** + Flathub remote | sandboxed/proprietary desktop apps via Shelly's flatpak pages |

[Shelly](https://github.com/Seafoam-Labs/Shelly-ALPM) is a GTK4 package manager
built directly on libalpm (pacman's own library). CachyOS adopted it as their
default GUI package manager in April 2026. The `shelly-bin` AUR package
(maintained by the Shelly author) installs:

- `shelly-ui` — the GUI (what `Super+I` launches; also in the app launcher as "Shelly")
- `shelly` — the CLI
- `shelly-notifications` — tray service for update notifications (started via
  `exec-once` in the appended Hyprland config)

## Files

| File | Role |
|------|------|
| `install-software-install.sh` | idempotent installer — bootstraps yay if missing, installs `shelly-bin` + `flatpak` + `archlinux-appstream-data`, adds the Flathub remote, appends the bind |
| `hyprland-software-install.conf` | `Super+I` bind + `shelly-notifications` autostart → appended to `~/.config/caelestia/hypr-user.conf` |

```sh
sh ~/Downloads/software-install/install-software-install.sh
```

Also wired into `hyperwebster-update` as migration `1781222400-software-install.sh`.

## Packaging

Bake the packages into the base instead of installing post-hoc:

- **Add to the package list:** `yay-bin` (or `yay`), `shelly-bin`, `flatpak`,
  `archlinux-appstream-data`. This also satisfies the change-3 recommendation
  ("ship an AUR helper").
- **Preconfigure the Flathub remote** (`flatpak remote-add --if-not-exists
  flathub https://dl.flathub.org/repo/flathub.flatpakrepo`) in the image build
  or firstboot.
- The `Super+I` bind + notifier autostart land via `hypr-user.conf` like the
  other HyperWebster binds.

## Caveats

- Shelly is young (rapid 1.x → 2.x churn through 2026); pin `shelly-bin` updates
  to `hyperwebster-update` runs like everything else. CachyOS shipping it as default
  is a reasonable endorsement.
- `shelly-bin` lists `fish` as an optdepend for shell completions only — not a
  reason to keep fish.
