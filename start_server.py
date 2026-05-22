#!/usr/bin/env python3
"""生产环境启动（与 voiceprint-api/start_server.py 对齐）。"""

from app.core.logger import setup_logging, get_logger

setup_logging()

import signal
import sys
from pathlib import Path

import uvicorn

project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from app.core.config import settings

logger = get_logger(__name__)


def signal_handler(signum, frame):
    logger.info(f"收到信号 {signum}，退出")
    sys.exit(0)


def main():
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    logger.start(f"生产环境启动 {settings.host}:{settings.port}")
    uvicorn.run(
        "app.application:app",
        host=settings.host,
        port=settings.port,
        reload=False,
        workers=1,
        access_log=False,
        log_level="info",
        timeout_keep_alive=30,
        timeout_graceful_shutdown=300,
        limit_concurrency=1000,
        limit_max_requests=1000,
        backlog=2048,
    )


if __name__ == "__main__":
    main()
