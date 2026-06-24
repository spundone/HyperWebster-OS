# additions-installer - Settings → Additions (optional software on demand)

Turns the Settings app's placeholder **Plugins** section
into an **Additions** page: a curated list of optional software with
one-click installs.

## Sources policy

**No AUR. No Flatpak.** Official pacman repos or official upstream
installers/git only:

| Item | Source |
|------|--------|
| DeckShift Gaming Mode | official git - `https://git.no-signal.uk/hyperwebster/deckshift.git` → `deckshift.sh` → **deckshift-login installer** (the one-shot-autologin fix, always run after deckshift.sh) |
| Spotify | `[omarchy]` pacman repo (proprietary - no upstream git exists) |
| Once (Basecamp) | `[omarchy]` pacman repo (`once-bin`) |
| Obsidian | Arch `[extra]` |
| OBS Studio | Arch `[extra]` (`obs-studio`) + **GPU-detected encoder runtimes** via `obs-extras.sh` (see below) |
| Claude Code | official installer - `curl -fsSL https://claude.ai/install.sh \| bash` |
| Codex CLI | official installer - `curl -fsSL https://chatgpt.com/codex/install.sh \| sh` |
| opencode | official installer - `curl -fsSL https://opencode.ai/install \| bash` |

## OBS hardware encoders (obs-extras.sh)

First-round testing found `obs-studio` alone ships only the x264
software encoder path. The ISO lands on arbitrary GPUs (AMD / Intel /
NVIDIA, any mix), so the OBS entry delegates check AND install to
**`obs-extras.sh`**, which detects GPUs via `lspci` per machine:

- **AMD** - VAAPI (H.264/HEVC/AV1) ships inside mesa: nothing to add.
- **Intel** - installs `intel-media-driver` + `vpl-gpu-rt` (QSV).
- **NVIDIA** - NVENC comes with the proprietary driver; deliberately
  not auto-installed (driver branch is a system decision - see
  gaming-enablement); prints a pointer if the driver is absent.

Because the *check* also requires the detected runtimes, an OBS
installed without them shows as not-installed - clicking Install
completes the set idempotently.

## How it works (same mechanism as the Updates page)

- **`additions.json`** - the manifest, single source of truth. Per item:
  `id`, `name`, `desc`, `icon` (Material Symbol), `check` (sh, exit 0 =
  installed), `install` (sh). Edit this file to add/remove items - no
  code changes needed.
- **`hyperwebster-additions`** (`~/.local/bin`) - `status` re-runs every check
  and writes `~/.local/state/hyperwebster/additions-status.json`;
  `install <id>` runs the item's installer then re-statuses;` list`.
- **`AdditionsPage.qml`** - reads the status cache; each item is a row
  (Installed ✓ or description + click-to-install). Installs run in a
  visible floating terminal (`kitty --class TUI.float`) so git/sudo/
  pacman prompts stay in front of the user. Modeled line-for-line on
  UpdatesPage (Process objects inside the layout - see the comment).
- **`patch-additions-page.sh`** - root-run, idempotent: installs the
  page QML, swaps the *remaining* System `PlaceholderComp` (the Plugins
  stub) for the page, and relabels the menu entry
  Plugins → Additions / "Install optional software".
  **Ordering: requires the Updates-page patch first** - before it,
  the first placeholder is the Updates stub (guarded: warns and skips).
  Backups at `*.pre-hyperwebster-additions`; warns and degrades gracefully on
  upstream drift.
- **pacman hook** (`hyperwebster-additions-page.hook`) re-applies after every
  caelestia-shell upgrade.

## Packaging

- Ship the component in the layer tree + COPY-list; migration
  `1781420400-additions-installer.sh` (sorts after the cliamp-music migration; add to the
  baked `applied` list).
- The patch can be baked at image build (after the Updates-page patch).
- Do NOT pre-install any of the additions - the page is the opt-in.

## Version pins / drift

- Registry patch pinned against caelestia-shell **2.0.2** (same pin as
  the Updates page; both patch scripts warn-and-degrade on drift).
- The three `curl | sh` installers and the DeckShift git URL are
  upstream-controlled endpoints; if one moves, only `additions.json`
  needs editing.

## Test

1. Settings → System shows **Additions** (not "Plugins"); page lists 8
   items with sensible installed/not-installed state.
2. Install something small (e.g. Obsidian) → floating terminal, sudo
   prompt, pacman runs → row flips to "Installed" after the terminal
   closes.
3. "Re-check installed state" refreshes after installing/removing
   something from a terminal.
4. DeckShift entry: full chain (clone → deckshift.sh → deckshift-login
   fix), then the Gaming Mode checklist items apply (Super+Shift+S etc.).
