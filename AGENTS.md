# Agent Instructions for Kyanite

Kyanite is a bootc OS based on Fedora Kinoite (KDE Plasma).

## PRE-COMMIT CHECKLIST

1. **Conventional Commits** - Format: `type(scope): description`
2. **Shellcheck** - Run on all `.sh` files
3. **Validate** - `jq empty packages.json services.json` and `just --list`
4. **Confirm** - Always ask before committing

Valid types: `feat`, `fix`, `docs`, `chore`, `build`, `ci`, `refactor`, `test`

## CRITICAL RULES

1. Use `dnf5 -y` exclusively (never `dnf`, `yum`, `rpm-ostree`)
2. Disable COPR repos after install via `copr_install_isolated`
3. Never use `dnf5` in ujust files (immutable system)
4. Never hardcode variant packages/services in build scripts
5. System packages → `packages.json` `"include"`
6. Variant packages → `packages.json` `"variants.{name}.include"`
7. System services → `services.json` `"system.enable"`
8. Variant services → `services.json` `"variants.{name}.system.enable"`
9. Third-party software → `build/25-third-party-packages.sh`

## QUICK REFERENCE

| Task                   | Location                       | Format                                     |
| ---------------------- | ------------------------------ | ------------------------------------------ |
| Add system package     | `packages.json`                | `"include"` array                          |
| Add variant package    | `packages.json`                | `"variants.{name}.include"` array          |
| Remove package         | `packages.json`                | `"exclude"` array                          |
| Enable system service  | `services.json`                | `"system.enable"` array                    |
| Enable variant service | `services.json`                | `"variants.{name}.system.enable"` array    |
| Add 3rd-party RPM      | `build/25-third-party-*.sh`    | See examples                               |
| Add COPR package       | `build/25-third-party-*.sh`    | `copr_install_isolated "owner/repo" "pkg"` |
| Add Homebrew package   | `brew/*.Brewfile`              | `brew "package-name"`                      |
| Add Flatpak            | `flatpaks/{flavor}.preinstall` | `[Flatpak Preinstall app.id]`              |
| Add ujust command      | `ujust/{flavor}/*.just`        | Just recipe syntax                         |

## VARIANTS

Built images: `kyanite`, `kyanite-dx`, `kyanite-gaming`, `kyanite-dx-gaming`

Variants use **exact matching** by splitting `IMAGE_FLAVOR` on hyphens:

- `IMAGE_FLAVOR=gaming` → `["gaming"]`
- `IMAGE_FLAVOR=dx-gaming` → `["dx", "gaming"]` (installs both)

### Configuration Layers

**1. Packages** (`packages.json`):

```json
{
    "include": ["common-pkg"],
    "variants": {
        "gaming": { "include": ["steam"], "exclude": [] }
    }
}
```

**2. Services** (`services.json`):

```json
{
    "system": { "enable": ["docker.socket"], "disable": [] },
    "variants": {
        "gaming": { "system": { "disable": ["sunshine.service"] } }
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

1. `10-build.sh` - Orchestration, file copying
2. `20-fedora-packages.sh` - Packages from packages.json
3. `25-third-party-packages.sh` - Docker, Tailscale, COPR
4. `30-workarounds.sh` - Compatibility fixes
5. `40-systemd.sh` - Services from services.json
6. `80-branding.sh` - OS release + KDE branding
7. `90-cleanup.sh` - Cleanup

See `build/README.md` for details.

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
├── ujust/                 # User commands by flavor
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
# In build/25-third-party-packages.sh
dnf5 config-manager addrepo --from-repofile=https://example.com/repo.repo
dnf5 config-manager setopt example-repo.enabled=0
dnf5 -y install --enablerepo='example-repo' package-name
```

### Add COPR Package

```bash
# In build/25-third-party-packages.sh
source /ctx/build/copr-helpers.sh
copr_install_isolated "owner/repo" "package-name"
```

## UJUST RULES

- Never use `dnf5` (system is immutable)
- Create shortcuts to Brewfiles/Flatpaks
- Use `[group('Category')]` for organization
- Source `/usr/lib/ujust/ujust.sh` for helpers

## DOCUMENTATION

- **BUILD.md** - Build system architecture
- **build/README.md** - Build scripts reference
- **custom/\*/README.md** - Runtime customization guides
- **README.md** - User overview

## REFERENCES

- [Universal Blue](https://universal-blue.org/)
- [bootc](https://containers.github.io/bootc/)
- [Just Manual](https://just.systems/man/en/)
