#!/bin/bash

echo "########################################"
echo "[INFO] Downloading ComfyUI & Manager..."
echo "########################################"

set -euxo pipefail

echo "[INFO] Current working directory: $(pwd)"
echo "[INFO] Available disk space: $(df -h /opt/comfyui)"
echo "[INFO] Current directory contents: $(ls -la /opt/comfyui)"

# ComfyUI
echo "[INFO] Installing/Updating ComfyUI..."
cd /opt/comfyui
if [ -d "ComfyUI" ]; then
    echo "[INFO] ComfyUI directory exists, updating..."
    cd ComfyUI
    git remote -v
    echo "[INFO] Current ComfyUI version: $(git describe --tags)"
    git pull
    echo "[INFO] Updated ComfyUI version: $(git describe --tags)"
else
    echo "[INFO] Cloning ComfyUI repository..."
    git clone --recurse-submodules https://github.com/comfyanonymous/ComfyUI.git
    cd ComfyUI
    echo "[INFO] Cloned ComfyUI version: $(git describe --tags)"
fi

# ComfyUI Manager
echo "[INFO] Installing/Updating ComfyUI Manager..."
cd /opt/comfyui/ComfyUI/custom_nodes
if [ -d "ComfyUI-Manager" ]; then
    echo "[INFO] ComfyUI-Manager directory exists, updating..."
    cd ComfyUI-Manager
    git remote -v
    echo "[INFO] Current Manager version: $(git describe --tags || git rev-parse --short HEAD)"
    git pull
    echo "[INFO] Updated Manager version: $(git describe --tags || git rev-parse --short HEAD)"
else
    echo "[INFO] Cloning ComfyUI-Manager repository..."
    git clone --recurse-submodules https://github.com/ltdrdata/ComfyUI-Manager.git
    cd ComfyUI-Manager
    echo "[INFO] Cloned Manager version: $(git describe --tags || git rev-parse --short HEAD)"
fi

# Copy workflows
echo "[INFO] Setting up workflows..."
WORKFLOWS_DIR="/opt/comfyui/ComfyUI/user/default/workflows"
echo "[INFO] Creating workflows directory: $WORKFLOWS_DIR"
mkdir -p "$WORKFLOWS_DIR"

if [ -d "/workflows" ]; then
    echo "[INFO] Found workflows directory, contents:"
    ls -la /workflows
    echo "[INFO] Copying workflows to $WORKFLOWS_DIR"
    cp -R /workflows/* "$WORKFLOWS_DIR/"
    echo "[INFO] Workflows copied successfully. Final contents:"
    ls -la "$WORKFLOWS_DIR"
else
    echo "[WARNING] /workflows directory not found. Skipping workflow copy."
fi

# Verify installations
echo "[INFO] Verifying installations..."
echo "[INFO] ComfyUI installation:"
ls -la /opt/comfyui/ComfyUI
echo "[INFO] ComfyUI Manager installation:"
ls -la /opt/comfyui/ComfyUI/custom_nodes/ComfyUI-Manager
echo "[INFO] Workflows installation:"
ls -la "$WORKFLOWS_DIR"

# Create completion marker
echo "[INFO] Creating installation completion markers..."
touch /opt/comfyui/.download-complete
echo "[INFO] Installation complete at $(date)"

# Show final disk space
echo "[INFO] Final disk space usage:"
df -h /opt/comfyui