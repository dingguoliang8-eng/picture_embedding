#!/bin/bash
set -e

# 配置变量（请根据实际情况修改）
REGISTRY="registry.cn-hangzhou.aliyuncs.com"
NAMESPACE="dejavu_ding"
IMAGE_NAME="picture-embedding"
VERSION=${1:-latest}

FULL_IMAGE_NAME="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${VERSION}"

echo "=========================================="
echo "构建并推送 Docker 镜像到阿里云"
echo "镜像: ${FULL_IMAGE_NAME}"
echo "=========================================="

if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装，请先安装 Docker"
    exit 1
fi

echo "检查 Docker 登录状态..."
if ! docker info &> /dev/null; then
    echo "警告: 无法连接到 Docker daemon，请确保 Docker 正在运行"
    exit 1
fi

echo "提示: 如果推送失败，请先登录阿里云镜像仓库："
echo "docker login --username=<你的用户名> ${REGISTRY}"
echo ""

echo "正在构建镜像..."
docker build -t ${IMAGE_NAME}:${VERSION} .

echo "正在标记镜像..."
docker tag ${IMAGE_NAME}:${VERSION} ${FULL_IMAGE_NAME}

echo "正在推送镜像到阿里云..."
docker push ${FULL_IMAGE_NAME}

echo "=========================================="
echo "✅ 完成！镜像已推送到: ${FULL_IMAGE_NAME}"
echo ""
echo "在测试环境部署步骤："
echo "1. docker login --username=<你的用户名> ${REGISTRY}"
echo "2. docker compose -f docker-compose.test.yml pull"
echo "3. docker compose -f docker-compose.test.yml up -d"
echo "4. docker compose -f docker-compose.test.yml logs -f"
echo "=========================================="
