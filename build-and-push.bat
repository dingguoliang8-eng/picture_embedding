@echo off
setlocal EnableDelayedExpansion

set REGISTRY=crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com
set NAMESPACE=whalesbot
set IMAGE_NAME=whalesbot-ai-platform
set VERSION=%1
if "%VERSION%"=="" set VERSION=latest
if not defined TORCH_CUDA set TORCH_CUDA=cu124

echo ==========================================
echo picture-embedding 双镜像构建 cpu + gpu
echo 版本: %VERSION%
echo ==========================================

call :build_and_push cpu
if errorlevel 1 exit /b 1
call :build_and_push cuda
if errorlevel 1 exit /b 1

echo.
echo 完成:
echo   .../picture-embedding-%VERSION%-cpu
echo   .../picture-embedding-%VERSION%-gpu
exit /b 0

:build_and_push
set DEVICE=%~1
set TAG=picture-embedding-%VERSION%-%DEVICE%
set LOCAL=picture-embedding:%VERSION%-%DEVICE%
set REMOTE=%REGISTRY%/%NAMESPACE%/%IMAGE_NAME%:%TAG%

echo.
echo ---------- 构建 %DEVICE% ----------
docker build --build-arg TORCH_DEVICE=%DEVICE% --build-arg TORCH_CUDA=%TORCH_CUDA% -t %LOCAL% .
if errorlevel 1 exit /b 1
docker tag %LOCAL% %REMOTE%
if errorlevel 1 exit /b 1
docker push %REMOTE%
if errorlevel 1 (
    echo 推送失败: docker login --username=leocao0828 %REGISTRY%
    exit /b 1
)
echo 已推送 %REMOTE%
exit /b 0
