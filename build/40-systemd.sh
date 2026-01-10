#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# Systemd Service Configuration
###############################################################################
# This script enables and disables systemd services for the kyanite image.
###############################################################################

echo "::group:: Configure Systemd Services"

# Create docker group at build-time so docker.socket can start on boot
# GID 994 is typically assigned to docker group by the package
if ! grep -q "^docker:" /usr/lib/group; then
    echo "Creating docker group in /usr/lib/group"
    echo "docker:x:994:" >>/usr/lib/group
fi

# Enable system services
systemctl enable docker.socket
systemctl enable flatpak-preinstall.service
systemctl enable podman.socket
systemctl enable tailscaled.service

# Enable global user services
systemctl --global enable bazaar.service

echo "::endgroup::"

echo "Systemd service configuration complete!"
