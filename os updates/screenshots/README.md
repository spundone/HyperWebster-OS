# screenshots — Print = region capture, everything saved to Pictures

| Key | Action |
|-----|--------|
| `Print` | Select a region (crosshair) → clipboard **and** `~/Pictures/Screenshots` |
| `Shift+Print` | Whole screen → clipboard **and** `~/Pictures/Screenshots` |
| `Super+Shift+S` | Region with freeze + annotate (caelestia/swappy) — now saves to Pictures too |
| `Super+Shift+Alt+S` | Region annotate (caelestia/swappy) — saves to Pictures too |

## What & why

`hyperwebster-screenshot` (a small grim/slurp wrapper) is the single quick-capture
path: it **always** writes a PNG to `~/Pictures/Screenshots` *and* copies the
image to the clipboard, then notifies. caelestia's own region/freeze binds pipe
into `swappy`, which had no save dir configured — so this also writes a swappy
config pointing `save_dir` at `~/Pictures/Screenshots`. Net result: every
screenshot path lands in Pictures.

`Print` is remapped from stock full-screen-to-clipboard to **region** (the
crosshair selection you wanted); full screen moves to `Shift+Print`.
(`Super+Print` is left as the HyperWebster color picker, `hyprpicker -a`.)

**No package delta** — `grim`, `slurp`, `swappy`, `wl-clipboard`, `libnotify`
are all in the base image.

## Files

- `hyperwebster-screenshot` → `~/.local/bin`
- `swappy-config` → `~/.config/swappy/config` (only if absent / previously ours)
- binds appended to `~/.config/caelestia/hypr-user.conf` (idempotent marked block)

## Install

```sh
sh install-screenshots.sh
```

## Builder notes

- caelestia already defaults `screenshots_dir` to `$XDG_PICTURES_DIR/Screenshots`
  (`caelestia/utils/paths.py`), so the fullscreen "Save" action already lands in
  Pictures; this change makes the *region/swappy* and *quick Print* paths match.
- If baking binds directly, write the marked block from `install-screenshots.sh`
  into the shipped `hypr-user.conf`, drop `hyperwebster-screenshot` in `~/.local/bin`,
  and ship `swappy-config` as `~/.config/swappy/config`.
