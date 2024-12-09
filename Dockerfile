# Base Image
FROM python:3.11-slim-bookworm as base

# System dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    build-essential \
    gcc \
    g++ \
    aria2 \
    libgl1 \
    libglib2.0-0 \
    fonts-dejavu-core \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create directory structure and user first
RUN useradd -m -u 1000 -d /opt/comfyui comfyui && \
    mkdir -p /opt/comfyui/{models,config,output,cache,.local/lib/python3.11/site-packages} && \
    mkdir -p /opt/comfyui/models/{unet,clip,vae,loras} && \
    chown -R comfyui:comfyui /opt/comfyui

# Switch to comfyui user for pip installations
USER comfyui:comfyui
ENV PATH="/opt/comfyui/.local/bin:$PATH"
ENV PYTHONPATH=/opt/comfyui
ENV HOME=/opt/comfyui
ENV PIP_CACHE_DIR=/opt/comfyui/cache/pip

# Install CUDA-enabled PyTorch and related packages
ARG CUDA_VERSION=cu121
RUN pip install --no-cache-dir --user \
    torch \
    torchvision \
    torchaudio \
    xformers \
    --index-url https://download.pytorch.org/whl/${CUDA_VERSION}

# Install onnxruntime-gpu
RUN pip uninstall --yes onnxruntime-gpu || true && \
    pip install --no-cache-dir --user onnxruntime-gpu \
    --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/

# Install ComfyUI core
RUN cd /opt/comfyui && \
    git clone --recurse-submodules https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    pip install --no-cache-dir --user -r requirements.txt

# Install common custom nodes
RUN cd /opt/comfyui/ComfyUI/custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone https://github.com/Extraltodeus/ComfyUI-AutomaticCFG && \
    git clone https://github.com/Clybius/ComfyUI-Extra-samplers && \
    git clone https://github.com/flowtyone/ComfyUI-Flowty-LDSR.git && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    git clone https://github.com/city96/ComfyUI_ExtraModels && \
    git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale --recursive

# Runtime Image
FROM base as runtime

USER root

# Copy scripts
COPY --chmod=755 scripts/entrypoint.sh /scripts/
COPY --chmod=755 scripts/models_download.sh /scripts/
COPY scripts/models.txt /scripts/
COPY scripts/models_fp8.txt /scripts/

# Set ownership
RUN chown -R comfyui:comfyui /scripts

USER comfyui:comfyui

# Environment setup
ENV CLI_ARGS=""
ENV PYTHONPATH=/opt/comfyui
ENV HOME=/opt/comfyui
ENV PATH="/opt/comfyui/.local/bin:$PATH"
ENV PYTHONPYCACHEPREFIX="/opt/comfyui/cache/pycache"

# Volume configuration
VOLUME ["/opt/comfyui/models", "/opt/comfyui/config", "/opt/comfyui/output", "/opt/comfyui/cache"]

WORKDIR /opt/comfyui
EXPOSE 8188

CMD ["/scripts/entrypoint.sh"]