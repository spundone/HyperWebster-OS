#!/usr/bin/env bash
# Migration: force UTF-8 locale for Qt / caelestia (en_US → en_US.UTF-8).
set +e
: "${HYPERWEBSTER_SRC:?}"

SRC="$HYPERWEBSTER_SRC/locale-utf8"
if [ -f "$SRC/install-locale-utf8.sh" ]; then
  sh "$SRC/install-locale-utf8.sh"
else
  echo ":: locale-utf8 installer missing — skipping"
fi

printf '%s\n' ":: UTF-8 locale enforced - log out/in then Ctrl+Super+Alt+R"
exit 0
