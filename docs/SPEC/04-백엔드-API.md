# SPEC 04 — 백엔드 API (FastAPI)

**영역 ID 대역**: `SP-API`
**저장 경로**: `docs/SPEC/04-백엔드-API.md`
**목적**: loupit 슬림 **읽기 전용 FastAPI** 서버(C3, `server/`)의 구현 계약을 개발자가 추측 없이 그대로 만들 수 있는 수준으로 확정한다. (1) 모듈/패키지 구조(`main`/`config`/`database`/`routers`/`services`/`models`/`cache`), (2) GET 4종 엔드포인트의 요청·응답 Pydantic 모델·상태코드·오류 형태, (3) aiomysql 풀 + 원시 SQL(`%s` 플레이스홀더), (4) 인메모리 TTL 캐시, (5) 인증·쓰기 미들웨어 부재 명시, (6) CORS·전송 헤더·캐시 정책, (7) pytest + httpx(ASGITransport) 테스트 명세를 소유한다.

**상위 추적**: CONTEXT_BRIEF §6(읽기 전용 API 표면)·§2-1·§2-4(무인증·무쓰기)·§8(스택), FRD `11-API.md`(**FR-90~FR-96** 전송 계약), FRD `02-데이터-계약.md`(**FR-D1~FR-D11** 본문 스키마), FRD `12-오류-엣지.md`(**FR-E1·FR-E2·FR-E6** 실패 처리), SPEC `01-개요와-아키텍처.md`(**SP-ARCH-1·4·5·6·7·10** 컴포넌트·번들 단일 소스·디렉토리·버전·불변식), SPEC `02-데이터베이스-스키마.md`(**SP-DB-2~9** 테이블·컬럼·`AMT_SOURCE_CD`↔`amt_source` 필드맵). 하위 TASK 문서는 `SP-API-N` ID를 인용한다.

**범위 경계**: 본 문서는 **런타임 읽기 전용 HTTP 서버**만 소유한다. DB DDL·제약은 SP-DB, 96개 시드 재이식은 SP-SEED, 정적 생성기(빌드타임 `build_reference_bundle` 소비)는 SP-GEN, 클라이언트 계산·`value_source` 프로버넌스·밴드 산정은 SP-CALC/SP-FE가 소유한다. **번들 빌더 함수(`services/reference.py::build_reference_bundle`)는 런타임 API와 빌드타임 generator가 공유하는 단일 소스**(SP-ARCH-4)이며 본 문서가 그 원시 SQL·조립 계약을 확정한다. 로그인/회원/프로파일러/서버측 사용자 쓰기는 영구 제외이며 본 서버 어디에도 등장하지 않는다(§2-1·§2-3·§2-4, NFR16·NFR20).

**전역 불변식(SP-ARCH-10 상속)**: INV-1(API 표면 = GET 4종, 쓰기 라우트 0, 인증/세션 미들웨어 0) · INV-2(`reference/all` 최상위 3키·프로파일러 키 부재·`Cache-Control: public, max-age=3600`) · INV-5(밴드는 `amt_source` 기준, 서버는 근거 필드만 전달).

---

## SP-API-1 — 패키지·모듈 구조

`server/` 패키지는 SP-ARCH-6 레이아웃을 정본으로 하며, 본 문서는 인메모리 캐시 모듈 `cache.py`를 추가한다(SP-ARCH-6 규칙: 하위 SPEC은 파일 추가 가능, 디렉토리 경계 불변).

```
server/
├─ __init__.py
├─ main.py                 # SP-API-5  FastAPI 앱·lifespan·라우터 등록·CORS. 미들웨어 인증/세션 0
├─ config.py               # SP-API-2  환경변수(DB·CORS·캐시 TTL). JWT/OAuth/SMTP 키 없음
├─ database.py             # SP-API-3  aiomysql 풀·fetch_all/fetch_one (DictCursor·%s). 쓰기 헬퍼 미제공
├─ cache.py                # SP-API-4  인메모리 TTL 캐시(TTLCache)
├─ routers/
│  ├─ __init__.py
│  ├─ health.py            # SP-API-8   GET /health              (FR-91)
│  ├─ reference.py         # SP-API-9   GET /reference/all       (FR-92)
│  └─ companies.py         # SP-API-10  GET /companies/search    (FR-93)
│                          # SP-API-11  GET /companies/{comp_id} (FR-94)
├─ services/
│  ├─ __init__.py
│  └─ reference.py         # SP-API-7  build_reference_bundle(conn)->dict  (SP-ARCH-4, generator 공유)
├─ models/
│  ├─ __init__.py
│  ├─ reference.py         # SP-API-6  CompanyType·PresetBenefit·Benefit·Company·ReferenceBundle
│  ├─ company.py           # SP-API-6  CompanySearchItem
│  └─ common.py            # SP-API-6  HealthResponse·ErrorEnvelope(문서용)
├─ tests/
│  ├─ conftest.py          # SP-API-14 ASGITransport 클라이언트·DB 계층 monkeypatch 픽스처
│  ├─ test_health.py
│  ├─ test_reference.py
│  ├─ test_search.py
│  ├─ test_company_detail.py
│  └─ test_surface.py      # 라우트 표면·CORS·메서드(INV-1)
├─ requirements.txt
└─ .env.example
```

- **레거시 델타**: `job_change/server`의 auth/oauth/profiler/comparisons/admin/landing 라우터·JWT/SMTP 설정·미들웨어를 전부 제거한 형태. `routers/`는 3파일(GET 4종)만 존재.
- **추적**: SP-ARCH-1·SP-ARCH-6, F8, FR-90, §6.

---

## SP-API-2 — 설정 (`config.py`)

환경변수만으로 구성한다(`python-dotenv`로 `.env` 로드). **인증·메일·소셜 키는 정의하지 않는다**(무인증, §2-1). Pydantic `BaseSettings`(pydantic-settings) 또는 단순 dataclass 중 하나. 본 SPEC은 `pydantic-settings` 기준.

