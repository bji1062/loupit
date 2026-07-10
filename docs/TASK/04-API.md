# TASK 04 — 백엔드 읽기전용 API (SP-API)

> SPEC 계약: [SPEC/04-백엔드-API.md](../SPEC/04-백엔드-API.md) (SP-API). 이 문서는 해당 도메인을 최소 독립 기능 리프로 분해한다. 리프 완료(- [v]) = 구현 + 대응 테스트 green(SP-TEST-1 DoD). 진행중 - [-], 미착수 - [ ].
> 마일스톤: M2(API·번들) — 전체 빌드순서·의존은 [00-빌드순서-마일스톤.md](00-빌드순서-마일스톤.md).
> 선행 의존: SP-DB(스키마·필드 계약: TCOMPANY_TYPE·TCOMPANY·TCOMPANY_ALIAS·TCOMPANY_BENEFIT·TBENEFIT_PRESET 컬럼·`AMT_SOURCE_CD`↔`amt_source` 필드맵) · SP-SEED(런타임 데이터·통합 스모크). `server/` 디렉토리·`requirements.txt`·`.env.example`은 SP-ARCH(T-01.2.1) 스캐폴드 재사용(중복 생성 금지). 확정 순서는 00이 소유.
> 테스트: 러너=pytest 8.3 + httpx 0.28(`ASGITransport`, 러닝 서버 불필요) + pytest-asyncio 0.24 (무 DB — `database.fetch_all`/`fetch_one`/`build_reference_bundle` monkeypatch 캔드 주입) · 위치=`server/tests/` · 케이스 대역=TS · TH · TR · TSE · TC · TM · TN · TCORS · TE (26).

## 진행 요약
- 리프 총 28 / 완료 0 / 진행 0 / 미착수 28
- Tier-0 게이트 리프: T-04.5.2 (TS-1 GET 4종·무쓰기), T-04.5.3 (TS-2 무인증·무세션), T-04.7.1 (TR-1 3키 계약), T-04.7.2 (TR-2 캐시/전송 헤더), T-04.7.3 (TR-3 프로파일러 키 부재), T-04.7.5 (TR-5 캐시 1회 조립)
- 선결정 게이트: DG-4 (T-04.6.2 위 — `/health` 레디니스 503 확장 구현 여부; 전역 레지스트리 00 §4의 **DG-4**로 통합)

## T-04.1 패키지 골격·테스트 하네스  — (SP-API-1, SP-API-14.1, INV-1, FR-90)
- [ ] T-04.1.1 server 서브패키지 스캐폴드·레거시 델타(auth/oauth/profiler 부재)
  - 구현: `server/`에 SP-API-1 레이아웃 서브패키지 `__init__.py` 생성 — `server/__init__.py`·`routers/__init__.py`·`services/__init__.py`·`models/__init__.py`·`tests/__init__.py`. `routers/`는 3파일(health·reference·companies=GET 4종)만 예약. `server/requirements.txt`·`.env.example`은 **위임**(SP-ARCH T-01.2.1). 레거시 델타: auth/oauth/profiler/comparisons/admin/landing 라우터·JWT/SMTP·미들웨어 파일 부재(SP-ARCH-6 규칙: 파일 추가 가능·디렉토리 경계 불변).
  - 테스트: 패키지 import 스모크(`import server`·`import server.routers`·`import server.services`) + 금지 라우터/모듈(auth·oauth·profiler·comparisons) 파일 부재 grep(pytest+bash) — RED 먼저. 라우트 표면 회귀는 TS-1(T-04.5.2)
  - refs: SP-API-1 · SP-ARCH-6·SP-ARCH-1 · FR-90 · INV-1 · NFR20
- [ ] T-04.1.2 conftest.py 테스트 하네스 (ASGITransport client + fake_data monkeypatch 픽스처)
  - 구현: `server/tests/conftest.py` — `fake_data`(monkeypatch로 `database.fetch_all`/`fetch_one`에 캔드 행 주입: 회사 2개·유형 6종 축약·복지·별칭, sql 패턴 분기로 검색/별칭/복지/존재·부재 반환), `client`(`create_app()` + lifespan 우회: `init_pool`/`close_pool` no-op patch·`app.state.reference_cache=TTLCache(3600)`·`httpx.AsyncClient(transport=ASGITransport(app), base_url="http://t")`), `build_reference_bundle` 캔드 dict 반환 monkeypatch 헬퍼(풀 없이 reference/all·companies/{id} 검증용). pytest-asyncio 모드.
  - 테스트: 픽스처 smoke — `client` 부트 성립·`fake_data` monkeypatch 적용 확인(pytest server/tests/) — RED 먼저(`create_app` 부재)
  - refs: SP-API-14.1 · SP-API-14 · SP-ARCH §9.1 · INV-1

