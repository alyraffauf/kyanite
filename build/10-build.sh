#!/usr/bin/env bash

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

# Copy shared system files
rsync -rvKl /ctx/files/shared/ /

# Copy gaming-specific system files for gaming variant
if [[ "${IMAGE_FLAVOR}" == "gaming" ]]; then
	rsync -rvKl /ctx/files/gaming/ /
fi

# Copy Brewfiles to standard location
mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/

# Consolidate Just Files
mkdir -p /usr/share/ublue-os/just/
find /ctx/custom/ujust -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/60-custom.just

# Copy Flatpak preinstall files
mkdir -p /etc/flatpak/preinstall.d/
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/

echo "::endgroup::"

###############################################################################
# Execute remaining build scripts in sequence
###############################################################################
# Each script is checked for existence before execution
for script in 20-packages.sh 30-workarounds.sh 40-systemd.sh 80-branding.sh 90-cleanup.sh; do
	script_path="/ctx/build/${script}"
	if [[ ! -x "${script_path}" ]]; then
		echo "ERROR: Build script ${script} not found or not executable" >&2
		exit 1
	fi
	echo "::group:: Executing ${script}"
	"${script_path}"
	echo "::endgroup::"
done

echo "Build process completed successfully!"
