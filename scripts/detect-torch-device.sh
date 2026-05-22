#!/bin/sh
# 输出 cpu 或 cuda，供宿主机排查 PyTorch 设备（镜像构建已不再区分 cpu/gpu）
# 可覆盖：TORCH_DEVICE=cpu|cuda

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

echo "${TORCH_DEVICE}"
