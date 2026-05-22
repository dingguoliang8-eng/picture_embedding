from app.core.logger import get_logger, setup_logging

setup_logging()

import uvicorn

from app.core.config import settings

logger = get_logger(__name__)


if __name__ == "__main__":
    logger.start(f"开发环境启动 {settings.host}:{settings.port}")
    logger.info(f"文档: http://{settings.host}:{settings.port}/picture-embedding/docs")
    uvicorn.run(
        "app.application:app",
        host=settings.host,
        port=settings.port,
        reload=True,
        workers=1,
        access_log=False,
        log_level="info",
    )
