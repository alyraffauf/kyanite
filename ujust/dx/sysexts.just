# vim: set ft=make :
#######################
### sysexts.just
#######################

repo := "alyraffauf/kyanite"

# Install the ROCm sysext (downloads latest release and merges into /usr)
[group('Extensions')]
install-rocm-sysext:
    #!/usr/bin/env bash
    set -euo pipefail
    BASE="https://github.com/{{ repo }}/releases/download/sysext-rocm"
    TMP=$(mktemp -d)
    trap 'rm -rf "$TMP"' EXIT

    curl -fSL "$BASE/SHA256SUMS" -o "$TMP/SHA256SUMS"
    LATEST=$(awk '{print $2}' "$TMP/SHA256SUMS" | grep -E '\.raw$' | sort -V | tail -n1)
    echo "Fetching $LATEST"
    curl -fSL "$BASE/$LATEST" -o "$TMP/$LATEST"
    curl -fSL "$BASE/rocm.conf" -o "$TMP/rocm.conf"
    (cd "$TMP" && sha256sum -c --ignore-missing SHA256SUMS)

    sudo install -D -m 0644 "$TMP/$LATEST" /var/lib/extensions/rocm.raw
    sudo install -D -m 0644 "$TMP/rocm.conf" /etc/sysupdate.d/rocm.conf
    sudo systemd-sysext merge
    echo "ROCm sysext merged. Future updates: ujust update-rocm-sysext."

# Pull a newer ROCm sysext via systemd-sysupdate
[group('Extensions')]
update-rocm-sysext:
    sudo systemd-sysupdate --component=rocm update
    sudo systemd-sysext refresh

# Remove the ROCm sysext
[group('Extensions')]
remove-rocm-sysext:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo systemd-sysext unmerge || true
    sudo rm -f /var/lib/extensions/rocm.raw /etc/sysupdate.d/rocm.conf
    sudo systemd-sysext merge || true
    echo "ROCm sysext removed."
