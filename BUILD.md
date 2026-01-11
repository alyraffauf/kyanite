# Build System Architecture

This document explains how Kyanite's build system works, including the variant system for building both `kyanite` and `kyanite-gaming` from a single Containerfile.

## Overview

Kyanite uses a **single Containerfile** with **conditional build logic** to create two image variants:

- **kyanite** (main flavor) - Base KDE Plasma image
- **kyanite-gaming** (gaming flavor) - Base + Steam and gaming tools

This follows the pattern used by Universal Blue projects like Bluefin and Aurora.

## Architecture

### 1. Containerfile (Single Source)

```dockerfile
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"

# Build logic passes IMAGE_FLAVOR to build scripts
RUN IMAGE_FLAVOR="${IMAGE_FLAVOR}" /ctx/build/10-build.sh
```

**Key Points**:

- Uses `IMAGE_FLAVOR` build argument (default: "main")
- Same Containerfile builds all variants (supports combining features)
- Follows Bluefin/Aurora pattern

### 2. Build Scripts

**`build/10-build.sh`**:

- Executes build scripts in sequence
- Passes `IMAGE_FLAVOR` to all subsequent scripts

**`build/20-fedora-packages.sh`**:

- Reads variant-specific packages from `packages.json`
- Uses pattern matching (`=~`) to detect variants in `IMAGE_FLAVOR`
- Automatically installs packages for all matching variants
- Supports combined variants (e.g., "gaming-dx-nvidia")

```bash
# Dynamically reads variants from packages.json
VARIANT_NAMES=$(jq -r '.variants | keys[]' /ctx/packages.json)

for variant in ${VARIANT_NAMES}; do
    if [[ ${IMAGE_FLAVOR} =~ ${variant} ]]; then
        # Install packages from .variants.{variant}.include
        readarray -t VARIANT_PACKAGES < <(jq -r ".variants.${variant}.include[]" /ctx/packages.json)
        dnf5 -y install "${VARIANT_PACKAGES[@]}"
    fi
done
```

**`packages.json`** structure:

```json
{
    "include": ["common", "packages"],
    "exclude": ["unwanted", "packages"],
    "variants": {
        "gaming": {
            "include": ["steam", "gamescope", "mangohud.x86_64", "gamemode"],
            "exclude": []
        }
    }
}
```

### 3. GitHub Actions Workflows

**Reusable Workflow** (`.github/workflows/reusable_build.yml`):

- Contains all build logic (DRY principle)
- Accepts inputs: `image_name`, `image_flavor`, `image_desc`, `image_keywords`
- Handles: checkout, build, tag, push to registry

**Variant Workflows** (call the reusable workflow):

**`.github/workflows/build.yml`**:

```yaml
jobs:
    build-kyanite:
        uses: ./.github/workflows/reusable_build.yml
        with:
            image_name: "kyanite"
            image_flavor: "main"
            image_desc: "Kyanite - A clean KDE Plasma bootc image"

    build-kyanite-gaming:
        uses: ./.github/workflows/reusable_build.yml
        with:
            image_name: "kyanite-gaming"
            image_flavor: "gaming"
            image_desc: "Kyanite Gaming - Gaming-focused variant with Steam"
```

### Benefits of This Design

✅ **No Code Duplication** - All build logic in one reusable workflow
✅ **Easy to Add Variants** - Just create new workflow file calling reusable workflow
✅ **Simple Maintenance** - Update build logic once, applies to all variants
✅ **Clear Separation** - Variant-specific configs in caller workflows
✅ **Follows Best Practices** - Matches Universal Blue patterns

## Local Development

### Build Standard Kyanite

```bash
just build
# or explicitly:
just build kyanite stable main
```

### Build Gaming Variant

```bash
IMAGE_FLAVOR=gaming just build
# or explicitly:
just build kyanite stable gaming
```

### Build VM Images

```bash
# Standard
just build-qcow2

# Gaming
IMAGE_FLAVOR=gaming just build-qcow2
```

### Direct Podman Build

```bash
# Standard
podman build -t localhost/kyanite:latest .

# Gaming
podman build \
  --build-arg IMAGE_FLAVOR=gaming \
  -t localhost/kyanite-gaming:latest \
  .
```

## How Variants Work

### Build Flow

1. **Trigger**: Push to main or manual workflow dispatch
2. **Jobs**: Both variants build in parallel within `build.yml`
    - `build-kyanite` job with `IMAGE_FLAVOR=main`
    - `build-kyanite-gaming` job with `IMAGE_FLAVOR=gaming`
3. **Reusable Workflow**: Executes build steps
4. **Conditional Logic**: `20-packages.sh` checks `IMAGE_FLAVOR`
5. **Output**: Two images pushed to registry
    - `ghcr.io/alyraffauf/kyanite:stable`
    - `ghcr.io/alyraffauf/kyanite-gaming:stable`

### IMAGE_FLAVOR Values

| Value    | Image Name     | Description    | Steam Installed |
| -------- | -------------- | -------------- | --------------- |
| `main`   | kyanite        | Base image     | ❌ No           |
| `gaming` | kyanite-gaming | Gaming variant | ✅ Yes          |

## Adding New Variants

To add a new variant (e.g., `kyanite-dev`):

1. **Add variant packages** to `packages.json`:

```json
{
  "variants": {
    "gaming": { ... },
    "dev": {
      "include": [
        "development-tools",
        "gcc",
        "make"
      ],
      "exclude": []
    }
  }
}
```

2. **Add new job** to `.github/workflows/build.yml`:

```yaml
build-kyanite-dev:
    name: Build Kyanite Dev
    uses: ./.github/workflows/reusable_build.yml
    permissions:
        contents: read
        packages: write
        id-token: write
    with:
        image_name: "kyanite-dev"
        image_flavor: "dev"
        image_desc: "Kyanite Dev - Development variant"
        image_keywords: "bootc,ublue,kde,development"
```

3. **Done!** New variant builds automatically

## File Structure

```
kyanite/
├── .github/workflows/
│   ├── reusable_build.yml   # Reusable workflow (all build logic)
│   ├── build.yml            # Builds both kyanite and kyanite-gaming
│   ├── validate-*.yml       # Validation workflows
│   └── clean.yml            # Cleanup old images
├── build/
│   ├── 10-build.sh          # Main build orchestrator
│   ├── 20-packages.sh       # Package installation + gaming variant logic
│   ├── 30-workarounds.sh    # System workarounds
│   ├── 40-systemd.sh        # Systemd service configuration
│   └── 90-cleanup.sh        # Final cleanup
├── Containerfile            # Single Containerfile for all variants
└── Justfile                 # Local build commands
```

## Debugging

### Check Build Arguments

```bash
# During build, check IMAGE_FLAVOR
echo "IMAGE_FLAVOR: ${IMAGE_FLAVOR}"
```

### Check Installed Packages

```bash
# Verify Steam installation
rpm -q steam

# Check gaming tools
rpm -q gamescope mangohud gamemode
```

## References

- [Universal Blue Documentation](https://universal-blue.org/)
- [Bluefin Containerfile](https://github.com/ublue-os/bluefin/blob/main/Containerfile)
- [Aurora Containerfile](https://github.com/ublue-os/aurora/blob/main/Containerfile)
- [GitHub Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
