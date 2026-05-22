#!/bin/bash
set -e

REGISTRY="crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com"
NAMESPACE="whalesbot"
IMAGE_NAME="whalesbot-ai-platform"
VERSION=${1:-latest}
TORCH_CUDA="${TORCH_CUDA:-cu124}"

build_and_push() {
  local device=$1
  local tag="picture-embedding-${VERSION}-${device}"
  local local_image="picture-embedding:${VERSION}-${device}"
  local remote="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${tag}"

  echo ""
  echo "------------------------------------------"
  echo "构建并推送: ${device} (TORCH_CUDA=${TORCH_CUDA})"
  echo "远程: ${remote}"
  echo "------------------------------------------"

  docker build \
    --build-arg TORCH_DEVICE="${device}" \
    --build-arg TORCH_CUDA="${TORCH_CUDA}" \
    -t "${local_image}" \
    .

  docker tag "${local_image}" "${remote}"
  docker push "${remote}"
  echo "✅ 已推送: ${remote}"
}

echo "=========================================="
echo "picture-embedding 双镜像构建（cpu + gpu）"
echo "版本: ${VERSION}"
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

build_and_push cpu
build_and_push cuda

echo ""
echo "=========================================="
echo "✅ 全部完成"
echo ""
echo "  CPU: ${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:picture-embedding-${VERSION}-cpu"
echo "  GPU: ${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:picture-embedding-${VERSION}-gpu"
echo ""
echo "部署（在 /data/www/whalesbot-ai-platform/picture_embedding）："
echo "  CPU: docker compose -f docker-compose.prod.yml pull && up -d"
echo "  GPU: docker compose -f docker-compose.prod.yml -f docker-compose.prod.gpu.yml pull && up -d"
echo "=========================================="
