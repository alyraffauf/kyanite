#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# Systemd Service Configuration
###############################################################################
# This script enables and disables systemd services for the kyanite image.
# Service configuration is read from services.json.
###############################################################################

echo "::group:: Build Service Lists"

# Build lists of common system and user services
readarray -t SYSTEM_ENABLE < <(jq -r '.system.enable | sort | unique[]' /ctx/services.json)
readarray -t SYSTEM_DISABLE < <(jq -r '.system.disable | sort | unique[]' /ctx/services.json)
readarray -t USER_ENABLE < <(jq -r '.user.enable | sort | unique[]' /ctx/services.json)
readarray -t USER_DISABLE < <(jq -r '.user.disable | sort | unique[]' /ctx/services.json)

# Add variant-specific services based on IMAGE_FLAVOR
# Supports combined variants (e.g., "gaming-dx-nvidia")
VARIANT_NAMES=$(jq -r '.variants | keys[]' /ctx/services.json)

for variant in ${VARIANT_NAMES}; do
    if [[ ${IMAGE_FLAVOR} =~ ${variant} ]]; then
        echo "Detected variant: ${variant}"

        # Add variant-specific system services
        readarray -t VARIANT_SYSTEM_ENABLE < <(jq -r ".variants.${variant}.system.enable | sort | unique[]" /ctx/services.json)
        SYSTEM_ENABLE+=("${VARIANT_SYSTEM_ENABLE[@]}")

        readarray -t VARIANT_SYSTEM_DISABLE < <(jq -r ".variants.${variant}.system.disable | sort | unique[]" /ctx/services.json)
        SYSTEM_DISABLE+=("${VARIANT_SYSTEM_DISABLE[@]}")

        # Add variant-specific user services
        readarray -t VARIANT_USER_ENABLE < <(jq -r ".variants.${variant}.user.enable | sort | unique[]" /ctx/services.json)
        USER_ENABLE+=("${VARIANT_USER_ENABLE[@]}")

        readarray -t VARIANT_USER_DISABLE < <(jq -r ".variants.${variant}.user.disable | sort | unique[]" /ctx/services.json)
        USER_DISABLE+=("${VARIANT_USER_DISABLE[@]}")
    fi
done

echo "::endgroup::"

echo "::group:: Enable System Services"

if [[ ${#SYSTEM_ENABLE[@]} -gt 0 ]]; then
    for service in "${SYSTEM_ENABLE[@]}"; do
        echo "Enabling system service: ${service}"
        systemctl enable "${service}"
    done
fi

echo "::endgroup::"

echo "::group:: Disable System Services"

if [[ ${#SYSTEM_DISABLE[@]} -gt 0 ]]; then
    for service in "${SYSTEM_DISABLE[@]}"; do
        echo "Disabling system service: ${service}"
        systemctl disable "${service}" || echo "Service ${service} not found, skipping"
    done
fi

echo "::endgroup::"

echo "::group:: Enable User Services"

if [[ ${#USER_ENABLE[@]} -gt 0 ]]; then
    for service in "${USER_ENABLE[@]}"; do
        echo "Enabling user service: ${service}"
        systemctl --global enable "${service}"
    done
fi

echo "::endgroup::"

echo "::group:: Disable User Services"

if [[ ${#USER_DISABLE[@]} -gt 0 ]]; then
    for service in "${USER_DISABLE[@]}"; do
        echo "Disabling user service: ${service}"
        systemctl --global disable "${service}" || echo "Service ${service} not found, skipping"
    done
fi

echo "::endgroup::"

echo "Systemd service configuration complete!"
