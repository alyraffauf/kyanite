#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# Systemd Service Configuration
###############################################################################
# This script enables and disables systemd services for the kyanite image.
###############################################################################

echo "::group:: Configure Systemd Services"

# Enable system services
systemctl enable podman.socket
systemctl enable tailscaled.service
systemctl enable flatpak-preinstall.service

# Enable global user services
systemctl --global enable bazaar.service

# Disable global user services
systemctl --global disable sunshine.service

echo "::endgroup::"

echo "Systemd configuration complete!"
