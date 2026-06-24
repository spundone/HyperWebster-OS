#!/usr/bin/env bash
# 1781456400-sudo-timed-nopasswd.sh
# Delegates to the time-boxed passwordless-sudo installer (Settings -> Services
# toggle "Passwordless sudo (15 min)"). Does NOT enable sudoless — only installs
# the CLI, the boot-clean safety service, and the panel toggle. Idempotent.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sudo sh "$HYPERWEBSTER_SRC/sudo-timed-nopasswd/install-sudo-timed-nopasswd.sh"