## T-04.2 설정·DB·캐시 인프라 계층  — (SP-API-2·3·4, FR-96·FR-93·FR-92, NFR16·NFR20·NFR3)
- [ ] T-04.2.1 config.py Settings (환경변수·CORS 목록·캐시 TTL, 인증키 부재)
  - 구현: `server/config.py` — `class Settings(BaseSettings)`(pydantic-settings): `db_host/db_port/db_user/db_password/db_name/db_pool_min/db_pool_max/db_connect_timeout`, `api_prefix="/api/v1"`, `cors_allow_origins`(콤마 문자열, 와일드카드 금지), `reference_cache_ttl=3600`, `reference_cache_control="public, max-age=3600"`; `@property cors_origin_list`(콤마 분할·strip·빈값 제거); `@lru_cache get_settings()`. **`JWT_SECRET`·`OAUTH_*`·`SMTP_*`·세션 키 정의 금지**(NFR16).
  - 테스트: config 유닛 — `cors_origin_list` 파싱·기본 `api_prefix`·`reference_cache_control` 값·부재 키(`jwt`/`oauth`/`smtp` 필드 미정의) assert(pytest) — RED 먼저. 무인증 표면 회귀는 TS-2 위임(T-04.5.3)
  - refs: SP-API-2 · SP-ARCH-7 · FR-96 · NFR16·NFR22
- [ ] T-04.2.2 database.py aiomysql 풀·읽기 헬퍼 (fetch_all/fetch_one, %s 바인딩, 쓰기 헬퍼 부재)
  - 구현: `server/database.py` — 전역 `_pool`, `init_pool()`(`aiomysql.create_pool`: DictCursor·`charset="utf8mb4"`·`autocommit=True`·`connect_timeout`·pool min/max), `close_pool()`, `get_pool()`(assert 초기화), `async fetch_all(sql, params=())`/`async fetch_one(sql, params=())`(`%s` 바인딩, DictCursor dict 반환), `async ping()`(`SELECT 1 AS ok`). **execute/commit/rollback(쓰기) 헬퍼 미제공**(INV-1·NFR20).
  - 테스트: database 유닛 — `fetch_all`/`fetch_one` `%s` 바인딩(fake 커서 monkeypatch)·쓰기 헬퍼 심볼(execute·commit) 부재 assert·`ping()` True/False(pytest) — RED 먼저
  - refs: SP-API-3 · SP-ARCH-7 · FR-93(바인딩) · INV-1·NFR20
- [ ] T-04.2.3 cache.py TTLCache (get/set/clear, monotonic 만료)
  - 구현: `server/cache.py` — `class TTLCache(ttl_seconds)`: `_store: dict[str, tuple[float, Any]]`, `get(key)`(만료 시 `pop`→None), `set(key, value)`(`time.monotonic()+ttl`), `clear()`. 단일 프로세스 인메모리(asyncio 단일 스레드, 락 불요). 저장 대상=직렬화 JSON 바이트·키=`"reference_all"`.
  - 테스트: cache 유닛 — set→get 히트·TTL=0 즉시 미스·만료 후 pop·clear(pytest, monotonic 제어) — RED 먼저. reference/all 통합 캐시 회귀는 TR-5·TR-6(T-04.7.5/6)
  - refs: SP-API-4 · FR-92·FR-96 · NFR3 · D4.4

## T-04.3 Pydantic 응답 모델  — (SP-API-6, FR-D1~D6, SP-DB-2~9)
- [ ] T-04.3.1 models/reference.py — CompanyType·PresetBenefit·Benefit·Company·ReferenceBundle
  - 구현: `server/models/reference.py`(Pydantic v2) — `CompanyType`(comp_tp_id/comp_tp_cd/comp_tp_nm, growth_rate_val float|None, growth_label_nm, stability_score_no int|None), `PresetBenefit`(benefit_cd/nm, benefit_amt int|None, benefit_ctgr_cd, badge_cd="est", default_checked_yn=True, sort_order_no), `Benefit`(전 필드 + `amt_source`∈{stated,estimated,none}, qual_yn bool, qual_desc_ctnt, note_ctnt, verified_dtm/expires_dtm str|None, badge_src_cd/badge_src_url_ctnt, sort_order_no), `Company`(comp_id..logo_nm, work_style_val dict|None, careers_benefit_url, `aliases: list[str]`, `benefits: list[Benefit]`), `ReferenceBundle`(company_types, `benefit_presets: dict[str, list[PresetBenefit]]`, companies) — 최상위 정확히 3키·감사 4종·내부 PK 미노출.
  - 테스트: TR-4 부분(`ReferenceBundle(**body)` 모델 검증)·필드 존재/타입 유닛 assert(pytest) — RED 먼저
  - refs: SP-API-6.1 · FR-D1~D5 · SP-DB-2~9 · INV-5
