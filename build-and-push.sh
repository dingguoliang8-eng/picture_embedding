#!/bin/bash
set -e

REGISTRY="crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com"
NAMESPACE="whalesbot"
IMAGE_NAME="whalesbot-ai-platform"
VERSION=${1:-latest}

# 检测本机 GPU（可用 TORCH_DEVICE=cpu|cuda、TORCH_CUDA=cu124 覆盖）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "${TORCH_DEVICE}" ]; then
  DEVICE="${TORCH_DEVICE}"
else
  if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
    DEVICE=cuda
    echo "检测到 NVIDIA GPU，将构建 CUDA 版 PyTorch（TORCH_CUDA=${TORCH_CUDA:-cu124}）"
  else
    DEVICE=cpu
    echo "未检测到 GPU，将构建 CPU 版 PyTorch"
  fi
fi

TORCH_CUDA="${TORCH_CUDA:-cu124}"
IMAGE_TAG="picture-embedding-${VERSION}-${DEVICE}"
LOCAL_IMAGE="picture-embedding:${VERSION}-${DEVICE}"
FULL_IMAGE_NAME="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "=========================================="
echo "构建并推送 Docker 镜像"
echo "PyTorch: ${DEVICE} (TORCH_CUDA=${TORCH_CUDA})"
echo "远程: ${FULL_IMAGE_NAME}"
echo "=========================================="

if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "错误: Docker daemon 未运行"
    exit 1
fi

echo "提示: 推送前请先登录："
echo "  docker login --username=leocao0828 ${REGISTRY}"
echo ""
echo "强制 CPU 构建: TORCH_DEVICE=cpu $0 ${VERSION}"
echo "强制 GPU 构建: TORCH_DEVICE=cuda TORCH_CUDA=cu124 $0 ${VERSION}"
echo ""

echo "正在构建镜像..."
docker build \
  --build-arg TORCH_DEVICE="${DEVICE}" \
  --build-arg TORCH_CUDA="${TORCH_CUDA}" \
  -t "${LOCAL_IMAGE}" \
  .

echo "正在标记镜像..."
docker tag "${LOCAL_IMAGE}" "${FULL_IMAGE_NAME}"

echo "正在推送镜像..."
docker push "${FULL_IMAGE_NAME}"

echo "=========================================="
echo "✅ 完成: ${FULL_IMAGE_NAME}"
echo ""
echo "拉取: docker pull ${FULL_IMAGE_NAME}"
echo ""
echo "部署 (${DEVICE}):"
echo "  cd /data/www/whalesbot-ai-platform/picture_embedding"
if [ "${DEVICE}" = "cuda" ]; then
  echo "  docker compose -f docker-compose.prod.yml -f docker-compose.prod.gpu.yml pull"
  echo "  docker compose -f docker-compose.prod.yml -f docker-compose.prod.gpu.yml up -d"
else
  echo "  docker compose -f docker-compose.prod.yml pull"
  echo "  docker compose -f docker-compose.prod.yml up -d"
fi
echo "=========================================="
