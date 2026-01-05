# Agent Instructions for Kyanite

Kyanite is a custom bootc operating system based on Fedora Kinoite (KDE Plasma). This document provides guidelines for AI agents working on this project.

## CRITICAL: Pre-Commit Checklist

**Execute before EVERY commit:**
1. **Conventional Commits** - ALL commits MUST follow conventional commit format
2. **Shellcheck** - `shellcheck *.sh` on all modified shell files
3. **YAML validation** - `python3 -c "import yaml; yaml.safe_load(open('file.yml'))"` on all modified YAML
4. **Justfile syntax** - `just --list` to verify
5. **Confirm with user** - Always confirm before committing and pushing

**Never commit files with syntax errors.**

### Conventional Commit Format

ALL commits MUST use this format:
```
<type>[optional scope]: <description>

[optional body]
```

**Valid types**: `feat`, `fix`, `docs`, `chore`, `build`, `ci`, `refactor`, `test`

**Examples**:
- `feat(packages): add development tools`
- `fix(systemd): correct service dependencies`
- `docs: update README with new features`
- `chore: update dependencies`

## Repository Structure

```
kyanite/
├── Containerfile          # Main build definition
├── Justfile              # Local build automation
├── packages.json         # Package include/exclude lists
├── build/                # Build-time scripts (executed in order)
│   ├── 10-build.sh      # Main orchestrator
│   ├── 20-packages.sh   # Package management
│   ├── 30-workarounds.sh # System workarounds
│   ├── 40-systemd.sh    # Service configuration
│   ├── 90-cleanup.sh    # Final cleanup
│   └── copr-helpers.sh  # COPR helper functions
├── files/                # System files to copy to root (/)
├── custom/               # User customizations (runtime)
│   ├── brew/            # Homebrew Brewfiles
│   ├── flatpaks/        # Flatpak preinstall files
│   └── ujust/           # User-facing just commands
├── iso/                  # Local testing (QCOW2, ISO builds)
└── .github/workflows/   # CI/CD workflows
```

## Core Principles

### Build-time vs Runtime
- **Build-time** (`build/`, `packages.json`): Baked into container. System packages, services, configs.
- **Runtime** (`custom/`): User installs after deployment. Brewfiles, Flatpaks, ujust commands.

### Package Management
- **ALWAYS** use `dnf5` exclusively (never `dnf`, `yum`, or `rpm-ostree`)
- **ALWAYS** use `-y` flag for non-interactive installs
- **ALWAYS** disable COPR repositories after installation using `copr_install_isolated`

### Image Variants
Kyanite has two variants built from the same Containerfile:
- **kyanite** (`IMAGE_FLAVOR=main`) - Base KDE Plasma desktop
- **kyanite-gaming** (`IMAGE_FLAVOR=gaming`) - Includes Steam and gaming tools

The `IMAGE_FLAVOR` variable controls conditional package installation in `build/20-packages.sh`.

## Where to Add Packages

### System Packages (Build-time)

**Location**: `packages.json`

System packages are installed at build-time and baked into the container image.

```json
{
    "include": [
        "vim",
        "git",
        "htop"
    ],
    "exclude": [
        "firefox",
        "discover"
    ]
}
```

**When to use**: System utilities, services, dependencies needed on first boot.

### Third-Party Software (Build-time)

**Location**: `build/20-packages.sh`

For software not in Fedora repos (e.g., Cider, Tailscale).

```bash
# Add repository, install package, disable repository
dnf5 config-manager addrepo --from-repofile=https://example.com/repo.repo
dnf5 config-manager setopt example-repo.enabled=0
dnf5 -y install --enablerepo='example-repo' package-name
```

### COPR Packages (Build-time)

**Location**: `build/20-packages.sh`

Use the `copr_install_isolated` helper function:

```bash
source /ctx/build/copr-helpers.sh
copr_install_isolated "copr-owner/repo-name" "package-name"
```

**CRITICAL**: Never leave COPR repos enabled. The helper function automatically disables them.

### Homebrew Packages (Runtime)

**Location**: `custom/brew/*.Brewfile`

For CLI tools and development environments installed by users.

```ruby
# custom/brew/default.Brewfile
brew "bat"
brew "eza"
brew "ripgrep"
```

Users install via: `ujust install-default-apps`

### Flatpak Applications (Runtime)

**Location**: `custom/flatpaks/*.preinstall`

For GUI applications installed on first boot.

```ini
[Flatpak Preinstall org.mozilla.firefox]
Branch=stable

[Flatpak Preinstall com.visualstudio.code]
Branch=stable
```

**Note**: Flatpaks are downloaded on first boot, not embedded in the ISO.

## Quick Reference

| Task | Location | Example |
|------|----------|---------|
| Add system package | `packages.json` | Add to `include` array |
| Remove package | `packages.json` | Add to `exclude` array |
| Add third-party software | `build/20-packages.sh` | See Cider/Tailscale examples |
| Add COPR package | `build/20-packages.sh` | Use `copr_install_isolated` |
| Enable/disable service | `build/40-systemd.sh` | `systemctl enable service` |
| Add Homebrew package | `custom/brew/*.Brewfile` | `brew "package-name"` |
| Add Flatpak | `custom/flatpaks/*.preinstall` | INI format |
| Add user command | `custom/ujust/*.just` | Just recipe syntax |
| Test locally | Terminal | `just build && just build-qcow2 && just run-vm-qcow2` |

## Build Scripts

