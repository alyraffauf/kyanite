#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# Stage variant-scoped files into the image:
#   files/<variant>/             → /  (rsync overlay)
#   ujust/<variant>/             → /usr/share/ublue-os/just/60-custom.just
#   flatpaks/<variant>.preinstall → /usr/share/flatpak/preinstall.d/
###############################################################################

echo "::group:: Copy Custom Files"

IFS='-' read -ra FLAVOR_PARTS <<<"${IMAGE_FLAVOR}"
VARIANTS=(main)
for variant in "${FLAVOR_PARTS[@]}"; do
    [[ ${variant} == "main" ]] || VARIANTS+=("${variant}")
done

if [[ -d /ctx/common/system_files/shared ]]; then
    echo "Copying common system files"
    rsync -rvKl /ctx/common/system_files/shared/ /
fi

# Copy variant file overlays
for variant in "${VARIANTS[@]}"; do
    if [[ -d "/ctx/files/${variant}" ]]; then
        echo "Copying files for: ${variant}"
        rsync -rvKl "/ctx/files/${variant}/" /
    fi
done

# Consolidate Just files into the ublue-os custom recipe location
mkdir -p /usr/share/ublue-os/just/
for variant in "${VARIANTS[@]}"; do
    if [[ -d "/ctx/common/ujust/${variant}" ]]; then
        echo "Installing common ujust recipes for: ${variant}"
        find "/ctx/common/ujust/${variant}" -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/60-custom.just
    fi
done

for variant in "${VARIANTS[@]}"; do
    if [[ -d "/ctx/ujust/${variant}" ]]; then
        echo "Installing ujust recipes for: ${variant}"
        find "/ctx/ujust/${variant}" -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/60-custom.just
    fi
done

# Stage Flatpak preinstall files
mkdir -p /usr/share/flatpak/preinstall.d/
for variant in "${VARIANTS[@]}"; do
    if [[ -f "/ctx/common/flatpaks/${variant}.preinstall" ]]; then
        echo "Installing common Flatpak preinstall for: ${variant}"
        cp "/ctx/common/flatpaks/${variant}.preinstall" "/usr/share/flatpak/preinstall.d/kyanite-common-${variant}.preinstall"
    fi
done

for variant in "${VARIANTS[@]}"; do
    if [[ -f "/ctx/flatpaks/${variant}.preinstall" ]]; then
        echo "Installing Flatpak preinstall for: ${variant}"
        cp "/ctx/flatpaks/${variant}.preinstall" "/usr/share/flatpak/preinstall.d/kyanite-${variant}.preinstall"
    fi
done

echo "::endgroup::"

echo "Custom file staging complete!"