```python
# server/config.py
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_prefix="", extra="ignore")

    # DB (aiomysql)
    db_host: str = "127.0.0.1"
    db_port: int = 3306
    db_user: str = "loupit"
    db_password: str = ""
    db_name: str = "loupit"
    db_pool_min: int = 1
    db_pool_max: int = 10
    db_connect_timeout: int = 5          # 초

    # API
    api_prefix: str = "/api/v1"

    # CORS 허용목록 (콤마 구분). 와일드카드 '*' 금지(FR-96)
    cors_allow_origins: str = "https://jobcho.wiki,https://www.jobcho.wiki"

    # 참조 번들 캐시
    reference_cache_ttl: int = 3600      # 인메모리 TTL(초). Cache-Control max-age와 동일값
    reference_cache_control: str = "public, max-age=3600"   # FR-92 명시값(브리프 §6)

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_allow_origins.split(",") if o.strip()]

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

**설정 키 표**:

| 키 | 기본값 | 용도 | 근거 |
|----|--------|------|------|
| `DB_HOST`/`DB_PORT` | `127.0.0.1`/`3306` | loopback MySQL(비공개) | SP-ARCH-2 |
| `DB_USER`/`DB_PASSWORD`/`DB_NAME` | `loupit`/``/`loupit` | 읽기 전용 계정 권장(SELECT만) | NFR22 |
| `DB_POOL_MIN`/`DB_POOL_MAX` | `1`/`10` | aiomysql 풀 크기 | SP-API-3 |
| `API_PREFIX` | `/api/v1` | 버전 접두 | FR-90·§6 |
| `CORS_ALLOW_ORIGINS` | `https://jobcho.wiki,https://www.jobcho.wiki` | 허용목록(콤마) | FR-96 |
| `REFERENCE_CACHE_TTL` | `3600` | 서버 인메모리 캐시 TTL | SP-API-4 |
| `REFERENCE_CACHE_CONTROL` | `public, max-age=3600` | `reference/all`·`companies/{id}` 헤더 | FR-92·FR-96 |

- **부재 키(정의 금지)**: `JWT_SECRET`·`OAUTH_*`·`SMTP_*`·세션/쿠키 시크릿 — 회원/로그인 부재(NFR16). `.env.example`에도 미포함.
- **추적**: SP-ARCH-7, §8, FR-96, NFR16·NFR22.

---

## SP-API-3 — DB 접근 계층 (`database.py`)

aiomysql 풀 + 원시 SQL. **모든 파라미터는 `%s` 플레이스홀더**로 바인딩하고 문자열 결합을 금지한다(주입 방지, FR-93 규칙2). `DictCursor`로 dict 행을 반환한다. **읽기 헬퍼만 제공하며 execute/commit(쓰기) 헬퍼는 두지 않는다**(NFR20).

```python
# server/database.py
import aiomysql
from server.config import get_settings

_pool: aiomysql.Pool | None = None

async def init_pool() -> aiomysql.Pool:
    global _pool
    s = get_settings()
    _pool = await aiomysql.create_pool(
        host=s.db_host, port=s.db_port,
        user=s.db_user, password=s.db_password, db=s.db_name,
        minsize=s.db_pool_min, maxsize=s.db_pool_max,
        connect_timeout=s.db_connect_timeout,
        charset="utf8mb4", autocommit=True,      # 읽기 전용 → 트랜잭션 불필요
        cursorclass=aiomysql.DictCursor,
    )
    return _pool

async def close_pool() -> None:
    global _pool
    if _pool is not None:
        _pool.close()
        await _pool.wait_closed()
        _pool = None

def get_pool() -> aiomysql.Pool:
    assert _pool is not None, "pool not initialized (lifespan 미기동)"
    return _pool

async def fetch_all(sql: str, params: tuple = ()) -> list[dict]:
    async with _pool.acquire() as conn:
        async with conn.cursor() as cur:      # DictCursor
            await cur.execute(sql, params)    # %s 바인딩
            return await cur.fetchall()

async def fetch_one(sql: str, params: tuple = ()) -> dict | None:
    async with _pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(sql, params)
            return await cur.fetchone()

async def ping() -> bool:                      # health 레디니스 확장용(SP-API-8)
    try:
        row = await fetch_one("SELECT 1 AS ok", ())
        return bool(row and row.get("ok") == 1)
    except Exception:
        return False
```

- `autocommit=True`: 순수 SELECT만 수행하므로 명시 트랜잭션 없음. 쓰기 API 부재로 커밋/롤백 헬퍼를 제공하지 않는다(INV-1).
- `charset="utf8mb4"`: 한국어 콘텐츠(§8, D1). `DictCursor`로 컬럼명 키 dict 반환 → 모델 매핑 단순화.
- **`WORK_STYLE_VAL`(JSON 컬럼)**: aiomysql은 JSON을 **문자열**로 반환한다. 조립 시 `json.loads`로 파싱하고 실패 시 `None` 폴백(SP-API-7).
- **추적**: SP-ARCH-7(aiomysql 0.2.0), §8, FR-93(바인딩), NFR20.

---

## SP-API-4 — 인메모리 TTL 캐시 (`cache.py`)

`reference/all` 응답을 DB 반복 조회 없이 서빙하기 위한 프로세스 로컬 캐시. **서버측 인메모리 캐시(DB 부하 흡수)** 와 **HTTP `Cache-Control`(브라우저/프록시)** 는 독립 기제이며 동일 `3600`값을 공유한다.

```python
# server/cache.py
import time
from typing import Any

class TTLCache:
    """단일 프로세스 인메모리 TTL 캐시. 쓰기 락 불필요(asyncio 단일 스레드 이벤트 루프)."""
    def __init__(self, ttl_seconds: int):
        self._ttl = ttl_seconds
        self._store: dict[str, tuple[float, Any]] = {}

    def get(self, key: str) -> Any | None:
        item = self._store.get(key)
        if item is None:
            return None
        expires_at, value = item
        if time.monotonic() >= expires_at:      # 만료 → 미스 취급
            self._store.pop(key, None)
            return None
        return value

    def set(self, key: str, value: Any) -> None:
        self._store[key] = (time.monotonic() + self._ttl, value)

    def clear(self) -> None:
        self._store.clear()
```

