"""SP-API-2 환경설정 — DB·CORS·캐시 TTL만 정의한다.

인증·메일·소셜 로그인 관련 키(JWT_SECRET·OAUTH_*·SMTP_*·세션 시크릿)는
정의하지 않는다 — 로그인/회원 기능 영구 제외(INV-1·NFR16).
"""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# server/config.py 기준 상대경로 — cwd(리포 루트/서버 기동 위치)에 무관하게
# server/.env를 항상 찾는다(SP-API-2 pseudocode의 "env_file='.env'"를 배포
# cwd 독립적으로 구현한 형태 — 임의결정, 관측 가능한 설정 계약은 동일).
_ENV_FILE = Path(__file__).resolve().parent / ".env"


class Settings(BaseSettings):
    """서버 설정. 환경변수 + server/.env에서만 로드한다."""

    model_config = SettingsConfigDict(
        env_file=str(_ENV_FILE),
        env_file_encoding="utf-8",
        env_prefix="",
        extra="ignore",
    )

    # --- DB (aiomysql) ---
    db_host: str = "127.0.0.1"
    db_port: int = 3306
    db_user: str = "loupit"
    db_password: str = ""
    db_name: str = "loupit"
    db_pool_min: int = 1
    db_pool_max: int = 10
    db_connect_timeout: int = 5  # 초

    # --- API ---
    api_prefix: str = "/api/v1"

    # CORS 허용목록 (콤마 구분). 와일드카드 '*' 금지(FR-96)
    cors_allow_origins: str = "https://loupit.co,https://www.loupit.co"

    # 참조 번들 캐시
    reference_cache_ttl: int = 3600  # 인메모리 TTL(초). Cache-Control max-age와 동일값
    reference_cache_control: str = "public, max-age=3600"  # FR-92 명시값(브리프 §6)

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_allow_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
