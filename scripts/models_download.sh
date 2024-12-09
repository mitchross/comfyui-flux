#!/bin/bash
set -e

echo "########################################"
echo "[INFO] Checking and downloading models..."
echo "########################################"

# Determine model list file based on LOW_VRAM
if [ "$LOW_VRAM" == "true" ]; then
    echo "[INFO] LOW_VRAM is set to true. Using FP8 models..."
    MODEL_LIST_FILE="/scripts/models_fp8.txt"
else
    echo "[INFO] Using standard models..."
    MODEL_LIST_FILE="/scripts/models.txt"
fi

# Filter model list based on HF_TOKEN availability
if [ -z "${HF_TOKEN}" ]; then
    echo "[INFO] HF_TOKEN not provided. Skipping authenticated models..."
    sed '/# Requires HF_TOKEN/,/^$/d' $MODEL_LIST_FILE > /scripts/models_filtered.txt
    DOWNLOAD_LIST_FILE="/scripts/models_filtered.txt"
else
    DOWNLOAD_LIST_FILE="$MODEL_LIST_FILE"
fi

# Download models
cd /opt/comfyui/models
aria2c --input-file="$DOWNLOAD_LIST_FILE" \
    --allow-overwrite=false \
    --auto-file-renaming=false \
    --continue=true \
    --max-connection-per-server=5 \
    --conditional-get=true \
    ${HF_TOKEN:+--header="Authorization: Bearer ${HF_TOKEN}"}