- 저장 대상 = `reference/all`의 **직렬화된 JSON 바이트**(재직렬화 비용 제거, SP-API-9). 키 = `"reference_all"`.
- 캐시 인스턴스는 `main.py`가 1개 생성해 `app.state.reference_cache`로 공유(SP-API-5).
- 재시드(빌드타임) 후 최대 TTL(1시간) 내 반영(D4.4). 프로세스 재기동 시 캐시 비움(콜드 스타트 = 첫 요청이 DB 조회).
- **추적**: FR-92·FR-96(캐시), NFR3, D4.4.

---

## SP-API-5 — 애플리케이션 조립 (`main.py`)

lifespan에서 풀 생성/해제, 라우터 3종 등록(접두 `/api/v1`), CORS 미들웨어(허용목록) 부착. **인증·세션 미들웨어를 추가하지 않는다**(INV-1).

```python
# server/main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from server.config import get_settings
from server.database import init_pool, close_pool
from server.cache import TTLCache
from server.routers import health, reference, companies

@asynccontextmanager
async def lifespan(app: FastAPI):
    s = get_settings()
    await init_pool()
    app.state.reference_cache = TTLCache(s.reference_cache_ttl)
    yield
    await close_pool()

def create_app() -> FastAPI:
    s = get_settings()
    app = FastAPI(title="loupit read-only API", version="1.0.0", lifespan=lifespan)

    # CORS: 허용목록만. 와일드카드+자격증명 금지. 쓰기 메서드 미포함(FR-96)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=s.cors_origin_list,
        allow_methods=["GET", "HEAD", "OPTIONS"],
        allow_headers=["*"],
        allow_credentials=False,
    )

    p = s.api_prefix
    app.include_router(health.router,    prefix=p)
    app.include_router(reference.router, prefix=p)
    app.include_router(companies.router, prefix=p)
    return app

app = create_app()
```

- **미들웨어 목록 = CORS 1종뿐**. `AuthenticationMiddleware`·`SessionMiddleware`·커스텀 인증 의존성 0(INV-1, 테스트 SP-API-14 TS-2로 강제).
- 라우터는 GET(+ 자동 HEAD/OPTIONS)만 선언. POST/PUT/PATCH/DELETE 데코레이터 0 → 등록 경로 비-GET 요청은 FastAPI가 **405 + `Allow: GET`**(FR-90/FR-95).
- 미등록 `/api/v1/*` 경로 → 기본 **404**(FR-90).
- Uvicorn 기동: `uvicorn server.main:app --host 127.0.0.1 --port 8000`(SP-ARCH-2, systemd `loupit-api.service`).
- **추적**: SP-ARCH-2·SP-ARCH-5, FR-90·FR-96, INV-1·INV-7, §6·§8.

---

## SP-API-6 — Pydantic 응답 모델 (`models/`)

§02 데이터 계약(FR-D2·D3·D4·D5·D6)과 §02 스키마(SP-DB)의 컬럼을 **JSON snake_case 필드**로 1:1 매핑한다. 감사 4종·내부 PK(`ALIAS_ID`/`PRESET_ID`/`BENEFIT_ID`)는 미노출(§02 공통 규약). Pydantic v2 기준.

### SP-API-6.1 `models/reference.py`

```python
from pydantic import BaseModel

class CompanyType(BaseModel):                 # FR-D2 / TCOMPANY_TYPE
    comp_tp_id: int
    comp_tp_cd: str                           # ∈ {large,startup,mid,foreign,public,freelance}
    comp_tp_nm: str
    growth_rate_val: float | None = None      # DECIMAL(5,4) → float
    growth_label_nm: str | None = None
    stability_score_no: int | None = None     # 1~100

class PresetBenefit(BaseModel):               # FR-D3 / TBENEFIT_PRESET (출처·만료·amt_source 없음)
    benefit_cd: str
    benefit_nm: str
    benefit_amt: int | None = None            # 만원. NULL 가능
    benefit_ctgr_cd: str                      # 9종
    badge_cd: str = "est"                     # 프리셋은 통상 est
    default_checked_yn: bool = True           # DEFAULT_CHECKED_YN → bool
    sort_order_no: int | None = None

class Benefit(BaseModel):                     # FR-D5 / TCOMPANY_BENEFIT
    benefit_cd: str
    benefit_nm: str
    benefit_amt: int | None = None            # 만원. qual_yn=true면 None
    benefit_ctgr_cd: str                      # 9종
    badge_cd: str                             # ∈ {official, est}
    amt_source: str                           # ∈ {stated, estimated, none}  ← AMT_SOURCE_CD(SP-DB-5 필드맵)
    qual_yn: bool                             # QUAL_YN → bool
    qual_desc_ctnt: str | None = None
    note_ctnt: str | None = None
    verified_dtm: str | None = None           # ISO8601 문자열
    expires_dtm: str | None = None
    badge_src_cd: str | None = None           # ∈ {scrape_official,scrape_fallback,ai_parse,manual,user_report}
    badge_src_url_ctnt: str | None = None
    sort_order_no: int | None = None

class Company(BaseModel):                     # FR-D4 / TCOMPANY (+aliases,+benefits 인라인)
    comp_id: int
    comp_eng_nm: str
    comp_nm: str
    comp_tp_cd: str                           # TCOMPANY_TYPE 조인 파생
    industry_nm: str | None = None
    logo_nm: str | None = None
    work_style_val: dict | None = None        # {remote,flex,unlimitedPTO,refreshLeave,overtime}
    careers_benefit_url: str | None = None
    aliases: list[str]                        # 회사당 ≥1
    benefits: list[Benefit]                   # 회사당 ≥1 (실복지, 비어있지 않음)

class ReferenceBundle(BaseModel):             # FR-D1 (최상위 정확히 3키)
    company_types: list[CompanyType]
    benefit_presets: dict[str, list[PresetBenefit]]   # {comp_tp_cd: [...]}
    companies: list[Company]
```

### SP-API-6.2 `models/company.py`

```python
from pydantic import BaseModel

class CompanySearchItem(BaseModel):           # FR-D6 (축소 투영 5필드)
    comp_id: int
    comp_nm: str
    comp_tp_cd: str
    industry_nm: str | None = None
    logo_nm: str | None = None
```

