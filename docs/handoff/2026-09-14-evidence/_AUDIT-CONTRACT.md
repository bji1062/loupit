# 웨이브 3 코퍼스 횡단 감사 계약 (W-2 후반, Opus ×1) — 2026-09-14

목적: 이번 웨이브 시드 파일 N개를 **기존 코퍼스 126파일과 함께** 놓고 통합 준비 데이터를 만든다(웨이브 2 `docs/handoff/2026-09-05-evidence/wave2/integration-audit.md` 와 같은 산출물). 검증(verify)이 회사 안을 보면 감사는 회사 **사이**를 본다. 리포 읽기 전용 · DB 금지.
스크래치패드 = `/tmp/claude-0/-home-ubuntu-loupit/723f8817-c77d-4e78-ab10-c256a6b1bdd7/scratchpad` (아래 `…/scratchpad`). 산출물: `…/scratchpad/wave3/integration-audit.md` — **절 단위로 먼저 써 나간다**(웨이브 2 감사 1차는 보고 직전 세션 한도로 끊겼다).

## 반드시 실제 임포트로 재현
`load._split_sql_statements` · `company_meta.parse_header_insert` · `generator.slug.slug_of` 를 **실제로 import** 해 N파일을 돌린다. 출발점 = `…/scratchpad/wave3/_precheck.py`(웨이브 2 `_precheck.py` 를 경로만 바꾼 것) — 확장한 스크립트는 `…/scratchpad/wave3/_audit.py` 로 남긴다. 파싱 실패·문장 수 ≠5·slug 충돌은 BLOCK.

## 심사 항목
1. **신규 BENEFIT_CD** — 코퍼스 86종(`docs/handoff/2026-09-14-evidence/_VOCAB.md`) 대비 신규 전수 목록(수집기가 「신규」라 적지 않은 것까지). 각각 유지 / 흡수(→기존 코드) / 통합(신규끼리 → 1) 판정 + 근거(선례 회사·행). 웨이브 2 판정 논리(`integration-audit.md` §1 — 신규 2종 기각·`smart_office` 1종 신설) 그대로.
2. **회사 간 일관성** — 같은 제도가 회사마다 다른 코드로 간 것, 같은 코드가 다른 뜻으로 쓰인 것, 카테고리 불일치. 이번 웨이브 안에서만이 아니라 **기존 126사 행과도** 대조한다.
3. **금액** — AMT 있는 행 전수: 원문 명시·연환산 규약(SI-B2)·대출 한도/비율/상한/1회성 오입력. 무관 회사 간 동일 (코드·금액) 앵커 반복(백필 M-4 강등 대상 — 웨이브 2 넷마블 250·240 선례).
4. **등록 INSERT** — N개 COMP_ENG_NM·COMP_NM·유형·업종·LOGO 표. slug 정규화 후 기존 126 과 충돌 0. INDUSTRY_NM 이 기존 값에 합류했는지(trending 폴백 그룹핑 키). 이름이 `…/scratchpad/corp_codes_wave3.csv` 의 DART 명과 어떻게 대응하는지.
5. **verify 판정 반영 조치 목록** — `…/scratchpad/wave3/verify/*.verify.md` 의 REFUTED/SUSPECT/MISSED 가 SQL 에 어떻게 반영돼야 하는지 회사별 조치(삭제할 행·재코딩·병합·각주·AMT NULL·문안 교체). 감사는 SQL 을 고치지 않고 **조치 목록만** 낸다. verify 끼리 판정이 엇갈리면 원문을 직접 확인해 결론을 낸다.
6. **핀 계산** — 최종 행 수 합계 → `server/tests/test_seed_counts.py` SD-3(현 126)·SD-4(현 2032 → 2032 + 이번 행 수) · `test_seed_integrity.py` SI-8(126) · `test_seed_idempotency.py` SM-1(126) · `test_corp_load.py` FN-1(현 125/124 매핑 수, 공유 corp_code 유무 확인) · 금융사면 `db/seed/load_corp.py` FINANCIAL_COMPANIES 와 `test_corp_load.py` FINANCIAL_7 집합 · `test_seed_badge_backfill.py` SB-10 · `generator/data/company_registrations.json` 새 웨이브(회사 영문명 N개 — 날짜는 리드가 서빙 반영일로 넣는다).
7. **이메일 도메인** — evidence 의 관측 도메인 전수 + `db/seed/company_email_domain.sql` 의 @rejected·SED-5 그룹 병합 규칙 충돌 여부(같은 그룹 기존 줄은 `IN(...)` 병합 — 웨이브 2: 삼성 4사 samsung.com·한화생명 hanwha.com).
8. **업종·별칭 초안** — `generator/data/krx_sector.csv` N행(기존 파일에서 같은 업종 회사의 값을 선례로 — ⚠ CRLF·LF 혼재 파일이라 바이너리 append 권고를 적는다), `db/seed/company_meta.py` 에 붙일 WAVE3 별칭(구명·영문·약칭, 타 법인 이름은 금지). `db/seed/corp_code_map.csv` N행 초안 — **note 의 DART 명은 홑따옴표 필수**(`_DART_NM_RE`, 없으면 조용히 comp_nm 폴백 — 웨이브 2 BLOCK-1).
9. **사용자 노출 필드의 편집 주석 일소** — QUAL_DESC_CTNT·NOTE_CTNT·BENEFIT_NM 은 `/api/v1/companies` 와 비교 엔진으로 그대로 노출된다. 「코퍼스」「선례」「어휘표」「규칙 N」「수집기」「검증」「병합」「미수록」「회피」「흡수」「판독」「정본」「⚠」 같은 내부 용어·판단 근거와 **법정 제도 문구**(시차 출근·난임휴가·근로자의 날 등)를 N파일 전수 스캔해 행별로 내고, 원문 근거만 남는 대체 문안을 제안한다(웨이브 2: 69필드·법정 4행).

## 보고 형식
웨이브 2 `integration-audit.md` 와 같은 뼈대: §0 한 줄 요약 표 → §1 신규 코드 심사 → §2 일관성 → §3 금액 → §4 등록 데이터 → §5 verify 반영 조치 목록(회사별) → §6 핀 → §7 이메일/업종/별칭/corp_code 초안 → §8 BLOCK/MED/LOW 문제 목록(각 BLOCK 에 재현 명령 또는 파일·행 위치) → §9 편집 주석·법정 문구 대체 문안.
