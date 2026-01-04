#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Main Build Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

echo "::group:: Copy Custom Files"

# Copy system files

rsync -rvKl /ctx/files/ /

# Copy Brewfiles to standard location
mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/

# Consolidate Just Files
mkdir -p /usr/share/ublue-os/just/
find /ctx/custom/ujust -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just

# Copy Flatpak preinstall files
mkdir -p /etc/flatpak/preinstall.d/
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/

echo "::endgroup::"

echo "::group:: Install Packages"

# Install packages using dnf5
# Example: dnf5 install -y tmux

# Example using COPR with isolated pattern:
# copr_install_isolated "ublue-os/staging" package-name

echo "::endgroup::"

echo "::group:: System Configuration"

# System configuration tasks will be handled by later scripts
# See 40-systemd.sh for service enablement

echo "::endgroup::"

echo "Custom build complete!"

###############################################################################
# Execute remaining build scripts in sequence
###############################################################################
# Each script is checked for existence before execution
for script in 20-packages.sh 30-workarounds.sh 40-systemd.sh 90-cleanup.sh; do
    script_path="/ctx/build/${script}"
    if [[ ! -x "${script_path}" ]]; then
        echo "ERROR: Build script ${script} not found or not executable" >&2
        exit 1
    fi
    echo "::group:: Executing ${script}"
    "${script_path}"
    echo "::endgroup::"
done

echo "All build scripts completed successfully!"
