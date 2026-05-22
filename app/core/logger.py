"""日志（对齐 voiceprint-api 风格）。"""

import logging
import os
import sys
import warnings
from typing import Optional

from loguru import logger

from .config import settings
from .version import VERSION

logger.remove()


class LoggingHandler(logging.Handler):
    def emit(self, record):
        try:
            level = logger.level(record.levelname).name
        except ValueError:
            level = record.levelno
        logger_name = record.name
        if logger_name.startswith("uvicorn"):
            logger_name = "uvicorn"
        elif logger_name.startswith("fastapi"):
            logger_name = "fastapi"
        elif logger_name.startswith("modelscope"):
            logger_name = "modelscope"
        elif logger_name.startswith("torch"):
            logger_name = "torch"
        logger.opt(exception=record.exc_info).bind(name=logger_name, version=VERSION).log(
            level, record.getMessage()
        )


def setup_logging(level: Optional[str] = None) -> None:
    log_level = level or settings.logging.get("level", "INFO")
    log_dir = "logs"
    os.makedirs(log_dir, exist_ok=True)

    console_format = (
        "<cyan>{time:YYMMDD HH:mm:ss}</cyan>"
        "<blue>[{extra[version]}]</blue>"
        "<light-black>[{name}]</light-black>-"
        "<level>{level}</level>-"
        "<green>{message}</green>"
    )
    file_format = (
        "{time:YYMMDD HH:mm:ss}" "[{extra[version]}]" "[{name}]-" "{level}-" "{message}"
    )

    logger.add(
        sys.stdout,
        format=console_format,
        level=log_level,
        colorize=True,
        backtrace=True,
        diagnose=True,
        enqueue=True,
    )
    logger.add(
        os.path.join(log_dir, "picture_embedding_api.log"),
        format=file_format,
        level=log_level,
        rotation="10 MB",
        retention="7 days",
        compression="gz",
        encoding="utf-8",
        backtrace=True,
        diagnose=True,
        enqueue=True,
    )

    for handler in logging.root.handlers[:]:
        logging.root.removeHandler(handler)
    logging.basicConfig(handlers=[LoggingHandler()], level=0, force=True)
    intercept_handler = LoggingHandler()
    for name in logging.root.manager.loggerDict:
        log = logging.getLogger(name)
        for h in log.handlers[:]:
            log.removeHandler(h)
        log.addHandler(intercept_handler)
        log.propagate = False

    logger.bind(version=VERSION).info(f"日志初始化完成，级别: {log_level}")


class Logger:
    def __init__(self, name: str):
        self._logger = logger.bind(name=name, version=VERSION)

    def debug(self, message: str, *args, **kwargs):
        self._logger.debug(message, *args, **kwargs)

    def info(self, message: str, *args, **kwargs):
        self._logger.info(message, *args, **kwargs)

    def warning(self, message: str, *args, **kwargs):
        self._logger.warning(message, *args, **kwargs)

    def error(self, message: str, *args, **kwargs):
        self._logger.error(message, *args, **kwargs)

    def fail(self, message: str, *args, **kwargs):
        self._logger.error(f"❌ {message}", *args, **kwargs)

    def start(self, operation: str, *args, **kwargs):
        self._logger.info(f"🚀 开始: {operation}", *args, **kwargs)

    def complete(self, operation: str, duration: Optional[float] = None, *args, **kwargs):
        if duration is not None:
            self._logger.info(f"✅ 完成: {operation} (耗时: {duration:.3f}秒)", *args, **kwargs)
        else:
            self._logger.info(f"✅ 完成: {operation}", *args, **kwargs)


def get_logger(name: str) -> Logger:
    return Logger(name)
