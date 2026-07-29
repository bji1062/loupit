---
name: parse-benefits
description: >
  loupit 회사 복지 시드 SQL 생성·갱신. 저장된 원문(db/seed/benefit/raw/{회사명}.txt) 또는
  채용/복지 페이지 URL을 AI 파싱해 db/seed/benefit/sql/{회사명}.sql(TCOMPANY_BENEFIT 10컬럼
  INSERT)을 만들고 시드 카운트 테스트 상수까지 함께 갱신한다. 회사 복지 데이터를 새로 추가하거나
  기존 회사 복지를 재파싱·갱신할 때 사용. 복지 9카테고리 분류·BENEFIT_CD 정본 목록·금액 연간환산
  앵커의 정본 문서이기도 하다.
argument-hint: "{회사명} [--url URL] [--eng snake_case] [--type large|startup|mid|foreign|public|freelance] [--industry 업종] [--logo 약어] [--dry-run] [--force]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebFetch, AskUserQuestion
---

# /parse-benefits — 복지 원문 → 시드 SQL

`/parse-benefits {회사명} [옵션]` 으로 호출한다. 산출물은 **`db/seed/benefit/sql/{회사명}.sql` 하나**이며,
정식 시드 파이프라인(`python3 db/seed/load.py`)에 그대로 편입된다.

## §0 적용 범위와 현재 상태

- **loupit 저장소 전용.** 저장소 루트에서 실행한다.
- 이 스킬이 만드는 SQL은 **백필 전 중간 산출물**이다. `BADGE_CD='est'`로 쓰고,
  `db/seed/backfill_dec2.py`가 `official` 승격·`AMT_SOURCE_CD` 도출·`VERIFIED_DTM`/`EXPIRES_DTM`
  설정을 담당한다. 백필을 거치지 않으면 데이터 계약 위반 상태다.
- `docs/RESEARCH/benefit-scraping.md:162`(§6 CHANGE)는 이 **대화형 경로를 Phase 2에서
  SDK `client.messages.parse()` 배치로 대체**할 것을 확정했다. 그때까지 이 스킬은 유효한
  수동·증분 경로이며, 이후에는 §5 앵커·§4 코드 목록·§7 문구 규칙을 배치 프롬프트에 공급하는
  정본 문서로 축소된다.
- 스크래퍼(`scrape_benefits.py`)는 **이 저장소에 이식되지 않았다.** 입력은 §2 단계 2의 두 경로로 확보한다.

## §1 불변 계약 — 깨면 시드 전체가 실패한다

| # | 계약 | 근거 | 깨졌을 때 |
|---|---|---|---|
| C-1 | 파일은 `db/seed/benefit/sql/*.sql` 안에만 | `db/seed/load.py:28,178` | 이 디렉토리 밖이면 시드에서 **영구 제외** |
| C-2 | 회사 자기등록 INSERT의 `VALUES ('eng','nm',(SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD='type')` 형태 유지 | `db/seed/company_meta.py:38-41` 정규식 | `parse_header_insert` 예외 → **시드 4단계 전체 실패(모든 회사)** |
| C-3 | 헤더 주석 `-- 출처: AI 파싱 (YYYY-MM-DD)` / `-- URL: ...` 2줄 형식 유지 | `db/seed/backfill_dec2.py:32-33` 정규식 | 날짜 미매치 시 **조용히** `2026-07-10` 폴백, URL 미매치 시 출처 링크 소실 |
| C-4 | INSERT는 **10컬럼 고정** | 95개 파일 전부 동일 | 나머지 6컬럼은 백필이 파생. 직접 쓰면 무의미하고 ODKU 불일치 발생 |
| C-5 | 4문장 구조: `INSERT IGNORE` → `SET @comp_id` → `DELETE` → `INSERT…ODKU` | `db/seed/load.py:39-64` 분할 | 문장 수가 4가 아니면 이스케이프 오류 |
| C-6 | 문자열 이스케이프는 `''` 만. **`\'` 금지** | `load.py:39-64` 따옴표 단순 토글 파서 | 문장 분할이 어긋나 문법 오류 또는 엉뚱한 문장 실행 |
| C-7 | 시드 파일의 `BADGE_CD`는 **항상 `'est'`** | 백필이 승격 | `verified`/`official`을 직접 쓰면 DELETE가 자기 행을 못 지워 멱등성 상실(SM-1 실패) |

## §2 실행 단계

### 단계 0 — 전제 확인

`db/seed/load.py`와 `db/seed/benefit/sql/`이 있는지 확인한다. 없으면 **중단**: "loupit 저장소 루트에서 실행하세요."
`git status --short`를 기록해 두고, 완료 보고에 롤백 명령을 포함한다.

### 단계 1 — 인자·식별자 확정

