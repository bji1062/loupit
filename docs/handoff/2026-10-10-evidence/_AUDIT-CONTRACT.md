# 웨이브 5 코퍼스 횡단 감사 계약 v2 (W-2 후반 · Opus ×1) — 2026-10-10

목적: 이번 웨이브 시드 N파일을 **기존 코퍼스 147파일과 함께** 놓고 통합 준비 데이터를 만든다. 검증은 회사 **안**을 봤고 감사는 회사 **사이**와 코퍼스 전체를 본다. 여기서 통과한 것은 통합(Sonnet)이 판단 없이 그대로 집행하고 곧 공개된다(W4 감사 계약 · R-1 감사 계약 L7).

- **금지:** 리포 `/home/ubuntu/loupit` 쓰기 · DB 접속 · git 상태 변경 · 수집본(`W5/collect/`) 수정. 고치는 일은 통합이 한다. 감사는 **조치 목록**과 **모의 최종본**만 낸다.
- **보고서는 절 단위로 먼저 써 나간다** — 절 하나를 마칠 때마다 저장한다(웨이브 2 감사 1차는 보고 직전 세션 한도로 끊겼다).
- 규칙의 정본은 `W5/_COLLECT-CONTRACT.md`(규칙 1~16 · 출처 약칭) · `W5/_VERIFY-CONTRACT.md` · `W5/_VOCAB.md`(89종)다. 「⚖ C-n」 은 `W5/_CHANGES.md` (c) 의 리드 판정 자리다 — 리드가 판정한 값이 계약에 반영돼 있으면 그것을, 아니면 권고안을 적용하고 §13 에 표시한다.

## 경로 (`W5` = `/home/ubuntu/loupit-evidence/2026-10-10-wave5`)

| 무엇 | 경로 |
|---|---|
| 수집본 N파일(읽기만 — 목록은 리드 프롬프트) | `W5/collect/<파일명>.sql` · `.evidence.md` · 원문 사본 `W5/<eng>/` |
| 검증 보고서 | `W5/verify/<파일명>.verify.md` · 독립 재수집 기록 `W5/verify/evidence-<레인>/` |
| 프로브 | `W5/probe/<회사명>.md` |
| 리드 명단(있으면) | `W5/_ROSTER.md` — 회사 · corp_code · DART 정식명 · 수요 |
| 기존 코퍼스 | `/home/ubuntu/loupit/db/seed/benefit/sql/*.sql`(147파일 · 3,179행 — 2026-10-10 `main` = `ab47ce6`) |
| **감사 보고서** | `W5/audit/integration-audit.md` |
| **재현 스크립트** | `W5/audit/_audit.py` — 출발점 `/home/ubuntu/loupit/docs/handoff/2026-09-19-evidence/wave4/_audit.py` · `_precheck.py`(경로만 W5 로 · 어휘표는 `W5/_VOCAB.md`). `check-seed <폴더>` 하위 명령을 둔다: 그 폴더의 이번 N파일을 `W5/audit/sim/` 과 행 단위로 대조해 「형식 문제 n · 불일치 n」을 찍는다(R-1 감사 · 통합 방식) |
| **모의 최종본** | `/home/ubuntu/loupit-evidence/2026-10-10-wave5/audit/sim/<파일명>.sql` — 수집본 사본에 §5 조치를 그대로 적용한 결과(헤더 한 줄 포함). 통합이 독립 집행한 뒤 이것과 diff 한다 |
| 뼈대 본보기 | `/home/ubuntu/loupit/docs/handoff/2026-09-19-evidence/wave4/integration-audit.md`(웨이브 4 감사) · `/home/ubuntu/loupit-evidence/2026-09-26-recollect/audit/integration-audit.md` §5(집행형 조치 목록 — 운영 반영 명세 §6 은 재수집 전용이라 쓰지 않는다) |
| 점검 도구 | `W5/_row_check.py` · `/home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py` · `/home/ubuntu/loupit/docs/handoff/2026-09-19-evidence/_legal_scan.py` |

## 반드시 실제 임포트로 재현

