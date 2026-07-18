## Learned User Preferences

- Prefers delegating large feature sets to background workers ("Start multitasking") rather than blocking the main chat.
- Expects logical git commits grouped by feature area and uses `cursor/` branch prefixes for PR branches.
- For HyperWebster-OS public docs: use hyphens instead of em dashes; omit personal hardware specs and model numbers.
- Public repo must include a vibecoded, personal-use-only disclaimer (untested, experimental).
- Wants tasteful Omarchy-inspired features layered in, not a wholesale Omarchy install; also wants Omarchy-style named/community themes (color systems, not wallpaper packs) installable from Nexus Colours, with optional wallpaper-based theme generation.
- Requests keybinding conflict audits when adding Omarchy or other shortcut layers.
- Prefers detailed image-to-ASCII Starman art for boot and terminal branding over simple line-art logos.
- Wants Raycast-like themed search with Omarchy-style install menu (packages, AUR, apps like Steam) on Super+Alt+Space, optional frosted-glass blur when transparency is enabled (including the status top bar), and manual corner-radius, font selection, and related appearance controls in Wallpaper & style (beyond the Additions rounded-corners toggle).
- Wants Nexus Additions page toggles for all mod/layer components; also wants Nexus Settings for a circular-cropped profile photo picker and launchers for system apps (CachyOS kernel manager, display, keyboard, mouse).
- Expects Nexus update controls to invoke `hyperwebster-update`, aliasing leftover `nosignal-update` calls when needed.
- Uses hyperarch naming alongside HyperWebster/Starman where easier to pronounce.
- Expects upstream credit (NoSignal OS, caelestia, Omarchy, CachyOS, etc.) in public documentation and in the Nexus About settings page.

## Learned Workspace Facts

- HyperWebster-OS lives at `~/Projects/HyperWebster-OS`; public repo is `spundone/HyperWebster-OS` on GitHub.
- Personal Arch desktop ISO flavor forked from NoSignal-OS (`~/NoSignal-OS`); hyperarch / HyperWebster / Starman branding lineage.
- Live installer uses a HyperWebster OS-branded, Omarchy-inspired `gum` TUI with Starman art and stepwise install flow; do not pipe multiline Starman ASCII through `gum style` (it strips trailing spaces), and keep user-visible clear/status on `/dev/tty`. Live ISO tty2 login is `root` with an empty password. Post-install `hyperwebster-update-check` / `checkupdates` must use timeouts so offline installs do not hang.
- ISO builds use `./build.sh` for Arch native or containerized OrbStack/Docker Desktop/WSL2; on Apple Silicon OrbStack force `linux/amd64`, disable pacman alpm sandbox, and keep the AUR chroot and unsquash work tree on case-sensitive Docker volumes (not macOS bind mounts: virtiofs rejects `.arch-chroot`, and APFS collides on paths like `xt_connmark.h` vs `xt_CONNMARK.h`); nested `systemd-nspawn` in Docker needs `machine-id`, a propagate tmpfs, and `--keep-unit`; `hyperwebster.sh` auto-downloads the latest Arch ISO and uses mirror failover.
- Shell still builds from upstream `28allday/nosignal-shell` (branded and packed as a tarball for makechrootpkg; directories are not copied into the chroot) until a `hyperwebster-shell` fork exists; local shell work often uses `offline/aur/nosignal-shell.fork`; Nexus overlays such as `colours-page` and `shell-branding` live under `os updates/`.
- Layer components live under `os updates/`; `hyperwebster-update` pulls the layer from GitHub, skips rsync when trees already match, and supports `--force-migrations`; migrations must tolerate already-identical files and optional hardware gaps so the runner does not abort the whole update.
- Gaming/TV focus: Limine Starman boot, Deckify/gamescope/Chimera, LUKS2 with TPM auto-unlock and Omarchy-style Plymouth fallback; `systemd-cryptenroll` must use `--unlock-key-file` (not `--unlock-passphrase`); public docs describe generic 4K HDR VRR TV gaming without personal hardware; Super+Shift+S enters the gamescope gaming session only when the expected DeckShift/Chimera session desktop file is present; Limine HyperWebster/HyperArch submenu should auto-highlight and boot `linux-cachyos` by default.
- CachyOS optimized kernel and kernel manager ship out-of-the-box by default.
- Tailscale is preloaded for remote access; iPhone USB tethering ships via `28allday/omatether` with NetworkManager + networkd coexistence.
- Keeps NoSignal/caelestia desktop look with light/dark theme polish (SDDM sync, GTK bridge); Nexus Colours (`os updates/colours-page/`) drives caelestia Material schemes; Additions rounding/blur toggles are binary, while continuous appearance scales live in `shell.json` / `shell-tokens.json`.
- Secondary drives premount at boot via the `drive-automount` layer component.
- Session lock is Caelestia Quickshell `WlSessionLock` (hyprlock may be packaged but is unused); SDDM is the login greeter only.
