# RESUME — 작업 재개 가이드

> **다른 PC/새 세션에서 이 프로젝트를 이어받는 사람(또는 AI)을 위한 인수인계 문서.** 이 파일 하나만 읽으면 지금까지의 맥락·규칙·다음 할 일을 파악할 수 있다. 최종 업데이트: **2026-07-12** (구현 M0~M8 대부분 완료·beta 배포·검증 시점).
>
> **⚡ 먼저 아래 §A(현재 상태)·§B(다음 착수)를 읽어라.** 그 아래 §0~§2는 문서 파이프라인 시점(2026-07-10)의 배경이며, "다음 할 일"은 §B가 정본이다.

---

## A. 현재 상태 (2026-07-12) ⬅ 여기부터

**문서 파이프라인(1~7단계) 완료. 8단계 구현 = M0~M8 대부분 완료.** loupit이 **`beta.loupit.co` 무중단 스테이징으로 배포·적대적 검증**된 상태(재검증 판정 GO-with-fixes).

- **git**: `origin/main` 최신 = §B 1~7 완료(L-1 `0e4b79e`·L-4 `91d24a8`·L-2/L-3 `f5ba3c1`·복원 `b2a8bc7` + RESUME 갱신, push 완료·동기화). 다른 PC에서 `git pull`로 이어받기.
- **배포된 실행 상태 (⚠️ 서버 호스트 `158.180.79.39` 에만 존재·유지 — 로컬 클론엔 없음)**:
  - beta API: systemd `loupit-beta-api.service`, 127.0.0.1:**8001** (시스템 python3, `server/.env.beta`). 공개 `https://beta.loupit.co` (nginx + Let's Encrypt).
  - DB: MySQL 스키마 **LOUPIT** / 계정 **APP_LOUPIT** (pw는 `server/.env.beta`, gitignore — 새 환경엔 없음). 회사 95·복지 1317·프리셋 28.
  - nginx: `/etc/nginx/sites-available/loupit-beta.conf`(리포 `infra/nginx/loupit-beta.conf`) + 보안스니펫 `/etc/nginx/snippets/loupit-beta-security.conf`(✅ B-1로 커밋됨 — 리포 `infra/nginx/snippets/`, 배치는 `infra/deploy/deploy-beta.sh`).
  - 라이브 `loupit.co` = 예전 **job_change**(별개 DB, 무손상). 프로덕션 컷오버는 **승인 게이트**(§B 끝).
- **⚠️ 다른 PC에서 이어갈 때**: 실행 상태·이전 세션 AI의 로컬 메모리는 이 서버/PC에만 있다(안 넘어옴). **서버 접촉 작업(nginx·systemd·LOUPIT 재시드·라이브 검증)은 반드시 이 서버에 접속해서** 하라. 순수 코드 편집만 로컬 클론에서 가능. **이 RESUME.md가 유일한 인수인계원.**
- **⚠️ 테스트 안전규칙(C-1 수정 결과)**: 서빙 스키마 LOUPIT을 테스트에도 재사용한다. **테스트는 반드시 `bash infra/deploy/run_tests.sh` 로만 실행**(끝나면 trap이 `load.py --fresh`로 서빙 자동 복원). 맨 `pytest`로 DB 테스트를 돌리면 conftest 가드가 `[C-1 안전장치]`로 차단한다. **`LOUPIT_ALLOW_SERVING_SCHEMA=1` 설정 후 맨 pytest 실행 절대 금지**(서빙 비운 채 복원 안 됨). 서빙 깨지면 수동 복구: `python3 db/seed/load.py --fresh` + `sudo systemctl restart loupit-beta-api`.

### 이번 세션(2026-07-11~12) 한 일
1. **beta.loupit.co 무중단 스테이징 배포** (포트 8001, nginx vhost, TLS, X-Robots noindex).
2. **7차원 적대적 종합검증** → 치명결함 **C-1** 발견·실발현(`run_tests.sh`가 서빙 스키마 DROP → 라이브 API 다운, 즉시 복구).
3. **결함 7건 수정·커밋**(회귀 테스트 포함, run_tests.sh ALL GREEN 백엔드175·생성152·node·nginx):
   - **C-1**(e4ce20a): 별도 TEST DB 불가(APP_LOUPIT 권한) → LOUPIT 재사용+테스트후 자동복원(run_tests.sh trap) + `server/tests/schema_guard.py` 가드.
   - **M-1**(e4ce20a): `/company/`·`/vs/` soft-404 → `try_files ... =404` (beta+prod).
   - **M-3**(e4ce20a): 베타 산출물 `infra/nginx/loupit-beta.conf`·`infra/systemd/loupit-beta-api.service` 커밋.
   - **H-1**(5686dcd): `server/routers/reference.py` 캐시미스 조립 후 `ReferenceBundle.model_validate()`.
   - **M-2**(5686dcd): `_benefit_table.html` qual_desc `or ''` 가드(None 렌더 누수).
   - **M-4**(5686dcd): `db/seed/backfill_dec2.py` 앵커 강등(동일 코드·금액 ≥3개사 → stated→estimated, 49건).
   - **M-5**(5686dcd): 파크시스템스 출산금 10→100·크래프톤 운동비 10→120.
4. **재검증 워크플로우** → 판정 **GO-with-fixes**(5 holds / 2 partial), 잔여 결함 4건(§B).

## B. 다음 세션 즉시 착수 목록 ("전부 수정" — 사용자 승인 2026-07-12)

재검증이 찾은 결함(HIGH·MED·LOW) + 원래 L-1~4. **TDD(red-green-refactor)로 처리, 완료 후 커밋·push. 서버에서 작업.**

> **진행(2026-07-12~13 이어서)**: **1~7 전부 완료.** 1·2(우선순위) 이후 3~7(L-1~4·복원원자성)까지 TDD로 처리·커밋·push. 남은 것은 아래 '완료 후 흐름'의 **수동 QA(28리프) → 🚦 프로덕션 컷오버(승인 게이트)** 뿐.

1. ✅ **[HIGH] `loupit-beta-security.conf` 커밋** — 완료(커밋 `624223d`). 리포 `infra/nginx/snippets/loupit-beta-security.conf` + base `loupit-security.conf`(기존) + 배치 스크립트 `infra/deploy/deploy-beta.sh`(provision.sh는 프로덕션 전용이라 신설). 검증 통과: `git ls-files | grep beta-security` → 존재, `nginx -t` PASS.
2. ✅ **[MED] kakao_bank child_edu 금액 + 월→연 전수 스윕** — 완료(커밋 `6c013f1`). `child_edu` AMT 10→**120** + note '(연 120만원)' 명시. **95개 시드 SQL 전수 감사(8배치 병렬 스캔 + 적대적 재검증)** 결과 확정 실버그는 이 1건뿐(크래프톤·파크는 M-5 처리분, LS fitness 30은 이미 연값이라 기각). 회귀 `test_SI_B2_monthly_amount_annualized` 추가(red→green). 재시드+생성기 재빌드+beta-api 재시작 후 라이브 `/api/v1/reference/all` child_edu=120·`beta.loupit.co/company/kakao-bank` 200 검증.
3. ✅ **[LOW] L-1 HEAD 405** — 완료(`0e4b79e`). FastAPI APIRoute는 HEAD 자동추가 안 함 → 4개 라우트를 `api_route(methods=["GET","HEAD"])`로. HEAD=200 empty body(ASGI 스트립). 테스트 test_TL1·test_TR8. smoke SM-4의 f9459f9 우회 원복. 라이브 HEAD 4종 200.
4. ✅ **[LOW] L-2 / 정규 URL 중복** — 완료(`f5ba3c1`). `location ^~ /dist/ { return 404; }` + `/company/`·`/vs/` try_files `$uri $uri.html`→`$uri.html`(직접 .html 차단, 클린 URL 200). 양쪽 conf. beta 라이브 검증: `/dist/company/*.html(.gz)`→404, 직접 `/company/*.html`→404, 클린→200. (server-if 방식은 사이클 리스크로 미채택; `/index.html` 미세중복만 보류.)
5. ✅ **[LOW] L-3 robots 중복헤더** — 완료(`f5ba3c1`). beta.conf robots location의 `add_header Content-Type` 제거 + `default_type text/plain`. 라이브 Content-Type 1개 확인.
6. ✅ **[LOW] L-4 parseSalRange** — 완료(`91d24a8`). 빈/공백 토큰 거부(`Number('')===0` 함정)·2토큰 강제·`min<=max` 검증, 실패 센티널 {0,0,0} 보존. node 경계 테스트 red→green.
7. ✅ **[LOW] 복원 원자성** — 완료(`b2a8bc7`). (b) 정직화 채택: `load.py --fresh`는 DROP TABLE(DDL 암묵커밋)이라 비원자임을 명시(‘보장’→‘시도’), 재시드 후 TCOMPANY≥90 검증 + 실패 시 큰 경고. (a) 임시테이블+RENAME 원자스왑은 시드 SQL 테이블명 하드코딩 때문에 범위 커 별도 작업으로 남김.

**완료 후 흐름**: 커밋·push → **수동 QA(28리프, 실제 브라우저 플로우)** → **🚦 프로덕션 컷오버**(loupit.co를 job_change→loupit으로 스왑 · nginx `loupit.conf` 활성 · 포트 8000 · 인증서 · **반드시 사용자 승인 게이트**).

> **참고**: `docs/TASK.md`(마일스톤·진행 롤업)·`docs/TASK/00~12`가 리프 정본. 재검증 리포트 원본은 세션 임시파일이라 소실될 수 있어 위 §B에 요지를 남김.

---

## 0. 한 줄 요약

**loupit** = 기존 `job_change`("직장 선택 OS")를 **로그인 제거 + 광고(AdSense·제휴) 수익 모델**로 재설계하는 프로젝트. 현재 **8단계 문서 파이프라인 중 7단계(TASK)까지 완료**, 다음은 **8단계 구현(TDD)**.

## 1. 지금 어디까지 왔나

```
1 PRD ✅  2 USECASE ✅  3 FRD ✅  4 FLOW ✅  5 WIREFRAME ✅  6 SPEC ✅  7 TASK ✅
8 구현(TDD) ⬅ 다음 할 일
```

| 단계 | 문서 | 상태 | 규모 |
| --- | --- | --- | --- |
| 1 | [PRD.md](PRD.md) + PRD/ | ✅ | 10개 파일, 요구사항 ID G/F/MON/NFR/D/AS/R |
| 2 | [USECASE.md](USECASE.md) + USECASE/ | ✅ | 8개 파일, 44개 UC, F1~F8 커버리지 |
| 3 | [FRD.md](FRD.md) + FRD/ | ✅ | 12개 파일, 97개 FR |
| 4 | [FLOW.md](FLOW.md) + FLOW/ | ✅ | 8개 파일, 43화면/29플로우 (Mermaid) |
| 5 | [WIREFRAME.md](WIREFRAME.md) + WIREFRAME/ | ✅ | 8개 파일, 34개 SCR (ASCII 와이어) |
| 6 | [SPEC.md](SPEC.md) + SPEC/ | ✅ | 12개 파일, SP-* 구현 계약 |
| — | [RESEARCH.md](RESEARCH.md) + RESEARCH/ | ✅ | 복지 데이터 수집·스크래핑 전략 |
| 7 | [TASK.md](TASK.md) + TASK/ | ✅ | 14개 파일, 286 리프(계층·진행·DoD)·빌드순서 M0~M8·Tier-0 27·DG-1~4 |
| 8 | 구현 | ⬜ **다음** | TASK를 구현할 스킬 생성 후 M0부터 실행 |

**git**: 모든 진행분 커밋·push 완료. 리모트 `git@github.com:bji1062/loupit.git` (SSH). 작업 트리 clean.

## 2. 다음 할 일 (8단계 구현·TDD)

7단계 TASK 완료(2026-07-10): `docs/TASK.md`(얇은 인덱스) + `docs/TASK/00~12`(빌드순서 + 12 도메인). SPEC → **286개 최소 리프**(계층 `T-nn.g.i`, 진행마커 `- [ ]`/`- [-]`/`- [v]`, DoD=구현+테스트 green). 빌드순서 M0~M8·의존 DAG·크리티컬 패스·결정게이트 DG-1~4·Tier-0 27은 [`TASK/00-빌드순서-마일스톤.md`](TASK/00-빌드순서-마일스톤.md).

원래 지시(8단계 프로세스 中 8):
> `docs/TASK.md`를 구현할 스킬을 생성한 뒤 실행한다.

착수: **M0(스캐폴드)부터** 크리티컬 패스(SP-ARCH→SP-DB→SP-SEED→SP-API→SP-GEN) 순. 각 리프는 red-green-refactor(테스트 먼저), 완료=구현+테스트 green. **결정게이트 DG-1~4는 관련 마일스톤 착수 전 AskUserQuestion으로 반드시 확인**(임의판단 금지 — §3·§7).

## 3. 반드시 지킬 규칙 (사용자 지시)

1. **문서 위치**: 모든 문서는 `docs/`에. 각 `docs/<NAME>.md`는 **요약+참조목록만 담는 얇은 인덱스**, 상세는 `docs/<NAME>/<항목>.md`로 분리. (예: `docs/TASK.md` 얇게 + `docs/TASK/<항목>.md` 상세)
2. **결정 처리**: 애매하거나 결정이 필요하면 **임의 판단 금지, 항상 질문(AskUserQuestion)으로 확인** 후 진행.
3. **TDD 필수**: 모든 코드는 red-green-refactor. 새 모듈·공개함수·라우트는 테스트 우선. **TASK 항목 완료(`- [v]`) 기준 = 구현 + 테스트 통과 둘 다**. 한쪽만이면 진행중(`- [-]`).
4. **언어**: UI/콘텐츠 한국어, 코드(변수/함수) 영어.

## 4. 절대 잊으면 안 되는 확정 결정

- **로그인/회원/인증/OAuth/JWT/이메일인증/소셜피드 = 전면 제거.** 사용자별 서버 저장 없음. 사용자 데이터는 브라우저 **localStorage에만**.
- **프로파일러(가치관 진단 설문→페르소나) = 영구 제외.** 우선순위는 사용자가 직접 선택(연봉/워라밸/복지/브랜드).
- **회사 등록 = 복지 데이터가 있는 ~96개만** (KOSPI/KOSDAQ 200개 전체 아님). 예외: **엔씨소프트 포함**(복지 있음), **CJ→CJ올리브네트웍스로 등록**(계열사 실데이터).
- **백엔드 = 슬림 읽기 전용 FastAPI + MySQL** (쓰기·인증 없음). 참조 테이블 5개: TCOMPANY_TYPE/TCOMPANY/TCOMPANY_ALIAS/TCOMPANY_BENEFIT/TBENEFIT_PRESET.
- **TBENEFIT_PRESET = 회사페이지 폴백 아님.** 비교 툴 **직접입력 모드**(등록 밖 회사)의 유형 기반 기본복지 템플릿용.
- **비교 계산 = 100% 클라이언트 사이드.** 서버는 참조 데이터만 제공.
- **수익화 = AdSense(자동+수동) + 제휴(affiliate.json).** 배치 = **콘텐츠 페이지 위주**, **비교 입력 화면 무광고 강제**, 결과 하단 1개. "광고" 표기(공정위).
- **SEO 핵심**: 회사 상세 ~96개 + 인기 비교 조합 페이지를 빌드타임 정적 생성.
- **DEC-2 (복지 데이터 신뢰도)**: 96개는 출처=`official`(공식 페이지 기반)로 인정하되, **추정 금액은 `amt_source=estimated`로 정직 표기**. 불확실성 밴드는 금액 기준: stated ±5% / estimated ±20% / 만료 +15%.
- **디자인 접근(옵션1)**: SPEC은 **디자인 토큰만**(색·타입·간격 CSS 변수). 비주얼 polish는 **개발 후 실제 앱(styles.css)에서** 반복. hi-fi 시안 없음.

## 5. 기존 자산 위치 (참고·재사용)

- 원본 프로젝트: `/home/ubuntu/job_change` (코드는 새로 작성, 데이터는 보존)
- 복지 데이터: `job_change/server/seed/benefit/sql/*.sql` (96개 gold set)
- 회사 시드: `job_change/server/seed/companies_kospi_1~2.py`, `companies_kosdaq_1~2.py` (200개 메타 — 여기서 96개 매칭)
- 스크래퍼 재사용: `job_change/server/tools/discover_and_scrape.py`, `scrape_benefits.py`, `.claude/skills/parse-benefits/`
- 복지 9카테고리 분석: `job_change/benefit.md`
- 기존 비교 알고리즘 원형: `job_change/app.js` (compare/calc/getWSHours/getOTPay 등 — SPEC 05가 이식 명세)

## 6. 다른 PC에서 시작하는 법

```bash
git clone git@github.com:bji1062/loupit.git   # SSH 키가 GitHub에 등록돼 있어야 함
cd loupit
```
그다음 Claude에게: **"docs/RESUME.md 읽고 7단계 TASK부터 이어서 진행해줘."**

주의: 이전 세션 AI의 로컬 메모리는 넘어오지 않지만, 이 RESUME.md + `docs/` + git 로그로 맥락 복원 가능. RESEARCH 전략의 미결 이슈(OI-3 TTL 값 확정, OI-6 amt_source 백필 규칙 등)는 `docs/RESEARCH/benefit-scraping.md §8` 참고 — 구현 단계에서 결정 필요.

## 7. 미결 결정 (구현 전 확인 필요)

- OI-3: 카테고리별 만료 TTL 값 확정 (RESEARCH §4.3)
- OI-6: `amt_source` 백필 판별 규칙 (기존 `'(추정)'` 표기 → stated/estimated)
- 엔씨소프트 시드 메타(200 목록 밖) 확보 방법
- 그 외 RESEARCH §8 OI-4/5/7
