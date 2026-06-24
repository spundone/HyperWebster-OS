# HyperWebster — notes for an AI agent working on this machine

You are on **HyperWebster**: Arch Linux + Hyprland + the Caelestia shell (Quickshell)
+ SDDM (themed greeter). A "HyperWebster layer" of config and tooling sits ON TOP of
stock Caelestia. Read this before changing desktop/system config — your job is to
help the user manage their machine safely.

## Config layout — what is safe to edit

- `~/.config/caelestia/` — **the HyperWebster override layer** (edit here):
  - `hypr-user.conf` — user binds/rules/exec-once; sourced LAST, so it wins.
    This is the right place for new keybinds. `unbind =` works here.
  - `hypr-vars.conf` — `$variables` ($terminal, $kb*, gaps, blur…); sourced
    BEFORE keybinds.conf consumes them.
  - `shell.json`, `shell-tokens.json` — Caelestia shell appearance/behaviour.
  - Deleting any of these files restores stock Caelestia behaviour.
- `~/.config/hypr` is a **SYMLINK** into `~/.local/share/caelestia` (the
  dotfiles clone). Several other `~/.config` entries (foot, fish, fastfetch,
  uwsm) are symlinks into it too. **Never replace these symlinks with copies**
  and never edit the clone's hyprland.conf directly — use hypr-user.conf.
- `~/.config/hypr/scripts/wsaction.fish` and `configs.fish` are **bash** ports
  kept under their original .fish names (the stock config calls those paths).
  Keep the names and the bash shebang.

## Updates

- `~/.local/share/hyperwebster/` — the on-system layer: component sources, the
  keybindings doc, and `hyperwebster-update/` (the update command + its migrations).
- **`hyperwebster-update`** = the system update command: snapper snapshot →
  `yay -Syu` → run any NEW migrations. Applied migrations are tracked in
  `~/.local/state/hyperwebster/applied` — do not re-run or edit by hand.

## Keybindings

- `Super+K` (aliases `Super+/`, `Super+F1`) = searchable fuzzel cheatsheet.
- **Source of truth: `~/.local/share/hyperwebster/HyperWebster-keybindings.md`** — the
  cheatsheet is GENERATED from it (`hyperwebster-keybinds-gen`). If you add a bind
  in hypr-user.conf, document it in that file too.
- Layout follows **Omarchy defaults**: Super+Return terminal (kitty, bash),
  Super+W close, Super+Space launcher, Super+Tab next workspace,
  **Super+Grave = workspace overview**, Super+I Shelly store,
  Super+Ctrl+H monitor editor, Super+Shift+number move-to-workspace
  (bound by KEYCODE — GB layout).
- **Super+C / Super+V = universal copy/paste** (class-aware sendshortcut;
  clipboard HISTORY is Super+Ctrl+V). **Print = region screenshot** →
  clipboard + ~/Pictures/Screenshots (Shift+Print full). **Super+D =
  dashboard/calendar** (communication workspace → Super+Shift+D).
  **Super+M = CLIAmp**, the default music player (floating TUI; audio files
  open in it via `~/.config/mimeapps.list`). The shell's music/MPRIS panel
  is **Super+Shift+M**.

## Shell / desktop architecture gotchas

- The Caelestia shell runs from `/etc/xdg/quickshell/caelestia`. HyperWebster
  patches THREE things there, each re-applied by its own pacman hook after
  every caelestia-shell upgrade: the Settings → System → **Updates** page
  (`PageCompRegistry.qml` + `pages/UpdatesPage.qml`), the Settings →
  **Additions** page (same registry + `pages/AdditionsPage.qml` +
  Plugins→Additions relabel in `PageRegistry.qml`; backend =
  `hyperwebster-additions` + `additions.json` in the layer tree), and the Wi-Fi
  wrong-password recovery in `utils/NetworkConnection.qml`.
  **Do NOT create `~/.config/quickshell/caelestia`** — a user copy shadows
  /etc/xdg and silently drops the patches (and future ones).
  If the shell ever fails at login (background but no bar): reproduce with
  `qs -c caelestia -n` from a TTY (`WAYLAND_DISPLAY=wayland-1`) to get the QML
  error chain; suspect the page patches first.
