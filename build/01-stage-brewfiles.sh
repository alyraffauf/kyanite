#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# Stage Brewfiles to /usr/share/ublue-os/homebrew/ for ujust at runtime.
###############################################################################

echo "::group:: Stage Brewfiles"

IFS='-' read -ra FLAVOR_PARTS <<<"${IMAGE_FLAVOR}"

mkdir -p /usr/share/ublue-os/homebrew/
for variant in main "${FLAVOR_PARTS[@]}"; do
    if [[ -d "/ctx/brew/${variant}" ]]; then
        echo "Copying Brewfiles for: ${variant}"
        cp "/ctx/brew/${variant}"/*.Brewfile /usr/share/ublue-os/homebrew/ 2>/dev/null || true
    fi
done

echo "::endgroup::"

echo "Brewfile staging complete!"
