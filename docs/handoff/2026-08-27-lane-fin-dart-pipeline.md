# 세션 기록 — 2026-08-27 · 레인 A+C(재무 파이프라인+생성기) · DART 재무 PR-2

브랜치 `lane/fin-dart-pipeline`. `SPEC/15-회사정보-재무.md`(SP-FIN) · `TASK/15` 의 리프
**T-15.1.1~15.1.5 · T-15.2.1~15.2.4** 를 구현했다. **T-15.3.1(서빙 적재·재생성·릴리스)은 하지
않았다** — 관제 몫. 서빙 DB·nginx·release.sh 무접촉.

## 한 일 (커밋 순)

| # | 커밋 | 내용 |
|---|---|---|
| 1 | 데이터 파이프라인 | `db/seed/load_corp.py`(CSV → TCORP·TCOMPANY_CORP 멱등) · `db/seed/dart_finance.py`(수집기+결측 검사+`--probe`) · `config.dart_api_key` · `load.py` 마지막 단계 배선 · 픽스처 4사 JSON · FN-1/2/3/4 테스트 |
| 2 | 생성기 | `generator/finance.py`(로더·뷰) · `bundle.load_bundle_with_finance` · `build --finance-json` · `context.finance` · `format.krw_eok/pct_delta` · `_finance_table.html` · 회사 상세 실적 섹션 · `/companies` 일반/금융 섹션 · FN-5/6/7 테스트 |
| 3 | 문서 | 이 기록 + `PITFALLS/_incoming` 2건 |

### 데이터 파이프라인 (SP-FIN-2·3)

- **`load_corp.apply(cur, rows)`** — 회사는 **`COMP_NM` 으로** 맞춘다. CSV `comp_id` 는 힌트이고
  다르면 요약 한 줄로 경고(`id_drift`). `UNMAPPED`(CJ올리브영)는 건너뛰고 표준출력에 남긴다.
  금융 7사 `financial`, 나머지 `general`, `FS_DIV_CD` 는 최초 삽입만 `CFS`(재적용 때 안 덮는다 —
  운영자가 지주사를 OFS 로 돌린 결정을 재시드가 되감지 않게). `TCORP.CORP_NM` 은 note 의 DART 명
  (`케이티`·`씨제이올리브네트웍스`·`NC`·`LIG디펜스앤에어로스페이스`) 우선. **`TCOMPANY_CORP` 는 CSV 와
  완전 동기화**(CSV 밖 잔존 행 삭제) — `--fresh` 뒤 옛 COMP_ID 행이 남의 회사로 재해석되는 것을 막는다.
  `TCORP` 는 지우지 않는다(재무가 CASCADE 로 매달려 있다).
- **`load.py` 6단계**로 편입(백필 뒤, 커밋 전 같은 트랜잭션). `stats["corp_mapped"]`·`corp_unmatched`.
- **`dart_finance.collect(cur, corps, api_key=…, base_year=…, years=5, fetch_fn=…, sleep_sec=…)`** —
  `account_id` 3종만, CFS·OFS 둘 다, 보고서가 있으면 **3계정 행 전부**(없는 계정은 AMT_VAL NULL +
  그 보고서 접수번호). 013 은 "보고서 없음"(행 없음)으로 구분된다. 키 없으면 fetch 전에 `DartError`.
  전송 예외는 `str(exc).replace(api_key, "***")` 로 가린 채 다시 던진다.
