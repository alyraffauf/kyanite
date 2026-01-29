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

ARG BASE_IMAGE_SHA="sha256:c66424345f89d5c5d54aafa9241271716f1ef6aced6b36595b41926767e5542c"
ARG BREW_IMAGE_SHA="sha256:9021d14310509308f3cb8cc7cab98e5868212b2a744e044e998798d2eec26722"

###############################################################################
# IMPORT STAGES
###############################################################################
FROM ${BREW_IMAGE}@${BREW_IMAGE_SHA} AS brew

FROM scratch AS ctx
COPY /build /build
COPY /files /files
COPY /brew /brew
COPY /flatpaks /flatpaks
COPY /ujust /ujust
COPY /packages.json /packages.json
COPY /services.json /services.json

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

# Step 1: Copy files and configure base system
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    /ctx/build/01-build.sh

# Step 2: Install Fedora packages
RUN --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build/02-fedora-packages.sh

# Step 3: Install third-party packages
RUN --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    /ctx/build/03-third-party-packages.sh

# Step 4: Apply system workarounds
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build/04-workarounds.sh

# Step 5: Configure systemd services
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build/05-systemd.sh

# Step 6: Configure Homebrew
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build/06-homebrew.sh

# Step 7: Apply OS branding
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    IMAGE_NAME="${IMAGE_NAME}" \
    IMAGE_VENDOR="${IMAGE_VENDOR}" \
    BASE_IMAGE_NAME="${BASE_IMAGE_NAME}" \
    SHA_HEAD_SHORT="${SHA_HEAD_SHORT}" \
    UBLUE_IMAGE_TAG="${UBLUE_IMAGE_TAG}" \
    /ctx/build/07-branding.sh

# Step 8: Final cleanup
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build/08-cleanup.sh

###############################################################################
# FINALIZE
###############################################################################
RUN bootc container lint
