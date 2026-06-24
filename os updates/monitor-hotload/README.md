# monitor-hotload — hot-apply saved hyprmoncfg profiles

Follow-up to monitor-control and monitor-control-fix.

## Symptom

Save a monitor profile in the `Super+Ctrl+H` TUI and nothing changes
live: `~/.config/hypr/monitors.conf` is untouched and the layout/scale
stays as-is until the next login (or a monitor hotplug). A profile saved
remains unapplied until `systemctl --user restart hyprmoncfgd` is run,
which applies it instantly
(`best profile … score=100` → `applied profile`).

## Cause

Two upstream behaviours compound:

1. The TUI's plain **"Save Profile"** action only writes the snapshot to
   `~/.config/hyprmoncfg/profiles/` — applying is a separate
   **"Save & Apply"** action, which is easy to miss.
2. `hyprmoncfgd` re-evaluates profiles only on **startup, monitor
   hotplug (event or poll) and lid events** (see its `triggered:` log
   lines). It does not watch the profiles directory, so a new or edited
   profile is invisible to it until one of those triggers happens —
   on a desktop with one monitor, effectively never.

## Fix

A systemd user **path unit** closes the gap:

- `hyprmoncfgd-rescan.path` — watches `~/.config/hyprmoncfg/profiles`
  (`PathChanged=`, i.e. create/delete/rename/write-close inside the dir).
- `hyprmoncfgd-rescan.service` — oneshot
  `systemctl --user try-restart hyprmoncfgd` (`try-restart` so a daemon
  the user deliberately stopped stays stopped).

The daemon applies the best-scoring profile on startup, so a bounce IS
the rescan. Net effect: any save/edit/delete in the profiles dir is
applied within a couple of seconds. The daemon never writes to the
profiles dir itself, so this cannot loop.

Worth upstreaming to hyprmoncfg: the daemon could inotify-watch its own
profiles dir natively.

## Files

| File | Role |
|------|------|
| `install-monitor-hotload.sh` | idempotent installer — installs + enables both units, pre-creates the watched dir (no sudo) |
| `hyprmoncfgd-rescan.path` | watches the profiles dir |
| `hyprmoncfgd-rescan.service` | oneshot daemon bounce |

## Packaging

- Bake both units into the user skeleton and enable
  `hyprmoncfgd-rescan.path` alongside `hyprmoncfgd` (presets or
  skeleton symlink in `default.target.wants`).
- Pre-create `~/.config/hyprmoncfg/profiles/` (empty — the no-pre-seeded-
  profiles rule from monitor-control still stands; an empty dir is fine and the
  path unit needs it to exist).

## Test

1. `journalctl --user -fu hyprmoncfgd` in one terminal.
2. `Super+Ctrl+H`, change something (e.g. scale), plain **Save Profile**,
   quit the TUI.
3. Within ~2s the journal shows a daemon restart →
   `best profile … score=100` → `applied profile`, and the change is
   live; `~/.config/hypr/monitors.conf` reflects it.
4. Relogin → same layout, no error notification (the monitor-control-fix
   `ExecStartPre` gate still covers the login race).

No new keybinds; nothing to add to `HyperWebster-keybindings.md`.

## Behaviour

A file created in the profiles dir fires the path unit → the daemon bounces
and re-applies the saved profile (`score=100`) within 2s.