| 값 | 1순위 | 2순위 | 3순위 |
|---|---|---|---|
| `COMP_NM` | 위치 인자 `{회사명}` (필수) | — | — |
| `COMP_ENG_NM` | `--eng` | 기존 SQL 헤더(단계 3) | AskUserQuestion |
| `COMP_TP_CD` | `--type` | 기존 헤더 | AskUserQuestion (6종 제시) |
| `INDUSTRY_NM` | `--industry` | 기존 헤더 | AskUserQuestion |
| `LOGO_NM` | `--logo` | 기존 헤더 | 회사명 이니셜 제안 후 확인 |
| `CAREERS_BENEFIT_URL` | `--url` | 기존 헤더 | `NULL` |

`--eng`가 `^[a-z][a-z0-9_]{0,29}$`(30자 이내)를 위반하면 재질의한다.
셸 인자의 회사명은 항상 큰따옴표로 감싼다.

### 단계 2 — 입력 확보 (2경로)

```
경로 A (우선) : db/seed/benefit/raw/{회사명}.txt 존재 → Read 로 사용
경로 B        : A 부재 + --url 주어짐 → WebFetch → 본문을 raw/{회사명}.txt 로 저장 후 사용
```

- 경로 B의 WebFetch 프롬프트는 **"복지/베네핏 관련 문단을 원문 그대로, 요약·재서술 없이 나열"**로
  고정한다. 요약이 오면 항목이 소실된다.
- 저장 시 첫 두 줄에 프로버넌스를 남긴다: `# source: {url}` / `# fetched: {YYYY-MM-DD}`
- `db/seed/benefit/raw/`가 `.gitignore`에 없으면 추가를 **제안**한다(자동 수정 아님).
  회사 페이지 원문 전량 커밋은 `docs/RESEARCH/benefit-scraping.md` §5-4 원본 미복제 원칙과 충돌한다.

**분기**
- A·B 둘 다 없음 → **중단**:
  ```
  입력이 없습니다. 둘 중 하나를 하세요.
    1) db/seed/benefit/raw/{회사명}.txt 에 복지 페이지 원문을 저장 후 재실행
    2) --url "{공식 채용/복지 페이지 URL}" 을 붙여 재실행
  ```
- WebFetch 실패(403·robots·로그인 게이트) → **중단**, 경로 1 안내.
  우회 시도 금지(`docs/RESEARCH/benefit-scraping.md` §5-1 robots/ToS 준수).
- 파일이 비었거나 복지 키워드(식대·휴가·보험·근무·지원·검진 등)가 하나도 없으면 경고 후 사용자 확인.

### 단계 3 — 환경 프로브와 기존 데이터 조회

```bash
ls server/.env 2>/dev/null; python3 -c "import pymysql, dotenv" 2>&1 | tail -1
```

**DB 경로**(둘 다 OK일 때만): `python3 -c` 인라인으로 `dotenv`+`pymysql` 조회.
**`mysql -u ... -p{평문}` CLI는 절대 쓰지 않는다** — 평문 비밀번호는 `db/seed/load.py:10-11`
원칙 위반이고, 접속 정보는 `server/.env`에만 있다. 조회 항목:

1. `SELECT COMP_ID FROM TCOMPANY WHERE COMP_NM=%s`
2. `SELECT BENEFIT_CD, BENEFIT_NM, BADGE_CD, BADGE_SRC_CD FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c USING(COMP_ID) WHERE c.COMP_NM=%s AND b.BADGE_CD IN ('verified','official')`
3. `SELECT 1 FROM TCOMPANY WHERE COMP_ENG_NM=%s AND COMP_NM<>%s` (eng 충돌)

**파일 폴백**(기본 경로 — DB 없는 환경이 정상): 기존 시드 SQL을 소스오브트루스로 쓴다.

```bash
python3 -c "
import sys, glob; sys.path.insert(0,'db/seed')
from company_meta import parse_header_insert
for f in sorted(glob.glob('db/seed/benefit/sql/*.sql')):
    print(f, *parse_header_insert(open(f,encoding='utf-8').read()))
"
```

`parse_header_insert`는 레거시 경로를 건드리지 않아 DB 없이도 동작한다. 이걸 쓰면 스킬과
시드의 파싱 계약이 자동으로 일치한다. **폴백으로는 `verified` 행을 알 수 없다**(시드 파일엔 항상 `est`)
→ 단계 4에서 명시적으로 확인한다.

**분기**
- 같은 `COMP_ENG_NM`이 다른 회사명으로 존재 → **중단**(UNIQUE 위반), 다른 eng 요구
- 같은 회사가 다른 파일명으로 존재(`모비스` vs `현대모비스`) → **중단**, 별칭 통합 안내
- `db/seed/benefit/sql/{회사명}.sql` 이미 존재 → **갱신 모드**(단계 9에서 SD-4만 갱신)

### 단계 4 — verified 사전 확인 게이트

신규 회사면 **생략**(충돌 대상 없음). 기존 회사면:

