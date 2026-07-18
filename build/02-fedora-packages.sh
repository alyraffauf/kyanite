#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# Fedora Package Installation
###############################################################################
# This script installs and removes packages from Fedora repositories only.
# Third-party repositories are handled in 03-third-party-packages.sh.
###############################################################################

echo "::group:: Replicate ublue base customizations"

# Replicates the parts of ublue-os/main's install.sh that we want now that
# we're rebased directly on quay.io/fedora-ostree-desktops/kinoite.
# Two-phase: (1) repo setup + ublue-os-just install BEFORE the package list
# install so codecs come from negativo17 transparently, (2) distro-sync of
# the mesa/libva stack and versionlocks AFTER the install (see end of file).

# negativo17 fedora-multimedia for fuller codec coverage. priority=90 outranks
# Fedora's default (99); higher-priority versions auto-win during install.
dnf5 config-manager addrepo \
    --from-repofile="https://negativo17.org/repos/fedora-multimedia.repo" || true
dnf5 config-manager setopt fedora-multimedia.priority=90
dnf5 config-manager setopt fedora-multimedia.enabled=1

# Fedora packaging bug: OpenCL-ICD-Loader gets installed in error; ocl-icd is
# the expected ICD loader. https://bugzilla.redhat.com/show_bug.cgi?id=2332429
dnf5 -y swap --repo='fedora' OpenCL-ICD-Loader ocl-icd || true

# Replace podman's default policy.json so /etc has it (bootc/ostree copies
# /usr/etc to /etc on first boot, but moving avoids divergence).
if [[ -f /usr/etc/containers/policy.json ]]; then
    mv /usr/etc/containers/policy.json /etc/containers/policy.json
fi

# Pull a small set of ublue-os utility packages from their COPR. ujust
# infrastructure is now in-house (kyanite-common); the remaining packages
# provide LUKS unlock helpers, hardware udev rules, and rpm-ostreed-automatic
# timer wrappers.
dnf5 -y copr enable ublue-os/packages
dnf5 -y install \
    ublue-os-luks \
    ublue-os-udev-rules \
    ublue-os-update-services

echo "::endgroup::"

echo "::group:: Lock Plasma Desktop Version"

dnf5 versionlock add plasma-desktop

# Explicitly install KDE Plasma related packages with the same version as in base image
dnf5 -y install "plasma-firewall-$(rpm -q --qf "%{VERSION}" plasma-desktop)"

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

echo "::group:: Build Package Lists"

# Initialize package arrays
INCLUDED_PACKAGES=()
EXCLUDED_PACKAGES=()

# Split IMAGE_FLAVOR into array of variant names (e.g., "dx" -> ["dx"])
# Always includes "main" as the base
IFS='-' read -ra FLAVOR_PARTS <<<"${IMAGE_FLAVOR}"

for variant in main "${FLAVOR_PARTS[@]}"; do
    # Check if variant exists in packages.json
    if jq -e ".variants.${variant}" /ctx/packages.json >/dev/null 2>&1; then
        echo "Processing packages for variant: ${variant}"

        # Add variant-specific includes if they exist
        if jq -e ".variants.${variant}.include" /ctx/packages.json >/dev/null 2>&1; then
            readarray -t VARIANT_PACKAGES < <(jq -r ".variants.${variant}.include | sort | unique[]" /ctx/packages.json)
            INCLUDED_PACKAGES+=("${VARIANT_PACKAGES[@]}")
        fi

        # Add variant-specific excludes if they exist
        if jq -e ".variants.${variant}.exclude" /ctx/packages.json >/dev/null 2>&1; then
            readarray -t VARIANT_EXCLUDED < <(jq -r ".variants.${variant}.exclude | sort | unique[]" /ctx/packages.json)
            EXCLUDED_PACKAGES+=("${VARIANT_EXCLUDED[@]}")
        fi
    fi
done

echo "::endgroup::"

echo "::group:: Install Fedora Packages"

# Install all packages in one command
if [[ ${#INCLUDED_PACKAGES[@]} -gt 0 ]]; then
    dnf5 -y install \
        "${INCLUDED_PACKAGES[@]}"
else
    echo "No packages to install."
fi

echo "::endgroup::"

echo "::group:: Remove Excluded Packages"

# Filter to only packages that are actually installed

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

echo "::group:: Add Build Tools"

dnf5 -y group install development-tools

echo "::endgroup::"

echo "::group:: Override mesa/libva from fedora-multimedia + versionlocks"

# Force the mesa/libva/intel-codec stack to negativo17's fuller versions and
# pin them so a future Fedora upgrade doesn't flip-flop. Mirrors ublue's list.
OVERRIDES=(
    intel-gmmlib
    intel-mediasdk
    intel-vpl-gpu-rt
    libheif
    libva
    libva-intel-media-driver
    mesa-dri-drivers
    mesa-filesystem
    mesa-libEGL
    mesa-libGL
    mesa-libgbm
    mesa-va-drivers
    mesa-vulkan-drivers
)
dnf5 distro-sync --skip-unavailable -y --repo='fedora-multimedia' "${OVERRIDES[@]}"
dnf5 versionlock add "${OVERRIDES[@]}"

# Prevent partial qt6 upgrades that can break SDDM/KWin between Fedora bumps.
dnf5 versionlock add "qt6-*"

# Ship Flathub for first-boot flatpak preinstall (kyanite's flatpak-nuke-fedora
# service removes Fedora's flatpak remotes; this provides the real Flathub).
mkdir -p /etc/flatpak/remotes.d/
curl --retry 3 -fsSLo /etc/flatpak/remotes.d/flathub.flatpakrepo \
    https://dl.flathub.org/repo/flathub.flatpakrepo

echo "::endgroup::"

echo "Fedora package installation complete!"