- **`check_missing(cur, base_year, corps)`** — 표시 기준(`TCORP.FS_DIV_CD`)의 최신연도에서 필수 계정
  (일반 3 / 금융 순이익 1) NULL·부재 → 목록. 반대 기준에 있으면 `hint`("OFS 에는 있음 — FS_DIV_CD 를
  확인하라") — 자회사 없는 회사는 데이터 문제가 아니라 설정 문제다.
- **`--probe CORP_CODE`**: DB 무접촉 1회 호출 스모크. 실호출 1회 결과(삼성전자 2025 CFS):
  `status=000 rows=229 · 매출 3,336,059억 · 영업이익 436,011억 · 순이익 452,068억 · rcept 20260310002820`
  — `PLAN-확장` §5-2 실측과 일치. 파서가 실응답을 읽는다.

### 생성기 (SP-FIN-4·5)

- 재무는 **번들 dict 밖**: `load_bundle_with_finance() -> (bundle, finance)` 가 같은 커넥션에서
  `generator/finance.load_finance` 를 부르고, `build_context(bundle, finance=…)` 로 흘린다.
  `services/reference.py`·`models/reference.py` 무변경(FN-6 가드가 텍스트로 못박음).
- `build.py`: `--finance-json`(`--bundle-json` 의 짝, 단독이면 rc 2). DB 경로는 자동. 재무가 0건이면
  stderr 에 한 줄 남기고 실적 없이 렌더한다.
- **화면 결정 2가지(스펙 밖, 근거 있음)**:
  1. **재무가 빌드에 한 건도 안 실렸으면 섹션 자체를 내지 않는다**(`Ctx.finance_loaded`). 스펙은
     "없음 → '공시 데이터 없음' 문구, 섹션은 남긴다"인데, 그건 **수집이 돈 뒤** 개별 회사가 없을 때의
     계약이다. 수집 전 릴리스가 102개사 전부에 "비상장 또는 미제출"을 찍으면 삼성전자에 대한 거짓
     진술이다. 수집 후에는 스펙 그대로(SK하이닉스 픽스처 = 없음 문구). `/companies` 도 같은 규칙 —
     미적재면 기존 목록, 적재면 일반/금융 표.
  2. **고지문 "공시 수치이며 평가나 전망이 아닙니다"는 금지 어휘 `전망` 을 담고 있다.** 스펙이 둘 다
     요구하므로 FN-6 가드는 **그 문장을 정확히 그 형태로만** 걷어낸 뒤 검사하고, 문장이 실제로 있는지와
     `전망` 이 페이지에 정확히 1번인지도 함께 잰다(예외가 다른 문장을 숨기지 못하게).
- 행은 **최신 연도 먼저**, 증감률 분모는 `abs(prev)`(적자 기준에서 부호가 방향을 말하게). 출처 링크는
  최신 보고서 1개(사업보고서가 3개년 비교치를 싣는다). 접수번호가 숫자가 아니면 링크를 안 만든다.
- 형제 페이지 문장 "법인 기준 공시 — CJ ENM 커머스부문과 같은 법인의 수치입니다." — 조사(과/와)는
  받침으로 고른다(`_josa`).
- `/companies`: `<h1>` 유지, `<section data-acct-set="general|financial">`, 금융 0곳이면 섹션 생략,
  가나다 정렬은 **섹션 안에서**(GC-27 의 전역 정렬 계약은 섹션 분리로 섹션별 계약이 됐다 — 기존
  테스트는 재무 없는 목록 경로라 그대로 통과). 표 스타일은 `.benefit-table` 재사용(CSS 무변경).

## 검증

| 스위트 | before | after |
|---|---|---|
| 생성기 `pytest generator/tests` | 242 | **277** (+35, 회귀 0) |
| 백엔드 `DB_NAME=loupit_test pytest server/tests -m "not sc14"` | 559 (401 pass + 158 error — worktree 에 .env 부재. 관제가 놓은 뒤 559) | **596** (+37: test_corp_load 9 · test_dart_finance 28), 1 skipped, 3 deselected |
| 프론트 `node --test 'web/**/*.test.js'` | 705 | 705 (무변경 확인) |

TDD: 신규 테스트 전부 RED(ModuleNotFoundError/AttributeError) 확인 후 GREEN. CLI 렌더 1회
(`--bundle-json`+`--finance-json` → scratchpad `dist-fin`, rc 0) — 삼성전자 실적 섹션·네이버(금융
열)·인덱스 두 섹션 눈으로 확인. `--out web/dist` 는 쓰지 않았다.

## 알게 된 것

- **CSV `comp_id` 는 fresh 재시드 DB 에서 101행 중 100행이 어긋난다**(DB손해보험 csv=2/db=9).
  CSV 는 증분 적재된 prod 의 ID 이고, `--fresh` 는 파일 순서로 재배정한다. id 조인이었다면 삼성전자
  페이지에 남의 실적이 갔다 — 에러 없이. → `_incoming/csv-comp-id-drifts-on-fresh-seed.md`
- `run_tests.sh` 는 2026-08-26 부터 서빙 스키마를 만지지 않는다(loupit_test 전용). `conftest.py` 의
  "run_tests.sh 백업/재주입 목록에도 넣어야 한다" 주석은 **그 이전 판본 기준**이라 재무 3테이블에는
  해당 없다 — 서빙 `TCORP_FINANCE` 는 게이트에 지워지지 않는다. 서빙 `load.py --fresh` 도 TCORP 를
  DROP 하지 않는다(참조 5테이블만).
- `INSERT … AS new ON DUPLICATE KEY UPDATE new.col` 별칭 문법을 썼다(`VALUES()` 는 8.0.20 부터
  deprecated). **MySQL ≥ 8.0.19 필요** — 서버는 8.0.42.
- `Settings(_env_file=None)` 은 os.environ 을 못 끊는다 — conftest 가 `.env` 를 `load_dotenv` 로
  붓기 때문에 `DART_API_KEY` 가 들어간 호스트에서 기본값 테스트가 빨강이 됐다. `delenv` 로 걷어냈다
  (함정 0079 와 같은 결).
- pymysql 은 파라미터 없는 SQL 도 `%` 포맷을 거친다 — `LIKE 'CJ ENM %'` 는 `%%` 로.
- `--fresh` 는 TCOMPANY 를 DROP 하지만 `TCOMPANY_CORP`(FK ON DELETE CASCADE)는 `FOREIGN_KEY_CHECKS=0`
  아래라 **행이 살아남는다** — 그래서 load_corp 의 "CSV 밖 잔존 행 삭제"가 필요하다.

## 남긴 것 (미결)

- **T-15.3.1 — 관제 실행 커맨드** (서빙 `server/.env` 에 `DART_API_KEY` 가 있어야 한다):
  ```
  cd /home/ubuntu/loupit && python3 db/seed/load_corp.py
  cd /home/ubuntu/loupit && python3 db/seed/dart_finance.py --base-year 2025 --years 5 --sleep 0.05
  ```
  두 번째가 **rc 0**(결측 0)이어야 재생성으로 간다. rc 1 이면 결측 목록이 찍힌다 — `hint` 가
  "OFS 에는 있음"이면 `UPDATE TCORP SET FS_DIV_CD='OFS' WHERE CORP_CODE=…` 후 재실행(멱등). 재실행은
  UNIQUE upsert 라 안전하고, 받은 것은 결측이 있어도 커밋된다. 그 뒤 `release.sh`(빌드가 DB 에서
  재무를 자동으로 읽는다 — 0건이면 stderr 한 줄 + 실적 없이 렌더).
- **OI-D(금융 영업수익 계정)** 미확정 — 첫 실수집에서 금융 7사 응답의 `account_id` 를 보고 정한다.
  지금은 순이익만(주석에 OI-D 표시).
- 상장 후 5년 미만·비상장(CJ올리브네트웍스)은 013 이 정상 — 결측 목록에 오르면 `hint` 없이 뜬다.
  그 경우 "공시 데이터 없음(비상장 또는 미제출)"이 맞는 표현이니 그대로 둔다.
- **CSS**: 실적 표는 `.benefit-table` 을 빌려 쓴다. 전용 스타일(`.finance-*`)은 레인 D/프론트 몫.
- 두께 재측정(중앙값 목표 ~1,900자)·`STATE.md`·`TASK/15` 마커 갱신은 머지 뒤 관제가.
