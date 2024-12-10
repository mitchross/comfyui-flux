#!/bin/bash

echo "########################################"
echo "[INFO] Downloading ComfyUI & Manager..."
echo "########################################"

set -euxo pipefail

# ComfyUI
cd /opt/comfyui
git clone --recurse-submodules \
    https://github.com/comfyanonymous/ComfyUI.git \
    || (cd /opt/comfyui/ComfyUI && git pull)

# ComfyUI Manager
cd /opt/comfyui/ComfyUI/custom_nodes
git clone --recurse-submodules \
    https://github.com/ltdrdata/ComfyUI-Manager.git \
    || (cd /opt/comfyui/ComfyUI/custom_nodes/ComfyUI-Manager && git pull)

# Copy workflows
WORKFLOWS_DIR="/opt/comfyui/ComfyUI/user/default/workflows"
mkdir -p "$WORKFLOWS_DIR"

if [ -d "/workflows" ]; then
    cp -R /workflows/* "$WORKFLOWS_DIR/"
    echo "[INFO] Workflows copied successfully."
else
    echo "[WARNING] /workflows directory not found. Skipping workflow copy."
fi

# Finish
touch /opt/comfyui/.download-complete /opt/comfyui/.download-complete