### SP-API-6.3 `models/common.py`

```python
from pydantic import BaseModel

class HealthResponse(BaseModel):              # FR-91
    status: str                               # "ok" | "degraded"

class ErrorEnvelope(BaseModel):               # FR-95 문서용(FastAPI 기본 {"detail": ...})
    detail: str
```

- **필드맵 예외(SP-DB-5)**: DB `AMT_SOURCE_CD` → 와이어 `amt_source`(`_CD` 탈락). SQL `SELECT`에서 `AMT_SOURCE_CD AS amt_source`로 별칭 부여해 조립하므로 별도 매핑 코드 없이 필드명이 일치한다(SP-API-7). `QUAL_YN`(BOOLEAN)·`DEFAULT_CHECKED_YN`은 MySQL이 `0/1` int로 반환 → 조립 시 `bool(...)` 강제.
- **추적**: FR-D1~D6, SP-DB-2~9, §02 부록 A.

---

## SP-API-7 — 참조 번들 빌더 (`services/reference.py`)

**단일 소스**(SP-ARCH-4): 런타임 라우터(SP-API-9)와 빌드타임 generator(C2)가 이 함수 하나를 호출한다. 원시 SQL 5회 + 파이썬 조립. **부수효과·쓰기 0**(순수 조립). 시그니처는 `conn`(획득된 aiomysql 커넥션)을 받아 재사용성 확보 — 라우터는 풀에서 커넥션을 얻어 주입한다.

```python
# server/services/reference.py
import json

_SQL_TYPES = """
  SELECT COMP_TP_ID AS comp_tp_id, COMP_TP_CD AS comp_tp_cd, COMP_TP_NM AS comp_tp_nm,
         GROWTH_RATE_VAL AS growth_rate_val, GROWTH_LABEL_NM AS growth_label_nm,
         STABILITY_SCORE_NO AS stability_score_no
    FROM TCOMPANY_TYPE ORDER BY COMP_TP_ID"""

_SQL_PRESETS = """
  SELECT t.COMP_TP_CD AS comp_tp_cd, p.BENEFIT_CD AS benefit_cd, p.BENEFIT_NM AS benefit_nm,
         p.BENEFIT_AMT AS benefit_amt, p.BENEFIT_CTGR_CD AS benefit_ctgr_cd, p.BADGE_CD AS badge_cd,
         p.DEFAULT_CHECKED_YN AS default_checked_yn, p.SORT_ORDER_NO AS sort_order_no
    FROM TBENEFIT_PRESET p JOIN TCOMPANY_TYPE t ON p.COMP_TP_ID = t.COMP_TP_ID
   ORDER BY t.COMP_TP_CD, p.SORT_ORDER_NO, p.PRESET_ID"""

_SQL_COMPANIES = """
  SELECT c.COMP_ID AS comp_id, c.COMP_ENG_NM AS comp_eng_nm, c.COMP_NM AS comp_nm,
         t.COMP_TP_CD AS comp_tp_cd, c.INDUSTRY_NM AS industry_nm, c.LOGO_NM AS logo_nm,
         c.WORK_STYLE_VAL AS work_style_val, c.CAREERS_BENEFIT_URL AS careers_benefit_url
    FROM TCOMPANY c JOIN TCOMPANY_TYPE t ON c.COMP_TP_ID = t.COMP_TP_ID
   ORDER BY c.COMP_ID"""

_SQL_ALIASES = "SELECT COMP_ID AS comp_id, ALIAS_NM AS alias_nm FROM TCOMPANY_ALIAS ORDER BY ALIAS_ID"

_SQL_BENEFITS = """
  SELECT COMP_ID AS comp_id, BENEFIT_CD AS benefit_cd, BENEFIT_NM AS benefit_nm,
         BENEFIT_AMT AS benefit_amt, BENEFIT_CTGR_CD AS benefit_ctgr_cd, BADGE_CD AS badge_cd,
         AMT_SOURCE_CD AS amt_source, QUAL_YN AS qual_yn, QUAL_DESC_CTNT AS qual_desc_ctnt,
         NOTE_CTNT AS note_ctnt, VERIFIED_DTM AS verified_dtm, EXPIRES_DTM AS expires_dtm,
         BADGE_SRC_CD AS badge_src_cd, BADGE_SRC_URL_CTNT AS badge_src_url_ctnt,
         SORT_ORDER_NO AS sort_order_no
    FROM TCOMPANY_BENEFIT ORDER BY COMP_ID, SORT_ORDER_NO, BENEFIT_ID"""

def _parse_ws(v):                      # JSON 컬럼(문자열) → dict, 실패 시 None
    if v is None: return None
    if isinstance(v, dict): return v
    try: return json.loads(v)
    except (ValueError, TypeError): return None

def _norm_benefit(r: dict) -> dict:
    r["qual_yn"] = bool(r.get("qual_yn"))
    for k in ("verified_dtm", "expires_dtm"):
        if r.get(k) is not None:
            r[k] = r[k].isoformat() if hasattr(r[k], "isoformat") else str(r[k])
    return r

async def build_reference_bundle(conn) -> dict:
    async with conn.cursor() as cur:              # DictCursor
        await cur.execute(_SQL_TYPES);      types    = await cur.fetchall()
        await cur.execute(_SQL_PRESETS);    presets  = await cur.fetchall()
        await cur.execute(_SQL_COMPANIES);  comps    = await cur.fetchall()
        await cur.execute(_SQL_ALIASES);    aliases  = await cur.fetchall()
        await cur.execute(_SQL_BENEFITS);   benefits = await cur.fetchall()

    # 그룹핑
    presets_by_type: dict[str, list] = {}
    for p in presets:
        p["default_checked_yn"] = bool(p.get("default_checked_yn"))
        presets_by_type.setdefault(p.pop("comp_tp_cd"), []).append(p)

    aliases_by_comp: dict[int, list[str]] = {}
    for a in aliases:
        aliases_by_comp.setdefault(a["comp_id"], []).append(a["alias_nm"])

    benefits_by_comp: dict[int, list] = {}
    for b in benefits:
        cid = b.pop("comp_id")
        benefits_by_comp.setdefault(cid, []).append(_norm_benefit(b))

    for c in comps:
        c["work_style_val"] = _parse_ws(c.get("work_style_val"))
        c["aliases"]  = aliases_by_comp.get(c["comp_id"], [])
        c["benefits"] = benefits_by_comp.get(c["comp_id"], [])

    return {"company_types": types, "benefit_presets": presets_by_type, "companies": comps}
```