- [ ] T-04.3.2 models/company.py + models/common.py — CompanySearchItem·HealthResponse·ErrorEnvelope
  - 구현: `server/models/company.py` — `CompanySearchItem`(comp_id, comp_nm, comp_tp_cd, industry_nm|None, logo_nm|None) 축소 5필드 투영(FR-D6). `server/models/common.py` — `HealthResponse`(status str, "ok"|"degraded"), `ErrorEnvelope`(detail str, FastAPI 기본 `{"detail":...}` 문서용).
  - 테스트: 모델 유닛 — `CompanySearchItem` 5필드 한정(benefits/aliases/work_style_val 부재)·`HealthResponse`(pytest) — RED 먼저. 실계약은 TSE-1(T-04.8.1)·TH-1(T-04.6.1)
  - refs: SP-API-6.2·6.3 · FR-D6·FR-91·FR-95

## T-04.4 참조 번들 빌더 — 단일 소스 (SP-ARCH-4)  — (SP-API-7, FR-92·FR-D1, SP-DB-14)
- [ ] T-04.4.1 build_reference_bundle(conn)->dict 5쿼리 조립 (런타임·generator 공유 단일 소스)
  - 구현: `server/services/reference.py` — `_SQL_TYPES/_SQL_PRESETS/_SQL_COMPANIES/_SQL_ALIASES/_SQL_BENEFITS`(전량 SELECT, 파라미터 없음, `AMT_SOURCE_CD AS amt_source` 별칭으로 필드맵 예외 SP-DB-5 해소), `_parse_ws(v)`(JSON 문자열→dict, 실패 시 None), `_norm_benefit(r)`(qual_yn `bool()` 강제·verified/expires_dtm isoformat 문자열화), `async def build_reference_bundle(conn) -> dict`(5쿼리 fetchall → presets_by_type/aliases_by_comp/benefits_by_comp 그룹핑 → 회사에 work_style_val·aliases·benefits 인라인 → `{"company_types","benefit_presets","companies"}` plain dict 반환). **부수효과·쓰기 0**(순수 조립). **SP-GEN(C2 generator)이 빌드타임에 이 동일 함수를 Jinja 컨텍스트로 소비**(SP-ARCH-4). 단일 소스 심볼 동일성 회귀(T3)는 **위임**(SP-ARCH T-01.3.1).
  - 테스트: 빌더 유닛 — fake conn/cursor 캔드 행 주입 시 최상위 키=={company_types,benefit_presets,companies}·work_style_val dict 파싱·`amt_source` 별칭·qual_yn bool·default_checked_yn bool·회사별 aliases/benefits 인라인(pytest) — RED 먼저
  - refs: SP-API-7 · SP-ARCH-4 · FR-92·FR-D1·FR-D4·FR-D5 · SP-DB-14·SP-DB-5

## T-04.5 앱 조립·표면 불변식·CORS·라우팅  — (SP-API-5·13, FR-90·FR-96, INV-1·INV-7)
- [ ] T-04.5.1 create_app 조립·lifespan·라우터 등록·CORS 미들웨어 (main.py)
  - 구현: `server/main.py` — `@asynccontextmanager lifespan(app)`(`init_pool()` → `app.state.reference_cache=TTLCache(ttl)` → yield → `close_pool()`), `create_app()`(`FastAPI(title="loupit read-only API", version="1.0.0", lifespan=...)`, `CORSMiddleware(allow_origins=cors_origin_list, allow_methods=["GET","HEAD","OPTIONS"], allow_headers=["*"], allow_credentials=False)`, `include_router(health/reference/companies, prefix=api_prefix)`), `app=create_app()`. **인증·세션 미들웨어 0**(전역 예외 핸들러는 T-04.10.1이 채움).
  - 테스트: 앱 부트 스모크 — `create_app()` 성립·라우터 3종 등록·미들웨어 목록에 CORS만(pytest client) — RED 먼저. 표면 강제는 TS-1·TS-2(T-04.5.2/3)
  - refs: SP-API-5 · SP-ARCH-2·5 · FR-90·FR-96 · INV-1