- The workspace **overview is a separate Quickshell instance**
  (`~/.config/quickshell/overview`, `qs -c overview -d`, IPC-toggled by
  Super+Grave). It is independent of the main shell.
- The update-status timer (`hyperwebster-update-check.timer`, user),
  `hyprmoncfgd` (monitor hotplug profiles, user) and
  `hyprmoncfgd-rescan.path` (watches `~/.config/hyprmoncfg/profiles/` and
  bounces the daemon so plain profile saves apply live) are enabled systemd
  USER units. Status: `systemctl --user status <unit>`.

## Monitors

- Use **hyprmoncfg** (`Super+Ctrl+H`, TUI) — it writes
  `~/.config/hypr/monitors.conf` (+ workspaces.conf), which hypr-user.conf
  sources. Keep those `source =` lines; hyprmoncfg refuses to write otherwise.
- Both the TUI bind and the `hyprmoncfgd` daemon run with
  `--hypr-config ~/.config/caelestia/hypr-user.conf --monitors-conf
  ~/.config/hypr/monitors.conf` (hyprmoncfg doesn't follow nested `source =`
  includes). Keep the flags; the daemon's drop-in lives at
  `~/.config/systemd/user/hyprmoncfgd.service.d/override.conf`.

## Login / display manager / gaming

- **SDDM** is the display manager. Config drop-ins in `/etc/sddm.conf.d/`:
  `10-hyperwebster.conf` (X11 greeter, uwsm session notes) + `20-sddm-theme.conf`
  (themed greeter). The desktop session MUST stay `hyprland-uwsm.desktop`
  (uwsm-managed) — plain hyprland.desktop loses caelestia's session env.
- The greeter theme (`/usr/share/sddm/themes/caelestia`) mirrors the desktop
  scheme. After changing wallpaper, run **`sudo sddm-theme-sync`** to update
  the login screen (it does not auto-follow).
- **Gaming Mode is OPT-IN**: run `sh ~/deckshift/deckshift.sh`, then
  `sh ~/.local/share/hyperwebster/deckshift-login/install-deckshift-login.sh`
  (re-run the fix after any deckshift.sh re-run). Then Super+Shift+S enters
  the full gamescope/Steam session; Super+Shift+R (inside it) returns. Cold
  boots always show the password greeter (one-shot autologin). `[multilib]`
  is enabled and `omarchy-pkg-add` & friends are shims in `~/.local/bin`.

## Packages / system

- `yay` for AUR; **Shelly** (`shelly-ui`, Super+I) is the GUI store
  (repos + AUR + Flathub). Flathub remote is preconfigured. Settings →
  **Additions** installs curated optional software (DeckShift, Spotify,
  Once, Obsidian, OBS, Claude Code, Codex, opencode) from official sources
  only — extend via `additions.json` in the layer tree, no code changes.
- The firewall is **ufw**, enabled with Omarchy-style defaults — it is easy
  to miss because nothing advertises it: `sudo ufw status`.
- The `fish` package is REQUIRED by caelestia-meta — do not remove it, even
  though bash is the login/terminal shell.
- Btrfs + snapper: every pacman transaction snapshots (snap-pac); snapshots
  are BOOTABLE from the Limine menu (limine-snapper-sync, UKI at
  /boot/EFI/Linux/hyperwebster_linux.efi). Worst case: reboot → pick a snapshot.
- `[omarchy]` repo in pacman.conf provides prebuilt limine-snapper tools.
- omarchy-send is installed (LAN file transfer; receive dir `~/Omarchy-Send`,
  `Super+Ctrl+S` or launcher, CLI: `omarchy-send -to <alias> <files>`).
  Transcode: `Super+Ctrl+Period` or `hyperwebster-transcode`. OCR: `Super+Ctrl+Print`.
  Night light: `Super+Ctrl+N`. Its config contains a private key — never
  copy/share `~/.config/omarchy-send/`.

## Theme

- Wallpapers: `~/Pictures/Wallpapers/hyperwebster/` (the OS art set; default
  foam-sea.png). The colour scheme is Caelestia's **dynamic** Material scheme,
  generated FROM the current wallpaper — change wallpaper via the Caelestia
  UI or `caelestia wallpaper -f <file>` and the palette follows. The SDDM
  greeter does NOT auto-follow: run `sudo sddm-theme-sync` after.
