#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# Main Build Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

echo "::group:: Copy Custom Files"

# Copy shared system files
rsync -rvKl /ctx/files/shared/ /

# Copy variant-specific system files based on IMAGE_FLAVOR
# Split IMAGE_FLAVOR into array of variant names (e.g., "gaming-dx" -> ["gaming", "dx"])
IFS='-' read -ra FLAVOR_PARTS <<<"${IMAGE_FLAVOR}"

for variant_dir in /ctx/files/*/; do
    variant=$(basename "$variant_dir")
    # Skip shared directory (already copied above)
    if [[ $variant == "shared" ]]; then
        continue
    fi

    # Check if this variant is in the IMAGE_FLAVOR (exact match)
    for flavor in "${FLAVOR_PARTS[@]}"; do
        if [[ $variant == "$flavor" ]]; then
            echo "Detected variant: ${variant}"
            rsync -rvKl "/ctx/files/${variant}/" /
            break
        fi
    done
done

# Copy Brewfiles to standard location
mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/

# Consolidate Just Files
mkdir -p /usr/share/ublue-os/just/
find /ctx/custom/ujust -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/60-custom.just

# Copy Flatpak preinstall files for each flavor
mkdir -p /usr/share/flatpak/preinstall.d/
for variant_dir in /ctx/flatpaks/*/; do
    variant=$(basename "$variant_dir")
    # Check if this variant is in the IMAGE_FLAVOR (exact match)
    for flavor in "${FLAVOR_PARTS[@]}"; do
        if [[ $variant == "$flavor" ]]; then
            echo "Installing Flatpak preinstall for variant: ${variant}"
            cp "/ctx/flatpaks/${variant}/${variant}.preinstall" "/usr/share/flatpak/preinstall.d/kyanite-${variant}.preinstall"
            break
        fi
    done
done

echo "::endgroup::"

echo "File copying and setup completed successfully!"
