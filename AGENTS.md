# Agent Instructions for Kyanite

Kyanite is a bootc OS based on Fedora Kinoite (KDE Plasma). This guide covers critical rules and quick references for AI agents.

## PRE-COMMIT CHECKLIST ⚠️

**Execute before EVERY commit:**

1. **Conventional Commits** - Required format: `type(scope): description`
2. **Shellcheck** - Run on all modified `.sh` files
3. **YAML validation** - Validate all modified `.yml` files
4. **JSON validation** - Run `jq empty packages.json services.json` to validate
5. **Justfile syntax** - Run `just --list` to verify
6. **User confirmation** - Always confirm before committing

**Valid commit types**: `feat`, `fix`, `docs`, `chore`, `build`, `ci`, `refactor`, `test`

**Never commit files with syntax errors.**

## CRITICAL RULES

1. **ALWAYS** use `dnf5` exclusively (never `dnf`, `yum`, or `rpm-ostree`)
2. **ALWAYS** use `-y` flag for non-interactive installs
3. **ALWAYS** disable COPR repos after installation via `copr_install_isolated`
4. **NEVER** use `dnf5` in ujust files (immutable system)
5. **NEVER** commit secrets or private keys
6. **NEVER** hardcode variant packages or services in build scripts
7. System packages → `packages.json` under `"include"`
8. Variant packages → `packages.json` under `"variants.{name}.include"`
9. System services → `services.json` under `"system.enable"`
10. Variant services → `services.json` under `"variants.{name}.system.enable"`
11. Third-party software → `build/25-third-party-packages.sh`

## QUICK REFERENCE

| Task                  | Location                       | Command/Format                                        |
| --------------------- | ------------------------------ | ----------------------------------------------------- |
| Add system package    | `packages.json`                | Add to `"include"` array                              |
| Add variant package   | `packages.json`                | Add to `"variants.{name}.include"` array              |
| Remove package        | `packages.json`                | Add to `"exclude"` array                              |
| Remove variant pkg    | `packages.json`                | Add to `"variants.{name}.exclude"` array              |
| Enable system service | `services.json`                | Add to `"system.enable"` array                        |
| Enable user service   | `services.json`                | Add to `"user.enable"` array                          |
| Enable variant svc    | `services.json`                | Add to `"variants.{name}.system.enable"` array        |
| Disable service       | `services.json`                | Add to `"system.disable"` or `"user.disable"` array   |
| Add 3rd-party RPM     | `build/25-third-party-*.sh`    | See Docker/Cider/Tailscale examples                   |
| Add COPR package      | `build/25-third-party-*.sh`    | `copr_install_isolated "owner/repo" "pkg"`            |
| Add Homebrew package  | `custom/brew/*.Brewfile`       | `brew "package-name"`                                 |
| Add Flatpak           | `custom/flatpaks/*.preinstall` | `[Flatpak Preinstall app.id]`                         |
| Add ujust command     | `custom/ujust/*.just`          | Just recipe syntax                                    |
| Test locally          | Terminal                       | `just build && just build-qcow2 && just run-vm-qcow2` |

## IMAGE VARIANTS

Multiple variants can be built from single Containerfile using `IMAGE_FLAVOR`:

- **main** (default) → `kyanite` - Base KDE Plasma desktop
- **gaming** → `kyanite-gaming` - Adds Steam, Gamescope, GameMode, MangoHud, Sunshine
- **Combined variants** → `kyanite-gaming-dx-nvidia` - Multiple features combined

### Variant Architecture

All variants use **exact matching** (not substring matching) by splitting `IMAGE_FLAVOR` on hyphens:

- `IMAGE_FLAVOR=main` → `["main"]` → Installs main-specific packages/services/files
- `IMAGE_FLAVOR=gaming` → `["gaming"]` → Installs gaming-specific packages/services/files
- `IMAGE_FLAVOR=gaming-dx` → `["gaming", "dx"]` → Installs both gaming AND dx packages/services/files

### Four Declarative Layers

**1. Packages** (`packages.json`):

```json
{
    "include": ["common-package"],
    "variants": {
        "gaming": {
            "include": ["steam", "gamescope"],
            "exclude": []
        }
    }
}
```

**2. Services** (`services.json`):

```json
{
    "system": { "enable": ["docker.socket"] },
    "variants": {
        "gaming": {
            "system": { "disable": ["sunshine.service"] }
        }
    }
}
```

**3. Files** (`files/{variant}/`):

- `files/shared/` → Always copied
- `files/main/` → Copied when `IMAGE_FLAVOR` contains "main"
- `files/gaming/` → Copied when `IMAGE_FLAVOR` contains "gaming"

**4. KDE Branding** (dynamic):

- `IMAGE_FLAVOR=main` → Shows "Variant=DESKTOP" in KDE About
- `IMAGE_FLAVOR=gaming` → Shows "Variant=GAMING"
- `IMAGE_FLAVOR=gaming-dx-nvidia` → Shows "Variant=DX+GAMING+NVIDIA" (alphabetically sorted)

## BUILD SCRIPTS (Execution Order)

