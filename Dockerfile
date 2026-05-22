# 第一阶段：构建依赖
FROM python:3.10-slim AS builder

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

# pip / setuptools / wheel：阿里云 PyPI
RUN pip install --upgrade pip setuptools wheel \
    -i https://mirrors.aliyun.com/pypi/simple/ \
    --trusted-host mirrors.aliyun.com \
    --timeout 600
# PyTorch：使用清华源（确保有 2.9.1 版本）
RUN pip install --prefer-binary \
    torch==2.9.1 torchvision==0.24.1 \
    -i https://pypi.tuna.tsinghua.edu.cn/simple \
    --trusted-host pypi.tuna.tsinghua.edu.cn \
    --timeout 600 --retries 10

# 其余依赖：阿里云 PyPI
RUN pip install --prefer-binary -r requirements-base.txt \
    -i https://mirrors.aliyun.com/pypi/simple/ \
    --trusted-host mirrors.aliyun.com \
    --timeout 600 --retries 10

# 运行阶段
FROM python:3.10-slim

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
