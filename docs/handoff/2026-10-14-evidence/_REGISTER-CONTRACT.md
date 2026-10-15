# 웨이브 6 등록 접점 · 핀 · 리허설 계약 (Sonnet · 판단 없음) — 2026-10-14

**SendFeedback 도구 금지 · 하위 에이전트 금지.**

**너의 역할:** 통합이 끝난 worktree 에 등록 접점 · 테스트 핀 · 항목 페이지 예외를 감사 보고서가 준 글자 그대로 넣고, 격리 DB(`loupit_test`)에 리허설 적재를 해서 복지검색 표본을 다시 뽑은 뒤 전체 테스트를 돌린다. 코딩 작업이고 판단은 하지 않는다(사용자 지시 2026-10-01 모델 분업).
- 아래에 없는 개선 · 정리 · 문구 다듬기 금지. 감사 글과 실제 파일이 어긋나 집행이 둘 이상으로 읽히면 손대지 말고 「보류」로 보고한다.

`W6` = `/home/ubuntu/loupit-evidence/2026-10-14-wave6` · `WT` = `/home/ubuntu/loupit/.claude/worktrees/wave6`(브랜치 `data/wave6-13-companies`, `main` = `d071a97` 에서) · 감사 = `W6/audit/integration-audit.md` · 리드 판정 = `W6/_ROSTER.md` (97) ~ (113).

## 금지

- 🚨 **본체 체크아웃 `/home/ubuntu/loupit` 의 파일을 고치지 않는다.** 본체의 `web/assets` 는 라이브 docroot 다(저장 = 즉시 운영 — 2026-07-20 사고). 모든 쓰기는 `WT` 안에서만. 경로를 쓸 때마다 `WT` 로 시작하는지 본다.
- 운영 DB(`LOUPIT`)는 **읽기 전용 덤프(mysqldump)만**. 쓰기 · DDL 0. 베타 DB(`loupit_beta`)는 건드리지 않는다.
- git commit · push · PR 금지(리드가 한다). 시드 13파일(`WT/db/seed/benefit/sql/` 의 이번 파일)은 고치지 않는다 — 통합이 끝낸 것이다.
- `pytest` 를 직접 돌리지 않는다(C-1 안전장치가 막는다) — `run_tests.sh` 로만.

## A. 파일 집행 (감사 글자 그대로 · 반영일 = `2026-10-17`)

`<반영일>` · `<서빙 반영일 — 리드>` 자리는 전부 `2026-10-17` 로 쓴다(리드 판정 (113) ⑦).

1. **핀** — 감사 §6 표의 행을 전부: SD-3 · SD-4(+ 산식 주석 · docstring 산식 줄) · CANON_BENEFITS · SI-8 · SM-1 · FN-1 세 줄 · SB-10 · SI-13c 두 줄(`daewoong_pharm` · `s1`) · **SI-13c 맨 칩 단언에 `"hyundai_wia"` 추가**(리드 채택) · 쓰이는 코드 수 두 곳(파이썬 `test_find_page.py` · JS `find.test.js` — 89 → 91, 테스트 이름 「89종」도). 줄 번호는 `main` = `d071a97` 기준이니 내용으로 찾는다. 「변경 없음」 핀(SI-9 · 금융사 · 가이드 10월 판)은 손대지 않는다.
2. **대문 등록** — `WT/generator/data/company_registrations.json` `waves` 맨 앞에 감사 §6 의 객체(`"date": "2026-10-17"`, label 「회사 확장 웨이브 6」, companies 13개 — 감사 순서 그대로). 기존 웨이브 객체 모양 · 들여쓰기를 따른다.
3. **이메일 도메인** — 감사 §7-2 블록을 `WT/db/seed/company_email_domain.sql` 끝에. **BGF리테일 `bgf.co.kr` 은 기본안(미등록 + `@rejected` 줄)** — 리드 판정 (113) ②. 먼저 블록의 도메인마다 `dig +short MX <도메인>` 으로 확인해 결과를 보고에 붙인다. **MX 가 비었거나 NXDOMAIN 인 도메인은 그 INSERT 를 빼고 보류에 적는다**. 새 따옴표는 SQL 문자열 리터럴 말고 주석에 넣지 않는다(분할기). 넣은 뒤 `db.seed.load._split_sql_statements` 로 문장 수가 (전) → (전) + 넣은 INSERT 수인지 확인.
4. **업종** — 감사 §8-1 13줄을 `WT/generator/data/krx_sector.csv` 에 **바이너리 append**(`open(path,'ab')`, 줄마다 `\r\n`).
5. **별칭** — 감사 §8-2 `WAVE6_ALIASES` 사전을 `WT/db/seed/company_meta.py` 의 `WAVE5_ALIASES` 다음에, `build_company_meta()` 의 WAVE5 루프 블록 다음에 같은 모양으로. 사전의 행 끝 주석까지 감사 글 그대로.
6. **corp_code** — 감사 §8-3 13줄을 `WT/db/seed/corp_code_map.csv` 끝에(파일의 기존 줄바꿈 꼴을 바이트로 확인해 같게).
7. **항목 페이지 예외** — 감사 §10-1 의 23개 객체를 `WT/generator/data/benefit_pages/<파일>.json` 각 `overrides` 배열 끝에 글자 그대로. 기존 JSON 들여쓰기 · 한 줄 꼴을 따른다. 넣은 뒤 `generator.benefit_rules` 의 `load_pages` · `validate_all` 이 오류 0 인지 확인.
8. **`/find` 표시명 고정 2줄**(리드 판정 (113) ③) — `LABEL_OVERRIDE` 에 `"smoking_cessation": "금연 지원",` · `"excellence_award": "사내 포상 제도",` 를 `WT/generator/pages/find.py` 와 `WT/web/assets/js/find.js` **두 곳 같은 줄**(두 파일 머리 주석의 「같은 줄이어야 한다」 약속). 기존 항목 옆 주석 꼴로 한 줄 이유: smoking_cessation = 현금형(금연수당)과 프로그램형(HJ중공업 금연클리닉)을 함께 담는 이름 · excellence_award = 「포상제도」 · 「우수사원 포상」 5:5 동률이 행 하나에 뒤집혀 항목 페이지 제목으로 고정(2026-10-14 웨이브 6).

