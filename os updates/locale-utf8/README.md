# Locale UTF-8 fix

Qt and caelestia/quickshell require a UTF-8 locale. Some installs end up with
`LANG=en_US` (ISO-8859-1), which produces:

```
Detected locale "en_US" with character encoding "ISO-8859-1", which is not UTF-8.
Qt depends on a UTF-8 locale, and has switched to "en_US.UTF-8" instead.
```

## Apply

```sh
sh ~/.local/share/hyperwebster/locale-utf8/install-locale-utf8.sh
# or via hyperwebster-update migration
```

Then log out/in (or reboot). For an already-running shell in this session:

```sh
export LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8
qs -c caelestia kill 2>/dev/null
caelestia shell -d
```

Upstream credit: Arch `locale.conf` / `locale-gen`, systemd `environment.d`.
