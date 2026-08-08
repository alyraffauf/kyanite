#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# System Workarounds
###############################################################################
# This script applies workarounds for known issues and compatibility fixes.
###############################################################################

echo "::group:: Apply System Workarounds"

# systemd-sysupdate's state dirs need the systemd_importd_var_run_t label
# so the systemd-pull helper (running as systemd_importd_t) can write the
# downloaded temp files. Without an explicit rule the dirs can inherit
# something restrictive (e.g. container_var_lib_t) from earlier deployments.
semanage fcontext -a -t systemd_importd_var_run_t '/var/lib/sysupdate(/.*)?' || true
semanage fcontext -a -t systemd_importd_var_run_t '/var/lib/extensions(/.*)?' || true

# The parent systemd-sysupdate process runs as init_t (Fedora's policy has
# no domain transition for it) and needs to atomically rename the temp file
# into place and swap the symlink in /var/lib/extensions. init_t lacks those
# permissions on systemd_importd_var_run_t by default — grant them via a
# small policy module.
semodule -i /ctx/build/kyanite-sysupdate.cil

# Mask systemd-remount-fs.service: it runs `mount -o remount /`, which fails
# on bootc/composefs roots ("overlay: No changes allowed in reconfigure").
# There's nothing to remount on a read-only ostree root anyway. ublue-os/main
# masks this in their base; we replicate that now that we're on upstream.
systemctl mask systemd-remount-fs.service

# Configure Vicinae launcher for KDE (Super+Space to toggle)
# sed -i 's@\[Desktop Action toggle\]@\[Desktop Action toggle\]\nX-KDE-Shortcuts=Meta+Space@g' /usr/share/applications/vicinae.desktop
# cp /usr/share/applications/vicinae.desktop /usr/share/kglobalaccel/

echo "::endgroup::"

echo "System workarounds applied successfully!"