- **DB 경로에서 verified 행 발견** → 목록을 표로 보여주고 경고:
  > 아래 {N}개 행은 사용자가 직접 편집한 `verified` 행입니다. 생성될 SQL의
  > `ON DUPLICATE KEY UPDATE`가 같은 `BENEFIT_CD`를 덮으면 `BADGE_CD`가 `est`로 초기화되고,
  > `db/seed/backfill_dec2.py:63-65`가 이를 `official`로 승격시켜 **verified 표시가 영구 소실**됩니다.

  선택지: `해당 코드를 결과에서 제외하고 진행` / `덮어쓰기 승인` / `중단`
- **DB 조회 불가** → 무조건 1회 확인하고, 확인용 쿼리를 제시:
  ```sql
  SELECT BENEFIT_CD, BADGE_CD FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c USING(COMP_ID)
   WHERE c.COMP_NM='{회사명}' AND b.BADGE_CD='verified';
  ```
- `--force`면 경고만 출력하고 진행한다.

또한 **재파싱에서 빠진 기존 코드**를 보고한다 — `est` 행이면 DELETE로 사라지고,
`official`/`verified` 행이면 고아로 잔존한다.

### 단계 5 — AI 파싱

원문을 문맥 이해로 파싱한다(정규식 아님). 각 항목 = `{ctgr, cd, nm, amt, note, qual_yn, qual_desc}`.

- **코드 선택**: §4 정본 목록 우선 → 없으면 신규 snake_case(§8 정규식 자가 검증)
- **카테고리**: 코드가 §4에 있으면 **목록의 카테고리를 강제**(파서 판단보다 우선)
- **금액**: 원문 명시 → 연간 환산 / 미명시 → §5 앵커 / 앵커도 없고 §6 정성 목록에 있으면 → `QUAL_YN=TRUE`.
  **앵커에도 정성 목록에도 없는 코드는 금액을 지어내지 말고 정성 처리한다.**
- **`SORT_ORDER_NO`**: 카테고리 밴드 시작값부터 등장 순서대로 1씩 증가(§3 밴드)
- **제외**: 마케팅 슬로건, 네비게이션·푸터, 채용 프로세스 설명, 회사 소개
- **통합**: 한 복지가 여러 세부를 포함하면 대표 코드 하나로 묶고 `QUAL_DESC_CTNT`에 나열
  (예: 출산휴가+육아휴직+어린이집+난임휴가 → `parenting` 하나)

### 단계 6 — 자체 검증 (SQL 쓰기 전, DB 불필요)

| 검사 | 규칙 | 위반 시 |
|---|---|---|
| V-1 | DC-9: `qual_yn=True` ⇒ `amt is None` | 자동 수정(금액 제거) |
| V-2 | DC-11: `amt >= 0` | 중단 |
| V-3 | 길이: nm≤100, note≤200, qual_desc≤500, cd≤30 | 절단 후 보고 |
| V-4 | 도메인: ctgr ∈ 9종, cd 정규식 | 중단 |
| V-5 | 회사 내 `BENEFIT_CD` 유일 | 병합 |
| V-6 | 카테고리 밴드 내 연속·무중복·상한 미초과 | 자동 재부여 |
| V-7 | 정성 행 note=NULL, 금액 행 note 필수 | 자동 수정 |
| V-8 | stated 문구의 숫자 ≟ `BENEFIT_AMT` | note 재작성 |
| V-9 | **백필 결과 예보** — `derive_amt_source`를 실제 함수로 적용 | 표에 표시 |
| V-10 | **앵커 강등 예보** — 신규 `(코드,금액)`이 기존 시드에 몇 개사 있는지 | 표에 표시 |

V-9/V-10 집계:

```bash
python3 -c "
import sys, re, glob, collections; sys.path.insert(0,'db/seed')
from backfill_dec2 import derive_amt_source
pat = re.compile(r\"\(@comp_id,\s*'([a-z0-9_]+)',\s*'((?:[^']|'')*)',\s*(NULL|\d+),\s*'([a-z_]+)',\s*'(\w+)',\s*(NULL|'(?:[^']|'')*'),\s*(TRUE|FALSE),\s*(NULL|'(?:[^']|'')*'),\s*(\d+)\)\", re.S)
pairs = collections.defaultdict(set)
for f in glob.glob('db/seed/benefit/sql/*.sql'):
    for cd,nm,amt,ctgr,bd,note,q,qd,so in pat.findall(open(f,encoding='utf-8').read()):
        a = None if amt=='NULL' else int(amt)
        n = None if note=='NULL' else note[1:-1]
        if derive_amt_source(a, q=='TRUE', n) == 'stated': pairs[(cd,a)].add(f)
for k,v in sorted(pairs.items(), key=lambda x:-len(x[1])):
    if len(v) >= 2: print(len(v), k)
"
```

### 단계 7 — 사용자 확인 표

