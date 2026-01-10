# Build Scripts

This directory contains build scripts that run during image creation. Scripts are executed in numerical order by `10-build.sh`.

## How It Works

The `Containerfile` executes `10-build.sh`, which then runs all subsequent scripts in numerical order:

1. `10-build.sh` - Copies custom files and executes remaining scripts
2. `20-packages.sh` - Installs/removes packages
3. `30-workarounds.sh` - Applies system workarounds
4. `40-systemd.sh` - Configures systemd services
5. `90-cleanup.sh` - Final cleanup and configuration

## Build Scripts

### `10-build.sh` - Main Build Orchestrator

This script:

- Copies custom files from `/ctx/files/` to `/`
- Copies Brewfiles to `/usr/share/ublue-os/homebrew/`
- Consolidates ujust files to `/usr/share/ublue-os/just/60-custom.just`
- Copies Flatpak preinstall files to `/etc/flatpak/preinstall.d/`
- Executes all remaining build scripts in sequence

### `20-packages.sh` - Package Management

This script:

- Validates and parses `packages.json`
- Installs packages listed in the `include` array
- Removes packages listed in the `exclude` array
- Installs third-party software (Cider, Tailscale)
- Installs COPR packages (krunner-bazaar)
- Installs Flatpak preinstall support from COPR
- **Gaming variant only**: Installs Steam, gaming tools, and Sunshine from COPR

**To add system packages**: Edit `packages.json` in the repository root:

```json
{
    "include": ["vim", "git", "your-package-here"],
    "exclude": ["unwanted-package"]
}
```

**To add third-party software**: Add installation commands to this script. See existing examples for Cider and Tailscale.

### `30-workarounds.sh` - System Workarounds

Applies compatibility fixes and workarounds:

- Creates `/nix` directory for Nix package manager compatibility
- Configures default taskmanager panel applications
- Configures Ptyxis terminal for KDE integration
- Applies GTK input method workarounds

### `40-systemd.sh` - Service Configuration

Enables and disables systemd services:

- System services: `podman.socket`, `tailscaled.service`, `flatpak-preinstall.service`
- Global user services: enables `bazaar.service`, disables `sunshine.service`

### `90-cleanup.sh` - Final Cleanup

Performs final cleanup tasks:

- Hides desktop files for certain applications
- Disables/renames Plasma Discover desktop entries
- Configures Bazaar as the Flatpak ref handler
- Disables third-party repositories
- Commits the ostree container

### `copr-helpers.sh` - Helper Functions

Provides the `copr_install_isolated` function for safely installing packages from COPR repositories. This function:

- Enables the COPR repository
- Installs the specified package(s)
- Disables the COPR repository (critical for security)

## Best Practices

- **Use `packages.json`** for system packages - don't add them directly to scripts
- **Use descriptive names** for any new scripts you add
- **One purpose per script** - Easier to debug and maintain
- **Clean up after yourself** - Remove temporary files and disable temporary repos
- **Test incrementally** - Add one change at a time and test builds
- **Comment your code** - Explain why, not just what
- **Use `dnf5`** - Never use `dnf`, `yum`, or `rpm-ostree`
- **Always use `-y`** flag for non-interactive installs
- **Disable COPR repos** after installation using `copr_install_isolated`

## Adding New Build Scripts

To add a new build script:

1. Create a numbered file (e.g., `50-custom.sh`)
2. Make it executable: `chmod +x build/50-custom.sh`
3. Add it to the execution list in `10-build.sh`:

```bash
for script in 20-packages.sh 30-workarounds.sh 40-systemd.sh 50-custom.sh 90-cleanup.sh; do
    # ...
done
```

### Script Template

```bash
#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# Your Script Purpose
###############################################################################
# Description of what this script does.
###############################################################################

echo "::group:: Your Section Name"

# Your commands here

echo "::endgroup::"

echo "Your script complete!"
```

## Execution Flow

```
Containerfile
    └── RUN /ctx/build/10-build.sh
            ├── Copy custom files
            ├── Copy Brewfiles
            ├── Consolidate ujust files
            ├── Copy Flatpak preinstall files
            └── Execute remaining scripts:
                ├── 20-packages.sh
                ├── 30-workarounds.sh
                ├── 40-systemd.sh
                └── 90-cleanup.sh
```

## Notes

- Scripts run as root during build
- Build context is available at `/ctx`
- Custom files are at `/ctx/files`
- Brewfiles are at `/ctx/custom/brew`
- ujust files are at `/ctx/custom/ujust`
- Flatpak preinstall files are at `/ctx/custom/flatpaks`
- Package list is at `/ctx/packages.json`
- The `set -eoux pipefail` flags ensure:
    - `e` - Exit on error
    - `o` - Exit if any command in a pipeline fails
    - `u` - Exit on undefined variables
    - `x` - Print each command before executing (for debugging)
