# vim: set ft=make :
#######################
### sysexts.just
#######################

# Install a sysext (downloads transfer config, fetches latest version, merges into /usr)
[group('Extensions')]
install-sysext NAME:
    #!/usr/bin/env bash
    set -euo pipefail
    BASE="https://github.com/alyraffauf/kyanite-sysexts/releases/download/sysext-{{ NAME }}"
    TMP=$(mktemp -d)
    trap 'rm -rf "$TMP"' EXIT

    curl -fSL "$BASE/SHA256SUMS" -o "$TMP/SHA256SUMS"
    curl -fSL "$BASE/{{ NAME }}.transfer" -o "$TMP/{{ NAME }}.transfer"
    (cd "$TMP" && sha256sum -c --ignore-missing SHA256SUMS)

    sudo install -D -m 0644 "$TMP/{{ NAME }}.transfer" /etc/sysupdate.{{ NAME }}.d/{{ NAME }}.transfer
    sudo mkdir -p /var/lib/extensions
    sudo /usr/lib/systemd/systemd-sysupdate --component={{ NAME }} update
    sudo systemd-sysext refresh
    sudo udevadm control --reload && sudo udevadm trigger
    echo "{{ NAME }} sysext installed and merged."

# Pull a newer version of an installed sysext
[group('Extensions')]
update-sysext NAME:
    sudo /usr/lib/systemd/systemd-sysupdate --component={{ NAME }} update
    sudo systemd-sysext refresh
    sudo udevadm control --reload && sudo udevadm trigger

# Remove an installed sysext
[group('Extensions')]
remove-sysext NAME:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo rm -f /var/lib/extensions/{{ NAME }}.raw
    sudo rm -rf /etc/sysupdate.{{ NAME }}.d /var/lib/sysupdate/{{ NAME }}
    sudo systemd-sysext refresh
    sudo udevadm control --reload && sudo udevadm trigger
    echo "{{ NAME }} sysext removed."
