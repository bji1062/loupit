# 웨이브 4 코퍼스 횡단 감사 계약 (W-2 후반, Opus ×1) — 2026-09-19

목적: 이번 웨이브 시드 파일 12개를 **기존 코퍼스 138파일과 함께** 놓고 통합 준비 데이터를 만든다(웨이브 2 `docs/handoff/2026-09-05-evidence/wave2/integration-audit.md` 와 같은 산출물). 검증(verify)이 회사 안을 보면 감사는 회사 **사이**를 본다. 리포 읽기 전용 · DB 금지.
스크래치패드 = `/tmp/claude-0/-home-ubuntu-loupit/f1d13a36-92d2-4e1c-9ce2-b6e64e0505ce/scratchpad` (아래 `…/scratchpad`). 산출물: `…/scratchpad/wave4/integration-audit.md` — **절 단위로 먼저 써 나간다**(웨이브 2 감사 1차는 보고 직전 세션 한도로 끊겼다).

## 반드시 실제 임포트로 재현
`load._split_sql_statements` · `company_meta.parse_header_insert` · `generator.slug.slug_of` 를 **실제로 import** 해 12파일을 돌린다. 출발점 = `…/scratchpad/wave4/_precheck.py`(웨이브 2 `_precheck.py` 를 경로만 바꾼 것) — 확장한 스크립트는 `…/scratchpad/wave4/_audit.py` 로 남긴다. 파싱 실패·문장 수 ≠5·slug 충돌은 BLOCK.

## 심사 항목
1. **신규 BENEFIT_CD** — 코퍼스 87종(`docs/handoff/2026-09-19-evidence/_VOCAB.md`) 대비 신규 전수 목록(수집기가 「신규」라 적지 않은 것까지). 각각 유지 / 흡수(→기존 코드) / 통합(신규끼리 → 1) 판정 + 근거(선례 회사·행). 웨이브 2 판정 논리(`integration-audit.md` §1 — 신규 2종 기각·`smart_office` 1종 신설) 그대로.
2. **회사 간 일관성** — 같은 제도가 회사마다 다른 코드로 간 것, 같은 코드가 다른 뜻으로 쓰인 것, 카테고리 불일치. 이번 웨이브 안에서만이 아니라 **기존 138사 행과도** 대조한다.
3. **금액** — AMT 있는 행 전수: 원문 명시·연환산 규약(SI-B2)·대출 한도/비율/상한/1회성 오입력. 무관 회사 간 동일 (코드·금액) 앵커 반복(백필 M-4 강등 대상 — 웨이브 2 넷마블 250·240 선례).
4. **등록 INSERT** — 12개 COMP_ENG_NM·COMP_NM·유형·업종·LOGO 표. slug 정규화 후 기존 138 과 충돌 0. INDUSTRY_NM 이 기존 값에 합류했는지(trending 폴백 그룹핑 키). 이름이 `_ROSTER.md` §2·§6 의 corp_code·DART 명(리드가 DART API 로 12사 전부 확인함 — GC녹십자의 DART 정식명은 「녹십자」)과 어떻게 대응하는지.
5. **verify 판정 반영 조치 목록** — `…/scratchpad/wave4/verify/*.verify.md` 의 REFUTED/SUSPECT/MISSED 가 SQL 에 어떻게 반영돼야 하는지 회사별 조치(삭제할 행·재코딩·병합·각주·AMT NULL·문안 교체). 감사는 SQL 을 고치지 않고 **조치 목록만** 낸다. verify 끼리 판정이 엇갈리면 원문을 직접 확인해 결론을 낸다.
6. **핀 계산** — 최종 행 수 합계 → `server/tests/test_seed_counts.py` SD-3(현 138 → 150)·SD-4(현 **2233** → 2233 + 이번 확정 행 수) · `test_seed_integrity.py` SI-8(138 → 150) · `test_seed_idempotency.py` SM-1(138 → 150) · `test_corp_load.py` FN-1(현 137/136 매핑 수, 공유 corp_code 유무 확인) · 금융사 0(현대해상 불가) — `db/seed/load_corp.py` FINANCIAL_COMPANIES 와 `test_corp_load.py` FINANCIAL_7 집합 · `test_seed_badge_backfill.py` SB-10 · `generator/data/company_registrations.json` 새 웨이브(회사 영문명 N개 — 날짜는 리드가 서빙 반영일로 넣는다).
7. **이메일 도메인** — evidence 의 관측 도메인 전수 + `db/seed/company_email_domain.sql` 의 @rejected·SED-5 그룹 병합 규칙 충돌 여부(같은 그룹 기존 줄은 `IN(...)` 병합 — 웨이브 2: 삼성 4사 samsung.com·한화생명 hanwha.com).
8. **업종·별칭 초안** — `generator/data/krx_sector.csv` 12행(기존 파일에서 같은 업종 회사의 값을 선례로 — ⚠ CRLF·LF 혼재 파일이라 바이너리 append 권고를 적는다), `db/seed/company_meta.py` 에 붙일 WAVE4 별칭(구명·영문·약칭, 타 법인 이름은 금지). `db/seed/corp_code_map.csv` 12행 초안 — **note 의 DART 명은 홑따옴표 필수**(`_DART_NM_RE`, 없으면 조용히 comp_nm 폴백 — 웨이브 2 BLOCK-1).
9. **사용자 노출 필드의 편집 주석 일소** — QUAL_DESC_CTNT·NOTE_CTNT·BENEFIT_NM 은 `/api/v1/companies` 와 비교 엔진으로 그대로 노출된다. 「코퍼스」「선례」「어휘표」「규칙 N」「수집기」「검증」「병합」「미수록」「회피」「흡수」「판독」「정본」「⚠」 같은 내부 용어·판단 근거와 **법정 제도 문구**(시차 출근·난임휴가·근로자의 날 등)를 12파일 전수 스캔해 행별로 내고, 원문 근거만 남는 대체 문안을 제안한다(웨이브 2: 69필드·법정 4행).

