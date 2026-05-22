# 第一阶段：构建依赖
FROM python:3.10-slim AS builder

# cpu：官方 CPU wheel；cuda：官方 CUDA wheel（需运行容器配 nvidia-container-toolkit）
# 构建时由 build-and-push 传入：TORCH_DEVICE=cpu|cuda（脚本会各打一张镜像）
ARG TORCH_DEVICE=cpu
ARG TORCH_CUDA=cu126

RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list 2>/dev/null || true \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list 2>/dev/null || true \
    && sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=600 \
    PIP_PROGRESS_BAR=off

COPY requirements-base.txt .

# PyTorch：按 TORCH_DEVICE 选择索引（勿用阿里云 PyPI 拉 torch）
RUN if [ "$TORCH_DEVICE" = "cuda" ]; then \
        PYTORCH_INDEX="https://download.pytorch.org/whl/${TORCH_CUDA}"; \
        echo "安装 PyTorch (CUDA ${TORCH_CUDA}): ${PYTORCH_INDEX}"; \
    else \
        PYTORCH_INDEX="https://download.pytorch.org/whl/cpu"; \
        echo "安装 PyTorch (CPU): ${PYTORCH_INDEX}"; \
    fi \
    && pip install --no-cache-dir --upgrade pip setuptools wheel \
    && ( pip install --no-cache-dir --prefer-binary \
            torch==2.9.1 torchvision==0.24.1 \
            --index-url "${PYTORCH_INDEX}" \
            --trusted-host download.pytorch.org \
            --timeout 600 --retries 10 \
        || { [ "$TORCH_DEVICE" = "cpu" ] && pip install --no-cache-dir --prefer-binary \
                torch==2.9.1 torchvision==0.24.1 \
                -i https://pypi.tuna.tsinghua.edu.cn/simple \
                --trusted-host pypi.tuna.tsinghua.edu.cn \
                --timeout 600 --retries 10; } )

# 其余依赖：阿里云 PyPI
RUN pip install --no-cache-dir --prefer-binary -r requirements-base.txt \
    -i https://mirrors.aliyun.com/pypi/simple/ \
    --trusted-host mirrors.aliyun.com \
    --timeout 300 --retries 10

# 运行阶段
FROM python:3.10-slim

ARG TORCH_DEVICE=cpu
ENV PICTURE_EMBEDDING_TORCH_DEVICE=${TORCH_DEVICE}

RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list 2>/dev/null || true \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list 2>/dev/null || true \
    && sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libglib2.0-0 \
        libgomp1 \
        libgl1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages

RUN mkdir -p tmp data models

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

COPY picture_embedding.yaml .
COPY app ./app
COPY start_server.py .

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["python", "start_server.py"]
