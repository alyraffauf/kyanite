# vim: set ft=make :
#######################
### custom-audio.just
#######################

# Toggle PipeWire DSP for HP OmniBook Ultra (FH0xxx)
[group('Audio')]
toggle-dsp-omnibook-fh0xxx:
    #!/usr/bin/env bash
    set -euo pipefail

    FILTER_FILE="omnibook-fh0xxx-filter-chain.json"
    CONF_FILE="99-omnibook.conf"
    PROFILE_DIR="omnibook-fh0xxx"
    DEVICE_NAME="HP OmniBook Ultra (FH0xxx)"
    SOURCE_DIR="/usr/share/alyraffauf/pipewire-dsps/${PROFILE_DIR}"

    # Check if already installed
    if [ -f "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}" ] && [ -f "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}" ]; then
        echo "=== Removing ${DEVICE_NAME} Audio DSP ==="
        echo ""
        sudo rm -f "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}"
        sudo rm -f "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
        echo "✓ Removed DSP configuration files"
        echo ""
        echo "Restarting PipeWire and WirePlumber..."
        systemctl --user restart pipewire pipewire-pulse wireplumber
        echo ""
        echo "✓ ${DEVICE_NAME} DSP has been removed"
    else
        echo "=== Installing ${DEVICE_NAME} Audio DSP ==="
        echo ""

        # Verify source files exist
        if [ ! -f "${SOURCE_DIR}/${FILTER_FILE}" ]; then
            echo "Error: Filter chain file not found at ${SOURCE_DIR}/${FILTER_FILE}"
            exit 1
        fi

        if [ ! -f "${SOURCE_DIR}/${CONF_FILE}" ]; then
            echo "Error: Config file not found at ${SOURCE_DIR}/${CONF_FILE}"
            exit 1
        fi

        echo "Step 1: Detecting your audio device..."
        echo ""

        # Try to detect the actual speaker device name
        DETECTED_DEVICE=$(pw-dump 2>/dev/null | grep -o 'alsa_output\.pci-[^"]*Speaker[^"]*' | head -n1 || echo "")

        if [ -n "$DETECTED_DEVICE" ]; then
            echo "✓ Detected speaker device: $DETECTED_DEVICE"
            DEFAULT_DEVICE="$DETECTED_DEVICE"
        else
            echo "⚠ Could not auto-detect speaker device"
            DEFAULT_DEVICE="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"
        fi

        echo ""
        echo "Please verify your speaker device name."
        echo "You can find it by running: pw-dump | grep -C 5 Speaker"
        echo ""
        read -r -p "Enter device name (or press Enter for '$DEFAULT_DEVICE'): " USER_DEVICE
        AUDIO_DEVICE="${USER_DEVICE:-$DEFAULT_DEVICE}"

        echo ""
        echo "⚠️  IMPORTANT: Set your speakers to 100% volume before proceeding!"
        echo "The DSP filter chain will handle volume control after installation."
        echo ""
        read -p "Have you set speakers to 100% volume? (y/N): " -n 1 -r VOLUME_CONFIRM
        echo ""
        if ! [[ $VOLUME_CONFIRM =~ ^[Yy]$ ]]; then
            echo "Installation cancelled. Please set volume to 100% and run this command again."
            exit 1
        fi

        echo ""
        read -p "Hide the raw speaker device? (Y/n): " -n 1 -r HIDE_RAW
        echo ""
        if [[ $HIDE_RAW =~ ^[Nn]$ ]]; then
            HIDE_PARENT="false"
        else
            HIDE_PARENT="true"
        fi

        echo ""
        echo "Step 2: Creating system configuration directory..."
        sudo mkdir -p /etc/wireplumber/wireplumber.conf.d

        echo ""
        echo "Step 3: Installing ${FILTER_FILE}..."
        sudo cp "${SOURCE_DIR}/${FILTER_FILE}" "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}"

        # Substitute placeholders in filter-chain.json
        sudo sed -i "s|@DEVICE_NAME@|${AUDIO_DEVICE}|g" "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}"
        echo "✓ Installed ${FILTER_FILE} with device: ${AUDIO_DEVICE}"

        echo ""
        echo "Step 4: Installing WirePlumber configuration..."
        sudo cp "${SOURCE_DIR}/${CONF_FILE}" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"

        # Substitute placeholders in WirePlumber config
        sudo sed -i "s|@DEVICE_NAME@|${AUDIO_DEVICE}|g" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
        sudo sed -i "s|@FILTER_PATH@|/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}|g" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
        sudo sed -i "s|@HIDE_PARENT@|${HIDE_PARENT}|g" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
        echo "✓ Installed ${CONF_FILE} with device: ${AUDIO_DEVICE} (hide-parent: ${HIDE_PARENT})"

        echo ""
        echo "Step 5: Restarting PipeWire and WirePlumber..."
        systemctl --user restart pipewire pipewire-pulse wireplumber

        echo ""
        echo "=== Installation Complete! ==="
        echo ""
        echo "Important notes:"
        echo "1. Your speakers should be set to 100% volume (filter chain controls volume)"
        echo "2. You may need to select the enhanced speakers as your default output device"
        echo "3. Raw speaker device hidden: ${HIDE_PARENT}"
        echo "4. If you experience issues, check: journalctl --user -u wireplumber -f"
        echo ""
        echo "To remove this DSP configuration, run this command again."
        echo ""
    fi

