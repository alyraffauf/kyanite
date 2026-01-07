###############################################################################
# BUILD ARGUMENTS
###############################################################################
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite}"
ARG SOURCE_IMAGE="${BASE_IMAGE_NAME}-main"
# Static value enables Renovate to detect and update the base image
ARG BASE_IMAGE="ghcr.io/ublue-os/kinoite-main:43"
ARG BREW_IMAGE="ghcr.io/ublue-os/brew:latest"
# SHA pinning enables Renovate to automatically update dependencies
# See: https://docs.renovatebot.com/docker/#digest-pinning
ARG BASE_IMAGE_SHA="sha256:786475f85cb1730253336d049ddf8e2257bfe0c1124cdc6bc421f381ef17a4e8"
ARG BREW_IMAGE_SHA="sha256:f9637549a24a7e02315c28db04cc0827dfc04bb74cea3be5c187f10c262c30d2"

###############################################################################
# IMPORT STAGES
###############################################################################
FROM ${BREW_IMAGE}@${BREW_IMAGE_SHA} AS brew

FROM scratch AS ctx
COPY /build /build
COPY /files /files
COPY /custom /custom
COPY /packages.json /packages.json

# Import Homebrew files
COPY --from=brew /system_files /oci/brew

###############################################################################
# MAIN IMAGE
###############################################################################
FROM ${BASE_IMAGE}@${BASE_IMAGE_SHA} AS base

# Build arguments for image metadata and variant selection
ARG IMAGE_NAME="${IMAGE_NAME:-kyanite}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT:-}"
ARG UBLUE_IMAGE_TAG="${UBLUE_IMAGE_TAG:-stable}"

# Labels for image metadata
LABEL org.opencontainers.image.name="${IMAGE_NAME}"
LABEL org.opencontainers.image.vendor="${IMAGE_VENDOR}"
LABEL org.opencontainers.image.flavor="${IMAGE_FLAVOR}"

###############################################################################
# BUILD PROCESS
###############################################################################
# Execute build scripts with variant support
# IMAGE_FLAVOR is available to all build scripts:
#   - "main" (default): Base kyanite
#   - "gaming": Kyanite with Steam and gaming tools
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    /ctx/build/10-build.sh

###############################################################################
# FINALIZE
###############################################################################
RUN bootc container lint
