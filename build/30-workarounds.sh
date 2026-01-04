#!/usr/bin/env bash

set -eoux pipefail

# wonky patch for nix on fedora >=42
mkdir -p /nix
chown root:root /nix
chmod 755 /nix

# sets default/pinned applications on the taskmanager applet on the panel, there is no nice way to do this
# https://bugs.kde.org/show_bug.cgi?id=511560
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,applications:org.gnome.Ptyxis.desktop,applications:io.github.kolunmi.Bazaar.desktop,preferred:\/\/filemanager<\/default>/' \
  /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml

# Force Ptyxis version opened via dbus (e.g., keyboard shortcut) to use the proper shim
# https://github.com/ublue-os/bazzite/pull/3620
sed -i 's@Exec=/usr/bin/ptyxis@Exec=/usr/bin/kde-ptyxis@g' /usr/share/dbus-1/services/org.gnome.Ptyxis.service

# Ptyxis Terminal
sed -i 's@\[Desktop Action new-window\]@\[Desktop Action new-window\]\nX-KDE-Shortcuts=Ctrl+Alt+T@g' /usr/share/applications/org.gnome.Ptyxis.desktop
sed -i 's@Exec=ptyxis@Exec=kde-ptyxis@g' /usr/share/applications/org.gnome.Ptyxis.desktop
sed -i 's@Keywords=@Keywords=konsole;console;@g' /usr/share/applications/org.gnome.Ptyxis.desktop
# GTK 4.20 changed how it handles input methods; see https://github.com/ghostty-org/ghostty/discussions/8899#discussioncomment-14717979
desktop-file-edit --set-key=Exec --set-value='env GTK_IM_MODULE=ibus kde-ptyxis' /usr/share/applications/org.gnome.Ptyxis.desktop
cp /usr/share/applications/org.gnome.Ptyxis.desktop /usr/share/kglobalaccel/