- 반환은 **plain dict**(SP-ARCH-4 계약, generator가 Jinja 컨텍스트로 재사용). 최상위 키 정확히 3종·프로파일러 키 부재(INV-2)는 스키마에 소스 테이블이 없어 구조적으로 보장(SP-DB-14).
- `AMT_SOURCE_CD AS amt_source` 별칭으로 필드맵 예외(SP-DB-5)를 SQL에서 해소.
- 조립은 O(회사+별칭+복지) 단일 패스. 5개 쿼리는 전량 조회(파라미터 없음).
- **추적**: SP-ARCH-4, FR-92·FR-D1·FR-D4·FR-D5, SP-DB-14, §6.

---

## SP-API-8 — `GET /api/v1/health` (FR-91)

**라이브니스 기본**: 프로세스 생존만 표현, DB 조회 없음. 200 `{"status":"ok"}`.

```python
# server/routers/health.py
from fastapi import APIRouter, Response
from server.models.common import HealthResponse

router = APIRouter(tags=["health"])

@router.get("/health", response_model=HealthResponse)
async def health(response: Response) -> HealthResponse:
    response.headers["Cache-Control"] = "no-store"
    return HealthResponse(status="ok")
```

| 상태 | 조건 | 본문 | 헤더 |
|------|------|------|------|
| 200 OK | 프로세스 생존(기본) | `{"status":"ok"}` | `Cache-Control: no-store` |
| 503 Service Unavailable | (레디니스 확장 시) DB 풀 미가용 | `{"status":"degraded"}` | `no-store` |

- **레디니스 확장(선택, FR-91 대안)**: `database.ping()`(SP-API-3)이 `False`면 `JSONResponse(status_code=503, content={"status":"degraded"})`. MVP 기본은 라이브니스. 사용자·회사 식별정보 미포함(경량).
- **추적**: FR-91, UC-A5, NFR20.

---

## SP-API-9 — `GET /api/v1/reference/all` (FR-92)

부팅 단일 소스. 인메모리 캐시(미스 시 DB 조립·직렬화·저장) + `Cache-Control: public, max-age=3600`.

```python
# server/routers/reference.py
import json
from fastapi import APIRouter, Request, Response
from server.database import get_pool
from server.services.reference import build_reference_bundle
from server.models.reference import ReferenceBundle   # OpenAPI 문서용

router = APIRouter(tags=["reference"])
_CACHE_KEY = "reference_all"

@router.get("/reference/all", response_model=ReferenceBundle)
async def reference_all(request: Request) -> Response:
    settings = request.app.state  # cache
    cache = request.app.state.reference_cache
    body: bytes | None = cache.get(_CACHE_KEY)
    if body is None:                                   # 캐시 미스 → 조립
        async with get_pool().acquire() as conn:
            bundle = await build_reference_bundle(conn)
        body = json.dumps(bundle, ensure_ascii=False).encode("utf-8")
        cache.set(_CACHE_KEY, body)
    from server.config import get_settings
    return Response(
        content=body, media_type="application/json",
        headers={"Cache-Control": get_settings().reference_cache_control},
    )
```

| 상태 | 조건 | 본문 | 헤더 |
|------|------|------|------|
| 200 OK | 정상 | `ReferenceBundle`(FR-D1, 최상위 3키) | `Cache-Control: public, max-age=3600`, `Content-Type: application/json; charset=utf-8` |
| 500 | 예기치 못한 DB 오류 | `{"detail": "..."}`(일반 메시지) | `no-store`(오류 핸들러, SP-API-12) |

- **캐시된 바이트 직접 반환** → 요청당 Pydantic 재직렬화 비용 제거. `response_model`은 OpenAPI 스키마·계약 문서화 용도이며 `Response` 반환 시 검증을 우회한다(계약 검증은 테스트 SP-API-14가 담당).
- 최상위 키 정확히 3종·프로파일러 키 부재는 SP-API-7이 구조적으로 보장(INV-2).
- 클라이언트 로드 실패 처리는 FR-E1(SP-FE 소유).
- **추적**: FR-92·FR-D1, SP-ARCH-4·SP-ARCH-5, INV-2, NFR3, §6·D4.4.

---

## SP-API-10 — `GET /api/v1/companies/search?q=` (FR-93)

이름·별칭 LIKE 부분일치, 최대 20건. `q` 검증(FastAPI `Query` + trim 후 길이 규칙). `%s` 바인딩·LIKE 와일드카드 이스케이프.

```python
# server/routers/companies.py (search 부분)
from fastapi import APIRouter, Query, Response
from server.database import fetch_all, fetch_one
from server.models.company import CompanySearchItem

router = APIRouter(tags=["companies"])

_SQL_SEARCH = """
  SELECT DISTINCT c.COMP_ID AS comp_id, c.COMP_NM AS comp_nm, t.COMP_TP_CD AS comp_tp_cd,
         c.INDUSTRY_NM AS industry_nm, c.LOGO_NM AS logo_nm
    FROM TCOMPANY c
    JOIN TCOMPANY_TYPE t   ON c.COMP_TP_ID = t.COMP_TP_ID
    LEFT JOIN TCOMPANY_ALIAS a ON a.COMP_ID = c.COMP_ID
   WHERE c.COMP_NM LIKE %s ESCAPE '!' OR a.ALIAS_NM LIKE %s ESCAPE '!'
   ORDER BY (c.COMP_NM LIKE %s ESCAPE '!') DESC, c.COMP_NM
   LIMIT 20"""

def _like_escape(s: str) -> str:               # LIKE 메타문자 무력화(ESCAPE '!')
    return s.replace("!", "!!").replace("%", "!%").replace("_", "!_")

@router.get("/companies/search", response_model=list[CompanySearchItem])
async def search_companies(
    response: Response,
    q: str = Query(..., max_length=50),        # 미제공 → 422 / >50 → 422 (FR-93)
) -> list[CompanySearchItem]:
    response.headers["Cache-Control"] = "no-store"
    term = q.strip()
    if not term:                               # 공백/빈 문자열 → 200 []
        return []
    like = f"%{_like_escape(term)}%"
    prefix = f"{_like_escape(term)}%"
    rows = await fetch_all(_SQL_SEARCH, (like, like, prefix))
    return [CompanySearchItem(**r) for r in rows]
```

