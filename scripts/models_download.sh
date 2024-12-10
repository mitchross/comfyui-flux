#!/bin/bash
set -e

echo "########################################"
echo "[INFO] Checking and downloading models..."
echo "########################################"

echo "[INFO] Script started at $(date)"
echo "[INFO] Current working directory: $(pwd)"
echo "[INFO] Available disk space before downloads:"
df -h /opt/comfyui/models

# Verify directory exists
echo "[INFO] Creating model directories..."
mkdir -p /opt/comfyui/models/{unet,clip,vae,loras}
echo "[INFO] Directory structure created:"
ls -la /opt/comfyui/models/

# Determine model list file based on LOW_VRAM
echo "[INFO] Checking LOW_VRAM setting: ${LOW_VRAM:-false}"
if [ "${LOW_VRAM}" = "true" ]; then
    echo "[INFO] LOW_VRAM is set to true. Using FP8 models..."
    MODEL_LIST_FILE="/scripts/models_fp8.txt"
    echo "[INFO] Will use model list: $MODEL_LIST_FILE"
else
    echo "[INFO] Using standard models..."
    MODEL_LIST_FILE="/scripts/models.txt"
    echo "[INFO] Will use model list: $MODEL_LIST_FILE"
fi

# Verify model list file exists
echo "[INFO] Verifying model list file..."
if [ ! -f "$MODEL_LIST_FILE" ]; then
    echo "[ERROR] Model list file not found: $MODEL_LIST_FILE"
    echo "[ERROR] Contents of /scripts:"
    ls -la /scripts/
    exit 1
else
    echo "[INFO] Model list file found. Contents:"
    cat "$MODEL_LIST_FILE"
fi

# Filter model list based on HF_TOKEN availability
echo "[INFO] Checking HuggingFace token..."
if [ -z "${HF_TOKEN}" ]; then
    echo "[INFO] HF_TOKEN not provided. Skipping authenticated models..."
    echo "[INFO] Filtering model list to exclude authenticated models..."
    sed '/# Requires HF_TOKEN/,/^$/d' "$MODEL_LIST_FILE" > /scripts/models_filtered.txt
    DOWNLOAD_LIST_FILE="/scripts/models_filtered.txt"
    echo "[INFO] Filtered model list created. Contents:"
    cat "$DOWNLOAD_LIST_FILE"
else
    echo "[INFO] HF_TOKEN provided. Will download all models..."
    DOWNLOAD_LIST_FILE="$MODEL_LIST_FILE"
fi

echo "[INFO] Current models directory structure:"
tree /opt/comfyui/models/ || ls -R /opt/comfyui/models/

echo "[INFO] Available disk space after setup:"
df -h /opt/comfyui/models

echo "[INFO] Setup complete. Ready to begin downloads..."
echo "########################################"