추측하지 말고 리포 모듈을 **import 해** N파일을 돌린다:
- `db.seed.load._split_sql_statements` — 전부 5문장, 셋째가 `UPDATE TCOMPANY SET CAREERS_BENEFIT_URL`.
- `db.seed.company_meta.parse_header_insert` · `ws_conditions` · `derive_work_style` — 등록 값 · 근무형태 칩.
- `generator.slug.slug_of` — 기존 147 과 slug 충돌 0, 표시명 충돌 0.
- `db.seed.backfill_dec2.derive_amt_source` · `_DATE_RE` · `_URL_RE` — 금액 출처 예측 · 확인일 · 출처 URL.
- `generator.benefit_rules` `load_pages` · `classify` · `text_hash` · `validate_all` — 항목 페이지 영향(§10).
- `W5/_row_check.py`(위 함수들로 SI-9 · SI-11 · SI-12 · SI-13d · SI-B2 를 미리 본다) · `_len_check.py` · `_legal_scan.py`.

**BLOCK:** 파싱 실패 · 문장 수 ≠ 5 · slug · 표시명 충돌 · 머리말 정규식 불일치 · 필드 길이 초과 · 적재 게이트(`server/tests/test_seed_integrity.py` SI-9 · SI-11 · SI-12 · SI-13d · SI-B2)를 깰 행. 각 BLOCK 에 재현 명령이나 파일 · 행 위치를 붙인다.

## 심사 항목

### 1. 신규 BENEFIT_CD
`W5/_VOCAB.md` 89종에 없는 코드를 N파일에서 전수로 찾는다(수집기가 「신규」라 적지 않은 것까지). 코드마다 **유지 / 흡수(→ 기존 코드) / 통합(신규끼리 → 1)** 판정 + 근거(선례 회사 · 행). 판정 논리는 웨이브 4 감사 §1(신규 5종 제안 → 채택 3 · 기각 2):
- 코퍼스 전문 grep 결과(그 제도어로)를 직접 다시 돌린다 — 1건 찾고 멈추지 않는다(웨이브 4 `nonsmoking_bonus` ↔ `smoking_cessation`).
- 이름은 지급 형태가 아니라 제도 영역 · 원문에 없는 조건을 코드가 덧붙이지 않는다(`welfare_fund_loan` ↔ `welfare_fund`).
- 유지하는 신규 코드는 카테고리 · 어휘표에 넣을 한 줄(함정 절 포함) · 배선 확인(시드 · 어휘표 말고 배선이 필요 없는지 — 최근 신규 코드 `home_security` · `smart_office` · `severance_plus` 는 배선 없음, `/find` 대표 이름은 빌드가 뽑는다)을 적는다.

### 2. 회사 간 일관성
이번 웨이브 안에서만이 아니라 **기존 147사 행과도** 대조한다:
- 같은 제도가 회사마다 다른 코드로 간 것 · 같은 코드가 다른 뜻으로 쓰인 것 · 카테고리가 어휘표와 다른 것.
- 휴가 코딩(`refresh_leave` · `leave_general` · `summer_leave` · `long_service_leave` — 수집 계약 규칙 10) · 성과급(`incentive` / `profit_sharing` / `bonus` — 규칙 11) · 대출(`welfare_fund` / `welfare_fund_loan` / `housing_loan` — 규칙 12) · 교육(`lang` / `edu_support` / `self_development` / `mba` / `career` — 규칙 8).
- 그룹 각주의 꼴(「(그룹 통합 채용 기준)」 / 「, ○○그룹 공통 문구」 — ⚖ C-13) · 부문 · 직군 한정 표기(규칙 6-7 · 13).
- 같은 그룹의 기등록 형제가 있으면 그 시드와 문장 대조(형제 정본 문장이 이 회사 행에 들어갔는지 — 수집 계약 규칙 6).

