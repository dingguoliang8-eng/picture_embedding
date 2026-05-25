@echo off
setlocal EnableDelayedExpansion

set REGISTRY=crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com
set NAMESPACE=whalesbot
set IMAGE_NAME=whalesbot-ai-platform
set VERSION=%1
if "%VERSION%"=="" set VERSION=latest

set TAG=picture-embedding-%VERSION%
set LOCAL=picture-embedding:%VERSION%
set REMOTE=%REGISTRY%/%NAMESPACE%/%IMAGE_NAME%:%TAG%

echo ==========================================
echo picture-embedding 镜像构建
echo 版本: %VERSION%
echo 远程: %REMOTE%
echo ==========================================

docker info >nul 2>nul
if errorlevel 1 (
    echo 错误: Docker daemon 未运行
    exit /b 1
)

echo 提示: 推送前请先登录：
echo   docker login --username=leocao0828 %REGISTRY%
echo.

set DOCKER_BUILDKIT=1
docker build -t %LOCAL% .
if errorlevel 1 exit /b 1

docker tag %LOCAL% %REMOTE%
if errorlevel 1 exit /b 1

docker push %REMOTE%
if errorlevel 1 (
    echo 推送失败: docker login --username=leocao0828 %REGISTRY%
    exit /b 1
)

echo.
echo 已推送 %REMOTE%
echo.
echo 部署（在 /data/www/whalesbot-ai-platform/picture_embedding）:
echo   CPU: docker compose -f docker-compose.prod.yml pull ^&^& docker compose -f docker-compose.prod.yml up -d
echo   GPU: docker compose -f docker-compose.prod.yml -f docker-compose.prod.gpu.yml pull ^&^& docker compose -f docker-compose.prod.yml -f docker-compose.prod.gpu.yml up -d
exit /b 0
