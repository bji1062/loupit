# 웨이브 2 코퍼스 횡단 감사 계약 (W-2 후반, Opus ×1) — 2026-09-05

목적: 13개 시드 파일을 **기존 코퍼스 113파일과 함께** 놓고 통합 준비 데이터를 만든다(웨이브 1 `docs/handoff/2026-09-01-evidence/wave1/integration-audit.md` 와 같은 산출물). 검증(verify)이 회사 안을 보면 감사는 회사 **사이**를 본다. 리포 읽기 전용 · DB 금지. 산출물: `…/scratchpad/wave2/integration-audit.md`.

## 반드시 실제 임포트로 재현
`load._split_sql_statements` · `company_meta.parse_header_insert` / `_row_chunks`(있으면) · `generator.slug.slug_of` 를 **실제로 import** 해 13파일을 돌린다(웨이브 1 `_audit2.py` 방식 — 스크립트는 `…/scratchpad/wave2/_audit.py` 로 남긴다). 파싱 실패·문장 수 이상·slug 충돌은 BLOCK.

## 심사 항목
1. **신규 BENEFIT_CD** — 코퍼스 85종(`_VOCAB.md`) 대비 신규 전수 목록(수집기가 「신규」라 적지 않은 것까지). 각각 유지 / 흡수(→기존 코드) / 통합(신규끼리 → 1) 판정 + 근거(선례 회사·행). 웨이브 1 판정 논리(`integration-audit.md` §1) 그대로.
2. **회사 간 일관성** — 같은 제도가 회사마다 다른 코드로 간 것(예: 자녀 입학축하금 → child_edu 병합 선례, 하계휴가비 → travel_support), 같은 코드가 다른 뜻으로 쓰인 것, 카테고리 불일치(같은 코드가 health/perks 로 갈림).
3. **금액** — AMT 있는 행 전수: 원문 명시·연환산 규약(SI-B2)·대출 한도/비율/상한/1회성 오입력. 무관 회사 간 동일 (코드·금액) 앵커 반복(백필 M-4 강등 대상).
4. **등록 INSERT** — 13개 COMP_ENG_NM·COMP_NM·유형·업종·LOGO 표, slug 정규화 후 기존 113 과 충돌 0, 이름이 corp_code_map 이름과 일치하는지(`scratchpad/corp_codes_wave2.csv`).
5. **verify 판정 반영 여부** — `…/scratchpad/wave2/verify/*.verify.md` 의 REFUTED/SUSPECT/MISSED 가 SQL 에 어떻게 반영돼야 하는지 회사별 조치 목록(삭제할 행·재코딩·각주·AMT NULL). 감사는 SQL 을 고치지 않고 **조치 목록만** 낸다.
6. **핀 계산** — 최종 행 수 합계 → SD-4 = 1755 + N, SD-3/SI-8/SM-1 = 126, FN-1 = 125/124, FINANCIAL 8→10(삼성화재·한화생명), SB-10 +13 eng.
7. **이메일 도메인** — evidence 의 관측 도메인 전수 + `db/seed/company_email_domain.sql` 의 @rejected·SED-5 그룹 병합 규칙 충돌 여부.
9. **사용자 노출 필드의 편집 주석 일소** — QUAL_DESC_CTNT·NOTE_CTNT·BENEFIT_NM 은 `/api/v1/companies` 와 비교 엔진(qualCompare)으로 그대로 노출된다. 「코퍼스」「선례」「어휘표」「규칙 N」「수집기」「검증」「병합」「미수록」「회피」「흡수」 같은 내부 용어·판단 근거는 evidence 에만 두고 필드에서는 제거해야 한다(1라운드 검증이 삼성화재 3행에서 발견). 13파일 전수 스캔 결과를 행별로 내고, 제거 후 문장이 원문 근거만 남도록 대체 문안을 제안한다.
8. **업종·별칭 초안** — krx_sector 13행(선례 매핑: 조선/항공=운송장비·부품, PCB/전자부품=전기·전자, 보험=보험, IT/게임=IT 서비스, 식품=음식료·담배, 반도체소재=화학, 플랜트=건설, 제약=제약), WAVE2_ALIASES(구명·영문·약칭, 타 법인 이름은 금지).

## 보고 형식
웨이브 1 `integration-audit.md` 와 같은 뼈대: §0 한 줄 요약 표 → §1 신규 코드 심사 → §2 일관성 → §3 금액 → §4 등록 데이터 → §5 verify 반영 조치 목록(회사별) → §6 핀 → §7 이메일/업종/별칭 → §8 BLOCK/MED/LOW 문제 목록.