```
## {회사명} 복지 파싱 결과 ({신규 등록|갱신}, badge=est)

| # | 카테고리 | BENEFIT_CD | 항목명 | 연간(만원) | 정성 | NOTE_CTNT | 백필 amt_source | 앵커 강등 |
|---|---------|-----------|-------|-----------|------|-----------|----------------|----------|
| 1 | perks | meal | 구내식당 | 432 | - | 일 18,000원 x 240일 환산 | estimated | 기존 13사 — 이미 강등군 |
| 2 | perks | welfare_point | 복지포인트 | 200 | - | 연 200만원 지급 | stated → **estimated** | 기존 2사 합류 → 3사 강등 |

행수: {N}  (compensation {a} / flexibility {b} / ...)
금전 합계: 약 {S}만원/연 | 정성 항목: {Q}개
백필 후 예상: stated {x} / estimated {y} / none {z}
경고: 신규 강등 유발 쌍 {목록}
```

AskUserQuestion: `SQL 생성` / `항목 수정 후 재확인` / `중단`.
수정을 택하면 변경 행만 다시 보여주고 승인까지 반복한다. `--dry-run`이면 여기서 종료.

### 단계 8 — SQL 파일 생성

`Write` → `db/seed/benefit/sql/{회사명}.sql` (파일명은 `COMP_NM` 그대로, 한글 허용). 템플릿은 §9.

### 단계 9 — 테스트 상수 자동 갱신

**신규 회사 등록일 때만** 5곳을 `Edit`한다. 갱신 모드면 SD-4만.

| # | 위치 | 현재 | 갱신 |
|---|---|---|---|
| 1 | `server/tests/test_seed_counts.py:33` (SD-3, **Tier-0**) | `== 95` | `+1` |
| 2 | `server/tests/test_seed_counts.py:36,39` (SD-4) | `1317` ×3곳 | `1317 + N`. 주석의 유래 설명은 이어붙여 이력 보존 |
| 3 | `server/tests/test_seed_integrity.py:145` (SI-8) | `== 95` | `+1`. **`:146` `!= 200`은 불변** |
| 4 | `server/tests/test_seed_idempotency.py:52` (SM-1) | `== 95` | `+1` |
| 5 | `server/tests/test_seed_badge_backfill.py:157,168` (SB-10) | 집합 5원소, `== 5` | **헤더 URL이 실제 `http`일 때만** 집합에 eng 추가 + `== 6` |

행수 N은 추측하지 말고 파일에서 직접 센다:

```bash
python3 -c "
import re, glob
pat = re.compile(r'\(@comp_id,')
print(sum(len(pat.findall(open(f,encoding='utf-8').read())) for f in glob.glob('db/seed/benefit/sql/*.sql')))
"
```

**건드리지 않을 것**: `db/seed/load.py:124-127` `_MIN_*` 하한, `test_data_contract.py:46` DC-2(`>= 90`),
`db/seed/reingest_benefit_sql.py:54`(1회성 재이식 스크립트 — §12 T-8 참조).

각 Edit 후 diff를 보여주고, 완료 보고에 되돌리기 명령을 포함한다.

### 단계 10 — 생성 후 검증과 적용 안내

**(A) 정적 검증 — 항상 실행. 저장소의 실제 함수로 계약을 통과시킨다.**

```bash
python3 -c "
import sys, types; sys.path.insert(0,'db/seed')
# load.py 는 모듈 최상단에서 pymysql/dotenv 를 import 하지만 둘 다 함수 안에서만 쓴다.
# DB 드라이버 없는 환경에서도 분할기만 쓰기 위한 스텁(읽기 전용 정적 검증 전용).
for _m in ('pymysql','dotenv'):
    if _m not in sys.modules:
        _s = types.ModuleType(_m); _s.load_dotenv = lambda *a, **k: None; sys.modules[_m] = _s
from company_meta import parse_header_insert
from backfill_dec2 import _DATE_RE, _URL_RE
from load import _split_sql_statements
t = open('db/seed/benefit/sql/{회사명}.sql', encoding='utf-8').read()
print('header:', parse_header_insert(t))            # C-2 — 실패하면 시드 4단계 붕괴
print('date  :', _DATE_RE.search(t).group(1))       # C-3 — 없으면 조용히 폴백
m = _URL_RE.search(t); print('url   :', m.group(1) if m else 'ai_parse(URL NULL)')
print('stmts :', len(_split_sql_statements(t)))     # C-5 — 4 기대
"
```

- `parse_header_insert` 예외 → 헤더가 깨짐. **생성물 폐기 후 재생성.**
- `stmts != 4` → 이스케이프 오류(`\'` 사용 등).

**(B) 적용 (DB 있는 호스트에서만)**

```bash
python3 db/seed/load.py          # 멱등 재적용, 단일 트랜잭션(예외 시 rollback), 백필 포함
bash infra/deploy/run_tests.sh   # 릴리스 게이트
```

`mysql < file.sql` 단독 적용은 **금지** — 백필을 건너뛰어 `BADGE_CD='est'` 잔존(DC-13 Tier-0),
`AMT_SOURCE_CD` 기본값 오분류(DC-9), `VERIFIED_DTM` NULL(DC-14) 상태가 서빙 DB에 남는다.