**`q` 검증 매트릭스**(FR-93):

| 입력 상태 | 처리 | 상태코드 |
|-----------|------|----------|
| `q` 미제공 | 필수 파라미터 누락(FastAPI) | **422** |
| `q` trim 후 빈/공백만 | 무질의 → 빈 배열 | **200 `[]`** |
| `q` trim 후 1~50자 | 정상 검색(≤20건) | **200** |
| `q` trim 후 >50자 | `Query(max_length=50)` 위반 | **422** |

- **주입/와일드카드 방어**: `q`는 `%s` 바인딩. `%`·`_`·이스케이프문자(`!`)를 `_like_escape`로 무력화 후 `%...%` 래핑, `ESCAPE '!'` 명시(FR-93 규칙2). LIKE 전체 스캔이 사용자 입력 와일드카드로 폭주하지 않음.
- **정렬**: 접두 일치(`COMP_NM LIKE 'term%'`) 우선, 그 다음 이름순. `DISTINCT`로 별칭 다중 매칭 중복 제거. `LIMIT 20` 하드 상한(§6).
- `benefits`·`aliases`·`work_style_val` 미포함(축소 투영, FR-D6). 검색 실패·번들 폴백은 FR-E2(SP-FE).
- **추적**: FR-93·FR-D6, SP-DB-3·SP-DB-4(인덱스), §6.

---

## SP-API-11 — `GET /api/v1/companies/{comp_id}` (FR-94)

완전 회사 객체(실복지·별칭·근무형태 인라인). 미존재 → 404, 비정수 → 422.

```python
# server/routers/companies.py (detail 부분, 동일 router)
from fastapi import Path, HTTPException
from server.services.reference import _parse_ws, _norm_benefit
from server.models.reference import Company, Benefit
from server.config import get_settings

_SQL_COMP = """
  SELECT c.COMP_ID AS comp_id, c.COMP_ENG_NM AS comp_eng_nm, c.COMP_NM AS comp_nm,
         t.COMP_TP_CD AS comp_tp_cd, c.INDUSTRY_NM AS industry_nm, c.LOGO_NM AS logo_nm,
         c.WORK_STYLE_VAL AS work_style_val, c.CAREERS_BENEFIT_URL AS careers_benefit_url
    FROM TCOMPANY c JOIN TCOMPANY_TYPE t ON c.COMP_TP_ID = t.COMP_TP_ID
   WHERE c.COMP_ID = %s"""
_SQL_COMP_ALIASES  = "SELECT ALIAS_NM AS alias_nm FROM TCOMPANY_ALIAS WHERE COMP_ID = %s ORDER BY ALIAS_ID"
_SQL_COMP_BENEFITS = """
  SELECT BENEFIT_CD AS benefit_cd, BENEFIT_NM AS benefit_nm, BENEFIT_AMT AS benefit_amt,
         BENEFIT_CTGR_CD AS benefit_ctgr_cd, BADGE_CD AS badge_cd, AMT_SOURCE_CD AS amt_source,
         QUAL_YN AS qual_yn, QUAL_DESC_CTNT AS qual_desc_ctnt, NOTE_CTNT AS note_ctnt,
         VERIFIED_DTM AS verified_dtm, EXPIRES_DTM AS expires_dtm, BADGE_SRC_CD AS badge_src_cd,
         BADGE_SRC_URL_CTNT AS badge_src_url_ctnt, SORT_ORDER_NO AS sort_order_no
    FROM TCOMPANY_BENEFIT WHERE COMP_ID = %s ORDER BY SORT_ORDER_NO, BENEFIT_ID"""

@router.get("/companies/{comp_id}", response_model=Company)
async def get_company(
    response: Response,
    comp_id: int = Path(..., ge=1),            # 비정수·<1 → 422 (FR-94)
) -> Company:
    row = await fetch_one(_SQL_COMP, (comp_id,))
    if row is None:                            # 미존재 → 404 (FR-94/FR-E6)
        raise HTTPException(status_code=404, detail="회사를 찾을 수 없습니다.")
    aliases  = await fetch_all(_SQL_COMP_ALIASES, (comp_id,))
    benefits = await fetch_all(_SQL_COMP_BENEFITS, (comp_id,))
    row["work_style_val"] = _parse_ws(row.get("work_style_val"))
    row["aliases"]  = [a["alias_nm"] for a in aliases]
    row["benefits"] = [Benefit(**_norm_benefit(b)) for b in benefits]
    response.headers["Cache-Control"] = get_settings().reference_cache_control  # public, max-age=3600
    return Company(**row)
```

| 상태 | 조건 | 본문 | 헤더 |
|------|------|------|------|
| 200 OK | 존재하는 `comp_id` | `Company`(FR-D4, benefits=실복지) | `Cache-Control: public, max-age=3600` |
| 404 Not Found | 미존재 `comp_id` | `{"detail": "회사를 찾을 수 없습니다."}` | `no-store`(핸들러) |
| 422 | `comp_id` 비정수/<1 | 검증 오류 envelope | — |

- `Path(..., ge=1)`: 양의 정수 강제. `/companies/abc` → 422(FastAPI 경로 int 파싱). 검색↔상세 공통 5필드 값 일치(FR-94 규칙2)는 동일 소스 테이블로 보장.
- 회사페이지는 사전생성(SP-GEN)이라 런타임 호출 대상은 아니나 계약 완결성·향후 소비용으로 제공(SP-ARCH-5).
- **추적**: FR-94·FR-D4·FR-D7, FR-E6, SP-DB-3~5, §6.

