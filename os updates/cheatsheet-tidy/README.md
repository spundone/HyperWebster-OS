# cheatsheet-tidy — Super+K panel shows key + action only, fitted

Reworks the cheatsheet output so the Super+K panel stays compact.

## Symptom

The Super+K panel was cluttered and overflowed: a `[Section]` tag column
ate ~20 chars of every line, actions carried doc-provenance notes like
"(Omarchy key)", and lines ran up to 200 chars in a
72-char fuzzel panel — long actions were simply cut off mid-word.

## Fix

Full replacements of the two keybinds-help scripts (kept small on purpose —
the markdown stays the single source of truth and is untouched):

- **`hyperwebster-keybinds-gen`** — output is now two columns, key + action:
  - section tag column dropped (the markdown keeps its sections);
  - doc-only parentheticals stripped from actions — anything matching
    provenance patterns (`Omarchy`, `change N`, `(was …`, `moved`,
    `HyperWebster`, `dev/debug`); meaningful ones like
    "(logout / shutdown / reboot)" and "(alias, old key)" stay;
  - actions ellipsis-truncated to `$HYPERWEBSTER_KEYS_COLS` (default 98) so
    every line fits the panel.
- **`hyperwebster-keybinds`** — fuzzel `--width` 72 → 100, in sync with the
  generator budget (98 = 100 − margin). Comment in each file points at
  the other.

Result on the current keymap: 108 rows, all ≤ 98 chars, 6 lightly
ellipsis-truncated, none cut off by the panel.

The installer also refreshes the flat layer-root copies of both scripts
so a re-run of `install-keybinds-help.sh` cannot
regress the panel.

## Packaging

Replace the two scripts in the keybinds-help source with
these versions — this component then becomes part of keybinds-help rather
than a permanent overlay. No package/config delta, no keybind changes.

## Test

1. `Super+K` → every visible line is `KEY  action`, no `[Section]`
   tags, no "(Omarchy key)"-style noise, no line wider than the panel.
2. Type to filter (e.g. "workspace") — still searchable.
3. Select a line → still copies the shortcut to the clipboard.
4. `hyperwebster-keybinds-gen | awk '{print length($0)}' | sort -rn | head -1`
   ≤ 98.

## Notes

Cached list regenerated; max line length 98/98;
row count identical before/after (108).