### 3. 금액 (AMT)
AMT 가 있는 행 전수 표: 회사 · SORT · 코드 · 금액 · NOTE · **예측 AMT_SOURCE**(`derive_amt_source`) · 해당 조항(수집 계약 4-1 stated / 4-2 추정 4종 / 4-3 NULL 이어야 함) · 판정.
- stated 행은 원문 숫자 인용이 있는가 · 「회사가 밝힌 숫자로 연 금액을 적은 것」인가(SPEC 21 정의) · 합산이면 구성 원문 · 산술(사용자 결정 2026-10-02).
- 추정 행은 표지(「추정」 · 「환산」 · 식대 꼬리)가 있는가 · 넷(월액 × 12 · 포인트 환산 · 분포형 중간값 · 식대 식) 중 하나인가 · 타사 금액 · 기준 금액(틀 값)이 신규 회사에 들어가지 않았는가(⚖ C-1).
- 한도 · 1회성 · 비율 · 조건부 · 대출 원금 · 질권 · 처분 총액 오입력(규칙 4-3). 주기 없는 검진 금액(⚖ C-10).
- **그 축의 기존 최댓값을 2배 넘는 값**은 급부 형태가 섞였는지 다시 본다(명절 상여 축 등 — ⚖ C-2 · W4 감사 §3-5 ③).
- 게이트: SI-B2(월액 그대로) · SI-9(식대 꼬리 식 = 금액 · 단가 12,000 · 꼬리 끼니 ≤ 본문 끼니 · 꼬리 없는 식대 추정은 허용 목록 회사만 — ⚖ C-12) · SI-12(stated 서술에 원 숫자).
- 무관 회사 간 같은 (코드 · 금액) 겹침은 판단 근거가 아니다(M-4 폐기 — 사용자 결정 2026-09-28 · 다시 제안하지 않는다). 보는 것은 원문 인용 하나다.
- 회사별 금액 합(이직 계산기에 들어가는 연 금액 합)과 stated / 추정 행 수 표.

### 4. 등록 · 출처
- N개 `COMP_ENG_NM` · `COMP_NM` · 유형 · 업종 · LOGO · 정본 URL 표(`parse_header_insert` · `slug_of` 통과값 실측). 리드 명단의 corp_code · DART 정식명과 어떻게 대응하는지(웨이브 4 GC녹십자 DART 정식명 「녹십자」 선례).
- `INDUSTRY_NM` 이 기존 값(수집 계약 §3 목록 · 77종)에 합류했는지. 새 값이면 같은 웨이브 안에서 바이트 동일한지 · 합류가 더 나은지(W4 감사 §4-2).
- 정본 URL: 검증 보고서의 점검기(`run_checks`) 실측 결과를 모은다 — `ok` · `robots`(배포 시 주의) · 그 밖(`blocked` · `moved` · `gone` · `error`)은 BLOCK 후보. 한시적 출처(공고 · 공고 이미지)는 원본 사본이 `W5/<eng>/` 에 sha256 과 함께 있는지(W4 감사 §4-3 · M-8).

### 5. 회사별 조치 목록 (집행형 — 통합의 유일한 입력)
대상: N개 검증 보고서의 SUSPECT · REFUTED · MISSED 전수와, 보고서에 적힌 그 밖의 권고(문안 · 재코딩 · 칩 이름 · 항목 페이지 예외), 그리고 §1~§4 · §9 의 감사 결론.
- 조치 종류: 삭제 · 재코딩(코드 · 카테고리 · SORT 섹션 함께) · 병합(받는 행 · 덧붙일 원문 구절) · 분리 · 문안 교체 · 이름 교체 · AMT NULL(→ `NULL` · NOTE → QUAL_DESC 로 옮긴 새 글자 · `QUAL_YN TRUE`) · 추가.
- **문안 교체는 새 글자를 그대로** 적는다. **추가 행은 완성된 VALUES 튜플로** 적는다: `(@comp_id, '<code>', '<이름>', <AMT|NULL>, '<category>', 'est', <NOTE|NULL>, <TRUE|FALSE>, <QUAL_DESC|NULL>, <SORT>)`.
- 대상 행은 **코드 + SORT** 로 가리킨다. 바꿀 필드 · 새 값을 글자 그대로.
- 회사마다 헤더에 붙일 한 줄을 준다: `-- 검증 · 감사 판정 반영(<날짜>): <무엇을 삭제 · 병합 · 재코딩 · 추가했는지> — 최종 N행`(주석이라 노출되지 않는다 · 따옴표 금지).
- 검증 보고서와 근거표가 엇갈리거나 검증끼리 엇갈리면 **원문을 직접 확인해** 결론을 낸다. 판단이 남은 조치를 두지 않는다(R-1 감사 계약 L7). 규칙으로 풀리지 않는 **정책 문제만** §13 에 적고, 그 행도 권고안대로 §5 에 넣고 표시한다.
- 조치를 적용한 결과를 `W5/audit/sim/<파일명>.sql` 로 쓴다(수집본은 고치지 않는다). 모의본에 분할기 5문장 · `_len_check.py` 0 · `_legal_scan.py` · `_row_check.py` 총 오류 0 을 돌려 결과 줄을 §5 끝 「검산」에 적는다 — 조치로 문안이 길어져 200자 · 500자를 넘지 않았는지(R-3 묶음 2 리드 메모).
- 회사별 최종 행 수 · 합계 표.

