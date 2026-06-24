---
name: hyperwebster
description: >-
  How to manage a HyperWebster system for its user. Load this whenever you are helping
  the user configure, customize, fix, update, or troubleshoot their HyperWebster machine
  (Arch Linux + Hyprland + Caelestia/Quickshell shell + SDDM). Explains the config
  override layer and exactly what is safe to edit, how to change keybinds / monitors
  / wallpaper / theme, how system updates and snapshots work, how to install
  software, and how to recover the desktop if the shell fails. Read this before
  changing any desktop or system config on a HyperWebster box.
---

# HyperWebster - system management skill

You are managing a **HyperWebster** machine on behalf of its user: Arch Linux +
Hyprland + the Caelestia shell (Quickshell) + SDDM. A "HyperWebster layer" of config and
tooling sits ON TOP of stock Caelestia. Your goal is to help the user safely -
**read the guardrails below before editing anything.** Full detail is in
`references/ONBOX-AI-NOTES.md`.

## Config layout - where to make changes (and what NOT to touch)

- **Edit here:** `~/.config/caelestia/`
  - `hypr-user.conf` - keybinds/rules/exec-once; sourced **last**, so it wins. The
    right place for new binds (`unbind =` works here).
  - `hypr-vars.conf` - `$variables` ($terminal, gaps, blur…); sourced before binds.
  - `shell.json` / `shell-tokens.json` - shell appearance/behaviour.
  - Deleting any of these restores stock behaviour.
- **Do NOT touch:**
  - `~/.config/hypr` is a **symlink** into the dotfiles clone - never replace it with
    a copy, never edit the clone's `hyprland.conf`. Use `hypr-user.conf`.
  - **Never create `~/.config/quickshell/caelestia`.** The shell runs from
    `/etc/xdg/quickshell/caelestia` with HyperWebster patches re-applied by pacman hooks;
    a user copy shadows it and silently drops those patches.

## Common tasks

- **Keybinds:** add to `hypr-user.conf`; the `Super+K` cheatsheet is generated from
  `~/.local/share/hyperwebster/HyperWebster-keybindings.md` (`hyperwebster-keybinds-gen`) - keep
  it in sync. Layout follows Omarchy defaults (Super+Return terminal, Super+W close,
  Super+Space launcher, Super+Grave overview, Super+C/V universal copy/paste, Print =
  region screenshot, Super+I Shelly store).
- **Monitors:** use `hyprmoncfg` (`Super+Ctrl+H`, TUI). It writes
  `~/.config/hypr/monitors.conf` (sourced by hypr-user.conf); keep the `source =`
  lines. `hyprmoncfgd` (user unit) applies profiles live on save.
- **Wallpaper / theme:** `caelestia wallpaper -f <file>` (or the UI). The Material
  colour scheme is generated FROM the wallpaper. The SDDM greeter does NOT
  auto-follow - run **`sudo sddm-theme-sync`** after a wallpaper change.
- **System updates:** **`hyperwebster-update`** = snapper snapshot → `yay -Syu` → run new
  migrations (tracked in `~/.local/state/hyperwebster/applied` - don't re-run by hand).
- **Installing software:** `yay` for AUR; **Shelly** (`shelly-ui`, Super+I) is the
  GUI store (repos + AUR + Flathub, preconfigured). Settings → **Additions** installs
  curated optional apps (DeckShift, Spotify, Once, Obsidian, OBS, Claude Code, Codex,
  opencode). NOTE: some Additions apps (e.g. **Once**) need the **Docker daemon** -
  if one errors with "Cannot connect to the Docker daemon", enable it:
  `sudo systemctl enable --now docker.socket` (and add the user to the `docker` group
  to avoid sudo).
- **Gaming mode:** OPT-IN. `sh ~/deckshift/deckshift.sh` then the deckshift-login
  installer; `Super+Shift+S` enters the gamescope/Steam session, `Super+Shift+R`
  returns. `[multilib]` is enabled.
- **Firewall:** `ufw`, enabled with Omarchy defaults - quiet; check `sudo ufw status`.

## Recovery / troubleshooting

- **Shell fails at login** (wallpaper but no bar): reproduce from a TTY with
  `qs -c caelestia -n` (`WAYLAND_DISPLAY=wayland-1`) to get the QML error chain;
  suspect the shell page patches first.
- **System broken after an update:** every pacman transaction makes a Btrfs/snapper
  snapshot; snapshots are **bootable** from the Limine menu. Worst case: reboot →
  pick an earlier snapshot.
- **Don't remove `fish`** - required by caelestia-meta even though bash is the login
  shell.

## Reference files (bundled)

`references/ONBOX-AI-NOTES.md` (full system briefing) and
`references/HyperWebster-keybindings.md` (keybind reference). On a live install the
originals are in `~/.local/share/hyperwebster/`.

> Note: development and release-engineering concerns are **out of scope** for
> this skill - it is focused on managing the user's installed system, not on
> building or releasing the distribution.
