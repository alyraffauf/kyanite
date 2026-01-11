# vim: set ft=make :
#######################
### system.just
#######################

# Run a system benchmark (requires stress-ng from Homebrew)
[group('System')]
benchmark:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    if ! type -P "stress-ng" &>/dev/null ; then
        echo "stress-ng is not installed."
        if command -v brew &>/dev/null; then
            if gum confirm "Install stress-ng via Homebrew?" ; then
                brew install stress-ng
                brew link stress-ng
            else
                exit 0
            fi
        else
            echo "Please install stress-ng to run benchmarks."
            exit 1
        fi
    fi
    echo 'Running a 1 minute benchmark...'
    pushd $(mktemp -d) > /dev/null
    stress-ng --matrix 0 -t 1m --times
    popd > /dev/null

# Configure docker and libvirt groups for development
[group('System')]
configure-dev-groups:
    #!/usr/bin/pkexec bash
    CURRENT_USER="{{ `id -un` }}"
    echo "Adding $CURRENT_USER to docker and libvirt groups..."

    # Ensure groups exist in /etc/group
    for group in docker libvirt; do
        if ! grep -q "^$group:" /etc/group; then
            echo "Adding $group to /etc/group"
            grep "^$group:" /usr/lib/group | tee -a /etc/group > /dev/null
        fi
        usermod -aG $group $CURRENT_USER
    done

    echo "Groups configured. Log out and back in for changes to take effect."

# Example toggle command with user choice
[group('System')]
toggle-example-feature:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    echo "This is an example toggle command."
    echo "Current status: [check your status here]"
    OPTION=$(Choose "Enable" "Disable" "Cancel")
    case "$OPTION" in
        "Enable")
            echo "Enabling feature..."
            # Add your enable logic here
            ;;
        "Disable")
            echo "Disabling feature..."
            # Add your disable logic here
            ;;
        "Cancel")
            echo "No changes made."
            ;;
    esac

# Clean up container images and volumes
[group('Maintenance')]
clean-containers:
    #!/usr/bin/env bash
    echo "Cleaning up Podman containers, images, and volumes..."
    podman system prune -af
    podman volume prune -f
    if command -v docker &>/dev/null; then
        echo "Cleaning up Docker containers, images, and volumes..."
        docker system prune -af
        docker volume prune -f
    fi
    echo "Cleanup complete!"

# Update system and reboot if needed
[group('Maintenance')]
update-and-reboot:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    echo "Updating system..."
    sudo bootc upgrade
    OPTION=$(Choose "Reboot now" "Reboot later")
    case "$OPTION" in
        "Reboot now")
            systemctl reboot
            ;;
        "Reboot later")
            echo "Reboot later to apply updates."
            ;;
    esac

# Change the current user's shell
[group('System')]
change-shell:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    set -euo pipefail

    # Detect available shells in /usr/bin
    declare -a available_shells=()
    declare -a shell_paths=()

    # Check for common shells
    for shell in bash zsh fish dash ksh tcsh; do
        shell_path="/usr/bin/$shell"
        if [ -x "$shell_path" ]; then
            available_shells+=("$shell")
            shell_paths+=("$shell_path")
        fi
    done

    # Check if any shells were found
    if [ ${#available_shells[@]} -eq 0 ]; then
        echo "Error: No common shells found in /usr/bin"
        exit 1
    fi

    # Build shell options array for Choose
    available_shells+=("custom")
    CHOICE=$(Choose "${available_shells[@]}")

    if [ "$CHOICE" == "custom" ]; then
        read -p "Enter full path to shell executable: " SHELL_PATH
    else
        # Find the index of selected shell
        for i in "${!available_shells[@]}"; do
            if [ "${available_shells[$i]}" == "$CHOICE" ]; then
                SHELL_PATH="${shell_paths[$i]}"
                break
            fi
        done
    fi

    # Verify the shell exists
    if [ ! -x "$SHELL_PATH" ]; then
        echo "Error: Shell not found or not executable at $SHELL_PATH"
        echo "You may need to install it first."
        exit 1
    fi

    # Verify shell is in /etc/shells
    if ! grep -q "^${SHELL_PATH}$" /etc/shells 2>/dev/null; then
        echo "Warning: $SHELL_PATH is not listed in /etc/shells"
        RESPONSE=$(Choose "Add to /etc/shells" "Cancel")
        case "$RESPONSE" in
            "Add to /etc/shells")
                echo "$SHELL_PATH" | sudo tee -a /etc/shells > /dev/null
                ;;
            "Cancel")
                echo "Shell must be in /etc/shells to proceed. Exiting."
                exit 1
                ;;
        esac
    fi

    # Change the shell
    echo "Changing shell for user $USER to $SHELL_PATH"
    sudo usermod --shell "$SHELL_PATH" "$USER"

    echo ""
    echo "Shell changed successfully to $SHELL_PATH"
    echo "Please log out and log back in for changes to take effect."

# Rebase to a different Kyanite flavor
[group('System')]
rebase-helper:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh

    # Detect current flavor
    CURRENT_FLAVOR=$(grep '^IMAGE_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    echo "Current Kyanite flavor: $CURRENT_FLAVOR."

    # Define all flavors and images
    declare -A IMAGES=(
        ["kyanite"]="ghcr.io/alyraffauf/kyanite:stable"
        ["kyanite-dx"]="ghcr.io/alyraffauf/kyanite-dx:stable"
        ["kyanite-gaming"]="ghcr.io/alyraffauf/kyanite-gaming:stable"
        ["kyanite-dx-gaming"]="ghcr.io/alyraffauf/kyanite-dx-gaming:stable"
    )

    # Build choices, excluding current flavor
    CHOICES=()
    for flavor in "${!IMAGES[@]}"; do
        if [[ "$flavor" != "$CURRENT_FLAVOR" ]]; then
            CHOICES+=("$flavor")
        fi
    done
    CHOICES+=("Cancel")

    # Prompt user
    echo "Select the flavor you want to rebase to."
    FLAVOR=$(Choose "${CHOICES[@]}")
    if [[ "$FLAVOR" == "Cancel" ]]; then
        echo "No changes made."
        exit 0
    fi

    IMAGE="${IMAGES[$FLAVOR]}"
    echo "Rebasing to $FLAVOR..."
    sudo rpm-ostree rebase ostree-image-signed:docker://$IMAGE
    echo "Rebase complete! Please reboot to apply changes."