# Toggle PipeWire DSP for ThinkPad X1 Carbon Gen 7
[group('Audio')]
toggle-dsp-thinkpad-x1-gen7:
    #!/usr/bin/env bash
    set -euo pipefail

    FILTER_FILE="x1c-gen7-filter-chain.json"
    CONF_FILE="99-x1c.conf"
    PROFILE_DIR="thinkpad-x1-gen7"
    DEVICE_NAME="ThinkPad X1 Carbon Gen 7"
    SOURCE_DIR="/usr/share/alyraffauf/pipewire-dsps/${PROFILE_DIR}"

    # Check if already installed
    if [ -f "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}" ] && [ -f "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}" ]; then
        echo "=== Removing ${DEVICE_NAME} Audio DSP ==="
        echo ""
        sudo rm -f "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}"
        sudo rm -f "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
        echo "✓ Removed DSP configuration files"
        echo ""
        echo "Restarting PipeWire and WirePlumber..."
        systemctl --user restart pipewire pipewire-pulse wireplumber
        echo ""
        echo "✓ ${DEVICE_NAME} DSP has been removed"
    else
        echo "=== Installing ${DEVICE_NAME} Audio DSP ==="
        echo ""

        # Verify source files exist
        if [ ! -f "${SOURCE_DIR}/${FILTER_FILE}" ]; then
            echo "Error: Filter chain file not found at ${SOURCE_DIR}/${FILTER_FILE}"
            exit 1
        fi

        if [ ! -f "${SOURCE_DIR}/${CONF_FILE}" ]; then
            echo "Error: Config file not found at ${SOURCE_DIR}/${CONF_FILE}"
            exit 1
        fi

        echo "Step 1: Detecting your audio device..."
        echo ""

        # Try to detect the actual speaker device name
        DETECTED_DEVICE=$(pw-dump 2>/dev/null | grep -o 'alsa_output\.pci-[^"]*Speaker[^"]*' | head -n1 || echo "")

        if [ -n "$DETECTED_DEVICE" ]; then
            echo "✓ Detected speaker device: $DETECTED_DEVICE"
            DEFAULT_DEVICE="$DETECTED_DEVICE"
        else
            echo "⚠ Could not auto-detect speaker device"
            DEFAULT_DEVICE="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"
        fi

        echo ""
        echo "Please verify your speaker device name."
        echo "You can find it by running: pw-dump | grep -C 5 Speaker"
        echo ""
        read -r -p "Enter device name (or press Enter for '$DEFAULT_DEVICE'): " USER_DEVICE
        AUDIO_DEVICE="${USER_DEVICE:-$DEFAULT_DEVICE}"

        echo ""
        echo "⚠️  IMPORTANT: Set your speakers to 100% volume before proceeding!"
        echo "The DSP filter chain will handle volume control after installation."
        echo ""
        read -p "Have you set speakers to 100% volume? (y/N): " -n 1 -r VOLUME_CONFIRM
        echo ""
        if ! [[ $VOLUME_CONFIRM =~ ^[Yy]$ ]]; then
            echo "Installation cancelled. Please set volume to 100% and run this command again."
            exit 1
        fi

        echo ""
        read -p "Hide the raw speaker device? (Y/n): " -n 1 -r HIDE_RAW
        echo ""
        if [[ $HIDE_RAW =~ ^[Nn]$ ]]; then
            HIDE_PARENT="false"
        else
            HIDE_PARENT="true"
        fi

        echo ""
        echo "Step 2: Creating system configuration directory..."
        sudo mkdir -p /etc/wireplumber/wireplumber.conf.d

        echo ""
        echo "Step 3: Installing ${FILTER_FILE}..."
        sudo cp "${SOURCE_DIR}/${FILTER_FILE}" "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}"

        # Substitute placeholders in filter-chain.json
        sudo sed -i "s|@DEVICE_NAME@|${AUDIO_DEVICE}|g" "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}"
        echo "✓ Installed ${FILTER_FILE} with device: ${AUDIO_DEVICE}"

        echo ""
        echo "Step 4: Installing WirePlumber configuration..."
        sudo cp "${SOURCE_DIR}/${CONF_FILE}" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"

        # Substitute placeholders in WirePlumber config
        sudo sed -i "s|@DEVICE_NAME@|${AUDIO_DEVICE}|g" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
        sudo sed -i "s|@FILTER_PATH@|/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}|g" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
        sudo sed -i "s|@HIDE_PARENT@|${HIDE_PARENT}|g" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
        echo "✓ Installed ${CONF_FILE} with device: ${AUDIO_DEVICE} (hide-parent: ${HIDE_PARENT})"

        echo ""
        echo "Step 5: Restarting PipeWire and WirePlumber..."
        systemctl --user restart pipewire pipewire-pulse wireplumber

        echo ""
        echo "=== Installation Complete! ==="
        echo ""
        echo "Important notes:"
        echo "1. Your speakers should be set to 100% volume (filter chain controls volume)"
        echo "2. You may need to select the enhanced speakers as your default output device"
        echo "3. Raw speaker device hidden: ${HIDE_PARENT}"
        echo "4. If you experience issues, check: journalctl --user -u wireplumber -f"
        echo ""
        echo "To remove this DSP configuration, run this command again."
        echo ""
    fi

