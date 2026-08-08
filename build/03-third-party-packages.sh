#!/usr/bin/env bash

set -eoux pipefail

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

###############################################################################
# Third-Party Package Installation
###############################################################################
# This script optionally installs packages from third-party repositories:
# - Cider
# - Terra
# - Tailscale
# - COPR repositories
###############################################################################

# echo "::group:: Install Cider"

# echo "Installing Cider from official repository..."

# # Add Cider repository
# cat >/etc/yum.repos.d/cider.repo <<'EOF'
# [cidercollective]
# name=Cider Collective Repository
# baseurl=https://repo.cider.sh/rpm/RPMS
# enabled=0
# gpgcheck=1
# gpgkey=https://repo.cider.sh/RPM-GPG-KEY
# EOF

# # Install Cider package
# dnf5 -y install --enablerepo='cidercollective' Cider

# echo "::endgroup::"

echo "::group:: Install Terra packages"

# The bootstrap package is fetched before Terra's signing keys are available.
# All subsequent Terra packages are verified using the installed keys.
# shellcheck disable=SC2016 # dnf5 expands $releasever, not Bash.
TERRA_REPOSITORY='terra,https://repos.fyralabs.com/terra$releasever'
dnf5 -y install --nogpgcheck \
    --repofrompath "${TERRA_REPOSITORY}" \
    terra-release \
    terra-gpg-keys
dnf5 config-manager setopt terra.enabled=0
dnf5 -y install --enablerepo=terra \
    ghostty \
    zed

echo "::endgroup::"

echo "::group:: Install Tailscale"

dnf5 config-manager addrepo \
    --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf5 config-manager setopt tailscale-stable.enabled=0
dnf5 -y install --enablerepo=tailscale-stable tailscale

echo "::endgroup::"

echo "::group:: Install COPR packages"

# copr_install_isolated "quadratech188/vicinae" "vicinae"

copr_install_isolated "ublue-os/packages" \
    "krunner-bazaar"

echo "::endgroup::"

echo "::group:: Disable Third-Party Repositories"

# Disable third-party repos
for repo in negativo17-fedora-multimedia fedora-cisco-openh264; do
    if [[ -f "/etc/yum.repos.d/${repo}.repo" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "/etc/yum.repos.d/${repo}.repo"
    fi
done

echo "::endgroup::"

echo "Third-party package installation complete!"