### 6. 핀 계산 (리드가 고친다 — 감사는 파일 · 줄 · 새 값만)
최종 행 수 합계로 계산한다(값은 2026-10-10 `main` = `ab47ce6` 기준):

| 핀 | 위치 | 지금 | 새 값 |
|---|---|---:|---|
| SD-3 회사 수 | `/home/ubuntu/loupit/server/tests/test_seed_counts.py:35` | 147 | 147 + N |
| SD-4 복지 총행 | 같은 파일 `:139`(산식 주석 `:38` · `:136`) | 3179 | 3179 + 최종 행 합 |
| CANON_BENEFITS | `/home/ubuntu/loupit/server/tests/test_seed_member_rows.py:51` | 3179 | SD-4 와 같은 값 |
| SI-8 회사 수 | `/home/ubuntu/loupit/server/tests/test_seed_integrity.py:176` | 147 | 147 + N |
| SM-1 회사 수 | `/home/ubuntu/loupit/server/tests/test_seed_idempotency.py:60` | 147 | 147 + N |
| FN-1 매핑 · 법인 수 | `/home/ubuntu/loupit/server/tests/test_corp_load.py:55`(146) · `:56`(145) · `:77`(146) | 146 / 145 / 146 | + corp_code 매핑된 회사 수(공유 corp_code 유무 확인) |
| SB-10 실 URL 회사 집합 | `/home/ubuntu/loupit/server/tests/test_seed_badge_backfill.py:168` `real_url_engs` | — | 「# 확장 웨이브 5(<반영일>, N) — 신규 등록, 전부 실 URL 헤더」 줄 + eng N개 |
| SI-9 식대 꼬리 없는 추정 허용 목록 | `/home/ubuntu/loupit/server/tests/test_seed_integrity.py:325` `_MEAL_NO_TAIL_OK` | 6사 | 월액 · 포인트로 밝힌 식대 회사가 있으면 eng 추가(⚖ C-12) |
| SI-13c 근무형태 조건 칩 고정 | 같은 파일 `:546-560` | 11사 | 조건 칩(`cond`)이 생기는 새 회사가 있으면 그 줄 추가 |
| 쓰이는 코드 수 | `/home/ubuntu/loupit/generator/tests/test_find_page.py:197` | 89 | 신규 코드 유지 수만큼 |
| 대문 「새로 등록된 회사」 | `/home/ubuntu/loupit/generator/data/company_registrations.json` 맨 앞 새 웨이브(날짜 = 서빙 반영일 — 리드) | — | eng N개(`generator/tests/test_home_page.py` 가 시드 회사 전부가 한 번씩 실렸는지 강제) |
| 금융사 | `/home/ubuntu/loupit/db/seed/load_corp.py:35` `FINANCIAL_COMPANIES` · `/home/ubuntu/loupit/server/tests/test_corp_load.py:30` `FINANCIAL_7`(이름만 7 — 지금 12사) | 12 | 금융사가 있을 때만 |
| `/find` 표본 · 항목 페이지 표본 | `generator/tests/data/find_label_cases.json`(재생성 `python3 generator/tests/data/make_find_label_cases.py` — 리허설 DB) · `generator/tests/test_benefit_pages.py` 표본 단언(예: `:438`) | — | 리드가 리허설로 실측(감사는 바뀔 가능성만 표로) |

그 밖에 이번 회사 eng · 바뀌는 코드를 박아 둔 테스트 · 픽스처를 `grep -rn` 으로 찾아 적는다.

### 7. 이메일 도메인
근거표의 관측 도메인 전수 + `/home/ubuntu/loupit/db/seed/company_email_domain.sql` 초안(형식: `INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN) SELECT COMP_ID, '<도메인>', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = '<eng>';`). `@rejected` 줄 · 그룹 공용 도메인(삼성 · SK 그룹 단위 — 같은 그룹 기존 줄은 병합) 충돌 여부. 웹 도메인 ≠ 메일 도메인인 곳 표(W4 감사 §7-1 · W4인계 §7).

