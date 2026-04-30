#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# Systemd Service Configuration
###############################################################################
# This script enables and disables systemd services for the kyanite image.
# Service configuration is read from services.json.
###############################################################################

echo "::group:: Build Service Lists"

# Initialize service arrays
SYSTEM_ENABLE=()
SYSTEM_DISABLE=()
USER_ENABLE=()
USER_DISABLE=()

# Split IMAGE_FLAVOR into array of variant names (e.g., "gaming-dx" -> ["gaming", "dx"])
# Always includes "main" as the base
IFS='-' read -ra FLAVOR_PARTS <<<"${IMAGE_FLAVOR}"

for variant in main "${FLAVOR_PARTS[@]}"; do
    # Check if variant exists in services.json
    if jq -e ".variants.${variant}" /ctx/services.json >/dev/null 2>&1; then
        echo "Processing services for variant: ${variant}"

        # Add variant-specific system services if they exist
        if jq -e ".variants.${variant}.system.enable" /ctx/services.json >/dev/null 2>&1; then
            readarray -t VARIANT_SYSTEM_ENABLE < <(jq -r ".variants.${variant}.system.enable | sort | unique[]" /ctx/services.json)
            SYSTEM_ENABLE+=("${VARIANT_SYSTEM_ENABLE[@]}")
        fi

        if jq -e ".variants.${variant}.system.disable" /ctx/services.json >/dev/null 2>&1; then
            readarray -t VARIANT_SYSTEM_DISABLE < <(jq -r ".variants.${variant}.system.disable | sort | unique[]" /ctx/services.json)
            SYSTEM_DISABLE+=("${VARIANT_SYSTEM_DISABLE[@]}")
        fi

        # Add variant-specific user services if they exist
        if jq -e ".variants.${variant}.user.enable" /ctx/services.json >/dev/null 2>&1; then
            readarray -t VARIANT_USER_ENABLE < <(jq -r ".variants.${variant}.user.enable | sort | unique[]" /ctx/services.json)
            USER_ENABLE+=("${VARIANT_USER_ENABLE[@]}")
        fi

        if jq -e ".variants.${variant}.user.disable" /ctx/services.json >/dev/null 2>&1; then
            readarray -t VARIANT_USER_DISABLE < <(jq -r ".variants.${variant}.user.disable | sort | unique[]" /ctx/services.json)
            USER_DISABLE+=("${VARIANT_USER_DISABLE[@]}")
        fi
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