---

## SP-API-12 — 공통 상태코드·오류 응답 계약 (FR-95)

**상태코드 매트릭스**:

| 코드 | 조건 | 엔드포인트 |
|------|------|-----------|
| 200 | 정상(검색 0건 빈 배열 포함) | 전체 |
| 404 | 미존재 `comp_id` / 미등록 `/api/v1/*` 경로 | detail, 라우팅 |
| 405 | 등록 경로에 비-GET | 전 GET 라우트(`Allow: GET`) |
| 422 | 파라미터 검증 실패(누락/과길이 `q`, 비정수 `comp_id`) | search, detail |
| 500 | 예기치 못한 서버 오류 | 전체 |
| 503 | (레디니스 확장) DB 미가용 | health |

**오류 envelope**(FastAPI 관례):

| 유형 | 형태 |
|------|------|
| 명시 오류(404/405/500) | `{"detail": "<메시지>"}` |
| 검증 오류(422) | `{"detail": [{"loc": ["query","q"], "msg": "...", "type": "..."}]}` |

**전역 예외 핸들러**(`main.py` 등록) — 500 시 스택/SQL/내부경로 미노출:

```python
from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(Exception)
async def unhandled(request: Request, exc: Exception):
    # 서버 로그에만 상세 기록(logging), 응답 본문은 일반 메시지
    return JSONResponse(status_code=500, content={"detail": "일시적인 오류가 발생했습니다."},
                        headers={"Cache-Control": "no-store"})
```

- 500·404·405·422 응답은 `Cache-Control: no-store`. 응답 본문에 개인식별정보·사용자 데이터 미포함(§2-4). 클라이언트는 모든 비-2xx를 방어적으로 흡수(FR-D11, FR-E7, SP-FE).
- **추적**: FR-95·FR-D11, FR-E6·FR-E7, NFR16·NFR26.

---

## SP-API-13 — CORS·전송 헤더·캐시 정책 (FR-96)

**CORS**(SP-API-5 미들웨어):

| 항목 | 값 |
|------|----|
| `Access-Control-Allow-Origin` | 허용목록(`https://jobcho.wiki`, `https://www.jobcho.wiki`). 와일드카드 `*`+자격증명 금지 |
| `Access-Control-Allow-Methods` | `GET, HEAD, OPTIONS`(쓰기 미포함) |
| `Access-Control-Allow-Credentials` | `false`(무설정) — 인증·쿠키 없음(§2-1) |
| 프리플라이트 `OPTIONS` | CORSMiddleware가 처리 |

**캐시(Cache-Control) 정책**:

| 엔드포인트 | Cache-Control | 근거 |
|------------|---------------|------|
| `/reference/all` | `public, max-age=3600` | 브리프 §6 명시값(NFR3) |
| `/companies/{id}` | `public, max-age=3600` | 파생 기본값(D4.4 정렬) |
| `/companies/search` | `no-store` | 질의 가변·디바운스·번들 폴백 |
| `/health` | `no-store` | 실시간 상태 |
| 모든 오류(404/422/500) | `no-store` | SP-API-12 |

- 프로덕션은 동일 오리진(Nginx `/api/v1` 프록시, SP-ARCH-2)이라 CORS는 방어적·개발용. 모든 JSON 응답 `Content-Type: application/json; charset=utf-8`.
- **추적**: FR-96, INV-7, NFR3·NFR17, §6·§8.

---

## SP-API-14 — 테스트 명세 (pytest + httpx ASGITransport)

**도구**: `pytest` 8.3.x · `httpx` 0.28.x(`ASGITransport`, 러닝 서버 불필요) · `pytest-asyncio` 0.24.x. **DB 미의존 계약 테스트**를 기본으로 한다 — `database.fetch_all`/`fetch_one`/`build_reference_bundle`를 monkeypatch로 대체하여 캔드(canned) 행을 주입한다(SP-ARCH §9.1 API 계약 계층). 별도로 `loupit_test` 실 MySQL 대상 통합 스모크(선택, SP-DB-16 픽스처 재사용)를 둔다. **TDD**: 각 라우터 구현과 동시/선행 작성, 그린 전까지 미완(§10).

### SP-API-14.1 픽스처 (`conftest.py`)

```python
import pytest, httpx
from server.main import create_app
from server import database
from server.routers import reference as ref_router

@pytest.fixture
def fake_data(monkeypatch):
    # 캔드 회사/유형/복지/별칭 세트 (회사 2개, 유형 6종 축약)
    async def _fetch_all(sql, params=()):
        ...  # sql 패턴 분기로 검색/별칭/복지 행 반환
    async def _fetch_one(sql, params=()):
        ...  # comp_id 존재/부재 분기
    monkeypatch.setattr(database, "fetch_all", _fetch_all)
    monkeypatch.setattr(database, "fetch_one", _fetch_one)

@pytest.fixture
async def client(fake_data, monkeypatch):
    app = create_app()
    # lifespan(풀 생성) 우회: init/close_pool을 no-op, 캐시만 생성
    from server.cache import TTLCache
    monkeypatch.setattr(database, "init_pool", lambda: _noop())
    app.state.reference_cache = TTLCache(3600)
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://t") as c:
        yield c
```

> 참고: `reference/all`·`companies/{id}`는 `get_pool().acquire()`/`build_reference_bundle`를 사용하므로, 해당 테스트에서는 `build_reference_bundle`를 캔드 dict 반환 함수로 monkeypatch하여 풀 없이 검증한다.

### SP-API-14.2 테스트 케이스

