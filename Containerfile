###############################################################################
# BUILD ARGUMENTS
###############################################################################
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kinoite}"
# Static value enables Renovate to detect and update the base image
ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/kinoite:44"
ARG BREW_IMAGE="ghcr.io/ublue-os/brew:latest"
# SHA pinning enables Renovate to automatically update dependencies
# See: https://docs.renovatebot.com/docker/#digest-pinning

# Base Image @ fedora-ostree-desktops/kinoite (upstream Fedora; ublue
# customizations replicated in build/02-fedora-packages.sh)
ARG BASE_IMAGE_SHA="sha256:97ae835223c2e7b340dd5a1f8e793f62c90243d7889fdd810911f08696187400"

# Brew Image
ARG BREW_IMAGE_SHA="sha256:9449d3ce4bec06b815dcf33bc5547cc76204317a59df01c511c63063679ec90a"

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
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-alyraffauf}"
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
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    /ctx/build/01-stage-brewfiles.sh

RUN --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    /ctx/build/02-fedora-packages.sh

RUN --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    /ctx/build/03-third-party-packages.sh

# 04-workarounds seds third-party .desktop files; must follow step 03.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build/04-workarounds.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    /ctx/build/05-copy-files.sh

# 06-systemd enables units that may be shipped by step 05; must follow it.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    /ctx/build/06-systemd.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build/07-homebrew.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    IMAGE_FLAVOR="${IMAGE_FLAVOR}" \
    IMAGE_NAME="${IMAGE_NAME}" \
    IMAGE_VENDOR="${IMAGE_VENDOR}" \
    BASE_IMAGE_NAME="${BASE_IMAGE_NAME}" \
    SHA_HEAD_SHORT="${SHA_HEAD_SHORT}" \
    UBLUE_IMAGE_TAG="${UBLUE_IMAGE_TAG}" \
    /ctx/build/08-branding.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build/09-cleanup.sh

###############################################################################
# FINALIZE
###############################################################################
RUN bootc container lint
