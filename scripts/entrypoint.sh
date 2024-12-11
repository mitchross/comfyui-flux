#!/bin/bash
set -e

echo "########################################"
echo "[INFO] Starting ComfyUI setup..."
echo "########################################"

# Function to check and fix directory permissions
check_permissions() {
    local dir=$1
    if [ ! -w "$dir" ]; then
        echo "Warning: Cannot write to $dir. Attempting to fix permissions..."
        sudo chown -R $(id -u):$(id -g) "$dir"
        sudo chmod -R 755 "$dir"
    fi
}

# Check all critical directories
for dir in models config output cache; do
    check_permissions "/opt/comfyui/$dir"
done

# Ensure cache directories exist and have correct permissions
for cache_dir in pip huggingface pycache; do
    mkdir -p "/opt/comfyui/cache/.cache/$cache_dir"
    chmod 777 "/opt/comfyui/cache/.cache/$cache_dir"
done

# Ensure model subdirectories exist
for model_dir in unet clip vae loras; do
    mkdir -p "/opt/comfyui/models/$model_dir"
done

# Install or update ComfyUI
cd /opt/comfyui
if [ ! -d "/opt/comfyui/ComfyUI" ]; then
    echo "[INFO] ComfyUI not found. Installing..."
    chmod +x /scripts/install_comfyui.sh
    bash /scripts/install_comfyui.sh
else
    echo "[INFO] Updating ComfyUI..."
    cd /opt/comfyui/ComfyUI
    git pull
    echo "[INFO] Updating ComfyUI-Manager..."
    cd /opt/comfyui/ComfyUI/custom_nodes/ComfyUI-Manager
    git pull
    cd /opt/comfyui
fi

# Determine model list file based on LOW_VRAM
if [ "$LOW_VRAM" == "true" ]; then
    echo "[INFO] LOW_VRAM is set to true. Using FP8 models..."
    MODEL_LIST_FILE="/scripts/models_fp8.txt"
else
    echo "[INFO] LOW_VRAM is not set or false. Using standard models..."
    MODEL_LIST_FILE="/scripts/models.txt"
fi

# Download models
echo "########################################"
echo "[INFO] Downloading models..."
echo "########################################"

if [ -z "${HF_TOKEN}" ]; then
    echo "[INFO] HF_TOKEN not provided. Skipping models that require authentication..."
    sed '/# Requires HF_TOKEN/,/^$/d' $MODEL_LIST_FILE > /scripts/models_filtered.txt
    DOWNLOAD_LIST_FILE="/scripts/models_filtered.txt"
else
    echo "[INFO] HF_TOKEN provided. Downloading all models..."
    DOWNLOAD_LIST_FILE="$MODEL_LIST_FILE"
fi

aria2c --input-file="$DOWNLOAD_LIST_FILE" \
    --allow-overwrite=false \
    --auto-file-renaming=false \
    --continue=true \
    --max-connection-per-server=5 \
    --conditional-get=true \
    ${HF_TOKEN:+--header="Authorization: Bearer ${HF_TOKEN}"} \
    --summary-interval=30 \
    --console-log-level=warn

echo "########################################"
echo "[INFO] Starting ComfyUI..."
echo "########################################"

# Set environment variables
export PATH="${PATH}:/opt/comfyui/.local/bin"
export PYTHONPYCACHEPREFIX="/opt/comfyui/cache/.cache/pycache"

# Print some debug information
echo "[INFO] Python version: $(python3 --version)"
echo "[INFO] CUDA available: $(python3 -c 'import torch; print(torch.cuda.is_available())')"
echo "[INFO] GPU devices: $(python3 -c 'import torch; print(torch.cuda.device_count())')"
echo "[INFO] Current working directory: $(pwd)"

# Start ComfyUI
cd /opt/comfyui
python3 ./ComfyUI/main.py --listen --port 8188 ${CLI_ARGS}