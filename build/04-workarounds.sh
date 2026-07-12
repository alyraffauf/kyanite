#!/usr/bin/env bash

set -eoux pipefail

###############################################################################
# System Workarounds
###############################################################################
# This script applies workarounds for known issues and compatibility fixes.
###############################################################################

echo "::group:: Apply System Workarounds"

# Fix /nix directory for Nix package manager compatibility on Fedora >=42
mkdir -p /nix
chown root:root /nix
chmod 755 /nix

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

# Set default/pinned applications on the taskmanager panel applet
# There is no standard API for this configuration
# Reference: https://bugs.kde.org/show_bug.cgi?id=511560
#sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:com.mitchellh.ghostty.desktop,applications:io.github.kolunmi.Bazaar.desktop,preferred:\/\/filemanager<\/default>/' \
#    /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml

# Configure Ghostty for KDE
sed -i 's@\[Desktop Action new-window\]@\[Desktop Action new-window\]\nX-KDE-Shortcuts=Ctrl+Alt+T@g' /usr/share/applications/com.mitchellh.ghostty.desktop
sed -i 's@Keywords=@Keywords=konsole;console;@g' /usr/share/applications/com.mitchellh.ghostty.desktop
cp /usr/share/applications/com.mitchellh.ghostty.desktop /usr/share/kglobalaccel/

# Configure Vicinae launcher for KDE (Super+Space to toggle)
sed -i 's@\[Desktop Action toggle\]@\[Desktop Action toggle\]\nX-KDE-Shortcuts=Meta+Space@g' /usr/share/applications/vicinae.desktop
cp /usr/share/applications/vicinae.desktop /usr/share/kglobalaccel/

# # Force Ptyxis version opened via dbus (e.g., keyboard shortcut) to use the proper shim
# # https://github.com/ublue-os/bazzite/pull/3620
# sed -i 's@Exec=/usr/bin/ptyxis@Exec=/usr/bin/kde-ptyxis@g' /usr/share/dbus-1/services/org.gnome.Ptyxis.service

# # Configure Ptyxis terminal for KDE integration
# sed -i 's@\[Desktop Action new-window\]@\[Desktop Action new-window\]\nX-KDE-Shortcuts=Ctrl+Alt+T@g' /usr/share/applications/org.gnome.Ptyxis.desktop
# sed -i 's@Exec=ptyxis@Exec=kde-ptyxis@g' /usr/share/applications/org.gnome.Ptyxis.desktop
# sed -i 's@Keywords=@Keywords=konsole;console;@g' /usr/share/applications/org.gnome.Ptyxis.desktop
# # GTK 4.20 changed input method handling
# # Reference: https://github.com/ghostty-org/ghostty/discussions/8899#discussioncomment-14717979
# desktop-file-edit --set-key=Exec --set-value='env GTK_IM_MODULE=ibus kde-ptyxis' /usr/share/applications/org.gnome.Ptyxis.desktop
# cp /usr/share/applications/org.gnome.Ptyxis.desktop /usr/share/kglobalaccel/

echo "::endgroup::"

echo "System workarounds applied successfully!"
