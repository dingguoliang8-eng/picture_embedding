import time
from io import BytesIO

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from PIL import Image, UnidentifiedImageError
from pydantic import BaseModel, Field

from app.api.dependencies import verify_api_key
from app.core.config import settings
from app.core.logger import get_logger
from app.services import embedding_service

logger = get_logger(__name__)

router = APIRouter()


class EmbeddingResponse(BaseModel):
    model_name: str = Field(..., description="使用的预训练模型 id")
    dimension: int = Field(..., description="向量维度")
    smart_crop: bool = Field(..., description="是否经过 rembg 智能裁剪（与 popup_book_dinov3 一致）")
    vector: list[float] = Field(..., description="L2 未归一化的特征向量（可按需自行归一化）")


@router.post(
    "/embed",
    summary="图片 embedding",
    response_model=EmbeddingResponse,
    dependencies=[Depends(verify_api_key)],
)
async def embed_image(
    file: UploadFile = File(..., description="图片文件，支持常见格式"),
    smart_crop: bool = Query(
        None,
        description="是否去背景后按 bbox 裁剪；不传则使用配置 default_smart_crop",
    ),
):
    start = time.time()
    logger.start("图片 embedding 请求")
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="请上传 image/* 类型文件")

    raw = await file.read()
    if not raw:
        raise HTTPException(status_code=400, detail="空文件")

    try:
        image = Image.open(BytesIO(raw))
        image.load()
    except UnidentifiedImageError:
        raise HTTPException(status_code=400, detail="无法识别的图片格式")

    use_crop = settings.default_smart_crop if smart_crop is None else smart_crop
    try:
        vector = embedding_service.embed_pil(image, smart_crop=use_crop)
    except Exception as e:
        logger.error(f"embedding 失败: {e}")
        raise HTTPException(status_code=500, detail=f"embedding 失败: {e}") from e

    dim = len(vector)
    elapsed = time.time() - start
    logger.complete("图片 embedding", elapsed)
    return EmbeddingResponse(
        model_name=settings.model_name,
        dimension=dim,
        smart_crop=use_crop,
        vector=vector,
    )
