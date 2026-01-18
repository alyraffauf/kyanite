# Flatpak Preinstall Integration

This directory contains Flatpak preinstall configuration files for each image variant.

## Files

Each `.preinstall` file corresponds to an image variant:

- `main.preinstall` - Base variant flatpaks (applies to all kyanite images)
- `gaming.preinstall` - Gaming variant flatpaks (applies to kyanite-gaming and kyanite-dx-gaming)

Files are copied to `/usr/share/flatpak/preinstall.d/kyanite-{variant}.preinstall` in the built image based on the `IMAGE_FLAVOR` variable during the build.

## What is Flatpak Preinstall?

Flatpak preinstall is a feature that allows system administrators to define Flatpak applications that should be installed on first boot. These files are read by the Flatpak system integration and automatically install the specified applications.

## How It Works

1. **During Build**: Files from the appropriate variant directories are copied to `/usr/share/flatpak/preinstall.d/` in the image based on the `IMAGE_FLAVOR` variable
2. **On First Boot**: After user setup completes, the system reads these files and installs the specified Flatpaks
3. **User Experience**: Applications appear automatically after first login

## Important: Installation Timing

**Flatpaks are NOT included in the ISO or container image.** They are downloaded and installed after:

- User completes initial system setup
- Network connection is established
- First boot process runs `flatpak preinstall`

**The `flatpak-preinstall.service` runs before the graphical login screen appears**, ensuring all Flatpaks are installed before the user can log in. This prevents a race condition where users might log in before apps are ready.

This means:

- The ISO remains small and bootable offline
- Users need an internet connection after installation for Flatpaks to install
- First boot may take slightly longer as Flatpaks install before login
- All applications are ready when the user reaches the login screen
- If offline during first boot, the service will wait for network or timeout gracefully

## File Format

Each file uses the INI format with `[Flatpak Preinstall NAME]` sections:

```ini
[Flatpak Preinstall org.mozilla.firefox]
Branch=stable

[Flatpak Preinstall org.gnome.Calculator]
Branch=stable
```

**Keys:**

- `Install` - (boolean) Whether to install (default: true)
- `Branch` - (string) Branch name (default: "master", commonly "stable")
- `IsRuntime` - (boolean) Whether this is a runtime (default: false for apps)
- `CollectionID` - (string) Collection ID of the remote, if any

See: https://docs.flatpak.org/en/latest/flatpak-command-reference.html#flatpak-preinstall

## Usage

### Adding Flatpaks to Your Image

1. Edit the appropriate `.preinstall` file (e.g., `main.preinstall` or `gaming.preinstall`)
2. Add Flatpak references in INI format with `[Flatpak Preinstall NAME]` sections
3. Build your image - the files will be copied to `/usr/share/flatpak/preinstall.d/` based on the image variant
4. After user setup completes, Flatpaks will be automatically installed

**Note:** The `dx` variant does not have its own flatpak preinstall file - it inherits from other variants only.

### Finding Flatpak IDs

To find the ID of a Flatpak:

```bash
flatpak search app-name
```

Or browse Flathub: https://flathub.org/

## Adding New Variants

To add a new variant:

1. Create a new preinstall file: `flatpaks/{variant}.preinstall`
2. Add your Flatpak definitions using the INI format
3. The build script will automatically detect and copy the file if the variant is in `IMAGE_FLAVOR`

## Important Notes

- Files must be named `{variant}.preinstall` matching the variant name
- Comments can be added with `#`
- Empty lines are ignored
- **Flatpaks are downloaded from Flathub on first boot** - not embedded in the image
- **Internet connection required** after installation for Flatpaks to install
- Installation happens automatically after user setup completes
- Users can still uninstall these applications if desired
- First boot will take longer while Flatpaks are being installed

## Resources

- [Flatpak Documentation](https://docs.flatpak.org/)
- [Flatpak Preinstall Reference](https://docs.flatpak.org/en/latest/flatpak-command-reference.html#flatpak-preinstall)
- [Flathub](https://flathub.org/)