| ID | 대상 | 케이스 | 기대 |
|----|------|--------|------|
| **TS-1** | 표면(INV-1) | `app.routes` 순회 | `{method,path}` = health·reference/all·companies/search·companies/{comp_id}의 GET(+자동 HEAD/OPTIONS)뿐. POST/PUT/PATCH/DELETE 라우트 수 = 0 |
| **TS-2** | 표면(INV-1) | 미들웨어 목록 검사 | 인증/세션 미들웨어 클래스 부재. CORSMiddleware만 |
| **TH-1** | health | `GET /api/v1/health` | 200, `{"status":"ok"}`, `Cache-Control: no-store` |
| **TH-2** | health | (레디니스 확장) `ping()`→False patch | 503, `{"status":"degraded"}` |
| **TR-1** | reference | `GET /api/v1/reference/all`(build 캔드) | 200, 최상위 키 == `{company_types,benefit_presets,companies}` |
| **TR-2** | reference | 응답 헤더 | `Cache-Control: public, max-age=3600`, `Content-Type: application/json; charset=utf-8` |
| **TR-3** | reference | 프로파일러 키 부재 | 본문에 `profiles`/`job_groups`/`questions` 없음(INV-2) |
| **TR-4** | reference | 스키마 준수 | `ReferenceBundle(**body)` 검증 통과. 각 회사 `benefits` 비어있지 않음·`aliases` ≥1 |
| **TR-5** | reference **캐시** | `build_reference_bundle` 호출수 카운트, 2회 요청 | 빌더 **1회만** 호출(2번째는 캐시 히트) |
| **TR-6** | reference **캐시 만료** | TTL=0 캐시로 교체 후 2회 요청 | 빌더 2회 호출(만료 재조립) |
| **TSE-1** | search | `?q=삼성`(캔드 매칭) | 200, 배열, 각 항목 5필드(`comp_id,comp_nm,comp_tp_cd,industry_nm,logo_nm`)만, `Cache-Control: no-store` |
| **TSE-2** | search | `q` 미제공 `?` | **422** |
| **TSE-3** | search | `?q=`(빈)·`?q=%20%20`(공백) | **200 `[]`**(오류 아님) |
| **TSE-4** | search | `?q=`+51자 | **422**(max_length 위반) |
| **TSE-5** | search | 최대 20건 상한 | 캔드 30행 매칭 시 응답 길이 ≤ 20 |
| **TSE-6** | search | 주입/와일드카드 `?q=%_!` | 크래시 없이 200(파라미터 바인딩·이스케이프 검증). SQL에 `%s`·`ESCAPE` 사용 |
| **TSE-7** | search | 0건 매칭 `?q=존재안함` | **200 `[]`** |
| **TC-1** | detail | `GET /companies/1`(존재) | 200, `Company` 스키마, `benefits`·`aliases`·`work_style_val` 포함, `Cache-Control: public, max-age=3600` |
| **TC-2** | detail | `GET /companies/999999`(부재) | **404**, `{"detail": ...}`, `no-store` |
| **TC-3** | detail | `GET /companies/abc`(비정수) | **422** |
| **TC-4** | detail | `GET /companies/0`(<1) | **422**(`ge=1`) |
| **TM-1** | 메서드 | `POST /api/v1/companies/search` | **405**, `Allow` 헤더에 `GET` 포함 |
| **TN-1** | 라우팅 | `GET /api/v1/nonexistent` | **404** |
| **TCORS-1** | CORS | `Origin: https://jobcho.wiki` 요청 | `Access-Control-Allow-Origin: https://jobcho.wiki`. 와일드카드 아님 |
| **TCORS-2** | CORS | `OPTIONS` 프리플라이트 | 200/204 + `Allow-Methods: GET, HEAD, OPTIONS`, 쓰기 메서드 부재 |
| **TE-1** | 오류 | 데이터 계층에서 예외 발생 patch | **500**, `{"detail":"일시적인 오류가 발생했습니다."}`, 스택/SQL 미노출 |

**실행**: `pytest server/tests/ -v`. 릴리스 게이트 = TS·TH·TR·TSE·TC·TM·TN·TCORS·TE 전부 green(SP-ARCH-9 4단계, SP-TEST 종합).

- **추적**: 브리프 §10, SP-ARCH §9(T2·T4), FR-90~FR-96, FR-D1·D6·D11, NFR3·NFR16·NFR20·NFR26.

---

## SP-API-15 — 추적 요약 (본 문서)

| SP-API | 구현 대상 | 상위 FR/FR-D | 상위 F/NFR | SPEC 인용 | 브리프 |
|:---:|--------|--------------|-----------|-----------|--------|
| SP-API-1 | 패키지·모듈 구조 | FR-90 | F8, NFR20 | SP-ARCH-6 | §6·§8 |
| SP-API-2 | 설정·환경변수 | FR-96 | NFR16·NFR22 | SP-ARCH-7 | §8 |
| SP-API-3 | aiomysql 풀·원시SQL(%s) | FR-93 | NFR20 | SP-ARCH-7 | §8 |
| SP-API-4 | 인메모리 TTL 캐시 | FR-92·FR-96 | NFR3 | — | §6 |
| SP-API-5 | 앱 조립·CORS·무인증 | FR-90·FR-96 | NFR20, INV-1·7 | SP-ARCH-2·5 | §6·§8 |
| SP-API-6 | Pydantic 응답 모델 | FR-D1~D6 | F8 | SP-DB-2~9 | §6 |
| SP-API-7 | 번들 빌더(단일 소스) | FR-92·FR-D1 | F8, NFR3 | SP-ARCH-4, SP-DB-14 | §6 |
| SP-API-8 | GET /health | FR-91 | UC-A5, NFR20 | — | §6 |
| SP-API-9 | GET /reference/all | FR-92·FR-D1 | NFR3, INV-2 | SP-ARCH-5 | §6·D4.4 |
| SP-API-10 | GET /companies/search | FR-93·FR-D6 | F1 | SP-DB-3·4 | §6 |
| SP-API-11 | GET /companies/{id} | FR-94·FR-D4·D7 | F1·F4, NFR26 | SP-DB-3~5 | §6 |
| SP-API-12 | 상태코드·오류 envelope | FR-95·FR-D11 | NFR16·NFR26 | — | §6·§7 |
| SP-API-13 | CORS·헤더·캐시 | FR-96 | NFR3·NFR17, INV-7 | SP-ARCH-2 | §6·§8 |
| SP-API-14 | 테스트 명세 | FR-90~96·FR-D* | 전체, NFR26 | SP-ARCH §9 | §10 |
</content>
</invoke>
