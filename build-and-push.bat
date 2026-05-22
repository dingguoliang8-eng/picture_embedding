@echo off
setlocal EnableDelayedExpansion

set REGISTRY=crpi-pfk0ggqf1mx18vfr.cn-shanghai.personal.cr.aliyuncs.com
set NAMESPACE=whalesbot
set IMAGE_NAME=whalesbot-ai-platform
set VERSION=%1
if "%VERSION%"=="" set VERSION=latest
set TORCH_CUDA=cu124
if not defined TORCH_CUDA set TORCH_CUDA=cu124

if defined TORCH_DEVICE (
  set DEVICE=%TORCH_DEVICE%
) else (
  where nvidia-smi >nul 2>&1
  if !errorlevel! equ 0 (
    nvidia-smi >nul 2>&1
    if !errorlevel! equ 0 (
      set DEVICE=cuda
      echo 检测到 NVIDIA GPU，构建 CUDA 版
    ) else (
      set DEVICE=cpu
      echo 未检测到 GPU，构建 CPU 版
    )
  ) else (
    set DEVICE=cpu
    echo 未检测到 GPU，构建 CPU 版
  )
)

set IMAGE_TAG=picture-embedding-%VERSION%-%DEVICE%
set LOCAL_IMAGE=picture-embedding:%VERSION%-%DEVICE%
set FULL_IMAGE_NAME=%REGISTRY%/%NAMESPACE%/%IMAGE_NAME%:%IMAGE_TAG%

echo ==========================================
echo PyTorch: %DEVICE%  远程: %FULL_IMAGE_NAME%
echo ==========================================

docker build --build-arg TORCH_DEVICE=%DEVICE% --build-arg TORCH_CUDA=%TORCH_CUDA% -t %LOCAL_IMAGE% .
if errorlevel 1 exit /b 1

docker tag %LOCAL_IMAGE% %FULL_IMAGE_NAME%
if errorlevel 1 exit /b 1

docker push %FULL_IMAGE_NAME%
if errorlevel 1 (
    echo 推送失败: docker login --username=leocao0828 %REGISTRY%
    exit /b 1
)

echo 完成: %FULL_IMAGE_NAME%
echo 强制 CPU: set TORCH_DEVICE=cpu ^& %0 %VERSION%
echo 强制 GPU: set TORCH_DEVICE=cuda ^& %0 %VERSION%
