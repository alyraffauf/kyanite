#!/usr/bin/env bash

set -eoux pipefail

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

###############################################################################
# Third-Party Package Installation
###############################################################################
# This script optionally installs packages from third-party repositories:
# - Docker CE
# - Cider
# - Tailscale
# - COPR repositories
###############################################################################

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

copr_install_isolated scottames/ghostty "ghostty"

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

if [[ ${IMAGE_FLAVOR} =~ gaming ]]; then
    echo "::group:: Add Gaming Packages from COPR"

    copr_install_isolated "lizardbyte/beta" \
        "sunshine"

    echo "::endgroup::"
fi

if [[ ${IMAGE_FLAVOR} =~ dx ]]; then
    echo "::group:: Add Developer Packages"

    dnf5 config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
    dnf5 -y install --enablerepo=docker-ce-stable \
        containerd.io \
        docker-buildx-plugin \
        docker-ce \
        docker-ce-cli \
        docker-compose-plugin \
        docker-model-plugin

    # Create docker group manually in /usr/lib/group if it doesn't exist
    # GID 994 is typically assigned to docker group by the package
    if ! grep -q "^docker:" /usr/lib/group; then
        echo "Creating docker group in /usr/lib/group"
        echo "docker:x:994:" >>/usr/lib/group
    fi

    dnf5 config-manager addrepo --from-repofile=https://packages.microsoft.com/yumrepos/vscode/config.repo --save-filename=vscode
    sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/vscode.repo
    dnf5 -y install --enablerepo=vscode-yum \
        code

    echo "::endgroup::"
fi

echo "::group:: Disable Third-Party Repositories"

# Disable third-party repos
for repo in negativo17-fedora-multimedia tailscale fedora-cisco-openh264; do
    if [[ -f "/etc/yum.repos.d/${repo}.repo" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "/etc/yum.repos.d/${repo}.repo"
    fi
done

echo "::endgroup::"

echo "Third-party package installation complete!"