Scripts run in numerical order during image build:

1. **`10-build.sh`** - Copies custom files, executes remaining scripts
2. **`20-packages.sh`** - Installs/removes packages, third-party software, variant logic
3. **`30-workarounds.sh`** - System workarounds and compatibility fixes
4. **`40-systemd.sh`** - Enables/disables systemd services
5. **`90-cleanup.sh`** - Final cleanup and ostree commit

### Adding a New Build Script

1. Create numbered file (e.g., `50-custom.sh`)
2. Make executable: `chmod +x build/50-custom.sh`
3. Add to execution list in `10-build.sh`

```bash
#!/usr/bin/bash
set -eoux pipefail

echo "::group:: Your Section Name"
# Your commands here
echo "::endgroup::"
```

## ujust Commands

User-facing commands in `custom/ujust/*.just`.

**Rules**:
- **NEVER** use `dnf5` in ujust files (bootc images are immutable)
- Create shortcuts to Brewfiles and Flatpaks
- Use `[group('Category')]` for organization

**Example**:
```just
[group('Apps')]
install-dev-tools:
    brew bundle --file /usr/share/ublue-os/homebrew/development.Brewfile

[group('System')]
run-maintenance:
    #!/usr/bin/bash
    echo "Running maintenance..."
    podman system prune -af
```

## Workflows

### Development Workflow
1. Create feature branch
2. Make changes
3. Open pull request
4. Automated validation runs (shellcheck, YAML, Brewfile, Flatpak, etc.)
5. Review and merge to `main`
6. Merging triggers `:stable` image build

### Local Testing
```bash
just build              # Build container image
just build-qcow2        # Build VM disk image
just run-vm-qcow2       # Test in browser-based VM
```

### Image Tags
- `:stable` - Latest stable release from main branch
- `:stable.YYYYMMDD` - Datestamped stable release
- `:pr-123` - Pull request builds (for testing)

## Critical Rules

1. **ALWAYS** use Conventional Commits format
2. **ALWAYS** use `dnf5` exclusively (never `dnf`, `yum`, `rpm-ostree`)
3. **ALWAYS** disable COPR repositories after installation
4. **ALWAYS** use `-y` flag for non-interactive installs
5. **NEVER** use `dnf5` in ujust files
6. **NEVER** commit `cosign.key` to repository
7. **ALWAYS** run validation checks before committing
8. **System packages** go in `packages.json`, not directly in scripts
9. **Third-party software** goes in `build/20-packages.sh`
10. **Services** are configured in `build/40-systemd.sh`

## Common Patterns

### Pattern 1: Adding Third-Party RPM Repository
```bash
# In build/20-packages.sh
echo "::group:: Install Example Package"
dnf5 config-manager addrepo --from-repofile=https://example.com/repo.repo
dnf5 config-manager setopt example-repo.enabled=0
dnf5 -y install --enablerepo='example-repo' package-name
echo "::endgroup::"
```

### Pattern 2: Using COPR Repositories
```bash
# In build/20-packages.sh
source /ctx/build/copr-helpers.sh
copr_install_isolated "owner/repo" "package-name"
```

### Pattern 3: Enabling System Services
```bash
# In build/40-systemd.sh
systemctl enable podman.socket
systemctl enable tailscaled.service
systemctl enable --global bazaar.service
systemctl disable --global sunshine.service
```

### Pattern 4: Managing Packages via packages.json
```json
{
    "include": [
        "ansible",
        "chezmoi",
        "fish",
        "syncthing",
        "ptyxis"
    ],
    "exclude": [
        "firefox",
        "discover",
        "akonadi"
    ]
}
```

### Pattern 5: Creating ujust Command Shortcuts
```just
# In custom/ujust/custom-apps.just
[group('Apps')]
install-fonts:
    brew bundle --file /usr/share/ublue-os/homebrew/fonts.Brewfile

[group('Apps')]
install-dev-tools:
    brew bundle --file /usr/share/ublue-os/homebrew/development.Brewfile
```

## Debugging Tips

### Local Build Debugging
```bash
# Build with verbose output
just build

# Check build logs
podman logs <container-id>

# Test in VM
just build-qcow2
just run-vm-qcow2
```

### CI Debugging
- Check GitHub Actions logs
- PR builds create `:pr-123` tagged images for testing
- Validation workflows show specific errors (shellcheck, YAML, etc.)

### Runtime Debugging
```bash
# Check service status
systemctl status service-name

# View logs
journalctl -u service-name

# Check package installation
rpm -q package-name

# List enabled services
systemctl list-unit-files --state=enabled
```

## Updating README "What Makes Kyanite Different?"

**CRITICAL**: When modifying packages or configuration, update the README.md section that describes what makes Kyanite different from the base image.

The section should include:
- Added packages (with brief explanation)
- Added applications (Homebrew, Flatpak)
- Removed/disabled packages
- Configuration changes
- System services enabled/disabled

Keep descriptions brief and user-focused. Update the "Last updated" date with each change.

## Resources

- [Universal Blue Documentation](https://universal-blue.org/)
- [bootc Documentation](https://containers.github.io/bootc/)
- [Bluefin Documentation](https://docs.projectbluefin.io/)
- [Just Manual](https://just.systems/man/en/)
- [Homebrew Documentation](https://docs.brew.sh/)
- [Flatpak Documentation](https://docs.flatpak.org/)

## Attribution

When making significant changes or adding features inspired by other projects, maintain proper attribution in commit messages and documentation.