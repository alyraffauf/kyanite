# Agent Instructions for Kyanite

Kyanite is a bootc OS based on Fedora Kinoite (KDE Plasma). Heavy/optional functionality lives in the sibling [kyanite-sysexts](https://github.com/alyraffauf/kyanite-sysexts) repo.

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
7. Third-party RPMs and COPR setup → `build/03-third-party-packages.sh`

## QUICK REFERENCE

| Task                   | Location                           | Format                                     |
| ---------------------- | ---------------------------------- | ------------------------------------------ |
| Add base package       | `packages.json`                    | `"variants.main.include"` array            |
| Add variant package    | `packages.json`                    | `"variants.{name}.include"` array          |
| Remove package         | `packages.json`                    | `"variants.{name}.exclude"` array          |
| Enable base service    | `services.json`                    | `"variants.main.system.enable"` array      |
| Enable variant service | `services.json`                    | `"variants.{name}.system.enable"` array    |
| Add 3rd-party RPM      | `build/03-third-party-packages.sh` | See examples                               |
| Add COPR package       | `build/03-third-party-packages.sh` | `copr_install_isolated "owner/repo" "pkg"` |
| Add Homebrew package   | `brew/{variant}/*.Brewfile`        | `brew "package-name"`                      |
| Add Flatpak preinstall | `flatpaks/{variant}.preinstall`    | `[Flatpak Preinstall app.id]`              |
| Add ujust command      | `ujust/{variant}/*.just`           | Just recipe syntax                         |
| Add a sysext           | `kyanite-sysexts` repo             | New `mkosi.images/{name}/` + matrix entry  |

## VARIANTS

**Currently built:** `kyanite` (main only).

The variant architecture is preserved end-to-end so a fork (or future re-introduction) can spin up additional variants without rewriting plumbing. `packages.json` and `services.json` retain a `dx` block (currently empty) as a placeholder. Variant builds use exact matching by splitting `IMAGE_FLAVOR` on hyphens:

- `IMAGE_FLAVOR=main` → `["main"]` (default published image)
- `IMAGE_FLAVOR=dx` → `["dx"]` (scaffold; not currently built in CI)
- `IMAGE_FLAVOR=foo-bar` → `["foo", "bar"]` (composes both blocks on top of `main`)

Deprecated tags (`kyanite-dx`, `kyanite-gaming`, `kyanite-dx-gaming`) are aliased to `kyanite:stable` after each push by the `alias-deprecated-tags` job in `build.yml` — existing systems keep auto-updating.

### Configuration Layers

**1. Packages** (`packages.json`):

```json
{
    "variants": {
        "main": { "include": ["common-pkg"], "exclude": ["unwanted-pkg"] },
        "dx": { "include": [], "exclude": [] }
    }
}
```

**2. Services** (`services.json`):

```json
{
    "variants": {
        "main": {
            "system": { "enable": ["podman.socket"], "disable": [] },
            "user": { "enable": ["bazaar.service"], "disable": [] }
        }
    }
}
```

**3. Files** (`files/{variant}/`):

- `files/main/` → Always copied (base for every image).
- `files/{variant}/` → Copied when `IMAGE_FLAVOR` contains the variant name. Currently only `main/` is populated.

**4. Branding** (automatic):

- `IMAGE_FLAVOR=main` → KDE About shows "Variant=Main" (or omits the variant suffix).

## OPTIONAL EXTENSIONS (sysexts)

Heavy/opt-in functionality is **not** baked into the kyanite image. It ships as systemd-sysext packages from [kyanite-sysexts](https://github.com/alyraffauf/kyanite-sysexts):

| Sysext | Provides |
| --- | --- |
| `docker` | Docker CE + buildx, compose, model plugins |
| `rocm` | AMD ROCm runtime (HIP, OpenCL, rocm-smi) |
| `steam` | Native Steam, Gamescope, MangoHud, GameMode (multilib) |
| `virt` | QEMU/KVM + libvirt + edk2-ovmf + virtio drivers |

Users install via `ujust install-sysext NAME` (recipe in `ujust/main/sysexts.just`). To add a new sysext, work in the `kyanite-sysexts` repo — not this one.

## BUILD SCRIPTS (Order)

Ordered rare-changing → frequent-changing for cache efficiency. Third-party packages, Homebrew, and branding are placed LATE so silent upstream bumps don't bust the expensive Fedora layer.

1. `01-stage-brewfiles.sh` - Stage `brew/<variant>/*.Brewfile` to `/usr/share/ublue-os/homebrew/` (runtime data consumed by ujust)
2. `02-fedora-packages.sh` - Packages from `packages.json` (also pins `plasma-desktop` and installs `development-tools` group)
3. `03-third-party-packages.sh` - Cider, Tailscale, COPR
4. `04-workarounds.sh` - Compatibility fixes that sed third-party `.desktop` files (Ghostty KDE shortcut, etc.)
5. `05-copy-files.sh` - Variant overlay (`files/<variant>/` rsync — including custom `.service` units), ujust consolidation, Flatpak preinstalls
6. `06-systemd.sh` - Services from `services.json` (may reference units shipped in step 5)
7. `07-homebrew.sh` - Homebrew system files + service presets (late — brew base image SHA bumps multi-times/week)
8. `08-branding.sh` - OS release + KDE branding (uses `SHA_HEAD_SHORT` build arg, invalidates per commit)
9. `09-cleanup.sh` - Hide unused desktop entries, fix bootc lint, `ostree container commit`

## STRUCTURE

```
kyanite/
├── Containerfile          # Build definition
├── packages.json          # Package lists per variant
├── services.json          # Service configuration per variant
├── build/                 # Build scripts (numbered, run in order)
├── files/
│   └── main/              # System files (only main is populated)
├── brew/
│   └── main/              # Homebrew Brewfiles
├── flatpaks/
│   └── main.preinstall    # Flathub preinstall config
├── ujust/
│   └── main/              # User commands (apps, audio, services, sysexts, system)
└── .github/workflows/     # CI/CD (build, alias deprecated tags, clean old images)
```

## LOCAL TESTING

```bash
just build                    # Build container image (main variant)
just build-qcow2              # Build VM image
just run-vm-qcow2             # Test in VM

# Hypothetical variant build (no CI counterpart today)
IMAGE_FLAVOR=foo just build
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

### Add a Sysext (different repo)

Sysexts live in `kyanite-sysexts`. The pattern there is `mkdir <name>/` containing `mkosi.conf` + `mkosi.extra/usr/lib/extension-release.d/extension-release.<name>` + (optional) `mkosi.sandbox/etc/yum.repos.d/<repo>.repo` for non-default repos. Add the name to the matrix in `.github/workflows/build-sysexts.yml` and a corresponding `sysupdate.d/<name>.transfer`. No kyanite-side changes needed.

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

- [kyanite-sysexts](https://github.com/alyraffauf/kyanite-sysexts) - Sister repo for system extensions
- [Universal Blue](https://universal-blue.org/)
- [bootc](https://containers.github.io/bootc/)
- [Just Manual](https://just.systems/man/en/)
- [systemd-sysext(8)](https://www.freedesktop.org/software/systemd/man/systemd-sysext.html) - sysext semantics
