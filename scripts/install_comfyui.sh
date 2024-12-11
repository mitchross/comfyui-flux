#!/bin/bash
echo "########################################"
echo "[INFO] Downloading ComfyUI & Manager..."
echo "########################################"
set -euxo pipefail

# Function to handle git operations with retry
git_clone_or_pull() {
    local repo_url=$1
    local target_dir=$2
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if [ ! -d "$target_dir" ]; then
            echo "[INFO] Cloning $repo_url to $target_dir..."
            if git clone --recurse-submodules "$repo_url" "$target_dir"; then
                return 0
            fi
        else
            echo "[INFO] Updating existing repository in $target_dir..."
            cd "$target_dir"
            if git pull; then
                return 0
            fi
        fi
        
        retry_count=$((retry_count + 1))
        echo "[WARNING] Git operation failed. Attempt $retry_count of $max_retries"
        sleep 5
    done

    echo "[ERROR] Failed to clone/pull repository after $max_retries attempts"
    return 1
}

# Make sure we're in the right directory
cd /opt/comfyui

# Install/Update ComfyUI
echo "[INFO] Setting up ComfyUI..."
git_clone_or_pull "https://github.com/comfyanonymous/ComfyUI.git" "/opt/comfyui/ComfyUI"

# Create and setup custom_nodes directory
mkdir -p /opt/comfyui/ComfyUI/custom_nodes
cd /opt/comfyui/ComfyUI/custom_nodes

# Install/Update ComfyUI Manager
echo "[INFO] Setting up ComfyUI Manager..."
git_clone_or_pull "https://github.com/ltdrdata/ComfyUI-Manager.git" "/opt/comfyui/ComfyUI/custom_nodes/ComfyUI-Manager"

# Set up workflows directory
echo "[INFO] Setting up workflows..."
WORKFLOWS_DIR="/opt/comfyui/ComfyUI/user/default/workflows"
mkdir -p "$WORKFLOWS_DIR"

if [ -d "/workflows" ] && [ "$(ls -A /workflows)" ]; then
    echo "[INFO] Copying workflows..."
    cp -R /workflows/* "$WORKFLOWS_DIR/"
    echo "[INFO] Workflows copied successfully."
else
    echo "[WARNING] No workflows found in /workflows directory."
fi

# Verify installations
echo "[INFO] Verifying installations..."
for dir in "/opt/comfyui/ComfyUI" "/opt/comfyui/ComfyUI/custom_nodes/ComfyUI-Manager"; do
    if [ ! -d "$dir" ]; then
        echo "[ERROR] Installation failed: $dir not found"
        exit 1
    fi
done

# Create initialization marker
echo "[INFO] Creating initialization marker..."
touch /opt/comfyui/.download-complete

echo "########################################"
echo "[INFO] ComfyUI installation complete"
echo "########################################"