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

    # M9 활성화 마스터 스위치 (2026-07-27). **기본 OFF** — 이 플래그 하나가
    #   (A) 참여 라우터 3종 등록(main.create_app) · (B) 세션·코드 retention purge ·
    #   (C) 정책 페이지 문안(개인정보 P7·약관 T5, generator/content/policy.py)
    # 을 **동시에** 뒤집는다. (C)가 같은 스위치인 것이 핵심이다: 라이브 `/privacy` 는 지금
    # "회원가입·로그인·계정 기능이 없습니다 … 이메일을 수집·저장하지 않습니다" 라고 선언하므로,
    # 로그인 배포와 문안 전환이 어긋나면 어느 방향이든 처리방침이 허위 기재가 된다.
    #
    # 기본을 OFF 로 둔 이유(재시작 함정): 라우터 등록이 무조건이던 판본에서 프로덕션이 inert 했던
    # 유일한 근거는 `loupit-api` 가 SC14 코드 이전에 기동돼 아직 안 죽었다는 것뿐이었다 — 재부팅
    # 한 번이면 참여 테이블 0/7 인 스키마 위에서 M9 표면이 켜졌다. `release.sh` 의 M9 활성화
    # 가드는 릴리스 경로만 덮는다(test_m9_gate).
    #
    # 배포별: prod `server/.env` = 키 부재(OFF) · beta `server/.env.beta` = `M9_ENABLED=1` ·
    # 테스트 = conftest 가 세션 전역으로 1 주입(베이스 게이트는 ON 표면을 계약으로 가짐).
    m9_enabled: bool = False

    # 메일러 (SP-AUTH-11): mailer_mode=smtp 이되 smtp_user 미설정이면 ConsoleMailer 폴백(실발송 방지)
    mailer_mode: str = "console"  # ∈ {console, smtp}
    smtp_host: str = ""  # 예: smtp.naver.com
    smtp_port: int = 587
    smtp_user: str = ""  # 비면 smtp 모드라도 console 폴백
    smtp_pass: str = ""
    smtp_from: str = ""  # 발신 주소(표시명 포함 가능)

    # 운영자 큐 일일 요약 수신 주소(`ops digest --send`). 비면 발송이 **명시적으로 실패**한다 —
    # 조용히 넘어가면 "알림이 있다"고 믿게 된다. 요약은 건수·ID 만 담고 사용자 입력은 담지 않는다.
    ops_digest_to: str = ""

    # 운영 콘솔 권한 화이트리스트 (SP-AUTH-19, 2026-07-30) — 쉼표 구분 이메일.
    #
    # **비어 있으면 콘솔 라우터를 등록하지 않는다**(fail-closed, 웹훅 시크릿과 같은 규약).
    # 표면 변화가 **명시적 설정**에만 따라오게 만든 것이다 — 이 키를 넣기 전까지 API 표면은
    # 그대로다.
    #
    # 왜 DB 컬럼이 아니라 `.env` 인가: 운영자 1명엔 이게 최적이다. DB 변경이 0이고, **바꾸려면
    # 서버 접근이 필요하다는 사실 자체가 방어**다. `TMEMBER` 에 권한 컬럼을 넣으면 가입 경로와
    # 권한 경로가 한 테이블을 공유해 실수 하나가 권한 상승이 된다. 운영자가 늘면 `TOPERATOR` 로.
    operator_emails: str = ""

    # 세션·코드 TTL·시도 상한 (SP-AUTH-4·5·12, FR-101·112)
    session_ttl_days: int = 30  # 세션 만료(FR-101)
    login_code_ttl_min: int = 5  # 로그인/인증 코드 만료(FR-102·105, NFR31). 5분(2026-07-24, 사용자 결정: 10분은 김)
    code_max_attempts: int = 5  # 코드 검증 시도 상한(FR-112, NFR31)
    mail_resend_cooldown_sec: int = 60  # 재전송 쿨다운(FR-112)
    daily_edit_limit: int = 30  # 계정·회사당 일일 복지 편집 상한(FR-108·112)

    # 배달주소 기준 발송 백오프 (P1-3, SP-AUTH-18 — 2026-07-30)
    #
    # 쿨다운은 창당 1통을 허용하므로 한 수신함 기준 `86400/60` = 1,440통/일이 가능했다.
    # 여기서 하는 일은 **누적 발송량에 따라 쿨다운을 지수적으로 늘리는 것**이다. 하드 상한을
    # 쓰지 않는 이유는 그것이 "제3자가 피해자의 예산을 태워 하루 종일 로그인을 막는" 반대 방향
    # 사고를 만들기 때문이다(auth_code.effective_cooldown_sec 주석에 근거 전문).
    mail_burst_free_sends: int = 5  # 이 횟수까지는 주소 단위 추가 제약 없음 — 용도별 쿨다운만 적용(현행 동작 그대로)
    mail_cooldown_max_sec: int = 3600  # 백오프 상한. **정당한 사용자가 겪을 최대 대기**이기도 하다 — 올릴 때 그 대가를 같이 보라
    mail_rate_window_hours: int = 24  # SENT_CNT 를 되감는 롤링 창(첫 발송 기준. UTC 자정 정렬 아님)
    mail_rate_retention_days: int = 7  # TMAIL_SEND_RATE 행 보존 — 창(24h)보다 길어야 백오프가 퍼지로 사라지지 않는다
    employ_vrf_ttl_days: int = 365  # 재직 인증 만료(FR-106)

    # 비밀 pepper (SP-AUTH-4·7, NFR30) — 로그 금지
    session_hash_pepper: str = ""  # 세션 토큰 SHA-256 pepper(선택·48바이트 고엔트로피라 무키도 안전)
    comp_email_hmac_pepper: str = ""  # 회사 이메일 HMAC 키(재직 인증 필수 — 미설정 시 재직 경로 기동 실패, SP-AUTH-7)
    login_code_hmac_pepper: str = ""  # 로그인 코드 HMAC 키(보안강화, 보안점검 2026-07-23). 6자리 코드는 저엔트로피(10^6)라 무키 해시는 DB 유출 시 오프라인 무차별로 복원됨 → 운영 필수 주입

    # 메일 배달 결과 웹훅 (SP-AUTH-16, P1-4 — 2026-07-29)
    #
    # Resend(Svix) 웹훅 서명 시크릿. **비어 있으면 웹훅 라우터를 등록하지 않는다**(fail-closed,
    # main.create_app). 이 엔드포인트는 바운스를 받으면 그 주소의 메일 발송을 막으므로, 검증
    # 불가 상태로 열려 있으면 위조 이벤트 하나로 임의 주소의 로그인을 영구 차단할 수 있다.
    # 값은 Resend 대시보드에서 웹훅을 만들 때 발급된다(`whsec_…`). M9 스위치와 무관하다 —
    # 지금 실발송은 beta 지만 발신 도메인·무료 티어를 공유하므로 억제 목록은 prod 에 모은다.
    resend_webhook_secret: str = ""

    # DART(금융감독원 전자공시) OpenAPI 인증키 (SP-FIN-3, 2026-08-27) — 로그 금지.
    # 회사 재무 수집기(`db/seed/dart_finance.py`)만 읽는다. **비어 있으면 수집기가 즉시 실패**한다 —
    # 조용한 0건은 "수집했는데 없더라"로 읽혀 실적 섹션이 에러 없이 통째로 빠진다(함정 (57)).
    # 발급: opendart.fss.or.kr(무료, 일 20,000회). 런타임 API 는 이 키를 쓰지 않는다.
    dart_api_key: str = ""

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_allow_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