**(C) 환경 경고** — `db/seed/company_meta.py:23,133`이 `/home/ubuntu/job_change/server/seed`를
무가드로 로드한다. 이 경로가 없는 머신에서는 `load.py`가 **4단계에서 실패**한다. 그런 환경에서는
(A) 정적 검증까지만 수행하고, 실적용·pytest는 레거시 시드가 있는 호스트에서 한다.
신규 회사는 미매칭 폴백(`company_meta.py:143-145`)으로 자기명 별칭이 시드되어 SD-6/DC-4는 통과한다.

---

## §3 카테고리 9종

| 코드 | 파싱 라벨 | **서비스 표시 라벨** | SORT 밴드 | 포함 항목 |
|---|---|---|---|---|
| `compensation` | 보상·금전 | **보상** | 1-9 | 성과급(PS/PI), 인센티브, 스톡옵션, RSU, 명절상여, 포상금 |
| `flexibility` | 근무유연성 | **유연성** | 10-19 | 재택, 원격, 시차출퇴근, 유연근무, PC-OFF, 패밀리데이, 거점오피스 |
| `work_env` | 근무환경 | **근무환경** | 20-29 | 사무공간, 장비, 기숙사/사택, 수면실, 라운지, 주차공간 |
| `time_off` | 시간·휴가 | **휴가** | 30-39 | 하계집중휴가, 리프레시, 안식월, 장기근속휴가, 보건휴가 |
| `health` | 건강·의료 | **건강** | 40-49 | 종합검진, 단체보험, 사내의원, 심리상담, 헬스장, 운동비 |
| `family` | 가족·돌봄 | **가족** | 50-59 | 임신/출산/육아휴직, 어린이집, 자녀학자금, 경조사 |
| `growth` | 성장·커리어 | **성장** | 60-69 | 직무교육, 어학, MBA/석박사 파견, 자기계발비, 도서비, 컨퍼런스 |
| `leisure` | 여가·라이프 | **여가** | 70-79 | 휴양시설/콘도, 동호회, 웰컴키트, 사내편의시설(안마/북카페) |
| `perks` | 경제적 부가혜택 | **복리후생** | 80-89 | 식대, 통근비, 통신비, 복지포인트, 자사할인, 사내대출 |

- **서비스 표시 라벨**이 정본이다(`docs/SPEC/07-정적-생성기.md:467-469` `CATEGORY_LABEL`).
  파싱 라벨은 SQL 주석용으로만 쓴다(기존 95개 파일과 동일하게 유지).
- 밴드 실사용 최대치: perks 8, health 6, family 5, growth 5, time_off 4, work_env 4, 나머지 3.
  밴드를 초과할 만큼 항목이 많으면 먼저 통합한다.

## §4 BENEFIT_CD 정본 목록

실사용 64종 전수. `[dep]`는 폐기 예정 — 신규 사용 금지.

```
compensation (1-9)
  bonus · stock_option · stock_grant · profit_sharing · incentive
  holiday_gift · excellence_award
flexibility (10-19)
  flex_work · remote_work · pc_off · family_day · satellite_office
  [dep] remote_office → satellite_office
work_env (20-29)
  work_tools · dormitory · lounge · nap_room · parking
time_off (30-39)
  refresh_leave · long_service_leave · summer_leave · leave_general · birthday_leave
  [dep] long_service → long_service_leave
health (40-49)
  health_check · medical · insurance · mental · fitness · clinic
family (50-59)
  child_edu · parenting · wedding · event · childcare · fertility_support
growth (60-69)
  lang · edu_support · career · books · conference · mba · self_development
  retirement_support
leisure (70-79)
  club · library · resort · welcome_kit · massage
  leisure_room · leisure_ticket · sports_ticket
perks (80-89)
  welfare_point · meal · transport · telecom · discount · housing_loan
  snack_bar · commute_subsidy · pension_support · birthday_gift
  housing_support · relocation
```

**카테고리 충돌 6종 확정** — 기존 시드에 두 카테고리로 섞여 있는 코드다. 신규는 아래를 따른다.

| 코드 | 기존 분포 | **확정** | 근거 |
|---|---|---|---|
| `holiday_gift` | compensation 16 / perks 13 / family 1 | **compensation** | 명절상여는 금전 보상 |
| `parking` | work_env 7 / perks 5 | **work_env** | 주차 *공간* 제공. 주차 *비용* 지원은 `commute_subsidy` |
| `work_tools` | work_env 7 / perks 4 | **work_env** | 장비·사무기기 제공 |
| `family_day` | flexibility 6 / time_off 1 | **flexibility** | 정기 조기퇴근 = 근무유연성 |
| `welcome_kit` | leisure 6 / work_env 1 | **leisure** | |
| `massage` | leisure 4 / health 1 | **leisure** | 의료 처치가 아닌 편의시설 |