- [ ] T-04.5.2 API 표면 = GET 4종·쓰기 라우트 0 (TS-1) (Tier0)
  - 구현: 라우터 3종(health·reference·companies) 등록 결과 `app.routes` 순회 시 `{method,path}`가 health·reference/all·companies/search·companies/{comp_id}의 GET(+자동 HEAD/OPTIONS)뿐, POST/PUT/PATCH/DELETE 라우트 수=0임을 강제. 라우트 실구현은 라우터 leaf(T-04.6~9)가 채우고 본 리프는 **Tier-0 표면 회귀 게이트**만 소유. SP-ARCH T2가 이 케이스로 위임됨.
  - 테스트: TS-1 (pytest — `server/tests/test_surface.py`) — `app.routes` 순회, GET 4 엔드포인트뿐·쓰기 메서드 라우트 수=0 — RED 먼저
  - refs: SP-API-14 · INV-1 · FR-90·FR-95 · NFR20 (SP-ARCH T2 위임 수신)
- [ ] T-04.5.3 미들웨어 = CORS 1종·무인증·무세션 (TS-2) (Tier0)
  - 구현: `app.user_middleware`/미들웨어 스택에 `AuthenticationMiddleware`·`SessionMiddleware`·커스텀 인증 의존성 부재, `CORSMiddleware`만 존재함을 강제. **Tier-0 무인증 회귀 게이트**. SP-ARCH T2가 이 케이스로 위임됨.
  - 테스트: TS-2 (pytest — `server/tests/test_surface.py`) — 미들웨어 클래스 목록 검사, 인증/세션 미들웨어 부재·CORSMiddleware 존재 — RED 먼저
  - refs: SP-API-14·SP-API-5 · INV-1 · NFR16·NFR20 (SP-ARCH T2 위임 수신)
- [ ] T-04.5.4 CORS 허용목록·프리플라이트 (TCORS-1·TCORS-2)
  - 구현: `CORSMiddleware` 설정 검증 — `Origin: https://loupit.co` 요청 시 `Access-Control-Allow-Origin`=해당 오리진(와일드카드 `*` 아님), `OPTIONS` 프리플라이트 → `Access-Control-Allow-Methods: GET, HEAD, OPTIONS`(쓰기 메서드 부재), `allow_credentials=false`. 구현은 T-04.5.1 미들웨어, 본 리프는 CORS 계약 검증.
  - 테스트: TCORS-1(Origin loupit.co → ACAO 일치·비와일드카드)·TCORS-2(OPTIONS → 200/204 + Allow-Methods GET,HEAD,OPTIONS) (pytest client) — RED 먼저
  - refs: SP-API-13·SP-API-5 · FR-96 · INV-7 · NFR17
- [ ] T-04.5.5 미등록 경로 404·등록 경로 비-GET 405 (TN-1·TM-1)
  - 구현: 라우터가 GET만 선언 → 미등록 `/api/v1/*`=404(FastAPI 기본), 등록 경로 비-GET=405 + `Allow: GET`. 별도 코드 없음(FastAPI 라우팅 파생), 상태코드 회귀만 소유. SP-ARCH T2가 TM-1로 위임됨.
  - 테스트: TN-1(`GET /api/v1/nonexistent` → 404)·TM-1(`POST /api/v1/companies/search` → 405 + `Allow`에 GET 포함) (pytest client) — RED 먼저
  - refs: SP-API-5·SP-API-12 · FR-90·FR-95 · INV-1

## T-04.6 GET /api/v1/health  — (SP-API-8, FR-91, UC-A5)
- [ ] T-04.6.1 GET /health 라이브니스 200 (TH-1)
  - 구현: `server/routers/health.py` — `router=APIRouter(tags=["health"])`, `@router.get("/health", response_model=HealthResponse)` `async def health(response)`: `response.headers["Cache-Control"]="no-store"`; `return HealthResponse(status="ok")`. **DB 조회 없음**(프로세스 생존만·경량·사용자 식별정보 미포함).
  - 테스트: TH-1 (pytest — `server/tests/test_health.py`) — `GET /api/v1/health` → 200, `{"status":"ok"}`, `Cache-Control: no-store` — RED 먼저
  - refs: SP-API-8 · FR-91 · UC-A5 · NFR20
- 선결정 DG-4(로컬 — 전역 레지스트리 00 §4 DG-4): `/health` 레디니스 503 확장(`database.ping()`→False 시 503 `{"status":"degraded"}`) 구현 여부 — MVP 라이브니스 전용(SPEC 기본) vs 레디니스 확장(FR-91 대안). 구현 전 AskUserQuestion 확인. (미채택 시 T-04.6.2는 스킵·TH-2 미대상 표기)
- [ ] T-04.6.2 health 레디니스 확장 503 (TH-2) [선택·DG-4]
  - 구현: (선택, FR-91 대안) `health.py` — `database.ping()`이 `False`면 `JSONResponse(status_code=503, content={"status":"degraded"}, headers={"Cache-Control":"no-store"})`. MVP 기본은 라이브니스(T-04.6.1); 본 리프는 DG-4 채택 시에만 구현.
  - 테스트: TH-2 (pytest — `server/tests/test_health.py`) — `ping()`→False patch → 503, `{"status":"degraded"}`, no-store — RED 먼저
  - refs: SP-API-8 · FR-91 · NFR20 · DG-4

