# ujust - User-facing Just Commands

This directory contains Just recipe files organized by variant that will be installed into your custom image and made available to end users via the `ujust` command.

## What is ujust?

`ujust` is a command that allows users to run predefined tasks on their system. It's built on top of [just](https://github.com/casey/just), a command runner similar to `make` but designed for commands rather than builds.

## How It Works

1. **During Build**: All `.just` files from the appropriate variant directories are consolidated and copied to `/usr/share/ublue-os/just/60-custom.just` in the image based on `IMAGE_FLAVOR`
2. **After Installation**: Users run `ujust` to see available commands
3. **User Experience**: Simple command interface for system tasks

## Directory Structure

Organize `.just` files by image variant:

```
ujust/
├── README.md          # This file
├── main/              # Commands for all images
│   ├── apps.just
│   ├── audio.just
│   └── system.just
├── dx/                # Developer-specific commands (optional)
└── gaming/            # Gaming-specific commands (optional)
```

**Files are included based on IMAGE_FLAVOR:**

- `main/` - Always included
- `dx/` - Included for kyanite-dx and kyanite-dx-gaming
- `gaming/` - Included for kyanite-gaming and kyanite-dx-gaming

## Example Commands

### Basic Command

```just
# Run a system maintenance task
run-maintenance:
    echo "Running maintenance..."
    sudo systemctl restart some-service
```

### Interactive Command with gum

```just
# Configure system setting
configure-thing:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    echo "Configure thing?"
    OPTION=$(Choose "Enable" "Disable")
    if [[ "${OPTION,,}" =~ ^enable ]]; then
        echo "Enabling..."
        # your enable logic
    else
        echo "Disabling..."
        # your disable logic
    fi
```

### Command with Group

```just
# Groups organize commands in ujust help
[group('Apps')]
install-brewfile:
    brew bundle --file /usr/share/ublue-os/homebrew/development.Brewfile
```

## Best Practices

### Naming Conventions

- Use lowercase with hyphens: `install-something`
- Use verb prefixes for clarity:
    - `install-` - Install something
    - `configure-` - Configure something pre-installed
    - `setup-` - Install + configure
    - `toggle-` - Enable/disable a feature
    - `enable-` / `disable-` - Start/stop a Quadlet-shipped systemd service (see Quadlet Services below)
    - `fix-` - Apply a fix or workaround

### Command Structure

```just
# Brief description of what the command does
[group('Category')]
command-name:
    #!/usr/bin/env bash
    # Use bash shebang for multi-line scripts
    # Commands go here
```

### Error Handling

```just
install-something:
    #!/usr/bin/env bash
    set -euo pipefail  # Exit on error, undefined vars, pipe failures
    # Your commands
```

### User Prompts

Use `gum` for interactive prompts (included in Universal Blue images):

```just
interactive-command:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh  # Provides Choose() and other helpers
    OPTION=$(Choose "Option 1" "Option 2" "Cancel")
    echo "You chose: $OPTION"
```

## Quadlet Services

Kyanite ships containerized services as [Podman Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) templates. The convention has two halves:

1. **Catalog templates** in the OS image at `/usr/share/kyanite/quadlets/<name>.container`. These ship in `files/<variant>/usr/share/kyanite/quadlets/`, are owned by the image, and are never auto-loaded by systemd. They serve as immutable, OS-update-tracked source-of-truth templates.
2. **Matching `enable-<name>` / `disable-<name>` recipes** in a `services.just` file. The `enable-<name>` recipe copies the template into the user's `~/.config/containers/systemd/<name>.container` (where systemd actually loads it from) and starts the service. The `disable-<name>` recipe stops it.

This split means OS updates can refresh the template without ever clobbering a user's customizations to the running copy. Users edit their `~/.config/containers/systemd/<name>.container` freely; the catalog stays canonical.

### Conventions

- **Every shipped quadlet has matching `enable-X` and `disable-X` recipes.** No exceptions — that's the contract that makes the catalog discoverable via `ujust --list`.
- Use the `[group('Services')]` group label so all containerized services cluster together in `ujust --list`.
- The `enable-X` recipe should:
    - `mkdir -p` the user's quadlet directory
    - `cp -n` (no-clobber) the catalog template — never overwrite user edits
    - `systemctl --user daemon-reload`
    - `systemctl --user start <name>.service`
- Set `AutoUpdate=registry` in the quadlet so `podman-auto-update.timer` (enabled globally in `services.json`) refreshes the image nightly.
- For mutually-exclusive backends (e.g. multiple `ollama-*` variants on the same port), use `Conflicts=` in the `[Unit]` section so starting one stops the others.

### Example

Catalog template at `files/main/usr/share/kyanite/quadlets/example.container`:

```ini
[Unit]
Description=Example service (containerized)

[Container]
Image=docker.io/example/example:latest
ContainerName=example
AutoUpdate=registry
PublishPort=127.0.0.1:8080:8080

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
```

Matching recipes in `ujust/main/services.just`:

