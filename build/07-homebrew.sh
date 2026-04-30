#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# Homebrew Setup
###############################################################################
# This script configures Homebrew for the kyanite image.
###############################################################################

echo "::group:: Install Homebrew System Files"

# Copy Homebrew system files from brew image
rsync -rvKl /ctx/oci/brew/ /

echo "::endgroup::"

echo "::group:: Configure Homebrew Services"

# Set up homebrew systemd services
systemctl preset brew-setup.service
systemctl preset brew-update.timer
systemctl preset brew-upgrade.timer

echo "::endgroup::"

echo "Homebrew configuration complete!"