**기존 95개 파일은 수정하지 않는다** — 소급 수정은 D2.4 실데이터 보존 원칙에 반하고 밴드 정렬이
흔들린다. 기존 소수파 배치는 알려진 불일치이며, 신규만 정본을 따른다.

신규 코드는 정본에 대응이 없을 때만 만들고, `^[a-z][a-z0-9_]{1,29}$`를 지킨다.
예: `vehicle_discount`, `family_trip`, `referral_bonus`

## §5 금액 앵커 (정본)

원문에 금액이 없을 때만 쓴다. **연간 만원 단위.** 값은 시드 1317행 실측 중앙값/최빈값 기준이다.

| 코드 | 앵커 | 근거 | 금액행/전체 |
|---|---|---|---|
| `meal` | **432** | 일 18,000 × 240일. 최빈 432(45사) | 63/63 |
| `health_check` | **100** | 최빈 100(77사) — 사실상 표준 | 79/79 |
| `welfare_point` | **200** | 최빈 200(33사). 월정액 명시 시 ×12 | 55/55 |
| `resort` | **50** | 최빈 50(57사) | 65/65 |
| `event` | **50** | 최빈 50(36사) | 50/80 |
| `child_edu` | **200** | 최빈 200(27사) | 43/60 |
| `medical` | **100** | 최빈 100(32사) | 39/40 |
| `insurance` | **30** | 최빈 30(33사) | 36/36 |
| `holiday_gift` | **20** | 최빈 20(15사) | 27/30 |
| `commute_subsidy` | **120** | 최빈 120(15사) | 18/19 |
| `transport` | **120** | 최빈 120(11사) | 14/14 |
| `snack_bar` | **43** | 중앙 43, 분포 20~144 | 24/44 |
| `incentive` | **500** | 최빈 500(9사). 편차 큼 — **원문 우선** | 16/29 |
| `excellence_award` | **50** | 50(7사)/30(6사) | 13/21 |
| `telecom` | **30** | 최빈 30(5사). 월정액 시 ×12 | 8/8 |
| `discount` | **100** | 중앙 100, 분포 30~200 | 9/29 |
| `pension_support` | **50** | 6/6 전부 50 | 6/6 |
| `club` | **10** | 최빈 10(6사) | 11/48 |
| `books` | **10** | 중앙 10 | 5/17 |
| `self_development` | **50** | 중앙 50 | 5/11 |
| `parenting` | **50** | 중앙 50 — 대부분 정성 | 7/31 |
| `fitness` | **30** | 중앙 30 — 대부분 정성 | 4/36 |
| `lang` | **50** | 중앙 50 — 대부분 정성 | 4/28 |
| `edu_support` | **50** | 중앙 50 — 대부분 정성 | 3/50 |
| `birthday_leave` | **7** | 중앙 7 — 대부분 정성 | 4/15 |
| `welcome_kit` | **50** | 2건 | 2/7 |
| `fertility_support` | **55** | 2건 | 2/4 |
| `refresh_leave` | **150** | 2건. 휴가 자체는 정성, **휴가비 명시 시에만** | 2/28 |
| `long_service_leave` | **600** | 2건. 대부분 정성 | 2/39 |
| `bonus` · `profit_sharing` | **없음** | 회사별 편차 극심 — **추정 금지**, 원문 명시 시에만 | 1/3, 1/4 |
| `housing_loan` | **없음** | 48/49가 정성(이자지원은 환산 부적절) | 1/49 |

### 앵커 강등 규칙과의 상호작용

`db/seed/backfill_dec2.py:79-100`: 동일 `(BENEFIT_CD, BENEFIT_AMT)`가 **3개사 이상**에서 `stated`면
전부 `estimated`로 강등된다.

1. **앵커를 쓰면서 stated로 만들 이유가 없다.** `health_check=100`은 이미 25사, `meal=432`는 13사가
   강등군이다. note에서 "추정/환산"을 빼 stated로 만들어봐야 백필이 즉시 강등한다.
   → **앵커 사용 = §7의 estimated 문구**로 통일한다. 결과가 같으니 정직한 표기를 택한다.
2. **stated는 회사 고유 명시 금액 전용이다.**
3. **경계(2개사) 쌍 합류 시 부작용** — 신규 회사가 기존 2개사 쌍에 합류하면 **기존 2개사의 stated까지**
   estimated로 바뀐다. 단계 6 V-10이 이를 사전 예보하고 단계 7 표에 표시한다.
   회피: 원문이 "월 20만 포인트"라면 note를 `월 20만 포인트 → 연 240만원 환산`으로 써서 estimated로 둔다.

## §6 정성 전용 코드 — 금액 추정 금지

시드 1317행에서 **금액이 한 번도 부여된 적 없는** 코드다. `QUAL_YN=TRUE` · `BENEFIT_AMT=NULL` ·
`NOTE_CTNT=NULL` · `QUAL_DESC_CTNT` 필수로 처리한다.

