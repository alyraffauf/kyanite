#!/usr/bin/env bash

set -eoux pipefail

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

dnf5 versionlock add plasma-desktop

# Explicitly install KDE Plasma related packages with the same version as in base image
dnf5 -y install plasma-firewall-$(rpm -q --qf "%{VERSION}" plasma-desktop)

# Validate packages.json before attempting to parse it
# This ensures builds fail fast if the JSON is malformed
if ! jq empty /ctx/packages.json 2>/dev/null; then
    echo "ERROR: packages.json contains syntax errors and cannot be parsed" >&2
    echo "Please fix the JSON syntax before building" >&2
    exit 1
fi

# build list of all packages requested for inclusion
readarray -t INCLUDED_PACKAGES < <(jq -r '.include | sort | unique[]' /ctx/packages.json)

# Install Packages
if [[ ${#INCLUDED_PACKAGES[@]} -gt 0 ]]; then
    dnf5 -y install \
        "${INCLUDED_PACKAGES[@]}"
else
    echo "No packages to install."

fi

# build list of all packages requested for exclusion
readarray -t EXCLUDED_PACKAGES < <(jq -r '.exclude | sort | unique[]' /ctx/packages.json)

if [[ ${#EXCLUDED_PACKAGES[@]} -gt 0 ]]; then
    INSTALLED_EXCLUDED=()
    for pkg in "${EXCLUDED_PACKAGES[@]}"; do
        if rpm -q "$pkg" &>/dev/null; then
            INSTALLED_EXCLUDED+=("$pkg")
        fi
    done
    EXCLUDED_PACKAGES=("${INSTALLED_EXCLUDED[@]}")
fi

# remove any excluded packages which are still present on image
if [[ ${#EXCLUDED_PACKAGES[@]} -gt 0 ]]; then
    dnf5 -y remove \
        "${EXCLUDED_PACKAGES[@]}"
else
    echo "No packages to remove."
fi

# Docker packages from their repo
echo "::group:: Install Docker"
dnf5 config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
dnf5 -y install --enablerepo=docker-ce-stable \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    docker-model-plugin

echo "::endgroup::"

echo "::group:: Install Cider"

echo "Installing Cider from official repository..."

# Add Cider repository
cat >/etc/yum.repos.d/cider.repo <<'EOF'
[cidercollective]
name=Cider Collective Repository
baseurl=https://repo.cider.sh/rpm/RPMS
enabled=0
gpgcheck=1
gpgkey=https://repo.cider.sh/RPM-GPG-KEY
EOF

# Install Cider package
dnf5 -y install --enablerepo='cidercollective' Cider

echo "::endgroup::"

echo "::group:: Install Tailscale"

# Install tailscale package from their official repository
echo "Installing Tailscale from official repository..."
dnf5 config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf5 config-manager setopt tailscale-stable.enabled=0
dnf5 -y install --enablerepo='tailscale-stable' tailscale

echo "::endgroup::"

echo "::group:: Install COPR Packages"

# Example of COPR package installation (currently disabled)
# copr_install_isolated scottames/ghostty "ghostty"

copr_install_isolated "ublue-os/packages" \
    "krunner-bazaar"

echo "::endgroup::"

echo "::group:: Install Flatpak Preinstall Support"

# TODO: Remove this section when flatpak preinstall is available in Fedora stable
dnf5 -y copr enable ublue-os/flatpak-test
dnf5 -y copr disable ublue-os/flatpak-test
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper
dnf5 -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test install flatpak-debuginfo flatpak-libs-debuginfo flatpak-session-helper-debuginfo

echo "::endgroup::"

if [[ ${IMAGE_FLAVOR} == "gaming" ]]; then
    echo "::group:: Install Steam and Gaming Tools"

    dnf5 -y --setopt=install_weak_deps=False install \
        steam \
        gamescope \
        mangohud.x86_64 \
        mangohud.i686 \
        gamemode

    copr_install_isolated "lizardbyte/beta" \
        "sunshine"

    echo "::endgroup::"
fi

echo "Package installation complete!"