## T-04.7 GET /api/v1/reference/all + 인메모리 캐시  — (SP-API-9·4, FR-92·FR-D1, INV-2, NFR3)
- [ ] T-04.7.1 reference/all 캐시 미스 조립·직렬 바이트 반환 (TR-1) (Tier0)
  - 구현: `server/routers/reference.py` — `router`, `_CACHE_KEY="reference_all"`, `@router.get("/reference/all", response_model=ReferenceBundle)` `async def reference_all(request)`: `cache=request.app.state.reference_cache`; `body=cache.get(KEY)`; 미스 시 `async with get_pool().acquire() as conn: bundle=await build_reference_bundle(conn)` → `body=json.dumps(bundle, ensure_ascii=False).encode("utf-8")` → `cache.set(KEY, body)`; `return Response(content=body, media_type="application/json", headers={"Cache-Control": reference_cache_control})`. 캐시 바이트 직접 반환(요청당 재직렬화 회피). **Tier-0 3키 계약 게이트**.
  - 테스트: TR-1 (pytest — `server/tests/test_reference.py`, `build_reference_bundle` 캔드 monkeypatch) — 200, 최상위 키=={company_types,benefit_presets,companies} — RED 먼저
  - refs: SP-API-9·SP-API-7 · FR-92·FR-D1 · SP-ARCH-4·5 · INV-2
- [ ] T-04.7.2 reference/all 전송 헤더 (TR-2) (Tier0)
  - 구현: Response `Cache-Control: public, max-age=3600`(`get_settings().reference_cache_control`) + `Content-Type: application/json; charset=utf-8`(`ensure_ascii=False` utf-8 인코딩). **Tier-0 캐시/전송 헤더 게이트**.
  - 테스트: TR-2 (pytest — `server/tests/test_reference.py`) — `Cache-Control: public, max-age=3600` & `Content-Type: application/json; charset=utf-8` — RED 먼저
  - refs: SP-API-9·SP-API-13 · FR-92·FR-96 · INV-2·INV-7 · NFR3
- [ ] T-04.7.3 프로파일러 키 부재 (TR-3) (Tier0)
  - 구현: 번들 최상위에 `profiles`/`job_groups`/`questions` 키 부재 — SP-API-7 조립이 구조적 보장(소스 테이블 부재 SP-DB-14). 별도 코드 없음, **Tier-0 프로파일러 키 부재 회귀 게이트**만 소유. SP-ARCH T4가 이 케이스로 위임됨.
  - 테스트: TR-3 (pytest — `server/tests/test_reference.py`) — 본문에 `profiles`/`job_groups`/`questions` 키 없음 — RED 먼저
  - refs: SP-API-9·SP-API-7 · INV-2 · SP-DB-14 (SP-ARCH T4 위임 수신)
- [ ] T-04.7.4 reference/all 스키마 준수·회사 필수 배열 (TR-4)
  - 구현: 응답이 `ReferenceBundle` 계약 준수 — 각 회사 `benefits` 비어있지 않음·`aliases`≥1. 조립 실구현은 T-04.4.1/T-04.7.1 소유, 본 리프는 계약 검증만.
  - 테스트: TR-4 (pytest — `server/tests/test_reference.py`) — `ReferenceBundle(**body)` 검증 통과·회사별 `benefits` 비어있지 않음·`aliases`≥1 — RED 먼저
  - refs: SP-API-9·SP-API-6·SP-API-7 · FR-D1·FR-D4·FR-D5
- [ ] T-04.7.5 인메모리 캐시 1회 조립 (TR-5) (Tier0)
  - 구현: 2회 요청 시 `build_reference_bundle` **1회만** 호출(2번째 캐시 히트). 캐시 get/set(T-04.7.1) + TTLCache(T-04.2.3) 통합 회귀. **Tier-0 캐시 게이트**. SP-ARCH T4가 이 케이스로 위임됨.
  - 테스트: TR-5 (pytest — `server/tests/test_reference.py`, 빌더 호출수 카운트 monkeypatch) — 2회 요청 시 빌더 1회 호출 — RED 먼저
  - refs: SP-API-9·SP-API-4 · FR-92·FR-96 · NFR3·D4.4 (SP-ARCH T4 위임 수신)