```
flex_work · remote_work · pc_off · family_day · satellite_office · remote_office
dormitory · lounge · nap_room · parking
summer_leave · leave_general · long_service
childcare · mental · clinic
mba · career · conference · retirement_support
library · massage · leisure_room · leisure_ticket
stock_option · housing_support · relocation
```

앵커(§5)에도 이 목록에도 없는 코드는 **금액을 지어내지 말고 정성 처리**한다.

## §7 NOTE_CTNT · QUAL_DESC_CTNT 작성 규칙

백필 판정(`db/seed/backfill_dec2.py:36-43`):

```
qual_yn=TRUE 또는 amt IS NULL                        → none
note에 "추정" 또는 "환산" 포함, 또는 note가 빈 문자열  → estimated
그 외                                                 → stated
```

**주의**: `note or ""` 이므로 note가 NULL이어도 `estimated`가 된다. 또 "추정"·"환산"은
**부분 문자열 매치**라 "미추정", "환산 불필요" 같은 부정 표현도 estimated로 넘어간다.

| 행 유형 | NOTE_CTNT | QUAL_DESC_CTNT | 결과 |
|---|---|---|---|
| 정성 (`QUAL_YN=TRUE`, AMT NULL) | **NULL** | 필수(짧은 발췌) | `none` |
| stated (원문 명시 금액) | 근거 문장, **"추정"·"환산" 금지**, 연간 만원 숫자 포함 | NULL | `stated` |
| estimated (앵커·계산·업계평균) | **"추정" 또는 "환산" 필수** | NULL | `estimated` |

**stated 예시**
```
'복지포인트 연 240만원 지급'                  → AMT=240
'월 20만원 지급(연 240만원)'                  → AMT=240
'명절 상여 60만원(설·추석 각 30만원)'         → AMT=60
'자녀 1인당 학자금 연 300만원 지원'           → AMT=300
```
**estimated 예시**
```
'일 18,000원 x 240일 환산'                    → meal 432
'(추정)'                                      → 최소 형태
'업계 평균 기준 추정'                          → 앵커 사용 시 기본형
'월 20만 포인트 → 연 240만원 환산'
```

**QUAL_DESC_CTNT**: 스키마 주석이 **'짧은 발췌만, 원문 복제 금지'**를 명시한다. 상한은 500자지만
실무 목표는 **120자 이내**. 마케팅 문구·슬로건 금지, 사실 항목만. 여러 세부를 통합할 때 여기에 나열한다.
정성 행에만 채운다(비정성 행은 NULL — 실측 0건 규율 유지).

## §8 스키마 제약 체크리스트

| 컬럼 | 제약 | 강제할 것 |
|---|---|---|
| `BENEFIT_CD` | VARCHAR(30), `^[a-z][a-z0-9_]{1,29}$` (`server/models/benefit_edit.py:21`) | 2~30자, 소문자 시작, 회사 내 유일 |
| `BENEFIT_NM` | VARCHAR(100) NOT NULL | 짧은 한국어 명칭 |
| `BENEFIT_AMT` | INT NULL, DC-11 `< 0` 금지 | **연간 만원 정수**, 정성이면 NULL |
| `BENEFIT_CTGR_CD` | VARCHAR(20) NOT NULL | §3 9종 화이트리스트 |
| `BADGE_CD` | 도메인 `official`·`est`·`verified` | 시드는 **항상 `'est'`**. `expired`는 DB 값이 아닌 파생 표시상태 |
| `AMT_SOURCE_CD` · `BADGE_SRC_CD` · `BADGE_SRC_URL_CTNT` · `VERIFIED_DTM` · `EXPIRES_DTM` | — | **INSERT에 쓰지 않음** — 백필이 파생 |
| `NOTE_CTNT` | VARCHAR(200) | §7 규칙. 정성 행은 NULL |
| `QUAL_YN` | BOOLEAN NOT NULL | DC-9: TRUE면 AMT NULL |
| `QUAL_DESC_CTNT` | VARCHAR(500) | 짧은 발췌, 원문 복제 금지 |
| `SORT_ORDER_NO` | SMALLINT | 밴드 시작값부터 연속, 회사 내 유일 |
| `TCOMPANY.COMP_ENG_NM` | VARCHAR(30) UNIQUE | snake_case |
| `TCOMPANY.COMP_NM` | VARCHAR(100) UNIQUE | |
| `TCOMPANY.LOGO_NM` | VARCHAR(10) | 1~2자 약어(`'S'`, `'CJ'`) |
| `TCOMPANY.INDUSTRY_NM` | VARCHAR(50) | |
| `COMP_TP_CD` | **6종** | `large` · `startup` · `mid` · `foreign` · `public` · `freelance` |

## §9 SQL 출력 템플릿

`db/seed/benefit/sql/삼성전자.sql`과 **바이트 수준으로 같은 구조**를 유지한다.

