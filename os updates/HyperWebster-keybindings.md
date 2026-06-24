# HyperWebster — Keybinding Map

> **System:** Arch Linux (rolling), hostname `hyperwebster`, Wayland compositor **Hyprland**.
> **Base:** [Caelestia](https://github.com/caelestia-dots) dotfiles + shell (QuickShell).
> **HyperWebster layer:** styling flattened, stock apps rebound, overview added, and
> **the key layout follows Omarchy's defaults** (see
> `omarchy-keys/README.md` for the full mapping and deviations).
>
> **Modifier legend:** `Super` = Windows/Meta key · `Ctrl` · `Alt` · `Shift`.
> `XF86*` = laptop media/function keys. `mouse_up/down` = scroll wheel.
>
> Bindings are **variable-driven**. The tables below show the *resolved* keys
> (variables from `variables.conf` + overrides applied). See "Source map" at the
> end for where each value comes from and how to change it.

---

## 0. Built-in help (HyperWebster addition)

| Keys | Action |
|------|--------|
| `Super+K` | Open the searchable on-screen keybinding cheatsheet (Omarchy key) |
| `Super+/` | Same (alias) |
| `Super+F1` | Same (alias) |

The cheatsheet is a fuzzel dmenu list — start typing to filter by key or by
category tag (`[Window]`, `[Apps]`, `[Audio]`, …). Selecting a line copies that
shortcut to the clipboard (if `wl-copy` is present); it never executes anything.

**This very document is the single source of truth.** The on-screen help is
*generated* from the tables below — `hyperwebster-keybinds` regenerates the list from
this `.md` on every launch, so the cheatsheet can never drift from the doc.
Edit the keymap here and the help updates itself.

## 1. Shell & session

| Keys | Action |
|------|--------|
| `Super+Space` | Open app launcher (Omarchy key; stock `caelestia:launcher` is unbound first) |
| `Super` (tap & release) | Open app launcher (tapping another key/mouse cancels it) |
| `Super+Escape` | Session menu (logout / shutdown / reboot) |
| `Ctrl+Alt+Delete` | Session menu (alias, old key) |
| `Super+D` | Toggle dashboard — calendar + widgets (was hover-only) |
| `Super+Alt+Space` | Open Settings (Caelestia nexus) |
| `Super+N` | Toggle sidebar |
| `Super+Ctrl+K` | Show all shell panels |
| `Super+Ctrl+L` | Lock screen (Omarchy key) |
| `Super+Alt+L` | Restart shell daemon + re-lock (recover a broken lock) |
| `Super+Shift+Comma` | Clear all notifications (Omarchy key) |
| `Ctrl+Alt+C` | Clear all notifications (alias, old key) |
| `Ctrl+Super+Shift+R` | Kill the Caelestia shell (`qs -c caelestia kill`) |
| `Ctrl+Super+Alt+R` | Restart the Caelestia shell |
| `Super+Alt+F12` | Fire a test notification (dev/debug) |

## 2. Overview (HyperWebster addition)

| Keys | Action |
|------|--------|
| `Super+Grave` | Toggle the overview sidecar (moved off Super+Tab for Omarchy) |

## 3. Workspaces

| Keys | Action |
|------|--------|
| `Super+1`…`9`,`0` | Go to workspace 1–10 |
| `Super+Tab` | Next workspace (Omarchy key) |
| `Super+Shift+Tab` | Previous workspace (Omarchy key) |
| `Super+Ctrl+Tab` | Back to former workspace (Omarchy key) |
| `Ctrl+Super+1`…`9`,`0` | Go to workspace **group** 1–10 |
| `Ctrl+Super+Left` / `Right` | Previous / next workspace |
| `Super+Page_Up` / `Page_Down` | Previous / next workspace |
| `Super` + scroll up/down | Next / previous workspace |
| `Ctrl+Super` + scroll up/down | Jump workspace group ±10 |
| `Super+S` | Toggle special (scratchpad) workspace |

## 4. Moving windows between workspaces

