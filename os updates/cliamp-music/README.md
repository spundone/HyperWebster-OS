# cliamp-music - CLIAmp as the default music player

Adds a default music player - HyperWebster previously had none.

## What

[CLIAmp](https://github.com/search?q=cliamp) - "a retro terminal music
player inspired by Winamp 2.x" - is what Omarchy ships for terminal
music (their `omarchy-launch-or-focus-tui cliamp` bind), and it is
prebuilt in the `[omarchy]` pacman repo HyperWebster already carries
(v1.57.0 at time of writing; deps pull in ffmpeg and yt-dlp).

- **Package:** `cliamp` from `[omarchy]` (repo install, no AUR build).
- **Default player:** `cliamp.desktop` (launches in kitty, class
  `cliamp`) + `xdg-mime default` for 12 common audio types, mirroring
  the style of omarchy's `install/config/mimetypes.sh` (which sets no
  audio defaults itself). Opening an audio file anywhere now starts
  CLIAmp.
- **Keybind:** `Super+M` → launch-or-focus CLIAmp, floating 1100×700
  (same shape as the other HyperWebster TUI tools). Before this change both
  `Super+M` and `Super+Shift+M` toggled the shell's music panel (an
  MPRIS controller, not a player); the panel keeps `Super+Shift+M`.
  Launch-or-focus is inlined (`hyprctl dispatch focuswindow … || kitty …`)
  since HyperWebster does not ship omarchy's helper - note `hyprctl` exits 0
  even when no window matches, so the check greps for `ok`.
- **Keymap doc:** `Super+M` row updated (the Super+K cheatsheet
  regenerates from it on next open).

## Files

| File | Role |
|------|------|
| `install-cliamp-music.sh` | idempotent installer - package (sudo), desktop entry, MIME defaults, marked bind block, keymap doc row |
| `cliamp.desktop` | desktop entry: `kitty --class cliamp -e cliamp %F` + audio MimeType list |
| `hyprland-cliamp.conf` | `# >>> cliamp music player >>>` marked block (float rules + Super+M), appended to hypr-user.conf |

## Packaging

- Add `cliamp` to the package list (from `[omarchy]`).
- Bake the desktop entry, the MIME defaults (skeleton
  `~/.config/mimeapps.list`), the marked block (verbatim, markers
  included - the installer greps for it), and the keymap doc row.

## Test

1. `Super+M` → CLIAmp opens floating; `Super+M` again focuses it
   (no second instance). `Super+Shift+M` still toggles the music panel.
2. Open an `.mp3`/`.flac` from the file manager → opens in CLIAmp.
3. `xdg-mime query default audio/mpeg` → `cliamp.desktop`.
4. Super+K lists `Super+M  Music player - CLIAmp…`.

## Notes

cliamp 1.57.0-1 installed; audio/mpeg and audio/flac
default to cliamp.desktop; runtime binds confirm Super+M →
launch-or-focus CLIAmp and Super+Shift+M → music panel; keymap doc row
present.