```sql
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- {회사명} 복리후생 데이터
-- 출처: AI 파싱 ({YYYY-MM-DD})
-- URL: {실 URL 또는 '수동 입력'}
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('{eng}', '{회사명}',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = '{type}'),
        '{industry}', '{logo}', {url 또는 NULL});

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = '{eng}');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '성과 인센티브', 500, 'compensation',
   'est', '업계 평균 기준 추정', FALSE, NULL, 1),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '월 총 근무시간 내 출퇴근 자율 결정', 10),

  -- ── 근무환경 (work_env) ──

  -- ── 시간·휴가 (time_off) ──

  -- ── 건강·의료 (health) ──

  -- ── 가족·돌봄 (family) ──

  -- ── 성장·커리어 (growth) ──

  -- ── 여가·라이프 (leisure) ──

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '구내식당', 432, 'perks',
   'est', '일 18,000원 x 240일 환산', FALSE, NULL, 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
```

**규칙**
- 카테고리 주석 9줄은 **항목이 없어도 남긴다**(기존 파일 관례).
- 문자열 내 `'`는 `''`로. **`\'`는 절대 금지**(C-6).
- NULL은 따옴표 없이 `NULL`.
- 마지막 VALUES 행은 `,` 없이 `)`로 종결하고 다음 줄부터 `ON DUPLICATE KEY UPDATE`.
- 헤더 `-- URL:` 값과 INSERT의 6번째 값은 **같은 값으로 통일**한다.
  실 URL이면 둘 다 URL, 아니면 헤더는 `수동 입력` · INSERT는 `NULL`.
- `%`는 안전하다(`load.py`가 args 없이 execute).

## §10 함정

| # | 함정 | 결과 |
|---|---|---|
| T-1 | 헤더 INSERT 형태 변경 | `parse_header_insert` 예외 → **시드 4단계 전체 실패(모든 회사)** |
| T-2 | `-- 출처:` 줄 훼손 | **조용히** `2026-07-10` 폴백 → VERIFIED/EXPIRES 오류. 실패하지 않아 더 위험 |
| T-3 | `-- URL:` 값이 `http`로 시작 안 함 | `ai_parse` + URL NULL → 출처 아웃링크 소실(UC-42) |
| T-4 | 실 URL을 쓰면 SB-10 상수(`== 5`)가 깨짐 | 단계 9 항목 5로 조건부 갱신 |
| T-5 | ODKU × verified | 사용자 편집이 est로 덮이고 백필이 official로 승격 → **verified 영구 소실**. 단계 4 게이트로 방어 |
| T-6 | 백필 프로버넌스가 **회사 전체 행**을 덮음(`backfill_dec2.py:113-124`, `WHERE COMP_ID=%s`) | 재파싱과 무관하게 verified 행의 `user_report` 출처가 지워짐 — 알려진 한계 |
| T-7 | `\'` 이스케이프 | 문장 분할이 어긋나 문법 오류 또는 엉뚱한 문장 실행 |
| T-8 | `db/seed/reingest_benefit_sql.py` 재실행 | `:41-43`이 `DST`의 모든 `*.sql`을 `unlink()` → **신규 파일 조용히 삭제**. 1회성 재이식 전용 스크립트다 |
| T-9 | SORT_ORDER 밴드 초과 | compensation 10번째가 flexibility 밴드로 넘어가 정적 생성기 그룹핑 오류 |
| T-10 | `mysql < file.sql` 단독 적용 | 백필 우회 → DC-9·DC-13(Tier-0)·DC-14 위반 |
| T-11 | 테스트 상수 미갱신 | SD-3·SD-4·SI-8·SM-1 동시 red → Tier-0 배포 차단 |
| T-12 | 행수를 추측 | SD-4 상수 오류 → 매번 red. 단계 9 명령으로 직접 센다 |
| T-13 | `raw/*.txt` 커밋 | 회사 페이지 원문 전량이 저장소에 남음(RESEARCH §5-4 충돌) |
| T-14 | 시드에 `verified`/`official` 직접 쓰기 | DELETE가 자기 행을 못 지워 멱등성 상실(SM-1 실패) |

## §11 완료 보고

```
SQL 생성 완료: db/seed/benefit/sql/{회사명}.sql  ({N}행, {카테고리 수}개 카테고리)
테스트 상수 갱신: SD-3 {95→96} · SD-4 {1317→N} · SI-8 · SM-1 {SB-10: 갱신|무변경}

정적 검증: header OK / date {YYYY-MM-DD} / url {실 URL|ai_parse} / stmts 4

적용 (DB 있는 호스트):
  python3 db/seed/load.py
  bash infra/deploy/run_tests.sh

되돌리기:
  git checkout -- db/seed/benefit/sql/{회사명}.sql server/tests/test_seed_counts.py \
                  server/tests/test_seed_integrity.py server/tests/test_seed_idempotency.py \
                  server/tests/test_seed_badge_backfill.py
```
