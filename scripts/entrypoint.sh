#!/bin/bash
set -e

echo "########################################"
echo "[INFO] Starting ComfyUI with Flux..."
echo "########################################"

echo "[INFO] Current working directory: $(pwd)"
echo "[INFO] Python version: $(python3 --version)"
echo "[INFO] CUDA available: $(python3 -c 'import torch; print(torch.cuda.is_available())')"
echo "[INFO] GPU devices: $(python3 -c 'import torch; print(torch.cuda.device_count())')"

# Check environment variables
echo "[INFO] Checking environment variables..."
echo "[INFO] LOW_VRAM: ${LOW_VRAM:-false}"
echo "[INFO] HF_TOKEN: ${HF_TOKEN:+set (hidden)}"
echo "[INFO] CLI_ARGS: ${CLI_ARGS}"

# Initialize model downloads if needed
if [ ! -f "/opt/comfyui/models/.initialized" ]; then
    echo "[INFO] First run detected, initializing model downloads..."
    echo "[INFO] Models directory content before download:"
    ls -la /opt/comfyui/models/
    
    bash /scripts/models_download.sh
    
    echo "[INFO] Creating initialization marker..."
    touch /opt/comfyui/models/.initialized
    
    echo "[INFO] Models directory content after download:"
    ls -la /opt/comfyui/models/
else
    echo "[INFO] Models already initialized, skipping download"
    echo "[INFO] Current models directory content:"
    ls -la /opt/comfyui/models/
fi

# Check ComfyUI installation
echo "[INFO] Checking ComfyUI installation..."
if [ -d "/opt/comfyui/ComfyUI" ]; then
    echo "[INFO] ComfyUI installation found"
else
    echo "[ERROR] ComfyUI installation not found in /opt/comfyui/ComfyUI"
    exit 1
fi

# Start ComfyUI
echo "[INFO] Starting ComfyUI server..."
echo "[INFO] Using command: python3 main.py --listen --port 8188 ${CLI_ARGS}"
cd /opt/comfyui/ComfyUI
python3 main.py --listen --port 8188 ${CLI_ARGS}