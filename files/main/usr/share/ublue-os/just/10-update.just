# vim: set ft=make :

alias upgrade := update

# Update system, flatpaks, and containers all at once
update:
    #!/usr/bin/bash
    echo "Updating system (rpm-ostree)..."
    sudo rpm-ostree update
    echo "Updating flatpaks..."
    flatpak update -y
    echo "Updating distrobox containers..."
    distrobox upgrade --all 2>/dev/null || true
    echo "Update complete."

alias changelog := changelogs

# Show the changelog
changelogs:
    #!/usr/bin/bash
    rpm-ostree db diff --changelogs 2>/dev/null || \
        echo "Changelog not available."

# Update device firmware
[no-exit-message]
update-firmware:
    fwupdmgr refresh --force
    fwupdmgr get-updates
    fwupdmgr update

alias auto-update := toggle-updates

# Turn automatic updates on or off
toggle-updates:
    #!/usr/bin/bash
    if systemctl -q is-enabled rpm-ostreed-automatic.timer 2>/dev/null; then
        CURRENT_STATE="Enabled"
    else
        CURRENT_STATE="Disabled"
    fi
    echo "Automatic updates are currently: ${CURRENT_STATE}"
    echo "Enable or Disable automatic updates?"
    OPTION=$(gum choose Enable Disable)
    if [ "${OPTION}" == "Enable" ]; then
        sudo systemctl enable --now rpm-ostreed-automatic.timer
        echo "Automatic updates enabled."
    elif [ "${OPTION}" == "Disable" ]; then
        sudo systemctl disable --now rpm-ostreed-automatic.timer
        echo "Automatic updates disabled."
    fi
