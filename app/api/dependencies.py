from typing import Optional

from fastapi import HTTPException, Request, Security
from fastapi.security import APIKeyHeader

from app.core.config import settings

api_key_header = APIKeyHeader(name="X-Api-Key", auto_error=False)


async def verify_api_key(
    request: Request,
    x_api_key: Optional[str] = Security(api_key_header),
) -> None:
    """当配置 server.apikey 非空时，要求请求头 X-Api-Key 或 apikey 与之一致。"""
    expected = settings.api_key
    if not expected:
        return
    provided = (x_api_key or request.headers.get("apikey") or "").strip()
    if provided != expected:
        raise HTTPException(status_code=401, detail="API Key 无效或缺失")
