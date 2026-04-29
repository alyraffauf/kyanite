# vim: set ft=make :
########################
### services.just
########################

# Enable the containerized Syncthing service. Reuses an existing
# ~/.local/state/syncthing/ config if present.
[group('Services')]
enable-syncthing:
    #!/usr/bin/env bash
    /usr/libexec/kyanite/syncthing-start
    echo "Syncthing running at http://127.0.0.1:8384"

# Stop the containerized Syncthing service and prevent autostart at next login
[group('Services')]
disable-syncthing:
    #!/usr/bin/env bash
    set -euo pipefail
    systemctl --user stop syncthing.service 2>/dev/null || true
    systemctl --user mask syncthing.service
    echo "Syncthing service stopped and masked."

# Enable the CPU/generic Ollama service (uses the official ollama:latest image)
[group('Services')]
enable-ollama:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "$HOME/.config/containers/systemd"
    cp -n /usr/share/kyanite/quadlets/ollama.container \
        "$HOME/.config/containers/systemd/ollama.container"
    systemctl --user daemon-reload
    systemctl --user unmask ollama.service 2>/dev/null || true
    systemctl --user start ollama.service
    echo "Ollama running at http://127.0.0.1:11434"

# Enable the AMD ROCm Ollama service (uses the official ollama:rocm image).
# Requires the user to be in the 'render' and 'video' groups — run
# `ujust configure-gpu-groups` first if you haven't already.
[group('Services')]
enable-ollama-rocm:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "$HOME/.config/containers/systemd"
    cp -n /usr/share/kyanite/quadlets/ollama-rocm.container \
        "$HOME/.config/containers/systemd/ollama-rocm.container"
    systemctl --user daemon-reload
    systemctl --user unmask ollama-rocm.service 2>/dev/null || true
    systemctl --user start ollama-rocm.service
    echo "Ollama (ROCm) running at http://127.0.0.1:11434"

# Enable the Vulkan Ollama service (uses the official ollama:latest image).
# Requires the user to be in the 'render' and 'video' groups — run
# `ujust configure-gpu-groups` first if you haven't already.
[group('Services')]
enable-ollama-vulkan:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "$HOME/.config/containers/systemd"
    cp -n /usr/share/kyanite/quadlets/ollama-vulkan.container \
        "$HOME/.config/containers/systemd/ollama-vulkan.container"
    systemctl --user daemon-reload
    systemctl --user unmask ollama-vulkan.service 2>/dev/null || true
    systemctl --user start ollama-vulkan.service
    echo "Ollama (Vulkan) running at http://127.0.0.1:11434"

# Stop any Ollama service and prevent autostart at next login
[group('Services')]
disable-ollama:
    #!/usr/bin/env bash
    set -euo pipefail
    for svc in ollama.service ollama-rocm.service ollama-vulkan.service; do
        systemctl --user stop "$svc" 2>/dev/null || true
        systemctl --user mask "$svc"
    done
    echo "Ollama services stopped and masked."
