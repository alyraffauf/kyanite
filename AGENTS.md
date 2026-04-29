# Agent Instructions for Kyanite

Kyanite is a bootc OS based on Fedora Kinoite (KDE Plasma).

## PRE-COMMIT CHECKLIST

1. **Conventional Commits** - Format: `type(scope): description`
2. **Shellcheck** - Run on all `.sh` files
3. **Validate** - `jq empty packages.json services.json` and `just --list`
4. **Confirm** - Always ask before committing

Valid types: `feat`, `fix`, `docs`, `chore`, `build`, `ci`, `refactor`, `test`

## CRITICAL RULES

1. Use `dnf5 -y` exclusively in build scripts (never `dnf`, `yum`, `rpm-ostree`)
2. Disable COPR repos after install via `copr_install_isolated`
3. Never use `dnf5` in ujust files (immutable system)
4. Never hardcode variant packages/services in build scripts
5. All packages live under `packages.json` `"variants.{name}.include"` — the `main` variant is the base applied to every image
6. All services live under `services.json` `"variants.{name}.system.enable"` (or `.user.enable`) — same rule, `main` is the base
7. Third-party software → `build/03-third-party-packages.sh`

## QUICK REFERENCE

| Task                   | Location                          | Format                                     |
| ---------------------- | --------------------------------- | ------------------------------------------ |
| Add base package       | `packages.json`                   | `"variants.main.include"` array            |
| Add variant package    | `packages.json`                   | `"variants.{name}.include"` array          |
| Remove package         | `packages.json`                   | `"variants.{name}.exclude"` array          |
| Enable base service    | `services.json`                   | `"variants.main.system.enable"` array      |
| Enable variant service | `services.json`                   | `"variants.{name}.system.enable"` array    |
| Add 3rd-party RPM      | `build/03-third-party-packages.sh`| See examples                               |
| Add COPR package       | `build/03-third-party-packages.sh`| `copr_install_isolated "owner/repo" "pkg"` |
| Add Homebrew package   | `brew/{variant}/*.Brewfile`       | `brew "package-name"`                      |
| Add Flatpak            | `flatpaks/{variant}.preinstall`   | `[Flatpak Preinstall app.id]`              |
| Add ujust command      | `ujust/{variant}/*.just`          | Just recipe syntax                         |

## VARIANTS

Built images: `kyanite`, `kyanite-dx`, `kyanite-gaming`, `kyanite-dx-gaming`

Variants use **exact matching** by splitting `IMAGE_FLAVOR` on hyphens:

- `IMAGE_FLAVOR=gaming` → `["gaming"]`
- `IMAGE_FLAVOR=dx-gaming` → `["dx", "gaming"]` (installs both)

### Configuration Layers

**1. Packages** (`packages.json`):

```json
{
    "variants": {
        "main": { "include": ["common-pkg"], "exclude": [] },
        "gaming": { "include": ["steam"], "exclude": [] }
    }
}
```

**2. Services** (`services.json`):

```json
{
    "variants": {
        "main": {
            "system": { "enable": ["podman.socket"], "disable": [] },
            "user": { "enable": [], "disable": [] }
        },
        "gaming": {
            "system": { "enable": [], "disable": [] }
        }
    }
}
```

**3. Files** (`files/{variant}/`):

- `files/main/` → Always copied (base for all images)
- `files/gaming/` → Copied when variant contains "gaming"
- `files/dx/` → Copied when variant contains "dx"

**4. Branding** (automatic):

- `IMAGE_FLAVOR=dx-gaming` → KDE About shows "Variant=DX+GAMING"

## BUILD SCRIPTS (Order)

1. `01-build.sh` - Orchestration, file/Brewfile/ujust/flatpak-preinstall copying per variant
2. `02-fedora-packages.sh` - Packages from `packages.json` (also pins `plasma-desktop` and installs `development-tools` group)
3. `03-third-party-packages.sh` - Cider, Tailscale, COPR; Docker CE + VSCode for `dx`; Sunshine for `gaming`
4. `04-workarounds.sh` - Compatibility fixes (e.g. Ghostty KDE shortcut)
5. `05-systemd.sh` - Services from `services.json`
6. `06-homebrew.sh` - Homebrew system files + service presets
7. `07-branding.sh` - OS release + KDE branding
8. `08-cleanup.sh` - Hide unused desktop entries, fix bootc lint, `ostree container commit`

## STRUCTURE

```
kyanite/
├── Containerfile          # Build definition
├── packages.json          # Package lists
├── services.json          # Service configuration
├── build/                 # Build scripts
├── files/                 # System files
│   ├── main/             # All variants (base)
│   ├── dx/               # Developer variant
│   └── gaming/           # Gaming variant
├── brew/                  # Homebrew Brewfiles
├── flatpaks/              # Flatpak preinstall files
│   ├── main.preinstall
│   └── gaming.preinstall
├── ujust/                 # User commands by variant
│   ├── main/             # Commands for all images
│   ├── dx/               # Developer commands
│   └── gaming/           # Gaming commands
└── .github/workflows/     # CI/CD
```

## LOCAL TESTING

```bash
just build                    # Build container
just build-qcow2             # Build VM image
just run-vm-qcow2            # Test in VM

# Variants
IMAGE_FLAVOR=gaming just build
IMAGE_FLAVOR=dx-gaming just build
```

## COMMON PATTERNS

### Add Third-Party RPM

```bash
# In build/03-third-party-packages.sh
dnf5 config-manager addrepo --from-repofile=https://example.com/repo.repo
dnf5 config-manager setopt example-repo.enabled=0
dnf5 -y install --enablerepo='example-repo' package-name
```

### Add COPR Package

```bash
# In build/03-third-party-packages.sh
source /ctx/build/copr-helpers.sh
copr_install_isolated "owner/repo" "package-name"
```

## UJUST RULES

- Never use `dnf5` (system is immutable)
- Create shortcuts to Brewfiles/Flatpaks
- Use `[group('Category')]` for organization
- Source `/usr/lib/ujust/ujust.sh` for helpers

## DOCUMENTATION

- **README.md** - User overview, install/build instructions
- **brew/README.md** - Homebrew Brewfile conventions
- **flatpaks/README.md** - Flatpak preinstall format
- **ujust/README.md** - Custom ujust recipe conventions

## REFERENCES

- [Universal Blue](https://universal-blue.org/)
- [bootc](https://containers.github.io/bootc/)
- [Just Manual](https://just.systems/man/en/)
