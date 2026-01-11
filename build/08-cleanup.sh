#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# Final Cleanup and Configuration
###############################################################################
# This script performs final cleanup tasks and system tweaks.
###############################################################################

echo "::group:: Hide Desktop Files"

# Hide Desktop Files. Hidden removes mime associations
for file in htop nvtop; do
    if [[ -f "/usr/share/applications/${file}.desktop" ]]; then
        desktop-file-edit --set-key=Hidden --set-value=true /usr/share/applications/${file}.desktop
    fi
done

echo "::endgroup::"

echo "::group:: Configure Discover"

# Hide Discover entries by renaming them (allows for easy re-enabling)
discover_apps=(
    "org.kde.discover.desktop"
    "org.kde.discover.flatpak.desktop"
    "org.kde.discover.notifier.desktop"
    "org.kde.discover.urlhandler.desktop"
)

for app in "${discover_apps[@]}"; do
    if [ -f "/usr/share/applications/${app}" ]; then
        mv "/usr/share/applications/${app}" "/usr/share/applications/${app}.disabled"
    fi
done

# These notifications are useless and confusing
rm -f /etc/xdg/autostart/org.kde.discover.notifier.desktop

# Use Bazaar for Flatpak refs
echo "application/vnd.flatpak.ref=io.github.kolunmi.Bazaar.desktop" >>/usr/share/applications/mimeapps.list

echo "::endgroup::"

echo "::group:: Commit OSTree"

# Commit the ostree repository to finalize the image
ostree container commit

echo "::endgroup::"

echo "Final cleanup and configuration complete!"
