# Essential Flatpak Installation

This document describes the essential Flatpak installation system for Kyanite.

## Problem Statement

When installing from the Kyanite ISO, there was a race condition between the `flatpak-preinstall.service` and user login on first boot:

1. **Race Condition**: If users logged in before flatpak-preinstall completed, some applications would be missing, icons would be broken, etc.
2. **No Offline Support**: Users who installed without internet connectivity would have no applications at all - no web browser, no Flatpak store, nothing useful.

## Solution

A two-tier Flatpak installation system:

### Tier 1: Essential Apps (flatpak-essential-install.service)

Installs **critical** applications before user login:

- **Firefox** - Web browser for internet access
- **Bazaar** - Flatpak store for managing applications

This service:

- Runs on first boot after network is available
- Completes **before** the graphical login screen appears
- Uses a flag file (`/var/lib/flatpak/essential-installed`) to run only once
- Has retry logic for network failures (3 retries over 10 minutes)
- Has a 5-minute timeout per installation attempt

### Tier 2: Additional Apps (flatpak-preinstall.service)

Installs **all other** applications defined in `.preinstall` files:

- Runs after essential apps are installed
- Can run in parallel with user login (non-blocking)
- Users can work while additional apps install in the background

## Benefits

✅ **No more race condition** - Essential apps are ready before login
✅ **Offline capable** - Users without internet can still get Firefox and Bazaar once they connect
✅ **Better first impression** - Browser and app store are immediately available
✅ **Small ISO** - No apps embedded in the ISO image
✅ **Flexible** - Additional apps install in background, non-blocking

## Implementation Details

### Service Order

```
network-online.target
    ↓
flatpak-essential-install.service (Firefox, Bazaar)
    ↓
flatpak-preinstall.service (all other apps)
    ↓
graphical.target (user login)
```

### Files

- **Service Definition**: `files/main/usr/lib/systemd/system/flatpak-essential-install.service`
- **Service Enablement**: `services.json` (main variant)
- **App Lists**: `flatpaks/*.preinstall` (handled by flatpak-preinstall, not essential-install)

### Failure Modes

1. **No network on first boot**:

    - Essential install service waits for network
    - Retries 3 times over 10 minutes
    - If still no network, service fails gracefully
    - On next boot with network, service runs (flag file not created)

2. **Network fails during installation**:

    - Service retries with 60-second backoff
    - Up to 3 retry attempts
    - If all fail, service fails but system is usable
    - Manual retry: `sudo systemctl restart flatpak-essential-install.service`

3. **Flathub is down**:
    - Same retry logic as network failure
    - System remains usable
    - Manual retry possible

## Maintenance

### Adding Essential Apps

To add more apps to the essential tier:

1. Edit `files/main/usr/lib/systemd/system/flatpak-essential-install.service`
2. Add another `ExecStart=` line with the Flatpak ID
3. Consider timeout implications (more apps = longer timeout needed)

Example:

```ini
ExecStart=/usr/bin/flatpak install --system --noninteractive -y flathub org.mozilla.firefox
ExecStart=/usr/bin/flatpak install --system --noninteractive -y flathub io.github.kolunmi.Bazaar
ExecStart=/usr/bin/flatpak install --system --noninteractive -y flathub org.gnome.Software
```

### Adjusting Timeout

The current timeout is 300 seconds (5 minutes). This is calculated as:

- ~2 minutes per app on slow connections
- 2 apps × 2 minutes = 4 minutes
- +1 minute buffer = 5 minutes

If adding more apps, adjust `TimeoutStartSec=` accordingly.

### Disabling Essential Install

If you want to disable this feature:

1. Remove `flatpak-essential-install.service` from `services.json`
2. All Flatpaks will install via the regular `flatpak-preinstall.service`

## Testing

To test the service:

1. Build the image: `just build`
2. Build an ISO: `just build-iso`
3. Install in a VM with network disabled
4. Enable network on first boot
5. Verify Firefox and Bazaar appear before you can log in
6. Check service status: `systemctl status flatpak-essential-install.service`

## References

- [Flatpak Documentation](https://docs.flatpak.org/)
- [systemd.service Documentation](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- Original issue: Flatpaks not available during first boot after installing from ISO
