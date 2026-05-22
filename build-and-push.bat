@echo off
set REGISTRY=crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com
set NAMESPACE=whalesbot
set IMAGE_NAME=whalesbot-ai-platform
set VERSION=%1
if "%VERSION%"=="" set VERSION=latest
set IMAGE_TAG=picture-embedding-%VERSION%
set LOCAL_IMAGE=picture-embedding:%VERSION%
set FULL_IMAGE_NAME=%REGISTRY%/%NAMESPACE%/%IMAGE_NAME%:%IMAGE_TAG%

echo ==========================================
echo 远程镜像: %FULL_IMAGE_NAME%
echo ==========================================

docker build -t %LOCAL_IMAGE% .
if errorlevel 1 exit /b 1

docker tag %LOCAL_IMAGE% %FULL_IMAGE_NAME%
if errorlevel 1 exit /b 1

docker push %FULL_IMAGE_NAME%
if errorlevel 1 (
    echo 推送失败: docker login --username=leocao0828 %REGISTRY%
    exit /b 1
)

echo 完成: %FULL_IMAGE_NAME%
echo 部署: cd /data/www/whalesbot-ai-platform/picture_embedding
echo       docker compose -f docker-compose.prod.yml pull ^&^& up -d
