from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.docs import get_redoc_html, get_swagger_ui_html
from fastapi.openapi.utils import get_openapi
from fastapi.responses import RedirectResponse

from app.api.v1.api import api_router
from app.core.logger import get_logger
from app.core.version import VERSION
from app.services import embedding_service

_startup_log = get_logger(__name__)


@asynccontextmanager
async def _lifespan(app: FastAPI):
    _startup_log.info("正在预加载 DINOv3 模型（启动时加载，请求阶段复用全局实例）...")
    embedding_service.preload_model()
    _startup_log.info("DINOv3 模型预加载完成，服务就绪")
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title="Picture Embedding API",
        description="基于 DINOv3（ModelScope/HuggingFace）的图片向量服务",
        version=VERSION,
        docs_url=None,
        redoc_url=None,
        lifespan=_lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(api_router, prefix="/picture-embedding")

    @app.get("/picture-embedding/openapi.json", include_in_schema=False)
    async def custom_openapi():
        if app.openapi_schema:
            return app.openapi_schema
        app.openapi_schema = get_openapi(
            title=app.title,
            version=app.version,
            description=app.description,
            routes=app.routes,
        )
        return app.openapi_schema

    @app.get("/picture-embedding/docs", include_in_schema=False)
    async def custom_swagger_ui_html():
        return get_swagger_ui_html(
            openapi_url="/picture-embedding/openapi.json",
            title=app.title + " - Swagger UI",
            swagger_js_url="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui-bundle.js",
            swagger_css_url="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui.css",
        )

    @app.get("/picture-embedding/redoc", include_in_schema=False)
    async def custom_redoc_html():
        return get_redoc_html(
            openapi_url="/picture-embedding/openapi.json",
            title=app.title + " - ReDoc",
            redoc_js_url="https://cdn.jsdelivr.net/npm/redoc@2.1.3/bundles/redoc.standalone.js",
        )

    @app.get("/", include_in_schema=False)
    def root():
        return RedirectResponse(url="/picture-embedding/docs")

    @app.get("/picture-embedding/", include_in_schema=False)
    def pe_root():
        return RedirectResponse(url="/picture-embedding/docs")

    return app


app = create_app()
