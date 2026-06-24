# base-default-packages (installed by default, not opt-in)

The install command needs root — run it once.

Packages that should ship **installed by default** in the base build (distinct
from the opt-in Settings → Additions). Official repos only; GPU-agnostic.

| Package | Provides | Repo | Why |
|---------|----------|------|-----|
| `github-cli` | `gh` | extra | GitHub CLI — default dev tooling (PRs, issues, repo ops, auth) |

## Builder integration
Add the package(s) above to the ISO base package set. `install-base-default-
packages.sh` covers already-installed machines (idempotent `pacman -S --needed`)
and is wired via the migration below.

## Apply on an existing box
```
sudo pacman -S --needed github-cli
```

## Files
- `install-base-default-packages.sh` — idempotent installer (root).
- `migrations/1781452800-base-default-packages.sh` — delegates to it.
