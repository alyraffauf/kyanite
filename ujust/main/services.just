# vim: set ft=make :
########################
### services.just
########################

# Remove the legacy containerized Syncthing Quadlet (transition helper).
# Use the syncthing sysext instead: `ujust install-sysext syncthing`.
[group('Services')]
remove-syncthing-quadlet:
    #!/usr/bin/env bash
    set -euo pipefail
    systemctl --user stop syncthing.service 2>/dev/null || true
    rm -f "$HOME/.config/containers/systemd/syncthing.container"
    systemctl --user daemon-reload
    echo "Syncthing Quadlet removed. To run native syncthing, install the sysext:"
    echo "  ujust install-sysext syncthing"
    echo "  systemctl --user enable --now syncthing.service"

# Enable the CPU/generic Ollama service (uses the official ollama:latest image)
[group('Services')]
enable-ollama:
    #!/usr/bin/env bash
    set -euo pipefail
    podman network exists ai 2>/dev/null || podman network create ai
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
    podman network exists ai 2>/dev/null || podman network create ai
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
    podman network exists ai 2>/dev/null || podman network create ai
    mkdir -p "$HOME/.config/containers/systemd"
    cp -n /usr/share/kyanite/quadlets/ollama-vulkan.container \
        "$HOME/.config/containers/systemd/ollama-vulkan.container"
    systemctl --user daemon-reload
    systemctl --user unmask ollama-vulkan.service 2>/dev/null || true
    systemctl --user start ollama-vulkan.service
    echo "Ollama (Vulkan) running at http://127.0.0.1:11434"

# Enable the containerized Open WebUI service. Creates the shared 'ai' podman
# network (if missing) so Open WebUI can reach Ollama by hostname, copies the
# launcher into ~/.local/share/applications/ for the KDE menu, and starts the UI.
[group('Services')]
enable-open-webui:
    #!/usr/bin/env bash
    set -euo pipefail
    podman network exists ai 2>/dev/null || podman network create ai
    /usr/libexec/kyanite/open-webui-start &
    mkdir -p "$HOME/.local/share/applications"
    cp -f /usr/share/kyanite/launchers/open-webui.desktop \
        "$HOME/.local/share/applications/open-webui.desktop"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    echo "Open WebUI enabled. Will be reachable at http://127.0.0.1:8080 once started."

# Stop the containerized Open WebUI service, prevent autostart, and remove the launcher
[group('Services')]
disable-open-webui:
    #!/usr/bin/env bash
    set -euo pipefail
    systemctl --user stop open-webui.service 2>/dev/null || true
    systemctl --user mask open-webui.service 2>/dev/null || true
    rm -f "$HOME/.local/share/applications/open-webui.desktop"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    echo "Open WebUI service stopped, masked, and launcher removed."

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
