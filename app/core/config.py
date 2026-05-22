import logging
from pathlib import Path
from typing import Any, Dict

import yaml

logger = logging.getLogger(__name__)


class Settings:
    """应用配置：优先读取 data/.picture_embedding.yaml。"""

    def __init__(self) -> None:
        self._config = self._load_config()

    def _load_config(self) -> Dict[str, Any]:
        config_path = Path("../data/.picture_embedding.yaml")
        if not config_path.exists():
            logger.error("配置文件 data/.picture_embedding.yaml 未找到，请先复制 picture_embedding.yaml。")
            raise RuntimeError("请先配置 data/.picture_embedding.yaml（可参考项目根目录 picture_embedding.yaml）")

        with open(config_path, "r", encoding="utf-8") as f:
            config = yaml.safe_load(f) or {}

        if "server" not in config:
            config["server"] = {}

        return config

    @property
    def server(self) -> Dict[str, Any]:
        return self._config.get("server", {})

    @property
    def embedding(self) -> Dict[str, Any]:
        return self._config.get("embedding", {})

    @property
    def logging(self) -> Dict[str, Any]:
        return self._config.get("logging", {})

    @property
    def host(self) -> str:
        return str(self.server.get("host", "0.0.0.0"))

    @property
    def port(self) -> int:
        return int(self.server.get("port", 8010))

    @property
    def api_key(self) -> str:
        """请求头鉴权用；配置为空字符串则关闭鉴权（仅建议内网/开发）。"""
        v = self.server.get("apikey", "")
        return str(v).strip() if v is not None else ""

    @property
    def model_name(self) -> str:
        return str(
            self.embedding.get(
                "model_name",
                "facebook/dinov3-vitl16-pretrain-lvd1689m",
            )
        )

    @property
    def models_dir(self) -> str:
        return str(self.embedding.get("models_dir", "models"))

    @property
    def default_smart_crop(self) -> bool:
        return bool(self.embedding.get("default_smart_crop", False))


settings = Settings()
