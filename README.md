# Kyanite

Kyanite is a custom bootable container based on Fedora Kinoite focusing on minimal branding, sane defaults, and clean behavior. Built with [Universal Blue](https://universal-blue.org/).

![](./_img/kyanite-logo.png)

## What Changed

Kyanite is built on Universal Blue's [kinoite-main](https://github.com/ublue-os/main) image, which itself derives from Fedora Kinoite.

Kyanite improves Fedora Kinoite with:

- **Saner defaults** - Mozilla's official Flatpak build of Firefox, Discover swapped for Bazaar, Flathub out of the box, and modernized KDE Plasma settings.
- **Full container workflows** - Docker CE with buildx/compose, enhanced Podman.
- **Developer tools** - Fish shell, modern terminal, comprehensive tooling.
- **Nice to haves** - Tailscale VPN, Syncthing, dynamic wallpapers.
- **Gaming necessities** - Steam, Gamescope, MangoHud, etc.
- **Audio enhancements** - Improved audio DSPs for select hardware.
- **Flexible variants** - Declarative flavors you can mix and match.

## Available Flavors

All images are built and published automatically:

- **kyanite** - Clean, modern, featureful KDE desktop for normal people.
- **kyanite-dx** - Developer experience with Docker CE, QEMU/KVM, ROCm, Android tools, Flatpak builder, etc.
- **kyanite-gaming** - Gaming experience with Steam, Gamescope, ProtonUp-Qt, Heroic Game Launcher, etc.
- **kyanite-dx-gaming** - Everything combined.

## Quick Start

```bash
# Standard variant
sudo bootc switch ghcr.io/alyraffauf/kyanite:stable
sudo systemctl reboot

# Developer variant
sudo bootc switch ghcr.io/alyraffauf/kyanite-dx:stable
sudo systemctl reboot

# Gaming variant
sudo bootc switch ghcr.io/alyraffauf/kyanite-gaming:stable
sudo systemctl reboot

# Combined DX + Gaming
sudo bootc switch ghcr.io/alyraffauf/kyanite-dx-gaming:stable
sudo systemctl reboot
```

After first boot, explore available commands:

```bash
ujust --list
```

## Customization

Kyanite uses a declarative configuration system:

- **[packages.json](packages.json)** - Define packages per flavor.
- **[services.json](services.json)** - Configure systemd units.
- **files/{variant}/** - Flavor-specific system files (main, gaming, dx).
- **[brew/](brew/)** - Homebrew packages (runtime installation).
- **[flatpaks/](flatpaks/)** - Flatpak preinstall files by flavor.
- **[ujust/](ujust/)** - Custom `ujust` commands by flavor.

See the documentation files for detailed configuration options.

## Building Locally

Requires [Podman](https://podman.io/) and [Just](https://just.systems/):

```bash
# Build standard variant
just build

# Build specific variant
IMAGE_FLAVOR=dx just build
IMAGE_FLAVOR=gaming just build
IMAGE_FLAVOR=dx-gaming just build

# Build with NVIDIA base image
BASE_IMAGE_SHA=$(skopeo inspect docker://ghcr.io/ublue-os/kinoite-nvidia:latest --format '{{.Digest}}')
BASE_IMAGE=ghcr.io/ublue-os/kinoite-nvidia:latest \
BASE_IMAGE_SHA=$BASE_IMAGE_SHA \
IMAGE_FLAVOR=dx-gaming \
just build

# Create bootable images
just build-iso
just build-qcow2
just build-raw
```

Output appears in `output/` directory.

## Security

Images are signed with [Sigstore Cosign](https://github.com/sigstore/cosign) using keyless signing:

```bash
cosign verify \
  --certificate-identity-regexp="https://github.com/alyraffauf/kyanite/.*" \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  ghcr.io/alyraffauf/kyanite:stable
```

### Use Signed Transport

```bash
# Switch to signed registry
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/alyraffauf/kyanite:stable
sudo systemctl reboot

# Verify
rpm-ostree status  # Should show "ostree-image-signed:" prefix
```

## Resources

- [Universal Blue](https://universal-blue.org/) - Project ecosystem.
- [bootc Documentation](https://containers.github.io/bootc/) - Cloud-native OS.
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp) - Community support.

## License

Apache License 2.0 - See [LICENSE.md](LICENSE.md) for details.

Built with [Universal Blue](https://universal-blue.org/) tooling. Based on [Fedora Kinoite](https://fedoraproject.org/kinoite/) with [KDE Plasma](https://kde.org/).
