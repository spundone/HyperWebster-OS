# HyperWebster — system polish bundle

Three small quality-of-life pieces in one bundle.

## A. Menu cleanup + working printing

**Hidden launcher entries** (per-user `Hidden=true` overrides in
`~/.local/share/applications/` — survive package upgrades, deleting the
override restores the entry):

| Entry | Why hidden |
|-------|-----------|
| `avahi-discover`, `bssh`, `bvnc` | Avahi's bundled mDNS browser tools — diagnostic clutter. **The avahi-daemon itself stays** (needed for `.local` resolution and network printer discovery) |
| `qv4l2`, `qvidcap` | V4L2 camera test tools |
| `foot`, `footclient`, `foot-server` | Caelestia's stock terminal; HyperWebster uses kitty. Package stays (caelestia-meta dep) — just hidden |
| `org.gnupg.pinentry-qt`, `-qt5` | GPG PIN dialogs, not launchable apps |

**Printing:** the full stack (cups + system-config-printer + avahi) is
installed on the base but `cups.service` was disabled — so printing silently
didn't work. The installer enables **`cups.socket`** (socket-activated: zero
cost until something prints). Print dialogs and `system-config-printer` then
work, with network printers auto-discovered via avahi.

## B. Web-app installer

The piece of Omarchy's app story not covered by the software-install and keybinding components:

```sh
hyperwebster-webapp-install "WhatsApp" https://web.whatsapp.com https://example.com/icon.png
hyperwebster-webapp-remove  "WhatsApp"
```

Creates a launcher entry running `chromium --app=<url>` (no tabs/omnibox —
feels like a native app). Icon URL optional (generic web icon otherwise).
Icons live in `~/.local/share/applications/icons/`.

## C. First-login welcome

`hyperwebster-welcome` (started by `exec-once` in `hypr-user.conf`) shows one
notification on first login pointing at the discoverability keys —
`Super+K` keybindings, `Super+Space` launcher, `Super+I` software,
`Super+Ctrl+H` monitors — then stamps
`~/.local/state/hyperwebster/welcomed` and never appears again. (Remove the stamp
to see it again.)

## Install

```sh
sh ~/Downloads/system-polish/install-system-polish.sh   # sudo only for cups.socket
```

Also wired into `hyperwebster-update` as migration `1781240400-system-polish.sh`.

## Packaging

- Bake the hidden-entry overrides into the user skeleton, enable
  `cups.socket` in the image (`systemctl enable cups.socket`), ship the three
  scripts in `~/.local/bin`, and put the welcome `exec-once` in the baked
  `hypr-user.conf` (don't pre-create the stamp!).
- Optionally pre-seed a couple of web apps (e.g. YouTube, WhatsApp) by
  running `hyperwebster-webapp-install` in the skeleton — keep it minimal.