## 보고 형식
웨이브 2 `integration-audit.md` 와 같은 뼈대: §0 한 줄 요약 표 → §1 신규 코드 심사 → §2 일관성 → §3 금액 → §4 등록 데이터 → §5 verify 반영 조치 목록(회사별) → §6 핀 → §7 이메일/업종/별칭/corp_code 초안 → §8 BLOCK/MED/LOW 문제 목록(각 BLOCK 에 재현 명령 또는 파일·행 위치) → §9 편집 주석·법정 문구 대체 문안.


## 웨이브 4 전용 — 감사가 반드시 결론을 내야 하는 것 (리드 지정)

정본은 `docs/handoff/2026-09-19-evidence/_ROSTER.md` §7(감사가 판정할 것)·§8(검증 결과)이다. 먼저 읽어라.

1. 🚨 **리드 오류 집행 — 규칙 3 임의 확대.** 리드가 GC녹십자 수집 프롬프트에만 「시차출퇴근·선택적근로시간은 법정이니 뺀다」를 넣어 **같은 웨이브의 JYP 와 처리가 갈렸다.** 검증 2레인이 독립적으로 「법정 아님」 결론(규칙 3 열거·`legal_baseline.json` 15항목·검출어 어디에도 없고, 코퍼스에 `flex_work` 「선택적 근로」 19행·`health_check` 「매년」 17행·`event` 「경조휴가」 70행이 라이브). GC녹십자 근거표 §8④ 에 **되살릴 행이 준비돼 있다.** 최종 판정과 집행을 하라.
2. **어휘 충돌 2건** — ① `smoking_cessation`(JYP) ↔ `nonsmoking_bonus`(피에스케이): 검증 권고는 `smoking_cessation` 통일 + 피에스케이 재코딩(기각 시 JYP 행 삭제·`health_check` 흡수). ② `welfare_fund`(동국제약) ↔ 기존 `welfare_fund_loan`: 양 레인이 「합치면 원문에 없는 대출을 단언한다」로 합병 반대.
3. **신규 코드 4개 전수 판정** — `welfare_fund` · `housekeeping`(검증은 `parenting` 흡수 권고) · `home_security`(유지 권고, 카테고리 `perks`/`health` 만 결정) · `smoking_cessation`/`nonsmoking_bonus`.
4. **금액 관례 확정**(제주반도체 검증의 코퍼스 실측을 검산하라) — ① 구간 금액: 진짜 선례 4건(상한 3·중간값 1)이고 유일한 중간값 선례 네패스가 **같은 `welfare_point`·같은 직급별 구간** → 220 대신 175 권고. ② **AMT 612행 전부 `QUAL_YN=FALSE`**(리드 재확인) → 조건부 금액을 AMT 에 넣으면 조건이 구조적으로 사라진다(주거비 600 → NULL 권고). ③ 명절 500 은 축 최댓값 150의 3.3배 → NULL 권고 + 축 분리 검토. **결론을 다음 웨이브 계약 문구로 쓸 수 있게 한 문단으로 정리하라.**
5. **`INDUSTRY_NM='유통'` 은 이번 웨이브 신규 값**이다(현대백화점·이마트 둘이 짝). 두 SQL 의 문자열이 **바이트 동일**한지 확인하고, 기존 값 합류가 더 나은지(「커머스/홈쇼핑」 등) 판단하라. KRX 섹터는 기존 「유통」에 합류한다(리드 실측).
6. **검증 SUSPECT 26건·MISSED 5건 전수 반영 조치** — 회사별로 삭제/재코딩/병합/문안 교체/AMT NULL 을 적고 최종 행 수를 계산하라. MISSED 5: GC녹십자 `flex_work` · 풍산 `mental`(ESG p.50 EAP)·`culture_day`(p.66) · 티에스이 `incentive` · 동국제약 「보너스(600%)」(코퍼스 `bonus` 4행과 비대칭 — 리드 실측 확인).
7. **`_legal_scan.py` 검출어를 리드가 보강했다**(`시차출퇴근`·`근로자의날`·`보호구`·`산업안전보건`·`산업재해`·`보상휴가`·`직무발명` 추가). **보강본으로 12파일을 다시 돌려라** — GC녹십자 SORT 24 「근로자의날」이 새로 잡힌다.
8. **출처가 한시적인 두 회사** — 이마트(공고 마감 2026-09-28·10-12)·제주반도체(공고 이미지). 사본·sha256 이 evidence 에 있는지, `CAREERS_BENEFIT_URL` 이 죽지 않는 주소인지 확인하라.
