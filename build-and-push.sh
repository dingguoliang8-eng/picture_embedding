#!/bin/bash
set -e

# 与平台共用同一镜像仓库 whalesbot-ai-platform，本服务使用 picture-embedding-<版本> 标签
REGISTRY="crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com"
NAMESPACE="whalesbot"
IMAGE_NAME="whalesbot-ai-platform"
VERSION=${1:-latest}
IMAGE_TAG="picture-embedding-${VERSION}"

LOCAL_IMAGE="picture-embedding:${VERSION}"
FULL_IMAGE_NAME="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "=========================================="
echo "构建并推送 Docker 镜像"
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

echo "正在构建镜像..."
docker build -t ${LOCAL_IMAGE} .

echo "正在标记镜像..."
docker tag ${LOCAL_IMAGE} ${FULL_IMAGE_NAME}

echo "正在推送镜像..."
docker push ${FULL_IMAGE_NAME}

echo "=========================================="
echo "✅ 完成: ${FULL_IMAGE_NAME}"
echo ""
echo "拉取: docker pull ${FULL_IMAGE_NAME}"
echo ""
echo "部署:"
echo "  cd /data/www/whalesbot-ai-platform/picture_embedding"
echo "  # 确认 docker-compose.prod.yml 中 image 标签为 ${IMAGE_TAG}"
echo "  docker compose -f docker-compose.prod.yml pull"
echo "  docker compose -f docker-compose.prod.yml up -d"
echo "=========================================="
