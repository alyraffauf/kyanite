# kyanite

A custom bootc operating system based on Fedora Kinoite (KDE Plasma) built using the lessons from [Universal Blue](https://universal-blue.org/).

This OS is based on **kinoite-main** (Fedora KDE Plasma) and provides a clean foundation for customization.

> Be the one who moves, not the one who is moved.

## What Makes Kyanite Different?

Kyanite is a clean KDE Plasma operating system based on Fedora Kinoite, built using the bootc architecture:

### Base Configuration
- **Desktop Environment**: KDE Plasma (via kinoite-main base image)
- **Clean Foundation**: Minimal base with essential integrations

### Included Integrations
- **Homebrew Support**: Via @ublue-os/brew for runtime package management
- **Flatpak Preinstall**: Automatic Flatpak installation on first boot
- **ujust Commands**: User-friendly command shortcuts

### Customizations
- **Added Packages**: ansible, chezmoi, fish, syncthing, ptyxis, and more (see `packages.json`)
- **Removed Packages**: firefox, discover, akonadi, and other unwanted defaults
- **Additional Apps**: Cider, Tailscale, Sunshine, krunner-bazaar
- **System Services**: podman.socket, tailscaled, flatpak-preinstall enabled

### Build System
- Automated builds via GitHub Actions on every commit
- Renovate setup that keeps your images and actions up to date
- Automatic cleanup of old images (90+ days) to keep it tidy
- Pull request workflow - test changes before merging to main
  - PRs build and validate before merge
  - `main` branch builds `:stable` images
- Validates your files on pull requests:
  - Brewfile, Justfile, ShellCheck, Renovate config, Flatpak validation

## Getting Started

### Using the Image

Switch to Kyanite from an existing bootc system:
```bash
sudo bootc switch ghcr.io/alyraffauf/kyanite:stable
sudo systemctl reboot
```

### Customizing Your Image

#### Add System Packages

Edit `packages.json` to add or remove packages:
```json
{
    "include": [
        "vim",
        "git",
        "htop"
    ],
    "exclude": [
        "unwanted-package"
    ]
}
```

Packages are installed by `build/20-packages.sh` during build time.

#### Install Third-Party Software

For software from third-party repositories (like Cider or Tailscale), add it to `build/20-packages.sh`. See the existing examples for the pattern.

#### Configure Applications
- Add Brewfiles in `custom/brew/` ([guide](custom/brew/README.md))
- Add Flatpaks in `custom/flatpaks/` ([guide](custom/flatpaks/README.md))
- Add ujust commands in `custom/ujust/` ([guide](custom/ujust/README.md))

### Development Workflow

All changes should be made via pull requests:

1. Create a branch and make your changes
2. Open a pull request on GitHub
3. The PR will automatically trigger:
   - Build validation
   - Brewfile, Flatpak, Justfile, and shellcheck validation
   - Test image build
4. Once checks pass, merge the PR
5. Merging triggers a `:stable` image build

## Architecture

This OS follows a **multi-stage build architecture** for modularity and maintainability.

### Multi-Stage Build Pattern

**Stage 1: Context (ctx)** - Combines resources from multiple sources:
- Local build scripts (`/build`)
- Local custom files (`/custom`, `/files`)
- Local package definitions (`packages.json`)
- **@ublue-os/brew** - Homebrew integration

**Stage 2: Base Image**:
- `ghcr.io/ublue-os/kinoite-main:43` (Fedora 43 KDE Plasma)

### Build Script Organization

Build scripts run in sequence:
1. **10-build.sh** - Copies custom files, Brewfiles, ujust commands, Flatpak preinstall files
2. **20-packages.sh** - Installs/removes packages from `packages.json`, installs third-party apps
3. **30-workarounds.sh** - Applies system workarounds and compatibility fixes
4. **40-systemd.sh** - Enables/disables systemd services
5. **90-cleanup.sh** - Final cleanup and configuration

### Benefits of This Architecture

- **Modularity**: Compose your image from reusable OCI containers
- **Maintainability**: Update shared components independently
- **Reproducibility**: Renovate automatically updates OCI tags to SHA digests
- **Clean Base**: KDE Plasma without extra configuration

### OCI Container Resources

Kyanite imports files from this OCI container at build time:

```dockerfile
COPY --from=ghcr.io/ublue-os/brew:latest /system_files /oci/brew
```

Your build scripts can access these files at:
- `/ctx/oci/brew/` - Homebrew integration files

**Note**: Renovate automatically updates `:latest` tags to SHA digests for reproducible builds.

## Local Testing

Test your changes before pushing:

```bash
just build              # Build container image
just build-qcow2        # Build VM disk image
just run-vm-qcow2       # Test in browser-based VM
```

## Detailed Guides

- [Homebrew/Brewfiles](custom/brew/README.md) - Runtime package management
- [Flatpak Preinstall](custom/flatpaks/README.md) - GUI application setup
- [ujust Commands](custom/ujust/README.md) - User convenience commands
- [Build Scripts](build/README.md) - Build-time customization

## Community

- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp)
- [bootc Discussion](https://github.com/bootc-dev/bootc/discussions)

## Learn More

- [Universal Blue Documentation](https://universal-blue.org/)
- [bootc Documentation](https://containers.github.io/bootc/)

## Security

This image is automatically built and updated:
- Automated security updates via Renovate
- Build provenance tracking
- Reproducible builds with SHA-pinned dependencies
- **Container image signing** with Sigstore Cosign using keyless signing

### Image Signing and Verification

All tagged container images are cryptographically signed using [Sigstore Cosign](https://github.com/sigstore/cosign) with GitHub OIDC tokens (keyless signing). This ensures image authenticity and integrity.

#### Switching from Unverified to Signed Registry

If you're currently using an unverified registry transport, switch to the signed registry:

```bash
# For kyanite
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/alyraffauf/kyanite:stable
sudo systemctl reboot

# For kyanite-gaming
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/alyraffauf/kyanite-gaming:stable
sudo systemctl reboot
```

After rebooting, verify you're using the signed transport:

```bash
rpm-ostree status
# Should show "ostree-image-signed:" instead of "ostree-unverified-registry:"
```

#### Verifying Image Signatures

To manually verify a Kyanite image signature:

```bash
# Install cosign (if not already installed)
brew install cosign
# or download from https://github.com/sigstore/cosign/releases

# Verify the image signature
cosign verify \
  --certificate-identity-regexp="https://github.com/alyraffauf/kyanite/.*" \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  ghcr.io/alyraffauf/kyanite:stable
```

A successful verification confirms the image was built by the official GitHub Actions workflow and has not been tampered with.