```just
# Enable the containerized example service
[group('Services')]
enable-example:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "$HOME/.config/containers/systemd"
    cp -n /usr/share/kyanite/quadlets/example.container \
        "$HOME/.config/containers/systemd/example.container"
    systemctl --user daemon-reload
    systemctl --user start example.service

# Stop the containerized example service
[group('Services')]
disable-example:
    #!/usr/bin/env bash
    set -euo pipefail
    systemctl --user stop example.service 2>/dev/null || true
```

### Documenting prerequisites

If a quadlet needs the user in particular groups (e.g. `render`/`video` for GPU passthrough), document that in a comment above the recipe and direct the user to the relevant `configure-*-groups` recipe — **don't** auto-fix groups inside `enable-X`. Single-purpose recipes compose better than recipes that quietly do system setup.

## Common Use Cases

### 1. Installing Software via Brewfiles

```just
[group('Apps')]
install-dev-tools:
    brew bundle --file /usr/share/ublue-os/homebrew/development.Brewfile
```

**See examples in [`custom-apps.just`](custom-apps.just)** for Brewfile shortcuts.

### 2. System Configuration

```just
[group('System')]
configure-firewall:
    #!/usr/bin/env bash
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --reload
```

**See examples in [`custom-system.just`](custom-system.just)** for system configuration.

### 3. Development Environment Setup

```just
[group('Development')]
setup-nodejs:
    #!/usr/bin/env bash
    curl -fsSL https://fnm.vercel.app/install | bash
    source ~/.bashrc
    fnm install --lts
```

### 4. Maintenance Tasks

```just
[group('Maintenance')]
clean-containers:
    podman system prune -af
    podman volume prune -f
```

**See examples in [`custom-system.just`](custom-system.just)** for maintenance tasks.

## Important: Package Installation

**Do not install packages via dnf5/rpm in ujust commands.** Bootc images are immutable and package installation should happen at build time in [`build/02-fedora-packages.sh`](../../build/02-fedora-packages.sh) or [`build/03-third-party-packages.sh`](../../build/03-third-party-packages.sh).

For runtime package installation, use:

- **Brewfiles** - Create shortcuts to Brewfiles in [`custom/brew/`](../brew/)
- **Flatpak** - Install Flatpaks for GUI applications
- **Containers** - Use toolbox/distrobox for development environments

Example Brewfile shortcut (from [`custom-apps.just`](custom-apps.just)):

```just
[group('Apps')]
install-fonts:
    brew bundle --file /usr/share/ublue-os/homebrew/fonts.Brewfile
```

## Available Helpers

Universal Blue images include helpers in `/usr/lib/ujust/ujust.sh`:

- `Choose()` - Present multiple choice menu
- `Confirm()` - Yes/no prompt
- Color variables: `${bold}`, `${normal}`, etc.

## Testing Your Commands

Test locally before committing:

1. Build your image: `just build` (see [`Justfile`](../../Justfile))
2. If on a bootc system: `sudo bootc switch --target localhost/kyanite:stable`
3. Reboot and test: `ujust your-command`

Or test the just files directly:

```bash
just --justfile custom/ujust/custom-apps.just --list
just --justfile custom/ujust/custom-apps.just install-something
```

## Customization

**Start by editing the example files:**

- **[`custom-apps.just`](custom-apps.just)** - Add your application installation commands
- **[`custom-audio.just`](custom-audio.just)** - Audio DSP configuration for specific devices
- **[`custom-system.just`](custom-system.just)** - Add your system configuration commands

**Create new files** for different categories:

- `custom-gaming.just` - Gaming-related commands
- `custom-media.just` - Media editing workflows
- `custom-dev.just` - Development environment setups

All `.just` files in this directory are automatically included. See [`build/05-copy-files.sh`](../../build/05-copy-files.sh) for the consolidation logic.

## Groups for Organization

Use groups to categorize commands:

```just
[group('Apps')]
install-app:
    echo "Installing app..."

[group('System')]
configure-system:
    echo "Configuring system..."

[group('Development')]
setup-dev:
    echo "Setting up dev environment..."
```

## Examples from Bluefin

The included files provide starting examples:

- **[`custom-apps.just`](custom-apps.just)** - Application installation commands
- **[`custom-audio.just`](custom-audio.just)** - Audio DSP configuration commands
- **[`custom-system.just`](custom-system.just)** - System configuration commands

These files show how to:

- Create shortcuts to Brewfiles in [`custom/brew/`](../brew/)
- Install Flatpaks interactively
- Configure system settings
- Run maintenance tasks

## Resources

- [Just Manual](https://just.systems/man/en/)
- [Universal Blue Just Documentation](https://universal-blue.org/guide/just/)
- [Bluefin ujust Commands](https://docs.projectbluefin.io/administration)
- [gum Documentation](https://github.com/charmbracelet/gum)

## Notes

- Commands run with user privileges by default
- Use `sudo` or `pkexec` when root access needed
- Consider providing both install and uninstall options
- Test on a clean system before distributing
- Document any prerequisites or dependencies
