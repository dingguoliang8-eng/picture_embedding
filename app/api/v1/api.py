from fastapi import APIRouter

from app.api.v1 import embedding

api_router = APIRouter()
api_router.include_router(embedding.router, tags=["图片向量"])
