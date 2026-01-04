#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Build Orchestrator Script
###############################################################################
# This script orchestrates the execution of all build scripts in sequence.
# It replaces multiple RUN commands in the Containerfile with a single
# entry point, reducing image layers and consolidating mount configurations.
###############################################################################

echo "::group:: Starting Build Process"
echo "Orchestrating build scripts..."
echo "::endgroup::"

# Execute build scripts in sequence
/ctx/build/15-custom-files.sh
/ctx/build/20-packages.sh
/ctx/build/30-workarounds.sh
/ctx/build/40-systemd.sh
/ctx/build/90-cleanup.sh

echo "All build scripts completed successfully!"
