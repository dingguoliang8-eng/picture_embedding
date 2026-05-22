"""

DINOv3 图片向量

"""

from __future__ import annotations
import os
import threading
from pathlib import Path
from typing import Any, List, Optional, Tuple
import numpy as np
import torch
from PIL import Image
from app.core.config import settings
from app.core.logger import get_logger

log = get_logger(__name__)

# ======================
# 模型缓存落到当前项目 models 目录（与 popup_book_dinov3 一致）
# ======================
_PROJECT_ROOT = Path(__file__).resolve().parents[2]
_MODELS_DIR = _PROJECT_ROOT / settings.models_dir
_MODELSCOPE_HUB_CACHE_DIR = _MODELS_DIR / "hub"
_HF_HOME_DIR = _MODELS_DIR / "huggingface"
_MODELSCOPE_HUB_CACHE_DIR.mkdir(parents=True, exist_ok=True)
_HF_HOME_DIR.mkdir(parents=True, exist_ok=True)
os.environ["MODELSCOPE_CACHE"] = str(_MODELSCOPE_HUB_CACHE_DIR)
os.environ.setdefault("HF_HOME", str(_HF_HOME_DIR))

from modelscope import AutoImageProcessor, AutoModel

# ======================
# 全局单例
# ======================
_lock = threading.Lock()
_bundle: Optional[Tuple[Any, Any]] = None
_PRETRAINED_MODEL_NAME = settings.model_name

# ======================
# DINOv3 加载
# ======================
def _load_model() -> Tuple[Any, Any]:
    processor = AutoImageProcessor.from_pretrained(_PRETRAINED_MODEL_NAME)
    model = AutoModel.from_pretrained(
        _PRETRAINED_MODEL_NAME,
        device_map="auto",
    )
    model.eval()
    log.info(f"DINOv3 模型已加载: {_PRETRAINED_MODEL_NAME}, device={model.device}")
    return processor, model


def _ensure_model() -> Tuple[Any, Any]:
    global _bundle
    with _lock:
        if _bundle is None:
            _bundle = _load_model()
        return _bundle

def _smart_crop(img: Image.Image) -> Image.Image:
    from rembg import remove
    img_no_bg = remove(img)
    bbox = img_no_bg.getbbox()
    if bbox:
        img = img_no_bg.crop(bbox)
    return img.convert("RGB")


def _prepare_image(image: Image.Image, smart_crop: bool) -> Image.Image:
    img = image.convert("RGB")
    if smart_crop:
        return _smart_crop(img)
    return img


def get_feature(processor, model, img: Image.Image) -> torch.Tensor:
    """DINOv3：取序列第 0 位 [CLS] 全局特征并 L2 归一化（余弦相似度前置）。"""
    inputs = processor(images=img, return_tensors="pt").to(model.device)
    with torch.inference_mode():
        outputs = model(**inputs)
    # [batch, seq_len, hidden] -> [batch, hidden]
    feat = outputs.last_hidden_state[:, 0, :]
    feat = torch.nn.functional.normalize(feat, dim=1)
    return feat


def _extract_feature(processor, model, img: Image.Image) -> torch.Tensor:
    return get_feature(processor, model, img)


def embed_pil(image: Image.Image, smart_crop: Optional[bool] = None) -> List[float]:
    if smart_crop is None:
        smart_crop = settings.default_smart_crop
    processor, model = _ensure_model()
    pil = _prepare_image(image, smart_crop)
    feat = _extract_feature(processor, model, pil)
    vec = feat.detach().float().cpu().numpy().reshape(-1)
    return [float(x) for x in vec.tolist()]



def preload_model() -> None:
    """应用启动时预加载（对应 popup_book_dinov3.preload_popup_book_dinov3）。"""
    _ensure_model()


def cosine_similarity(a: List[float], b: List[float]) -> float:
    va = np.asarray(a, dtype=np.float64)
    vb = np.asarray(b, dtype=np.float64)
    na = np.linalg.norm(va)
    nb = np.linalg.norm(vb)
    if na == 0 or nb == 0:
        return 0.0
    return float(np.dot(va, vb) / (na * nb))