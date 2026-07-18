# system-tools - Settings page for account photo and system apps

Adds **Settings → System tools** with:

| Section | Actions |
|---------|---------|
| Account | Change / reset profile photo (`~/.face`) - circular crop on lock + dashboard |
| Display & input | hyprmoncfg, keyboard/mouse remap, pavucontrol, Bluetooth |
| System | CachyOS kernel manager, btop, snapshots, maintenance menu |

## Install

```sh
sh ~/.local/share/hyperwebster/system-tools/install-system-tools.sh
```

Or via `hyperwebster-update` migration. Then **Ctrl+Super+Alt+R**.

## Lock screen

`lockscreen-polish` clips the avatar to a circle and prefers `~/.face` over the
Starman mark when a photo is set.
