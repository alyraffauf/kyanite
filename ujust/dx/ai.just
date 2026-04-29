# vim: set ft=make :
####################
### ai.just
####################

# Enable the CPU/generic Ollama service (uses the official ollama:latest image)
[group('AI')]
enable-ollama:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "$HOME/.config/containers/systemd"
    cp -n /etc/skel/.config/containers/systemd/ollama.container \
        "$HOME/.config/containers/systemd/ollama.container"
    systemctl --user daemon-reload
    systemctl --user start ollama.service
    echo "Ollama running at http://127.0.0.1:11434"

# Enable the AMD ROCm Ollama service (uses the official ollama:rocm image).
# Requires the user to be in the 'render' and 'video' groups — run
# `ujust configure-dev-groups` first if you haven't already.
[group('AI')]
enable-ollama-rocm:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "$HOME/.config/containers/systemd"
    cp -n /etc/skel/.config/containers/systemd/ollama-rocm.container \
        "$HOME/.config/containers/systemd/ollama-rocm.container"
    systemctl --user daemon-reload
    systemctl --user start ollama-rocm.service
    echo "Ollama (ROCm) running at http://127.0.0.1:11434"

# Enable the Vulkan Ollama service (uses the official ollama:latest image).
# Requires the user to be in the 'render' and 'video' groups — run
# `ujust configure-dev-groups` first if you haven't already.
[group('AI')]
enable-ollama-vulkan:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "$HOME/.config/containers/systemd"
    cp -n /etc/skel/.config/containers/systemd/ollama-vulkan.container \
        "$HOME/.config/containers/systemd/ollama-vulkan.container"
    systemctl --user daemon-reload
    systemctl --user start ollama-vulkan.service
    echo "Ollama (Vulkan) running at http://127.0.0.1:11434"

# Stop and disable any running Ollama service
[group('AI')]
disable-ollama:
    #!/usr/bin/env bash
    set -euo pipefail
    systemctl --user stop ollama.service ollama-rocm.service ollama-vulkan.service 2>/dev/null || true
    echo "Ollama services stopped."