- [ ] T-04.7.6 캐시 TTL 만료 재조립 (TR-6)
  - 구현: TTL=0 캐시로 교체 후 2회 요청 → 빌더 2회 호출(만료 재조립). TTLCache 만료 경로(T-04.2.3) 통합 회귀.
  - 테스트: TR-6 (pytest — `server/tests/test_reference.py`, `TTLCache(0)` 교체) — 2회 요청 시 빌더 2회 호출 — RED 먼저
  - refs: SP-API-9·SP-API-4 · FR-92 · NFR3

## T-04.8 GET /api/v1/companies/search?q=  — (SP-API-10, FR-93·FR-D6, SP-DB-3·4)
- [ ] T-04.8.1 companies/search 이름·별칭 LIKE·축소 5필드 투영 (TSE-1)
  - 구현: `server/routers/companies.py` — `router=APIRouter(tags=["companies"])`, `_SQL_SEARCH`(`SELECT DISTINCT` 5필드, `JOIN TCOMPANY_TYPE` + `LEFT JOIN TCOMPANY_ALIAS`, `WHERE c.COMP_NM LIKE %s ESCAPE '!' OR a.ALIAS_NM LIKE %s ESCAPE '!'`, `ORDER BY (c.COMP_NM LIKE %s ESCAPE '!') DESC, c.COMP_NM`, `LIMIT 20`), `_like_escape(s)`(`!`·`%`·`_` 무력화), `@router.get("/companies/search", response_model=list[CompanySearchItem])` `search_companies(response, q: str = Query(..., max_length=50))`: `Cache-Control: no-store`; `term=q.strip()`; `like=f"%{esc}%"`·`prefix=f"{esc}%"`; `rows=await fetch_all(_SQL_SEARCH, (like,like,prefix))`; `[CompanySearchItem(**r) for r in rows]`.
  - 테스트: TSE-1 (pytest — `server/tests/test_search.py`, fake_data 매칭) — `?q=삼성` → 200, 배열, 각 항목 5필드(`comp_id,comp_nm,comp_tp_cd,industry_nm,logo_nm`)만, `Cache-Control: no-store` — RED 먼저
  - refs: SP-API-10 · FR-93·FR-D6 · SP-DB-3·4
- [ ] T-04.8.2 q 검증 매트릭스 — 미제공 422·빈/공백 200[]·과길이 422 (TSE-2·3·4)
  - 구현: `Query(..., max_length=50)` → 미제공 422·>50자 422; `term=q.strip()`이 빈/공백이면 조기 `return []`(200). FR-93 검증 매트릭스.
  - 테스트: TSE-2(`?`(q 미제공) → 422)·TSE-3(`?q=` / `?q=%20%20` → 200 `[]`)·TSE-4(`?q=`+51자 → 422) (pytest — `server/tests/test_search.py`) — RED 먼저
  - refs: SP-API-10 · FR-93
- [ ] T-04.8.3 LIMIT 20 상한 + 0건 매칭 빈 배열 (TSE-5·TSE-7)
  - 구현: `_SQL_SEARCH`의 `LIMIT 20` 하드 상한(§6) → 캔드 30행 매칭 시 응답 길이 ≤20; 0건 매칭 시 200 `[]`(오류 아님).
  - 테스트: TSE-5(캔드 30행 매칭 → 응답 ≤20)·TSE-7(`?q=존재안함` → 200 `[]`) (pytest — `server/tests/test_search.py`) — RED 먼저
  - refs: SP-API-10 · FR-93 · §6
- [ ] T-04.8.4 주입·LIKE 와일드카드 이스케이프 (TSE-6)
  - 구현: `q`는 `%s` 바인딩 + `_like_escape`(`!`·`%`·`_` 무력화)로 `%...%` 래핑 + `ESCAPE '!'` 명시(FR-93 규칙2). 사용자 입력 와일드카드로 LIKE 전체 스캔 폭주 방지·크래시 없음.
  - 테스트: TSE-6 (pytest — `server/tests/test_search.py`) — `?q=%_!` → 200 무크래시, SQL에 `%s`·`ESCAPE` 사용 검증 — RED 먼저
  - refs: SP-API-10·SP-API-3 · FR-93(규칙2) · NFR20

