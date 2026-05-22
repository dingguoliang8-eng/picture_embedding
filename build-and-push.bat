@echo off
REM 构建并推送 Docker 镜像到阿里云（Windows）

set REGISTRY=registry.cn-hangzhou.aliyuncs.com
set NAMESPACE=dejavu_ding
set IMAGE_NAME=picture-embedding
set VERSION=%1
if "%VERSION%"=="" set VERSION=latest

set FULL_IMAGE_NAME=%REGISTRY%/%NAMESPACE%/%IMAGE_NAME%:%VERSION%

echo ==========================================
echo 构建并推送 Docker 镜像
echo 镜像: %FULL_IMAGE_NAME%
echo ==========================================

echo 正在构建镜像...
docker build -t %IMAGE_NAME%:%VERSION% .
if errorlevel 1 (
    echo 构建失败！
    exit /b 1
)

echo 正在标记镜像...
docker tag %IMAGE_NAME%:%VERSION% %FULL_IMAGE_NAME%
if errorlevel 1 (
    echo 标记失败！
    exit /b 1
)

echo 正在推送镜像到阿里云...
docker push %FULL_IMAGE_NAME%
if errorlevel 1 (
    echo 推送失败！请确保已登录: docker login --username=你的用户名 %REGISTRY%
    exit /b 1
)

echo ==========================================
echo 完成！镜像已推送到: %FULL_IMAGE_NAME%
echo.
echo 测试环境部署：
echo 1. docker login --username=你的用户名 %REGISTRY%
echo 2. docker compose -f docker-compose.test.yml pull
echo 3. docker compose -f docker-compose.test.yml up -d
echo ==========================================