| Keys | Action |
|------|--------|
| `Super+Shift+1`…`9`,`0` | Move window to workspace 1–10 (Omarchy key) |
| `Super+Alt+1`…`9`,`0` | Move window to workspace 1–10 (alias, old key) |
| `Ctrl+Super+Alt+1`…`9`,`0` | Move window to workspace **group** 1–10 |
| `Super+Alt+Page_Up` / `Page_Down` | Move window to workspace ±1 |
| `Super+Alt` + scroll up/down | Move window to workspace ±1 |
| `Ctrl+Super+Shift+Right` / `Left` | Move window to workspace +1 / −1 |
| `Ctrl+Super+Shift+Up` | Move window to special workspace |
| `Ctrl+Super+Shift+Down` | Move window to first empty workspace |
| `Super+Alt+S` | Move window to special workspace |

## 5. Window focus, move & resize

| Keys | Action |
|------|--------|
| `Super+←/→/↑/↓` | Move focus left/right/up/down |
| `Alt+Tab` / `Shift+Alt+Tab` | Cycle focus next / previous window (Omarchy key) |
| `Super+Shift+←/→/↑/↓` | Move window in that direction |
| `Super+Minus` / `Super+Equal` | Resize narrower / wider (−/+10% width) |
| `Super+Shift+Minus` / `Equal` | Resize shorter / taller (−/+10% height) |
| `Super+Alt+←/→/↑/↓` | Resize active window |
| `Super` + left-drag | Move window (mouse) |
| `Super+Z` + drag | Move window (mouse) |
| `Super` + right-drag | Resize window (mouse) |
| `Super+X` + drag | Resize window (mouse) |
| `Ctrl+Super+\` | Center window |
| `Ctrl+Super+Alt+\` | Resize to 55%×70% and center |
| `Super+Alt+\` | Picture-in-picture (PiP) mode |
| `Super+T` | Toggle floating (Omarchy key) |
| `Super+J` | Toggle window split (Omarchy key) |
| `Super+P` | Pseudo window (Omarchy key) |
| `Super+O` | Pin window — show on all workspaces (Omarchy "pop out") |
| `Super+F` | Fullscreen |
| `Super+Alt+F` | Fullscreen **with borders** |
| `Super+W` | Close window (Omarchy key) |

## 6. Window groups (tabbed stacks)

| Keys | Action |
|------|--------|
| `Super+G` | Toggle group on active window (Omarchy key) |
| `Super+Alt+G` | Move window out of group (Omarchy key) |
| `Super+Alt+Tab` | Cycle to next window in group (Omarchy key) |
| `Super+Alt+Shift+Tab` | Cycle to previous window in group (Omarchy key) |
| `Ctrl+Alt+Tab` | Change active group member (forward) |
| `Ctrl+Shift+Alt+Tab` | Change active group member (backward) |

## 7. Apps

| Keys | Action | App (HyperWebster default) |
|------|--------|----------------------|
| `Super+Return` | Terminal | **kitty** |
| `Super+Shift+Return` | Browser | **chromium** |
| `Super+Shift+B` | Browser (alias) | **chromium** |
| `Super+Shift+N` | Text editor | **gnome-text-editor** |
| `Super+Shift+F` | File manager | **nautilus** |
| `Super+Alt+E` | File manager (alt) | nemo |
| `Super+Shift+G` | GitHub Desktop | github-desktop |
| `Super+I` | Install software (app store) | **Shelly** |
| `Ctrl+Alt+Escape` | Process/task viewer | qps |
| `Super+Ctrl+A` | Audio control (Omarchy key) | pavucontrol |
| `Ctrl+Alt+V` | Audio control (alias) | pavucontrol |
| `Super+Ctrl+H` | Monitor layout editor & profiles | **hyprmoncfg** (TUI) |

> All app binds use Omarchy's keys. Caelestia's stock app picks
> (foot / zen-browser / codium / thunar) are **not installed**; HyperWebster points
> these binds at shipped apps via `hypr-vars.conf`.

## 8. Special-workspace toggles

| Keys | Action |
|------|--------|
| `Super+Ctrl+T` | System monitor — "Activity" (Omarchy key) |
| `Ctrl+Shift+Escape` | System monitor (alias) |
| `Super+Shift+M` | Music (Omarchy key) |
| `Super+M` | Music player — CLIAmp, floating (default for audio files) |
| `Super+Shift+D` | Communication (moved from Super+D — that's the dashboard now) |
| `Super+R` | To-do |

## 9. Screenshots & screen recording

| Keys | Action |
|------|--------|
| `Print` | Region capture (crosshair) → clipboard + ~/Pictures/Screenshots |
| `Shift+Print` | Full screen → clipboard + ~/Pictures/Screenshots |
| `Super+Shift+S` | Region capture, frozen screen (swappy → ~/Pictures/Screenshots) — becomes **Gaming Mode** after opting in (see §14) |
| `Super+Shift+Alt+S` | Region capture, live (swappy → ~/Pictures/Screenshots) |
| `Super+Print` | Color picker — hyprpicker (Omarchy key) |
| `Super+Shift+C` | Color picker (alias) |
| `Super+Ctrl+Print` | OCR — extract text from region → clipboard (Omarchy key) |
| `Ctrl+Alt+R` | Record screen (no audio) |
| `Super+Alt+R` | Record screen **with sound** |
| `Super+Shift+Alt+R` | Record a region |

## 10. Audio & brightness

| Keys | Action |
|------|--------|
| `Super+Ctrl+N` | Toggle night light (hyprsunset blue-light filter) |
| `XF86AudioRaiseVolume` / `LowerVolume` | Volume ±10% (unmutes first) |
| `XF86AudioMute` | Mute / unmute output |
| `XF86AudioMicMute` | Mute / unmute microphone |
| `XF86MonBrightnessUp` / `Down` | Screen brightness up / down |

## 11. Media playback

| Keys | Action |
|------|--------|
| `Ctrl+Super+Space` or `XF86AudioPlay`/`Pause` | Play / pause |
| `Ctrl+Super+Equal` or `XF86AudioNext` | Next track |
| `Ctrl+Super+Minus` or `XF86AudioPrev` | Previous track |
| `XF86AudioStop` | Stop |

## 12. Clipboard & emoji

| Keys | Action |
|------|--------|
| `Super+C` | **Copy** — universal (terminals → Ctrl+Shift+C, GUI → Ctrl+C) |
| `Super+V` | **Paste** — universal (terminals → Ctrl+Shift+V, GUI → Ctrl+V) |
| `Super+Ctrl+V` | Clipboard history (Omarchy key) |
| `Super+Alt+V` | Clipboard history — delete-entry mode |
| `Super+Ctrl+E` | Emoji picker (Omarchy key) |
| `Super+Period` | Emoji picker (alias) |
| `Ctrl+Shift+Alt+V` | Alternate paste — types last clip (needs ydotool, NOT installed: dead bind) |

## 12b. Share & transcode (Omarchy-inspired)

| Keys | Action |
|------|--------|
| `Super+Ctrl+S` | Share files on LAN — opens **omarchy-send** (LocalSend-compatible) |
| `Super+Ctrl+Period` | Transcode picture/video for sharing (fuzzel menus) |

CLI: `omarchy-send`, `hyperwebster-transcode`, bash aliases `img2jpg` / `transcode-video-1080p` (via `omarchy-transcode` shim).

## 13. Power

| Keys | Action |
|------|--------|
| `Super+Shift+L` | Suspend-then-hibernate |

## 14. Gaming Mode (opt-in)

Not active on a fresh install. Opt in on the installed system with
`sh ~/deckshift/deckshift.sh`, then
`sh ~/.local/share/hyperwebster/deckshift-login/install-deckshift-login.sh`.

`Super+Shift+S` is bound in the **base** and self-guards: it launches Gaming Mode
only if DeckShift is installed and **does nothing** otherwise. (It replaces
caelestia's Super+Shift+S screenshot-freeze for everyone — region shots stay on
Print / Shift+Print / Super+Shift+Alt+S.)

| Keys | Action |
|------|--------|
| `Super+Shift+S` | Switch to Gaming Mode (full DeckShift gamescope/Steam session via SDDM restart) **if DeckShift is installed**; does nothing otherwise |
| `Super+Shift+R` | Exit Gaming Mode back to the desktop — works **inside the gaming session only** (or Steam > Power > Exit to Desktop) |

Cold boots always show the SDDM password greeter; only the desktop↔gaming
switch itself skips the password (one-shot autologin).

---

## Source map (for the install-system handoff)

All paths below; `~/.config/hypr` → symlink → `~/.local/share/caelestia/hypr`.

| File | Role |
|------|------|
| `~/.config/hypr/hyprland.conf` | Top-level; sources everything in order |
| `~/.config/hypr/hyprland/keybinds.conf` | **The bind definitions** (uses `$kb*` variables) |
| `~/.config/hypr/variables.conf` | **Default key + app values** (`$kbCloseWindow = Super, Q`, etc.) |
| `~/.config/caelestia/hypr-vars.conf` | **HyperWebster overrides** — app rebinds + flattened styling + **Omarchy `$kb*` remaps** |
| `~/.config/caelestia/hypr-user.conf` | **HyperWebster overrides** — overview (Super+Grave), help binds, **Omarchy unbinds/extra binds**, `kb_layout = gb`, window rules |
| `~/.local/bin/hyperwebster-keybinds-gen` | **Generator** — parses this `.md` → display-ready cheatsheet lines (single source of truth) |
| `~/.local/bin/hyperwebster-keybinds` | **HyperWebster help launcher** — regenerates from this doc each run, shows the fuzzel dmenu |
| `~/.local/share/hyperwebster/keybinds.list` | Generated cache (auto-rebuilt; used as fallback if the doc is missing) |

**How the override layering works** (load order matters — later wins):
`variables.conf` sets stock defaults → `hyprland.conf` sources `hypr-vars.conf`
*before* `keybinds.conf` (so `$kb*` remaps take effect) and `hypr-user.conf`
*after everything* (so its `unbind`/`bind` lines win).

**HyperWebster deltas vs. stock Caelestia:**
- **Key layout remapped to Omarchy defaults** — full mapping table
  and deliberate deviations in `omarchy-keys/README.md`.
- Apps: terminal `foot→kitty`, browser `zen-browser→chromium`,
  editor `codium→gnome-text-editor`, file manager `thunar→nautilus`.
- Added bind: `Super+Grave` → overview sidecar (`exec-once = qs -c overview -d`).
- Added bind: `Super+K` (+ `Super+/`, `Super+F1`) → searchable keybinding
  cheatsheet, **generated from this document** so the two never drift.
- Added bind: `Super+I` → Shelly software store (repos + AUR + Flathub); yay
  and flatpak/Flathub added underneath (see `software-install/`).
- Added binds: `Super+C` / `Super+V` universal copy/paste (clipboard
  history → `Super+Ctrl+V`); `Print` region screenshot;
  `Super+D` dashboard (communication → `Super+Shift+D`).
- Keyboard layout forced to `gb` (UK).
- Glassmorphism off: blur/shadows disabled, opacity 1.0, smaller rounding/gaps.
- Keys left unbound by the Omarchy remap: `Super+Q`, `Super+E`,
  `Super+U`, `Super+Comma`, `Super+L`, `Super+Alt+Space`.

### Rebuild: this whole component ships in Downloads

Because the live system gets wiped and only Downloads is kept, the entire
feature is packaged there and reinstalled with one command per component:

| File in Downloads | Installs to |
|-------------------|-------------|
| `hyperwebster-keybinds-gen` | `~/.local/bin/` (the markdown→list generator) |
| `hyperwebster-keybinds` | `~/.local/bin/` (the cheatsheet launcher) |
| `HyperWebster-keybindings.md` (this file) | `~/.local/share/hyperwebster/` (canonical source of truth) |
| `hyprland-keybinds-help.conf` | appended to `~/.config/caelestia/hypr-user.conf` (Super+/ + F1 binds) |
| `install-keybinds-help.sh` | the installer — run it after rebuild |
| `omarchy-keys/` | the Omarchy remap (vars + user conf + installer) |

```sh
sh ~/Downloads/install-keybinds-help.sh
sh ~/Downloads/omarchy-keys/install-omarchy-keys.sh
```

Installers are idempotent (safe to re-run) and reload Hyprland if it's
running. **No PATH dependency:** binds use the absolute path
`~/.local/bin/hyperwebster-keybinds`, and that script locates its generator next to
itself — so it works even if `~/.local/bin` isn't on the session `PATH`.
No keymap data lives in the scripts; editing this doc is all that's needed to
change the on-screen help. Deps: `awk`, `fuzzel`, optional `wl-copy`.

**To change a binding:** edit `keybinds.conf` for new actions, or redefine the
matching `$kb*` variable. Put HyperWebster-specific changes in `hypr-user.conf` /
`hypr-vars.conf` so they survive a Caelestia update (the `hypr` symlink target
gets overwritten on upgrade; the two override files do not).

---
*Keybindings follow Omarchy defaults; the Super+K cheatsheet is generated from this file.*
