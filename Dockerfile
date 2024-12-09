# Base Image
FROM python:3.11-slim-bookworm

# System dependencies
RUN apt-get update && \
    apt-get install -y \
    git build-essential gcc g++ aria2 \
    libgl1 libglib2.0-0 fonts-dejavu-core sudo \
    && rm -rf /var/lib/apt/lists/*

# Create user and directory structure
RUN useradd -m -u 1000 -d /opt/comfyui comfyui && \
    mkdir -p /opt/comfyui/{models,config,output,cache} && \
    mkdir -p /opt/comfyui/models/{unet,clip,vae,loras} && \
    mkdir -p /opt/comfyui/ComfyUI/logs && \
    chown -R comfyui:comfyui /opt/comfyui && \
    chown -R comfyui:comfyui /usr/local/lib/python3.11/site-packages && \
    chmod -R 777 /usr/local/lib/python3.11/site-packages

USER comfyui:comfyui
ENV PATH="/opt/comfyui/.local/bin:$PATH" \
    PYTHONPATH=/opt/comfyui \
    HOME=/opt/comfyui \
    PIP_CACHE_DIR=/opt/comfyui/cache/pip

# Install PyTorch and dependencies
ARG CUDA_VERSION=cu121
RUN --mount=type=cache,target=/opt/comfyui/cache/pip \
    pip install --no-cache-dir --user \
    torch torchvision torchaudio xformers \
    --index-url https://download.pytorch.org/whl/${CUDA_VERSION}

# Install onnxruntime-gpu
RUN --mount=type=cache,target=/opt/comfyui/cache/pip \
    pip uninstall --yes onnxruntime-gpu || true && \
    pip install --no-cache-dir --user onnxruntime-gpu \
    --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/

# Install ComfyUI and requirements
WORKDIR /opt/comfyui
COPY --chown=comfyui:comfyui requirements.txt ./
RUN --mount=type=cache,target=/opt/comfyui/cache/pip \
    pip install --no-cache-dir --user -r requirements.txt

RUN rm -rf ComfyUI && \
    git clone --recurse-submodules https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && mkdir -p logs && chmod 777 logs

# Install custom nodes
RUN cd /opt/comfyui/ComfyUI/custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    cd ComfyUI-Manager && \
    pip install --no-cache-dir --user -r requirements.txt && \
    chmod -R 777 . && \
    cd .. && \
    git clone https://github.com/Extraltodeus/ComfyUI-AutomaticCFG && \
    git clone https://github.com/Clybius/ComfyUI-Extra-samplers && \
    git clone https://github.com/flowtyone/ComfyUI-Flowty-LDSR.git && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    git clone https://github.com/city96/ComfyUI_ExtraModels && \
    git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale --recursive

# Setup runtime environment
USER root
COPY --chmod=755 scripts/entrypoint.sh /scripts/
COPY --chmod=755 scripts/models_download.sh /scripts/
COPY scripts/models.txt /scripts/
COPY scripts/models_fp8.txt /scripts/
RUN chown -R comfyui:comfyui /scripts

USER comfyui:comfyui
ENV CLI_ARGS=""
VOLUME ["/opt/comfyui/models", "/opt/comfyui/config", "/opt/comfyui/output", "/opt/comfyui/cache"]
EXPOSE 8188

CMD ["/scripts/entrypoint.sh"]