#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# Fedora Package Installation
###############################################################################
# This script installs and removes packages from Fedora repositories only.
# Third-party repositories are handled in 25-third-party-packages.sh.
###############################################################################

echo "::group:: Lock Plasma Desktop Version"

dnf5 versionlock add plasma-desktop

# Explicitly install KDE Plasma related packages with the same version as in base image
dnf5 -y install plasma-firewall-$(rpm -q --qf "%{VERSION}" plasma-desktop)

echo "::endgroup::"

echo "::group:: Validate packages.json"

# Validate packages.json before attempting to parse it
# This ensures builds fail fast if the JSON is malformed
if ! jq empty /ctx/packages.json 2>/dev/null; then
    echo "ERROR: packages.json contains syntax errors and cannot be parsed" >&2
    echo "Please fix the JSON syntax before building" >&2
    exit 1
fi

echo "::endgroup::"

echo "::group:: Install Fedora Packages"

# build list of all packages requested for inclusion
readarray -t INCLUDED_PACKAGES < <(jq -r '.include | sort | unique[]' /ctx/packages.json)

# Install Packages
if [[ ${#INCLUDED_PACKAGES[@]} -gt 0 ]]; then
    dnf5 -y install \
        "${INCLUDED_PACKAGES[@]}"
else
    echo "No packages to install."
fi

echo "::endgroup::"

# Install variant-specific packages based on IMAGE_FLAVOR
# Supports combined variants (e.g., "gaming-dx-nvidia")
VARIANT_NAMES=$(jq -r '.variants | keys[]' /ctx/packages.json)

for variant in ${VARIANT_NAMES}; do
    if [[ ${IMAGE_FLAVOR} =~ ${variant} ]]; then
        echo "::group:: Install ${variant} variant packages"

        # Get variant-specific packages
        readarray -t VARIANT_PACKAGES < <(jq -r ".variants.${variant}.include | sort | unique[]" /ctx/packages.json)

        if [[ ${#VARIANT_PACKAGES[@]} -gt 0 ]]; then
            dnf5 -y --setopt=install_weak_deps=False install \
                "${VARIANT_PACKAGES[@]}"
        else
            echo "No packages to install for ${variant} variant."
        fi

        echo "::endgroup::"
    fi
done

echo "::group:: Remove Excluded Packages"

# Build list of all packages requested for exclusion (common)
readarray -t EXCLUDED_PACKAGES < <(jq -r '.exclude | sort | unique[]' /ctx/packages.json)

# Add variant-specific exclusions
for variant in ${VARIANT_NAMES}; do
    if [[ ${IMAGE_FLAVOR} =~ ${variant} ]]; then
        readarray -t VARIANT_EXCLUDED < <(jq -r ".variants.${variant}.exclude | sort | unique[]" /ctx/packages.json)
        EXCLUDED_PACKAGES+=("${VARIANT_EXCLUDED[@]}")
    fi
done

if [[ ${#EXCLUDED_PACKAGES[@]} -gt 0 ]]; then
    INSTALLED_EXCLUDED=()
    for pkg in "${EXCLUDED_PACKAGES[@]}"; do
        if rpm -q "$pkg" &>/dev/null; then
            INSTALLED_EXCLUDED+=("$pkg")
        fi
    done
    EXCLUDED_PACKAGES=("${INSTALLED_EXCLUDED[@]}")
fi

# Remove any excluded packages which are still present on image
if [[ ${#EXCLUDED_PACKAGES[@]} -gt 0 ]]; then
    dnf5 -y remove \
        "${EXCLUDED_PACKAGES[@]}"
else
    echo "No packages to remove."
fi

echo "::endgroup::"

echo "Fedora package installation complete!"
