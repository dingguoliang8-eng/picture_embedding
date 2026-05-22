#!/bin/sh
# 输出 cpu 或 cuda，供 build-and-push 与 docker build --build-arg 使用
# 可覆盖：TORCH_DEVICE=cpu|cuda TORCH_CUDA=cu124（cuda 时 PyTorch wheel 索引后缀）

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
  TORCH_CUDA=cu124
fi

echo "${TORCH_DEVICE}"