## T-04.9 GET /api/v1/companies/{comp_id}  — (SP-API-11, FR-94·FR-D4·D7, SP-DB-3~5)
- [ ] T-04.9.1 companies/{comp_id} 완전 회사 객체 (TC-1)
  - 구현: `companies.py`(동일 router) — `_SQL_COMP`(회사 1건 `WHERE c.COMP_ID=%s`)·`_SQL_COMP_ALIASES`(`WHERE COMP_ID=%s ORDER BY ALIAS_ID`)·`_SQL_COMP_BENEFITS`(`AMT_SOURCE_CD AS amt_source`, `WHERE COMP_ID=%s ORDER BY SORT_ORDER_NO, BENEFIT_ID`), `@router.get("/companies/{comp_id}", response_model=Company)` `get_company(response, comp_id: int = Path(..., ge=1))`: `row=await fetch_one(_SQL_COMP,(comp_id,))`; aliases/benefits `fetch_all`; `row["work_style_val"]=_parse_ws(...)`·`row["aliases"]=[...]`·`row["benefits"]=[Benefit(**_norm_benefit(b)) for b in benefits]`; `Cache-Control: public, max-age=3600`; `return Company(**row)`.
  - 테스트: TC-1 (pytest — `server/tests/test_company_detail.py`, fake_one/fake_all patch) — `/companies/1` → 200, `Company` 스키마, `benefits`·`aliases`·`work_style_val` 포함, `Cache-Control: public, max-age=3600` — RED 먼저
  - refs: SP-API-11 · FR-94·FR-D4·FR-D7 · SP-DB-3~5
- [ ] T-04.9.2 미존재 404·비정수/<1 검증 422 (TC-2·3·4)
  - 구현: `fetch_one`이 None → `raise HTTPException(status_code=404, detail="회사를 찾을 수 없습니다.")` + `no-store`(오류 핸들러); `Path(..., ge=1)` → `/abc` 비정수 422·`/0`(<1) 422.
  - 테스트: TC-2(`/companies/999999` → 404, `{"detail":...}`, no-store)·TC-3(`/companies/abc` → 422)·TC-4(`/companies/0` → 422 `ge=1`) (pytest — `server/tests/test_company_detail.py`) — RED 먼저
  - refs: SP-API-11·SP-API-12 · FR-94·FR-E6 · NFR26

## T-04.10 오류 처리·전역 예외 핸들러  — (SP-API-12, FR-95·FR-D11, NFR16·NFR26)
- [ ] T-04.10.1 전역 예외 핸들러 500 (스택/SQL/내부경로 미노출) (TE-1)
  - 구현: `main.py`에 `@app.exception_handler(Exception)` `async def unhandled(request, exc)` — 서버 로그(logging)에만 상세 기록, `return JSONResponse(status_code=500, content={"detail":"일시적인 오류가 발생했습니다."}, headers={"Cache-Control":"no-store"})`. 응답 본문에 스택/SQL/내부경로·개인식별정보 미포함(§2-4). 404/405/422 오류도 `no-store`(SP-API-12 매트릭스, 각 라우터 leaf가 개별 헤더 소유).
  - 테스트: TE-1 (pytest — `server/tests/test_reference.py` 또는 전용, 데이터 계층 예외 발생 patch) — 500, `{"detail":"일시적인 오류가 발생했습니다."}`, 스택/SQL 미노출 — RED 먼저
  - refs: SP-API-12 · FR-95·FR-D11 · FR-E7 · NFR16·NFR26

## 위임 케이스 (다른 SP 스위트에 실구현/검증 — 본 도메인 이중 구현 없음)
- **SP-ARCH 위임(수신·발신)**: (수신) SP-ARCH §9.2의 **T2**(INV-1 API 표면=GET 4종·무쓰기·무인증)는 본 도메인 **TS-1·TS-2·TM-1**(T-04.5.2/3/5, Tier-0)이 실구현·게이트 소유; **T4**(INV-2 3키·프로파일러 키 부재·1h 캐시)는 **TR-1~3·TR-5**(T-04.7.1~3/5, Tier-0)가 실구현. (발신) `build_reference_bundle` **단일 소스 심볼 동일성 회귀(T3)** 는 SP-ARCH T-01.3.1이 소유(함수 실구현은 T-04.4.1 여기). 통합 스모크(T7 무전송·T8 배포 `reference/all` 캐시 헤더 live curl)는 SP-ARCH/SP-INFRA M8.
- **SP-ARCH T-01.2.1 위임**: `server/requirements.txt`(fastapi·uvicorn·aiomysql·pydantic·httpx·pytest-asyncio pin)·`server/.env.example`(DB·CORS·캐시 변수만). 본 문서 T-04.1.1은 서브패키지 `__init__.py`만 생성.
- **SP-DB 위임**: 5종 테이블 DDL·`AMT_SOURCE_CD` 컬럼·제약. 본 도메인은 스키마를 SELECT로 소비만(SP-API-7/10/11 SQL).
- **SP-SEED 위임**: 런타임 데이터(유형 6종·프리셋·96개 회사 복지·별칭). 무 DB 테스트는 monkeypatch 캔드 주입, 실 데이터 스모크는 SP-SEED.
- **SP-FE 위임**: 번들 로드 실패(FR-E1)·검색 폴백(FR-E2)·`value_source` 프로버넌스·클라이언트 밴드 렌더. 서버는 근거 필드만 전달(INV-5).
- **SP-ENGINE 위임**: 불확실성 밴드 계산(±5/±20/만료+15)·계산 순수성(T5). 서버는 `amt_source`·`expires_dtm`·`badge_cd` 원시값만 노출.

