# starman-gaming-boot — Limine → Steam / gamescope session

Adds a **Starman (Gaming / Steam)** entry to the Limine boot menu (baked in
`hyperwebster.sh`). Selecting it appends `hyperwebster.starman=1` to the kernel
command line.

`hyperwebster-starman-boot.service` runs before SDDM and arms the same one-shot
autologin marker used by DeckShift's `gaming-session-switch` — so cold boots
via the Starman entry land in the gamescope Steam session **without** a password,
while normal boots still show the SDDM greeter.

## Prerequisites

DeckShift must be installed once (ships gaming session + switch scripts):

```sh
sh ~/deckshift/deckshift.sh
sh ~/.local/share/hyperwebster/deckshift-login/install-deckshift-login.sh
```

## Files

```
hyperwebster-starman-arm          -> /usr/local/bin
hyperwebster-starman-boot.service -> /etc/systemd/system
install-starman-gaming-boot.sh    idempotent installer (sudo)
```

## Test

1. Install DeckShift + deckshift-login (above).
2. Reboot → pick **Starman (Gaming / Steam)** in Limine.
3. SDDM autologins into Steam Big Picture (gamescope session).
4. Exit to desktop via Steam or `Super+Shift+R`.
5. Reboot normally (default Limine entry) → password greeter returns.