# Toggle PipeWire DSP for ThinkPad X1 Carbon Gen 9
[group('Audio')]
toggle-dsp-thinkpad-x1-gen9:
    #!/usr/bin/env bash
    set -euo pipefail

    FILTER_FILE="x1c-gen9-filter-chain.json"
    CONF_FILE="99-x1c.conf"
    PROFILE_DIR="thinkpad-x1-gen9"
    DEVICE_NAME="ThinkPad X1 Carbon Gen 9"
    SOURCE_DIR="/usr/share/alyraffauf/pipewire-dsps/${PROFILE_DIR}"

    # Check if already installed
    if [ -f "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}" ] && [ -f "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}" ]; then
        echo "=== Removing ${DEVICE_NAME} Audio DSP ==="
        echo ""
        sudo rm -f "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}"
        sudo rm -f "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
        echo "✓ Removed DSP configuration files"
        echo ""
        echo "Restarting PipeWire and WirePlumber..."
        systemctl --user restart pipewire pipewire-pulse wireplumber
        echo ""
        echo "✓ ${DEVICE_NAME} DSP has been removed"
    else
        echo "=== Installing ${DEVICE_NAME} Audio DSP ==="
        echo ""

        # Verify source files exist
        if [ ! -f "${SOURCE_DIR}/${FILTER_FILE}" ]; then
            echo "Error: Filter chain file not found at ${SOURCE_DIR}/${FILTER_FILE}"
            exit 1
        fi

        if [ ! -f "${SOURCE_DIR}/${CONF_FILE}" ]; then
            echo "Error: Config file not found at ${SOURCE_DIR}/${CONF_FILE}"
            exit 1
        fi

        echo "Step 1: Detecting your audio device..."
        echo ""

        # Try to detect the actual speaker device name
        DETECTED_DEVICE=$(pw-dump 2>/dev/null | grep -o 'alsa_output\.pci-[^"]*Speaker[^"]*' | head -n1 || echo "")

        if [ -n "$DETECTED_DEVICE" ]; then
            echo "✓ Detected speaker device: $DETECTED_DEVICE"
            DEFAULT_DEVICE="$DETECTED_DEVICE"
        else
            echo "⚠ Could not auto-detect speaker device"
            DEFAULT_DEVICE="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"
        fi

        echo ""
        echo "Please verify your speaker device name."
        echo "You can find it by running: pw-dump | grep -C 5 Speaker"
        echo ""
        read -r -p "Enter device name (or press Enter for '$DEFAULT_DEVICE'): " USER_DEVICE
        AUDIO_DEVICE="${USER_DEVICE:-$DEFAULT_DEVICE}"

        echo ""
        echo "⚠️  IMPORTANT: Set your speakers to 100% volume before proceeding!"
        echo "The DSP filter chain will handle volume control after installation."
        echo ""
        read -p "Have you set speakers to 100% volume? (y/N): " -n 1 -r VOLUME_CONFIRM
        echo ""
        if ! [[ $VOLUME_CONFIRM =~ ^[Yy]$ ]]; then
            echo "Installation cancelled. Please set volume to 100% and run this command again."
            exit 1
        fi

        echo ""
        read -p "Hide the raw speaker device? (Y/n): " -n 1 -r HIDE_RAW
        echo ""
        if [[ $HIDE_RAW =~ ^[Nn]$ ]]; then
            HIDE_PARENT="false"
        else
            HIDE_PARENT="true"
        fi

        echo ""
        echo "Step 2: Creating system configuration directory..."
        sudo mkdir -p /etc/wireplumber/wireplumber.conf.d

        echo ""
        echo "Step 3: Installing ${FILTER_FILE}..."
        sudo cp "${SOURCE_DIR}/${FILTER_FILE}" "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}"

        # Substitute placeholders in filter-chain.json
        sudo sed -i "s|@DEVICE_NAME@|${AUDIO_DEVICE}|g" "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}"
        echo "✓ Installed ${FILTER_FILE} with device: ${AUDIO_DEVICE}"

        echo ""
        echo "Step 4: Installing WirePlumber configuration..."
        sudo cp "${SOURCE_DIR}/${CONF_FILE}" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"

        # Substitute placeholders in WirePlumber config
        sudo sed -i "s|@DEVICE_NAME@|${AUDIO_DEVICE}|g" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
        sudo sed -i "s|@FILTER_PATH@|/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}|g" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
        sudo sed -i "s|@HIDE_PARENT@|${HIDE_PARENT}|g" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
        echo "✓ Installed ${CONF_FILE} with device: ${AUDIO_DEVICE} (hide-parent: ${HIDE_PARENT})"

        echo ""
        echo "Step 5: Restarting PipeWire and WirePlumber..."
        systemctl --user restart pipewire pipewire-pulse wireplumber

        echo ""
        echo "=== Installation Complete! ==="
        echo ""
        echo "Important notes:"
        echo "1. Your speakers should be set to 100% volume (filter chain controls volume)"
        echo "2. You may need to select the enhanced speakers as your default output device"
        echo "3. Raw speaker device hidden: ${HIDE_PARENT}"
        echo "4. If you experience issues, check: journalctl --user -u wireplumber -f"
        echo ""
        echo "To remove this DSP configuration, run this command again."
        echo ""
    fi