## 추적 (리프 → SPEC 항목 → 테스트 → 상위)
| 리프 | SP 항목 | 테스트 케이스 | 상위 FR/INV/NFR |
| --- | --- | --- | --- |
| T-04.1.1 | SP-API-1 | import 스모크·부재 grep | FR-90 · INV-1 · NFR20 |
| T-04.1.2 | SP-API-14.1 | 픽스처 smoke | INV-1 |
| T-04.2.1 | SP-API-2 | config 유닛·부재키 assert | FR-96 · NFR16·NFR22 |
| T-04.2.2 | SP-API-3 | database 유닛·쓰기헬퍼 부재 | FR-93 · INV-1·NFR20 |
| T-04.2.3 | SP-API-4 | cache 유닛(만료·clear) | FR-92·FR-96 · NFR3 |
| T-04.3.1 | SP-API-6.1 | TR-4 부분·모델 유닛 | FR-D1~D5 · INV-5 |
| T-04.3.2 | SP-API-6.2·6.3 | 모델 유닛(5필드·health) | FR-D6·FR-91·FR-95 |
| T-04.4.1 | SP-API-7 | 빌더 유닛(3키·별칭·bool) | FR-92·FR-D1·D4·D5 · SP-DB-14 |
| T-04.5.1 | SP-API-5 | 앱 부트 스모크 | FR-90·FR-96 · INV-1 |
| T-04.5.2 | SP-API-14 | TS-1 (Tier0) | INV-1 · FR-90·FR-95 |
| T-04.5.3 | SP-API-14·5 | TS-2 (Tier0) | INV-1 · NFR16·NFR20 |
| T-04.5.4 | SP-API-13·5 | TCORS-1·TCORS-2 | FR-96 · INV-7·NFR17 |
| T-04.5.5 | SP-API-5·12 | TN-1·TM-1 | FR-90·FR-95 · INV-1 |
| T-04.6.1 | SP-API-8 | TH-1 | FR-91 · UC-A5·NFR20 |
| T-04.6.2 | SP-API-8 | TH-2 (선택·DG-4) | FR-91 · NFR20 |
| T-04.7.1 | SP-API-9·7 | TR-1 (Tier0) | FR-92·FR-D1 · INV-2 |
| T-04.7.2 | SP-API-9·13 | TR-2 (Tier0) | FR-92·FR-96 · INV-2·7·NFR3 |
| T-04.7.3 | SP-API-9·7 | TR-3 (Tier0) | INV-2 · SP-DB-14 |
| T-04.7.4 | SP-API-9·6·7 | TR-4 | FR-D1·D4·D5 |
| T-04.7.5 | SP-API-9·4 | TR-5 (Tier0) | FR-92·FR-96 · NFR3 |
| T-04.7.6 | SP-API-9·4 | TR-6 | FR-92 · NFR3 |
| T-04.8.1 | SP-API-10 | TSE-1 | FR-93·FR-D6 · SP-DB-3·4 |
| T-04.8.2 | SP-API-10 | TSE-2·TSE-3·TSE-4 | FR-93 |
| T-04.8.3 | SP-API-10 | TSE-5·TSE-7 | FR-93 · §6 |
| T-04.8.4 | SP-API-10·3 | TSE-6 | FR-93 · NFR20 |
| T-04.9.1 | SP-API-11 | TC-1 | FR-94·FR-D4·D7 · SP-DB-3~5 |
| T-04.9.2 | SP-API-11·12 | TC-2·TC-3·TC-4 | FR-94·FR-E6 · NFR26 |
| T-04.10.1 | SP-API-12 | TE-1 | FR-95·FR-D11·FR-E7 · NFR16·NFR26 |
| (위임) | SP-API-7 / INV-2 | T3 → SP-ARCH T-01.3.1 | FR-92·FR-D* |
| (위임) | SP-API-1 / — | requirements·.env → SP-ARCH T-01.2.1 | F8·NFR16 |
| (위임) | SP-API-5 / INV-1 | T7·T8 스모크 → SP-ARCH/SP-INFRA M8 | FR-96·NFR3 |
