# vim: set ft=make :
#######################
### sysexts.just
#######################

repo := "alyraffauf/kyanite"

# Install the ROCm sysext (registers transfer config, fetches latest, merges)
[group('Extensions')]
install-rocm-sysext:
    #!/usr/bin/env bash
    set -euo pipefail
    BASE="https://github.com/{{ repo }}/releases/download/sysext-rocm"
    TMP=$(mktemp -d)
    trap 'rm -rf "$TMP"' EXIT

    curl -fSL "$BASE/SHA256SUMS" -o "$TMP/SHA256SUMS"
    curl -fSL "$BASE/rocm.transfer" -o "$TMP/rocm.transfer"
    (cd "$TMP" && sha256sum -c --ignore-missing SHA256SUMS)

    sudo install -D -m 0644 "$TMP/rocm.transfer" /etc/sysupdate.rocm.d/rocm.transfer
    sudo mkdir -p /var/lib/extensions
    sudo /usr/lib/systemd/systemd-sysupdate --component=rocm update
    sudo systemd-sysext merge
    echo "ROCm sysext installed and merged."

# Pull a newer ROCm sysext via systemd-sysupdate
[group('Extensions')]
update-rocm-sysext:
    sudo /usr/lib/systemd/systemd-sysupdate --component=rocm update
    sudo systemd-sysext refresh

# Remove the ROCm sysext
[group('Extensions')]
remove-rocm-sysext:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo systemd-sysext unmerge || true
    sudo rm -f /var/lib/extensions/rocm.raw
    sudo rm -rf /etc/sysupdate.rocm.d /var/lib/sysupdate/rocm
    sudo systemd-sysext merge || true
    echo "ROCm sysext removed."
