#!/bin/bash
set -e

echo "########################################"
echo "[INFO] Starting ComfyUI with Flux..."
echo "########################################"

# Initialize model downloads if needed
if [ ! -f "/opt/comfyui/models/.initialized" ]; then
    bash /scripts/models_download.sh
    touch /opt/comfyui/models/.initialized
fi

# Start ComfyUI
cd /opt/comfyui/ComfyUI
python3 main.py --listen --port 8188 ${CLI_ARGS}