### 8. 업종 · 별칭 · corp_code 초안
- `/home/ubuntu/loupit/generator/data/krx_sector.csv` N행 — 같은 업종 회사의 값을 선례로 · ⚠ CRLF · LF 혼재 파일이라 **바이너리 append**(`open(path,'ab')` + `\r\n`) 권고(W4 감사 M-9).
- `/home/ubuntu/loupit/db/seed/company_meta.py` `WAVE5_ALIASES` 초안(구명 · 영문 · 약칭 — **지주 · 형제 법인 이름 금지**, 「○○홀딩스」 등).
- `/home/ubuntu/loupit/db/seed/corp_code_map.csv` N행 — **note 의 DART 명은 홑따옴표 필수**(`load_corp.py` `_DART_NM_RE` — 없으면 조용히 comp_nm 폴백, 웨이브 2 BLOCK-1).
- 금융사면 `FINANCIAL_COMPANIES` · `FINANCIAL_7` 집합.

### 9. 사용자 노출 필드 — 편집 주석 · 법정 문구 · 형식
- `_legal_scan.py` 로 N파일 전수(검출 줄마다 허용 / 교체 / 삭제).
- 내부 용어(「코퍼스」 「선례」 「어휘표」 「규칙 N」 「수집기」 「검증」 「감사」 「병합」 「미수록」 「회피」 「흡수」 「판독」 「정본」 「시드」 「⚠」 「구본」 「승계」 「앵커」 「틀 값」 「항목명 그대로」 「○○로 표기」) · 레인 메모 낱말(SI-12) · 「 — 」 꼬리 둘 이상(SI-11) · 「연차」 · 「반차」 · 「반반차」(⚖ C-3) · 조사 · 부사형 어미로 끝나는 서술 · 법정 제도 문구.
- 걸린 행마다 원문 근거만 남긴 대체 문안을 글자 그대로(§5 에 반영). 「(그룹 통합 채용 기준)」 · 「○○그룹 공통 문구」 각주는 귀속의 전제라 지우지 않는다.

### 10. 항목 페이지 · `/find` 영향
- 검증이 권고한 예외(`generator/data/benefit_pages/*.json` `overrides` — comp · h · mode / facets · why)를 모아 **모의 최종 문안 기준 해시로** 다시 계산하고, 메모리에서 적용해 `validate_all` 오류 0 을 확인한다. 같은 설정 파일을 여러 회사가 고치면 배열을 합친다. 결과를 「동반 조치(리드 집행)」 표로: 파일 · 추가할 객체 글자 그대로.
- `MIN_COMPANIES = 20` 문턱(법정 행 · `exclude` 를 뺀 회사 수)을 이번 웨이브로 넘어 **새로 생기는 항목 페이지**가 있는지(SPEC 20 SP-BEN-3) — 있으면 그 코드의 설정 파일이 없어서 생성되지 않는지(설정 없음 = 페이지 없음)까지 적는다.
- 신규 코드 · 1~2회 쓰인 코드의 `/find` 대표 이름이 이 웨이브 이름으로 바뀔 가능성(빈도 동률 — 실측은 리드 리허설).

### 11. 근무형태 칩
회사별 `derive_work_style` 결과 표(remote · flex · refreshLeave · cond). 조건 칩이 생기는 회사는 §6 SI-13c 핀에 넣는다. 이름이 조건처럼 보이는데 조건으로 안 읽히는 행(SI-13d)은 BLOCK.

### 12. 법정 · 업무 교육 표시
신규 회사는 `generator/data/row_marks.json` 에 등록하지 않는다 — 법정만 · 업무 교육만 적힌 행이 남아 있으면 §5 에 삭제 또는 상회분만 남기는 조치(⚖ C-6).

## 웨이브 5 전용 — 감사가 반드시 결론을 낼 것 (리드가 채운다)

대상 13파일: `오뚜기.sql` · `KCC.sql` · `한솔케미칼.sql` · `오리온.sql` · `GS건설.sql` · `현대해상.sql` · `한온시스템.sql` · `에스엘.sql` · `코오롱인더.sql` · `산일전기.sql` · `ISC.sql` · `한국콜마.sql` · `코스맥스.sql`. **리드 판정 `W5/_ROSTER.md` W5-1 ~ W5-20 은 확정값이다** — 다시 다투지 말고 §5 에 집행형으로 옮긴다. 검증 권고와 리드 판정이 엇갈리면 리드 판정이 이긴다.

