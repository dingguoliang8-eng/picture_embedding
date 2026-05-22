#!/bin/sh
# 输出 cpu 或 cuda，供手动 docker build --build-arg 使用
# build-and-push.sh 已固定一次构建 cpu+gpu 双镜像，通常无需本脚本
# 可覆盖：TORCH_DEVICE=cpu|cuda TORCH_CUDA=cu126（CUDA 12.6，PyTorch wheel 索引后缀）

if [ -n "${TORCH_DEVICE}" ]; then
  case "${TORCH_DEVICE}" in
    cpu|cuda) ;;
    *)
      echo "无效 TORCH_DEVICE=${TORCH_DEVICE}，应为 cpu 或 cuda" >&2
      exit 1
      ;;
  esac
else
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    TORCH_DEVICE=cuda
  else
    TORCH_DEVICE=cpu
  fi
fi

if [ "${TORCH_DEVICE}" = "cuda" ] && [ -z "${TORCH_CUDA}" ]; then
  TORCH_CUDA=cu126
fi

echo "${TORCH_DEVICE}"
