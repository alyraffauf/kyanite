# vim: set ft=make :
#######################
### system.just
#######################

# Rebase to a different Kyanite variant
[group('System')]
rebase-helper:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh

    # Detect current variant
    CURRENT_VARIANT=$(grep '^IMAGE_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    echo "Current Kyanite variant: $CURRENT_VARIANT."

    # Define all variants and images
    declare -A IMAGES=(
        ["kyanite"]="ghcr.io/alyraffauf/kyanite:stable"
    )

    # Build choices, excluding current variant
    CHOICES=()
    for variant in "${!IMAGES[@]}"; do
        if [[ "$variant" != "$CURRENT_VARIANT" ]]; then
            CHOICES+=("$variant")
        fi
    done
    CHOICES+=("Cancel")

    # Prompt user
    echo "Select the variant you want to rebase to."
    VARIANT=$(Choose "${CHOICES[@]}")
    if [[ "$VARIANT" == "Cancel" ]]; then
        echo "No changes made."
        exit 0
    fi

    IMAGE="${IMAGES[$VARIANT]}"
    echo "Rebasing to $VARIANT..."
    sudo rpm-ostree rebase ostree-image-signed:docker://$IMAGE
    echo "Rebase complete! Please reboot to apply changes."
