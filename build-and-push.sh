#!/bin/bash
set -e

REGISTRY="crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com"
NAMESPACE="whalesbot"
IMAGE_NAME="whalesbot-ai-platform"
VERSION=${1:-latest}
TAG="picture-embedding-${VERSION}"
LOCAL_IMAGE="picture-embedding:${VERSION}"
REMOTE="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${TAG}"

echo "=========================================="
echo "picture-embedding 镜像构建"
echo "版本: ${VERSION}"
echo "远程: ${REMOTE}"
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

DOCKER_BUILDKIT=1 docker build -t "${LOCAL_IMAGE}" .

docker tag "${LOCAL_IMAGE}" "${REMOTE}"
docker push "${REMOTE}"

echo ""
echo "=========================================="
echo "✅ 已推送: ${REMOTE}"
echo ""
echo "部署（在 /data/www/whalesbot-ai-platform/picture_embedding）："
echo "  CPU: docker compose -f docker-compose.prod.yml pull && docker compose -f docker-compose.prod.yml up -d"
echo "  GPU: docker compose -f docker-compose.prod.yml -f docker-compose.prod.gpu.yml pull && docker compose -f docker-compose.prod.yml -f docker-compose.prod.gpu.yml up -d"
echo "=========================================="
