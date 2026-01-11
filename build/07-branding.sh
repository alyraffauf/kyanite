#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2154
set -eoux pipefail

echo "::group:: Applying OS Release Branding"

###############################################################################
# OS Release Branding
###############################################################################
# Complete branding changes to make system identify as "Kyanite"
# Following Aurora/Bluefin pattern - maintains full Fedora compatibility

IMAGE_PRETTY_NAME="Kyanite"
IMAGE_LIKE="fedora"
IMAGE_VENDOR="alyraffauf"
IMAGE_NAME="${IMAGE_NAME:-kyanite}"
IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
IMAGE_TAG="${UBLUE_IMAGE_TAG:-stable}"
BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite}"
FEDORA_VERSION="43"
VERSION="${VERSION:-43}"
HOME_URL="https://github.com/${IMAGE_VENDOR}/kyanite"
DOCUMENTATION_URL="https://github.com/${IMAGE_VENDOR}/kyanite/blob/main/README.md"
SUPPORT_URL="https://github.com/${IMAGE_VENDOR}/kyanite/issues/"
BUG_SUPPORT_URL="https://github.com/${IMAGE_VENDOR}/kyanite/issues/"
CODE_NAME="Silicate"

# Create image-info.json
mkdir -p /usr/share/ublue-os
IMAGE_INFO="/usr/share/ublue-os/image-info.json"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/${IMAGE_VENDOR}/${IMAGE_NAME}"

cat >$IMAGE_INFO <<EOF
{
  "image-name": "$IMAGE_NAME",
  "image-flavor": "$IMAGE_FLAVOR",
  "image-vendor": "$IMAGE_VENDOR",
  "image-ref": "$IMAGE_REF",
  "image-tag": "$IMAGE_TAG",
  "base-image-name": "$BASE_IMAGE_NAME",
  "fedora-version": "$FEDORA_VERSION"
}
EOF

# Modify OS Release File - following Aurora's pattern exactly
sed -i "s|^VARIANT_ID=.*|VARIANT_ID=$IMAGE_NAME|" /usr/lib/os-release
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"${IMAGE_PRETTY_NAME} (Version: ${VERSION})\"|" /usr/lib/os-release
sed -i "s|^NAME=.*|NAME=\"$IMAGE_PRETTY_NAME\"|" /usr/lib/os-release
sed -i "s|^HOME_URL=.*|HOME_URL=\"$HOME_URL\"|" /usr/lib/os-release
sed -i "s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"$DOCUMENTATION_URL\"|" /usr/lib/os-release
sed -i "s|^SUPPORT_URL=.*|SUPPORT_URL=\"$SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"$BUG_SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^CPE_NAME=\"cpe:/o:fedoraproject:fedora|CPE_NAME=\"cpe:/o:universal-blue:${IMAGE_PRETTY_NAME,}|" /usr/lib/os-release
sed -i "s|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME=\"${IMAGE_PRETTY_NAME,}\"|" /usr/lib/os-release
# Keep ID=fedora for BIB compatibility, but add ID_LIKE for custom branding
sed -i "/^ID=fedora/a ID_LIKE=\"${IMAGE_LIKE}\"" /usr/lib/os-release
sed -i "/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d" /usr/lib/os-release
sed -i "s|^VERSION_CODENAME=.*|VERSION_CODENAME=\"$CODE_NAME\"|" /usr/lib/os-release
sed -i "s|^VERSION=.*|VERSION=\"$VERSION ($BASE_IMAGE_NAME)\"|" /usr/lib/os-release
sed -i "s|^OSTREE_VERSION=.*|OSTREE_VERSION=\'${VERSION}\'|" /usr/lib/os-release

# Add BUILD_ID if available
if [[ -n ${SHA_HEAD_SHORT:-} ]]; then
    echo "BUILD_ID=\"$SHA_HEAD_SHORT\"" >>/usr/lib/os-release
fi

# Add IMAGE_ID and IMAGE_VERSION (systemd 249+)
echo "IMAGE_ID=\"$IMAGE_NAME\"" >>/usr/lib/os-release
echo "IMAGE_VERSION=\"$VERSION\"" >>/usr/lib/os-release

# Fix issues caused by ID no longer being fedora
sed -i 's|^EFIDIR=.*|EFIDIR="fedora"|' /usr/sbin/grub2-switch-to-blscfg

# Update KDE About dialog variant string based on IMAGE_FLAVOR
KDE_ABOUT_RC="/usr/share/kde-settings/kde-profile/default/xdg/kcm-about-distrorc"
if [[ -f $KDE_ABOUT_RC ]]; then
    if [[ ${IMAGE_FLAVOR} != "main" ]]; then
        # Split IMAGE_FLAVOR by hyphen, sort, uppercase, and join with +
        IFS='-' read -ra FLAVOR_PARTS <<<"${IMAGE_FLAVOR}"
        # Sort the array
        mapfile -t SORTED_FLAVORS < <(printf '%s\n' "${FLAVOR_PARTS[@]}" | sort)
        # Convert to uppercase and join with +
        VARIANT_STRING=$(printf '%s\n' "${SORTED_FLAVORS[@]}" | tr '[:lower:]' '[:upper:]' | paste -sd '+')

        # Append Variant= line to KDE About dialog
        echo "Variant=${VARIANT_STRING}" >>"$KDE_ABOUT_RC"
        echo "Set KDE Variant to: ${VARIANT_STRING}"
    else
        # For main variant, set to "DESKTOP"
        echo "Variant=DESKTOP" >>"$KDE_ABOUT_RC"
        echo "Set KDE Variant to: DESKTOP"
    fi
fi

###############################################################################

echo "::endgroup::"

echo "OS Release branding applied successfully!"