## B. 리허설 적재 (격리 DB `loupit_test`)

출발점 스크립트: 웨이브 5 `/home/ubuntu/loupit-evidence/2026-10-10-wave5/rehearsal/`(읽기만 — `run.sh` · `README.md`) — 복사해 `W6/rehearsal/run.sh` 로 고쳐 쓴다. 바뀌는 것: 출력 폴더 `W6/rehearsal/out` · worktree `WT` · **마이그레이션 없음**(신규 13사뿐) · 시작 때 `loupit_test` 가 비어 있지 않으면 **그 스키마의 테이블만** 지운다(대상 이름이 정확히 `loupit_test` 인지 먼저 assert).

1. 운영 참조 테이블 읽기 전용 덤프 → `loupit_test` → before 스냅숏.
2. `WT` 에서 `DB_NAME=loupit_test python3 db/seed/load.py`(적재 전에 `SELECT DATABASE()` = `loupit_test` assert).
3. 대조 → `W6/rehearsal/README.md` 에 결과 줄:
   - 총 복지 행 = 3,791? · 회사 = 173?
   - 13사: `WT` 시드와 전 필드(명칭 · 금액 · 카테고리 · NOTE · 정성여부 · 서술 · SORT) 불일치 0 · `AMT_SOURCE` 분포(감사 §3-0: 금액 행 3 = stated 1 · 추정 2)
   - 나머지 160사: before/after 행 증감 0 · 내용 변화 목록(있으면 전부)
   - `TCOMPANY` 13사 `CAREERS_BENEFIT_URL` · `WORK_STYLE_VAL`(감사 §11 표와 대조) · 13사 밖 변화
   - 적재 로그의 경고 줄 전부
4. **corp 적재 확인**: `DB_NAME=loupit_test python3 db/seed/load_corp.py`(인자 · 사용법은 파일 머리말) → `TCOMPANY_CORP` 172 · `TCORP` 171 · 13사 `TCORP.CORP_NM` 이 DART 정식명(감사 §4-1 · §8-3). **OpenDART 를 부르지 않는다**(재무 · 직원 적재는 릴리스 때 리드가).

## C. 복지검색 표본 다시 뽑기

1. `cd WT && DB_NAME=loupit_test python3 generator/tests/data/make_find_label_cases.py` — 먼저 `server.config.get_settings()` 가 환경변수 `DB_NAME` 을 따르는지 확인(아니면 bundle JSON 을 `loupit_test` 에서 덤프해 인자로 준다 — 스크립트 사용법 참고).
2. `git -C WT diff generator/tests/data/find_label_cases.json` 에서 **label 이 바뀐 코드**를 전부 적는다. 감사 예상(§10-3): 신규 `grocery_support` 「유기농 식품 구매 지원」 · `leave_buyout` 「미사용 휴가 1.5배 보상」 · `excellence_award` 는 override 로 「사내 포상 제도」 · `smoking_cessation` 은 override 로 「금연 지원」. 그 밖의 변화가 있으면 보고(고치지 말고).
3. **동률 표본 테스트 갱신** — `WT/generator/tests/test_find_page.py` 「동률」 표본 루프와 `WT/web/assets/js/find.test.js`(같은 쌍)를 새 픽스처로 다시 본다. 동률이 풀렸거나 대표 이름이 바뀐 쌍은 **지금 동률인 다른 코드**(새 픽스처에서 최다 빈도가 둘 이상인 코드 — 기대 문자열은 파이썬 `_most_common` 결과)로 바꾸고, 파이썬 · JS 를 같게, 기존 주석 꼴대로 한 줄 이력(「2026-10-14 웨이브 6: …」).

## D. 전체 테스트

```
cd /home/ubuntu/loupit/.claude/worktrees/wave6 && set -a && . /home/ubuntu/loupit/server/.env && set +a && env -u DB_NAME bash infra/deploy/run_tests.sh
```
- **foreground 로 돌린다**(백그라운드로 보내고 기다리면 결과를 놓친다 — 10-14 GTM 레인). timeout 넉넉히.
- 실패가 있으면 원인을 적는다. A~C 의 집행 실수면 고치고 다시 돌린다. 그 밖(계약에 없는 원인)은 고치지 말고 보고한다.
- 끝나면 `WT/package-lock.json` 이 새로 생겼으면 지운다. `node_modules` 는 심볼릭 링크라 둔다.

## 보고 (최종 응답은 짧게)

- A 1~8 집행 결과(파일 · 줄 수) · MX 결과 표 · 보류(없으면 「없음」)
- B 리허설 결과 줄(README 와 같게)
- C 바뀐 label 목록 · 동률 표본 교체 내역
- D `run_tests.sh` 마지막 요약 줄(통과 수 · 실패 수 계층별)
- `git -C WT status --short` 출력