1. `10-build.sh` - Copies files, orchestrates build (dynamic variant file detection)
2. `20-fedora-packages.sh` - Fedora packages (reads `packages.json` for variants)
3. `25-third-party-packages.sh` - Third-party repos (Docker, Tailscale, COPR)
4. `30-workarounds.sh` - System compatibility fixes
5. `40-systemd.sh` - Service configuration (reads `services.json` for variants)
6. `80-branding.sh` - OS release branding + dynamic KDE variant display
7. `90-cleanup.sh` - Final cleanup

Details: See `build/README.md`

## WHERE TO ADD THINGS

### Build-time (Baked into image)

- **System packages** → `packages.json` (`"include"` array)
- **Variant packages** → `packages.json` (`"variants.{name}.include"`)
- **System services** → `services.json` (`"system.enable"` / `"user.enable"`)
- **Variant services** → `services.json` (`"variants.{name}.system.enable"`)
- **Third-party RPMs** → `build/25-third-party-packages.sh`
- **System files (all variants)** → `files/shared/`
- **Variant-specific files** → `files/{variant}/` (auto-detected from directory names)

### Runtime (User installs after deployment)

- **CLI tools** → `custom/brew/*.Brewfile`
- **GUI apps** → `custom/flatpaks/*.preinstall`
- **User commands** → `custom/ujust/*.just`

## COMMON PATTERNS

### Add Variant Packages

```json
// In packages.json
{
    "variants": {
        "gaming": {
            "include": ["steam", "gamescope"],
            "exclude": []
        },
        "dx": {
            "include": ["dev-tools", "gcc"],
            "exclude": ["firefox"]
        }
    }
}
```

### Enable Systemd Services

```json
// In services.json
{
    "system": {
        "enable": ["docker.socket", "podman.socket"],
        "disable": []
    },
    "user": {
        "enable": ["bazaar.service"],
        "disable": []
    },
    "variants": {
        "gaming": {
            "system": {
                "enable": [],
                "disable": ["sunshine.service"]
            },
            "user": {
                "enable": [],
                "disable": []
            }
        }
    }
}
```

### Add Third-Party RPM Repository

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

### Add Brewfile Shortcut

```just
# In custom/ujust/custom-apps.just
[group('Apps')]
install-dev-tools:
    brew bundle --file /usr/share/ublue-os/homebrew/development.Brewfile
```

## STRUCTURE

```
kyanite/
├── Containerfile          # Build definition
├── Justfile              # Local automation
├── packages.json         # Package lists
├── services.json         # Systemd unit configuration
├── build/                # Build scripts (see build/README.md)
├── files/                # System files
│   ├── shared/          # All variants (always copied)
│   ├── main/            # Main variant only (exact match)
│   ├── gaming/          # Gaming variant (exact match)
│   ├── dx/              # DX variant (exact match)
│   └── {variant}/       # Any variant dir auto-detected via exact matching
├── custom/               # Runtime customizations
│   ├── brew/            # Brewfiles
│   ├── flatpaks/        # Preinstall configs
│   └── ujust/           # User commands
└── .github/workflows/   # CI/CD
```

## LOCAL TESTING

```bash
just build                    # Build container
just build-qcow2             # Build VM image
just run-vm-qcow2            # Test in browser VM

# Gaming variant
IMAGE_FLAVOR=gaming just build
IMAGE_FLAVOR=gaming just build-qcow2

# Combined variants
IMAGE_FLAVOR=gaming-dx just build
IMAGE_FLAVOR=dx-gaming-nvidia just build
```

## WORKFLOWS

**Development**: Branch → PR → Auto-validation → Merge → Build `:stable` + Sign

**Image Tags**:

- `:stable` - Latest from main
- `:stable.YYYYMMDD` - Datestamped
- `:pr-123` - PR builds (unsigned)

**Signing**: Automatic via Cosign v3.0.3 (keyless OIDC) for main branch only

## UJUST RULES

- **NEVER** use `dnf5` (system is immutable)
- Create shortcuts to Brewfiles/Flatpaks
- Use `[group('Category')]` for organization
- Source `/usr/lib/ujust/ujust.sh` for helpers (`Choose`, `Confirm`)

## DEBUGGING

```bash
# Build logs
podman logs <container-id>

# Service status
systemctl status service-name
journalctl -u service-name

# Package verification
rpm -q package-name
```

## DOCUMENTATION

- **BUILD.md** - Build system architecture details
- **build/README.md** - Build scripts reference
- **custom/\*/README.md** - Homebrew/Flatpak/ujust guides
- **README.md** - User-facing overview

## WHEN UPDATING PACKAGES

Update README.md "What's Included" section to reflect:

- Added packages/apps
- Removed packages
- Service changes
- Configuration changes

Keep descriptions brief and user-focused.

## VARIANT SYSTEM BENEFITS

✅ **Declarative** - Everything in JSON/directories, not hardcoded bash
✅ **Scalable** - Add new variants without modifying build scripts
✅ **Flexible** - Combine any variants (gaming-dx-nvidia)
✅ **Consistent** - Same pattern across packages, services, files, and branding
✅ **Efficient** - Single loop, single install command
✅ **Automatic** - Exact matching prevents false matches (main ≠ domain)

## REFERENCES

- [Universal Blue](https://universal-blue.org/) - Ecosystem docs
- [bootc](https://containers.github.io/bootc/) - Container OS architecture
- [Just Manual](https://just.systems/man/en/) - Just syntax
