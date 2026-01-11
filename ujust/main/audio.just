# vim: set ft=make :
#######################
### audio.just
#######################

# Internal helper to toggle laptop DSP configurations
_toggle_laptop_dsp DEVICE_NAME PROFILE_DIR FILTER_FILE CONF_FILE DEFAULT_DEVICE:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    set -euo pipefail

    SOURCE_DIR="/usr/share/alyraffauf/pipewire-dsps/{{ PROFILE_DIR }}"
    FILTER_FILE="{{ FILTER_FILE }}"
    CONF_FILE="{{ CONF_FILE }}"
    DEVICE_NAME="{{ DEVICE_NAME }}"
    DEFAULT_DEVICE="{{ DEFAULT_DEVICE }}"

    # Check current status
    if [ -f "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}" ] && [ -f "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}" ]; then
        echo "Current status: Enabled"
        OPTION=$(Choose "Disable" "Cancel")
    else
        echo "Current status: Disabled"
        OPTION=$(Choose "Enable" "Cancel")
    fi

    case "$OPTION" in
        "Disable")
            echo "Removing ${DEVICE_NAME} Audio DSP configuration..."
            sudo rm -f "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}"
            sudo rm -f "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
            echo ""
            echo "Restarting audio services..."
            systemctl --user restart pipewire pipewire-pulse wireplumber
            echo ""
            echo "DSP has been disabled."
            ;;
        "Enable")
            # Verify source files exist
            if [ ! -f "${SOURCE_DIR}/${FILTER_FILE}" ]; then
                echo "Error: Filter chain file not found at ${SOURCE_DIR}/${FILTER_FILE}"
                exit 1
            fi

            if [ ! -f "${SOURCE_DIR}/${CONF_FILE}" ]; then
                echo "Error: Config file not found at ${SOURCE_DIR}/${CONF_FILE}"
                exit 1
            fi

            echo "Before proceeding, please:"
            echo "1. Set your speaker volume to 100% (the DSP will handle volume control)"
            echo "2. Have your audio device name ready (run: pw-dump | grep -C 5 Speaker)"
            echo ""

            # Try to detect the actual speaker device name
            DETECTED_DEVICE=$(pw-dump 2>/dev/null | grep -o 'alsa_output\.pci-[^"]*Speaker[^"]*' | head -n1 || echo "")

            if [ -n "$DETECTED_DEVICE" ]; then
                echo "Detected speaker device: $DETECTED_DEVICE"
                FALLBACK_DEVICE="$DETECTED_DEVICE"
            else
                echo "Could not auto-detect speaker device"
                FALLBACK_DEVICE="${DEFAULT_DEVICE}"
            fi

            echo "Default device: $FALLBACK_DEVICE"
            echo ""
            read -r -p "Enter device name (or press Enter to use default): " USER_DEVICE
            AUDIO_DEVICE="${USER_DEVICE:-$FALLBACK_DEVICE}"

            echo ""
            read -p "Hide the raw speaker device? (Y/n): " -n 1 -r HIDE_RAW
            echo ""
            if [[ $HIDE_RAW =~ ^[Nn]$ ]]; then
                HIDE_PARENT="false"
            else
                HIDE_PARENT="true"
            fi

            echo ""
            echo "Installing DSP configuration..."
            sudo mkdir -p /etc/wireplumber/wireplumber.conf.d

            sudo cp "${SOURCE_DIR}/${FILTER_FILE}" "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}"
            sudo sed -i "s|@DEVICE_NAME@|${AUDIO_DEVICE}|g" "/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}"

            sudo cp "${SOURCE_DIR}/${CONF_FILE}" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
            sudo sed -i "s|@DEVICE_NAME@|${AUDIO_DEVICE}|g" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
            sudo sed -i "s|@FILTER_PATH@|/etc/wireplumber/wireplumber.conf.d/${FILTER_FILE}|g" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"
            sudo sed -i "s|@HIDE_PARENT@|${HIDE_PARENT}|g" "/etc/wireplumber/wireplumber.conf.d/${CONF_FILE}"

            echo ""
            echo "Restarting audio services..."
            systemctl --user restart pipewire pipewire-pulse wireplumber

            echo ""
            echo "DSP has been enabled for device: ${AUDIO_DEVICE}"
            echo ""
            echo "Next steps:"
            echo "- Select the enhanced speakers as your default output device if needed"
            echo "- If you experience issues, check: journalctl --user -u wireplumber -f"
            ;;
        "Cancel")
            echo "No changes made."
            ;;
    esac

# Toggle PipeWire DSP for HP OmniBook Ultra (FH0xxx)
[group('Audio')]
toggle-dsp-omnibook-fh0xxx:
    @just --justfile {{justfile()}} _toggle_laptop_dsp "HP OmniBook Ultra (FH0xxx)" "omnibook-fh0xxx" "omnibook-fh0xxx-filter-chain.json" "99-omnibook.conf" "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"

# Toggle PipeWire DSP for ThinkPad X1 Carbon Gen 7
[group('Audio')]
toggle-dsp-thinkpad-x1-gen7:
    @just --justfile {{justfile()}} _toggle_laptop_dsp "ThinkPad X1 Carbon Gen 7" "thinkpad-x1-gen7" "x1c-gen7-filter-chain.json" "99-x1c.conf" "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"

# Toggle PipeWire DSP for ThinkPad X1 Carbon Gen 9
[group('Audio')]
toggle-dsp-thinkpad-x1-gen9:
    @just --justfile {{justfile()}} _toggle_laptop_dsp "ThinkPad X1 Carbon Gen 9" "thinkpad-x1-gen9" "x1c-gen9-filter-chain.json" "99-x1c.conf" "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"
