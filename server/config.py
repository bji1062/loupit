"""SP-API-2 환경설정 — DB·CORS·캐시 TTL + SC14 참여(메일·세션·pepper) 키를 정의한다.

익명 읽기 배포는 DB·CORS·캐시 키만 쓴다. **SC14 참여(SP-AUTH-2)**는 메일러(SMTP)·세션/코드
TTL·시도 상한·비밀 pepper 키를 추가한다(기본값은 실발송 없는 안전값 — 미설정이면 ConsoleMailer
폴백). JWT·OAuth·비밀번호·소셜 키는 **영구 정의 금지**(SC10·NFR16) — 어떤 필드명도
`jwt·oauth·password_reset·social` 부분문자열을 포함하지 않는다(T10, test_config).
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
    cors_allow_origins: str = "https://jobcho.wiki,https://www.jobcho.wiki"

    # 참조 번들 캐시
    reference_cache_ttl: int = 3600  # 인메모리 TTL(초). Cache-Control max-age와 동일값
    reference_cache_control: str = "public, max-age=3600"  # FR-92 명시값(브리프 §6)

    # 실시간 비교 TOP 10 트렌딩 (INV-1 개정 2026-07-14)
    trending_cache_ttl: int = 60  # 인메모리 TTL(초). max-age와 동일값
    trending_cache_control: str = "public, max-age=60"
    trending_window_days: int = 7  # 집계 윈도우(일)
    trending_limit: int = 10  # 상위 N

    # TCOMPARE_LOG 보존 퍼지 (#7b 남용 방어 — 무인증 익명 로그 무한 증가 차단).
    # 트렌딩 윈도우(7일)를 훨씬 넘는 여유 배수만 보관하고 그 이전 행은 일 1회 삭제한다.
    # 소비 쿼리는 최근 7일만 읽으므로(trending.py) 이보다 오래된 행은 어떤 응답에도
    # 쓰이지 않는다. 삭제는 배치 LIMIT 루프로 장기 락을 피한다(database.purge_compare_log).
    compare_log_retention_days: int = 30  # 보관 일수(윈도우 7일의 여유 배수)
    compare_log_purge_batch: int = 5000  # 1회 DELETE 상한(락 시간 억제)
    compare_log_purge_interval_seconds: int = 86400  # 퍼지 주기(일 1회)

    # ── SC14 참여(로그인·재직인증·복지편집) — SP-AUTH-2 ─────────────────────────────────
    # 익명 배포엔 부재(값은 안전 기본), SC14 기여 배포 시 server/.env 로 주입한다(SP-INFRA §7).
    # 어떤 필드명도 금지 substring(jwt·oauth·password_reset·social)을 포함하지 않는다(T10).

    # 메일러 (SP-AUTH-11): mailer_mode=smtp 이되 smtp_user 미설정이면 ConsoleMailer 폴백(실발송 방지)
    mailer_mode: str = "console"  # ∈ {console, smtp}
    smtp_host: str = ""  # 예: smtp.naver.com
    smtp_port: int = 587
    smtp_user: str = ""  # 비면 smtp 모드라도 console 폴백
    smtp_pass: str = ""
    smtp_from: str = ""  # 발신 주소(표시명 포함 가능)

    # 세션·코드 TTL·시도 상한 (SP-AUTH-4·5·12, FR-101·112)
    session_ttl_days: int = 30  # 세션 만료(FR-101)
    login_code_ttl_min: int = 5  # 로그인/인증 코드 만료(FR-102·105, NFR31). 5분(2026-07-24, 사용자 결정: 10분은 김)
    code_max_attempts: int = 5  # 코드 검증 시도 상한(FR-112, NFR31)
    mail_resend_cooldown_sec: int = 60  # 재전송 쿨다운(FR-112)
    daily_edit_limit: int = 30  # 계정·회사당 일일 복지 편집 상한(FR-108·112)
    employ_vrf_ttl_days: int = 365  # 재직 인증 만료(FR-106)

    # 비밀 pepper (SP-AUTH-4·7, NFR30) — 로그 금지
    session_hash_pepper: str = ""  # 세션 토큰 SHA-256 pepper(선택·48바이트 고엔트로피라 무키도 안전)
    comp_email_hmac_pepper: str = ""  # 회사 이메일 HMAC 키(재직 인증 필수 — 미설정 시 재직 경로 기동 실패, SP-AUTH-7)
    login_code_hmac_pepper: str = ""  # 로그인 코드 HMAC 키(보안강화, 보안점검 2026-07-23). 6자리 코드는 저엔트로피(10^6)라 무키 해시는 DB 유출 시 오프라인 무차별로 복원됨 → 운영 필수 주입

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_allow_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
