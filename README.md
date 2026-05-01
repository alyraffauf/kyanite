# Kyanite

Kyanite is a custom bootable container based on Fedora Kinoite focusing on minimal branding, sane defaults, and clean behavior. Built with [Universal Blue](https://universal-blue.org/).

![](./_img/screenshot.png)

## What Changed

Kyanite is built on Universal Blue's [kinoite-main](https://github.com/ublue-os/main) image, which itself derives from Fedora Kinoite.

Kyanite improves Fedora Kinoite with:

- **Saner defaults** - Mozilla's official Flatpak build of Firefox, Discover swapped for Bazaar, Flathub out of the box, and modernized KDE Plasma settings.
- **Minimal base** - Heavy / opt-in functionality (Docker, virtualization, Steam, ROCm) lives outside the image as [system extensions](#optional-extensions).
- **Quality-of-life** - Fish shell, dynamic wallpapers, Cider for Apple Music, fcitx5 input methods.
- **Audio enhancements** - Improved audio DSPs for select hardware via PipeWire filter chains.
- **Local LLM stack** - Ollama Quadlets with CPU/ROCm/Vulkan backends preconfigured.
- **Declarative variant architecture** - `packages.json` + `services.json` schema if you want to fork and add your own variants.

## Quick Start

If you're already on a bootc-based system (like Kinoite or Aurora), switching is easy:

```bash
sudo bootc switch ghcr.io/alyraffauf/kyanite:stable
sudo systemctl reboot
```

Please be advised that some defaults in `/etc/skel` will not be copied over automatically and may need to be manually migrated. Also, rebasing across desktop environments (e.g., GNOME to KDE) is not recommended unless you know what you're doing.

After first boot, explore available commands:

```bash
ujust --list
```

> **Migrating from a previous Kyanite variant?** `kyanite-dx`, `kyanite-gaming`, and `kyanite-dx-gaming` tags now alias to `kyanite:stable`, so existing systems continue auto-updating. Run `ujust rebase-helper` to clean up the variant metadata when convenient.

## Optional Extensions

Heavy or opt-in functionality lives in [kyanite-sysexts](https://github.com/alyraffauf/kyanite-sysexts) as systemd-sysext packages. Install on demand with `ujust install-sysext NAME`:

| Sysext      | Provides                                                                  |
| ----------- | ------------------------------------------------------------------------- |
| `docker`    | Docker CE + buildx, compose, and model plugins                            |
| `rocm`      | AMD ROCm runtime + HIP, OpenCL, rocm-smi (for GPU compute / ML workloads) |
| `steam`     | Native Steam, Gamescope, MangoHud, GameMode (i686 multilib stack)         |
| `syncthing` | Native Syncthing daemon                                                   |
| `tailscale` | Tailscale mesh-VPN client + daemon                                        |
| `virt`      | QEMU/KVM + libvirt + edk2-ovmf (UEFI firmware) + virtio drivers           |

Each sysext auto-updates via `systemd-sysupdate.timer`. To remove: `ujust remove-sysext NAME`.

For gaming launchers (Heroic, ProtonUp-Qt, Lutris) installed as Flatpaks, run `ujust install-gaming-flatpaks`.

## Local LLMs (Ollama)

Three Podman Quadlet units ship for running [Ollama](https://ollama.com/) as a user-level systemd service, using the official upstream container images. GPU runtimes (ROCm, Vulkan ICDs) live inside the container, not the host.

```bash
# CPU (or NVIDIA, on a kinoite-nvidia base)
ujust enable-ollama

# AMD GPU via ROCm — fastest on officially-supported AMD cards
# (RX 6800/6900, 7000-series). Run `ujust configure-gpu-groups` first.
ujust enable-ollama-rocm

# AMD GPU via Vulkan — works on any modern AMD GPU, including
# cards not in ollama:rocm's bundled rocBLAS (e.g. RX 6700 XT / gfx1031).
# Run `ujust configure-gpu-groups` first.
ujust enable-ollama-vulkan
```

All three backends listen on `127.0.0.1:11434` and share an `ollama-data` volume, so any client (Continue, claude-code, opencode, the `ollama` CLI from Homebrew, etc.) just works and model weights persist when you switch backends. The services are mutually exclusive — starting one stops the others.

**Which to pick:** start with `ollama-rocm` if you have an officially-supported AMD card (RDNA1/2 high-end, RDNA3, CDNA). If `ollama list` shows your model running on CPU, your card isn't covered by the bundled rocBLAS — switch to `ollama-vulkan` instead.

## Syncthing

Syncthing is available as a [sysext](#optional-extensions) — install once, then enable the native user service:

```bash
ujust install-sysext syncthing
systemctl --user enable --now syncthing.service
```

GUI lives at `http://127.0.0.1:8384`. Existing `~/.local/state/syncthing/` config is preserved across the install (peer devices / folder lists carry over).

> Migrating from the previous containerized Quadlet flow? Run `ujust remove-syncthing-quadlet` to clean up the user-local Quadlet copy before installing the sysext.

## Quadlet Catalog

Available service templates live in `/usr/share/kyanite/quadlets/`. The `ujust enable-X` recipes copy the chosen template into `~/.config/containers/systemd/`, leaving the catalog untouched so your edits never get clobbered by an OS update. Customize the user copy (e.g. uncomment `HSA_OVERRIDE_GFX_VERSION` in `ollama-rocm.container`), then `systemctl --user daemon-reload && systemctl --user restart <service>`.

`podman-auto-update.timer` is enabled by default for all users, so quadlets with `AutoUpdate=registry` (which all Kyanite-shipped templates have) refresh nightly without manual intervention.

## State of the Project

Kyanite is quite usable as-is, and it's my daily driver. However, it's still under active development with frequent changes. Also, while the word-branding of the distribution has been changed, Fedora defaults persist in many places (Kickoff logo, `fastfetch`, wallpapers). I'm a photographer at best, not a graphics designer.

## Customization

Kyanite uses a declarative configuration system:

- **[packages.json](packages.json)** - Define packages per variant.
- **[services.json](services.json)** - Configure systemd units by variant.
- **files/{variant}/** - Variant-specific system files; only `main/` is currently populated.
- **[brew/](brew/)** - Homebrew packages (runtime installation via `ujust install-*`).
- **[flatpaks/](flatpaks/)** - Flatpak preinstall files (Flathub apps installed on first boot).
- **[ujust/](ujust/)** - Custom `ujust` commands.

The variant scaffold is preserved (`packages.json` `variants.{name}` blocks, `IMAGE_FLAVOR=NAME` build composition) even though only `kyanite` is currently built — forks can revive any variant with a single CI job edit.

## Building Locally

Requires [Podman](https://podman.io/) and [Just](https://just.systems/):

```bash
# Build the published variant (kyanite)
just build

# Build a hypothetical variant scaffold
IMAGE_FLAVOR=foo just build

# Build with NVIDIA base image
BASE_IMAGE_SHA=$(skopeo inspect docker://ghcr.io/ublue-os/kinoite-nvidia:latest --format '{{.Digest}}')
BASE_IMAGE=ghcr.io/ublue-os/kinoite-nvidia:latest \
BASE_IMAGE_SHA=$BASE_IMAGE_SHA \
just build

# Create bootable images
just build-iso
just build-qcow2
just build-raw
```

Output appears in `output/` directory.

## Building Your Own ISO

While the build system supports ISO generation (`just build-iso`), I don't yet provide pre-built ISOs for download. Your best bet is to install Fedora Kinoite and rebase from there. However, if you'd like to skip the middleman, you may buid an install ISO locally:

```bash
just build-iso  # Requires ~10GB disk space and 30+ minutes
```

The generated ISO will be in the `output/` directory.

## Security

Images are signed with [Sigstore Cosign](https://github.com/sigstore/cosign) against the public key at [`cosign.pub`](./cosign.pub):

```bash
cosign verify \
  --key https://raw.githubusercontent.com/alyraffauf/kyanite/main/cosign.pub \
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

- [kyanite-sysexts](https://github.com/alyraffauf/kyanite-sysexts) - Optional system extensions repo.
- [Universal Blue](https://universal-blue.org/) - Project ecosystem.
- [bootc Documentation](https://containers.github.io/bootc/) - Cloud-native OS.
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp) - Community support.

## License

Apache License 2.0 - See [LICENSE.md](LICENSE.md) for details.

Built with [Universal Blue](https://universal-blue.org/) tooling. Based on [Fedora Kinoite](https://fedoraproject.org/kinoite/) with [KDE Plasma](https://kde.org/).
