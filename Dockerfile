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

# Install CUDA-enabled PyTorch and related packages
ARG CUDA_VERSION=cu121
RUN pip install --no-cache-dir --break-system-packages \
    torch \
    torchvision \
    torchaudio \
    xformers \
    --index-url https://download.pytorch.org/whl/${CUDA_VERSION}

# Install onnxruntime-gpu
RUN pip uninstall --break-system-packages --yes onnxruntime-gpu && \
    pip install --no-cache-dir --break-system-packages onnxruntime-gpu \
    --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/

# Create directory structure and user
RUN useradd -m -u 1000 -d /opt/comfyui comfyui && \
    mkdir -p /opt/comfyui/{models,config,output,cache} && \
    mkdir -p /opt/comfyui/models/{unet,clip,vae,loras} && \
    chown -R comfyui:comfyui /opt/comfyui

# Install ComfyUI core
RUN cd /opt/comfyui && \
    git clone --recurse-submodules https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    pip install --no-cache-dir --break-system-packages -r requirements.txt

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
COPY --chmod=755 scripts/model_download.sh /scripts/
COPY scripts/models.txt /scripts/
COPY scripts/models_fp8.txt /scripts/

# Set ownership
RUN chown -R comfyui:comfyui /scripts

USER comfyui:comfyui

# Environment setup
ENV CLI_ARGS=""
ENV PYTHONPATH=/opt/comfyui
ENV HOME=/opt/comfyui
ENV PATH="${PATH}:/opt/comfyui/.local/bin"
ENV PYTHONPYCACHEPREFIX="/opt/comfyui/cache/pycache"

# Volume configuration
VOLUME ["/opt/comfyui/models", "/opt/comfyui/config", "/opt/comfyui/output", "/opt/comfyui/cache"]

WORKDIR /opt/comfyui
EXPOSE 8188

CMD ["/scripts/entrypoint.sh"]