1. **경영실적 성과급 코드 하나로(W5-10).** 「경영실적에 따른 성과급」 · 「경영성과에 따라」 꼴(평가 차등 · 개인 · 조직 평가 언급 없이 회사 실적 연동만) = `profit_sharing`. 13파일 전수와 기존 147사에서 같은 꼴 문장이 어느 코드로 갔는지 표로 — 이번 13파일 안의 어긋남은 §5 재코딩, 기존 코퍼스 어긋남은 §14 별건.
2. **옛 robots 차단 목록 줄(W5-17).** 산일전기 robots 의 `User-agent: Mozilla/3.Mozilla/2.01` 같은 옛 목록 줄이 다른 12곳 정본 호스트 robots 에도 있는지(검증 · 수집 원문 사본의 robots.txt 로 — 새 요청은 꼭 필요할 때만, 계약 16 예절) · 우리 점검기 `server/source_check.py:376` `parse_robots` 가 그 줄을 브라우저 UA 전체 차단으로 읽는지 실제 import 로 재현 · 배포 뒤 점검기가 그 회사를 `robots` 로 찍을 위험이 있으면 §15 MED + §14 후속(점검기 수정은 이번 시드 범위 밖).
3. **정본 URL 교체(W5-8).** 한국콜마 `CAREERS_BENEFIT_URL` · 머리말 `-- URL:` → `https://www.kolmar.co.kr/img/esg/2025_sustainability_report_kor_2.pdf` 를 §5 조치로. 그룹 채용 페이지는 머리말 「참고」 줄로 남긴다. 교체 뒤 `_URL_RE` · SB-10(실 URL 헤더) 통과 여부.
4. **그룹 각주 꼴 세 갈래(W5-2 · W5-7 · W5-8 · C-13).** 코스맥스 · 한국콜마 채용 페이지 근거 행 = 「(그룹 통합 채용 기준)」, 코스맥스 자기 도메인 근거 행(SORT 80 · 81) = 「, 코스맥스그룹 공통 문구」, 한국콜마 자기 보고서 근거 8행 = 각주 없음. 행마다 출처와 꼴이 맞는지 전수 표 · 꼬리 「 — 」 개수(SI-11) · 200자.
5. **GS건설 안식휴가(W5-16 ①).** `refresh_leave` 를 세우지 않고 `leave_general` 「안식휴가 (휴가 적립형)」(꼬리 「적립 재원·기간·유급 여부 미기재」) — 이미 `leave_general` 행이 있으면 그 서술에 합친다. `derive_work_style` 에서 GS건설 `refreshLeave` 칩이 켜지지 않는지 확인.
6. **표시명 · DART 정식명 어긋남 2곳.** KCC(DART 「케이씨씨」) · 코오롱인더(`COMP_NM` 「코오롱인더스트리」 · DART 「코오롱인더」 · 파일명 `코오롱인더.sql`) — `corp_code_map.csv` note 홑따옴표 · `WAVE5_ALIASES` 초안 · `load_corp.py` 이름 대조가 어떻게 맞물리는지 실제 코드로. 현대해상은 금융사 집합(`FINANCIAL_COMPANIES` · `FINANCIAL_7` 이름 수) 갱신.
7. **같은 페이지 형제 이중 등록 방지(W5-2).** 기존 147사에 코스맥스 · 콜마 · 한국타이어 계열 형제가 있는지(COMP_NM 대조)와 한온시스템 ↔ 한국타이어(기등록) 문장 겹침 재확인 결과를 §2 에 한 줄씩.

## 보고 형식 (`W5/audit/integration-audit.md`)

§0 한 줄 요약 표(회사별 수집 행 → 최종 행 · 조치 수 · BLOCK) → §1 신규 코드 → §2 일관성 → §3 금액 → §4 등록 · 출처 → §5 회사별 조치 목록(집행형 + 검산) → §6 핀 → §7 이메일 → §8 업종 · 별칭 · corp_code 초안 → §9 문안 · 법정 문구 → §10 항목 페이지 · `/find` → §11 근무형태 칩 → §12 표시 등록 → §13 사용자 · 리드 결정(있을 때만 — ⚖ 항목 적용 결과 포함) → §14 별건 후속(코퍼스 기존 행의 불일치 · 오류 — 이번 시드 수정 목록에는 넣지 않는다, R-1 감사 계약 L6) → §15 BLOCK / MED / LOW(각 BLOCK 에 재현 명령 또는 파일 · 행 위치) → §16 감사가 확인하지 못한 것.

**최종 응답은 짧게:** BLOCK / MED / LOW 수 · 최종 행 수와 핀 값(SD-3 · SD-4) · §13 유무 · 보고서 · 모의본 경로.
