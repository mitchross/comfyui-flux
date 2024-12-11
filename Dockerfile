FROM python:3.11-slim-bookworm

# Install git and aria2c
RUN apt-get update \
    && apt-get install -y git \
    build-essential \
    gcc \
    g++ \
    aria2 \
    libgl1 \
    libglib2.0-0 \
    fonts-dejavu-core \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Define build argument for CUDA version with default value
ARG CUDA_VERSION=cu121

# Set environment variables
ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    PIP_CACHE_DIR=/opt/comfyui/cache/.cache/pip \
    TRANSFORMERS_CACHE=/opt/comfyui/cache/.cache/huggingface \
    HOME=/opt/comfyui \
    PYTHONUNBUFFERED=1

# Install torch, torchvision, torchaudio and xformers
RUN pip install --no-cache-dir --break-system-packages \
    torch \
    torchvision \
    torchaudio \
    xformers \
    --index-url https://download.pytorch.org/whl/${CUDA_VERSION}

# Install onnxruntime-gpu
RUN pip uninstall --break-system-packages --yes \
    onnxruntime-gpu \
    && pip install --no-cache-dir --break-system-packages \
    onnxruntime-gpu \
    --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/

# Install dependencies for ComfyUI and ComfyUI-Manager
RUN pip install --no-cache-dir --break-system-packages \
    -r https://raw.githubusercontent.com/comfyanonymous/ComfyUI/master/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/requirements.txt

# Create directories and set up user
RUN useradd -m -d /opt/comfyui -u 1000 runner \
    && mkdir -p /opt/comfyui/{models/{unet,clip,vae,loras},config,output,cache/.cache/{pip,huggingface,pycache}} /scripts /workflows \
    && chown -R runner:runner /opt/comfyui /scripts /workflows \
    && chmod -R 777 /opt/comfyui/cache/.cache

COPY --chown=runner:runner scripts/. /scripts/
COPY --chown=runner:runner workflows/. /workflows/

# Add runner to sudoers
RUN echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner

USER runner:runner
VOLUME ["/opt/comfyui/models", "/opt/comfyui/config", "/opt/comfyui/output", "/opt/comfyui/cache"]
WORKDIR /opt/comfyui
EXPOSE 8188
ENV CLI_ARGS=""
CMD ["bash","/scripts/entrypoint.sh"]