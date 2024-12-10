# Use a specific CUDA base image instead of python slim
FROM nvidia/cuda:12.4.0-runtime-ubuntu22.04

# Set environment variables to reduce interaction during package installation
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Install Python and system dependencies in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    python3-pip \
    git \
    build-essential \
    gcc \
    g++ \
    aria2 \
    libgl1 \
    libglib2.0-0 \
    fonts-dejavu-core \
    sudo \
    && rm -rf /var/lib/apt/lists/* \
    && python3.11 -m venv /venv \
    && . /venv/bin/activate

# Set PATH to use venv by default
ENV PATH="/venv/bin:$PATH"

# Combine PyTorch installations to reduce layers and use specific versions
RUN pip install --no-cache-dir \
    torch==2.4.1+cu124 torchvision==0.19.1+cu124 torchaudio==2.4.1+cu124 \
    --extra-index-url https://download.pytorch.org/whl/cu124 \
    && pip install --no-cache-dir \
    xformers==0.0.22.post7 \
    einops>=0.6.1

# Install onnxruntime-gpu in the same layer
RUN pip install --no-cache-dir \
    onnxruntime-gpu \
    --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/

# Clone and install ComfyUI and its manager in a single layer
RUN mkdir -p /opt/comfyui \
    && cd /opt/comfyui \
    && git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git \
    && cd ComfyUI \
    && pip install --no-cache-dir -r requirements.txt \
    && mkdir -p custom_nodes \
    && cd custom_nodes \
    && git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git \
    && cd ComfyUI-Manager \
    && pip install --no-cache-dir -r requirements.txt

# Verify packages in the same layer as installation
RUN python3 -c "import torch; import einops; import transformers; import safetensors"

# Set up user and directories in a single layer
RUN useradd -m -d /app runner \
    && mkdir -p /scripts /workflows /opt/comfyui/models \
    && chown -R runner:runner /app /scripts /workflows /opt/comfyui \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner

COPY --chown=runner:runner scripts/. /scripts/
COPY --chown=runner:runner workflows/. /workflows/

USER runner:runner
VOLUME /app
WORKDIR /app
EXPOSE 8188
ENV CLI_ARGS=""
CMD ["bash","/scripts/entrypoint.sh"]