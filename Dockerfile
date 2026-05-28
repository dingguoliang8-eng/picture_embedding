# 第一阶段：构建依赖
FROM docker.m.daocloud.io/library/python:3.10-slim AS builder

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list 2>/dev/null || true \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list 2>/dev/null || true \
    && apt-get update \
    && apt-get install -y --no-install-recommends gcc g++ make

WORKDIR /app
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 PIP_DEFAULT_TIMEOUT=600 PIP_PROGRESS_BAR=off

COPY requirements-base.txt .

# pip 升级
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip setuptools wheel \
    -i https://mirrors.aliyun.com/pypi/simple \
    --trusted-host mirrors.aliyun.com

#  官方源安装 torch
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --prefer-binary \
    torch==2.9.1 torchvision==0.24.1 \
    --index-url https://download.pytorch.org/whl/cpu \
    --timeout 600 --retries 10

# 安装其他依赖
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --prefer-binary -r requirements-base.txt \
    -i https://mirrors.aliyun.com/pypi/simple \
    --trusted-host mirrors.aliyun.com \
    --timeout 600 --retries 10

# 运行阶段
FROM docker.m.daocloud.io/library/python:3.10-slim

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list 2>/dev/null || true \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list 2>/dev/null || true \
    && apt-get update \
    && apt-get install -y --no-install-recommends libglib2.0-0 libgomp1 libgl1

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