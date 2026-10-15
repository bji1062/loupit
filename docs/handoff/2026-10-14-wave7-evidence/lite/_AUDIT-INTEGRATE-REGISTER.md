# 감사 · 통합 · 등록 계약 (웨이브 7부터 · 고정 부분 · 2026-10-14 판)

세 단계는 웨이브 6 구조 그대로다 — **A 감사**(Opus ×1) → **B 통합**(Sonnet · 판단 없음) → **C 등록 · 핀 · 리허설**(Sonnet · 판단 없음) → **D 공개**(리드). 웨이브마다 바뀌는 값은 아래 「리드가 채우는 칸」에만 적고 본문은 고치지 않는다.
- 세 단계 공통: **SendFeedback 도구 금지 · 하위 에이전트 금지**(지시문에도 그대로). 규칙 정본 = `/home/ubuntu/loupit-evidence/wave-lite/` 의 `_CONTRACT.md`(수집) · `_VERIFY-LITE.md` · `_VOCAB.md`.
- 운영 한 줄: **수집은 쉬지 않고, 공개(load · release)만 주 1회 몰아서** — 웨이브 간 ≥1주 간격은 공개에만 적용한다. 여러 웨이브를 PR 하나로 묶어도 된다(그때 아래 칸의 대상 · 핀은 묶은 합계).

## 리드가 채우는 칸 (세 단계 공통)

| 칸 | 값 |
|---|---|
| `W` = 웨이브 폴더 · 웨이브 번호 `N` | |
| 대상 시드(파일명 · eng · slug) · 회사 수 `K` · 함께 묶는 대기 웨이브(있으면 그 폴더) | |
| 출발 코퍼스: `main` 해시 · 회사 수 · 복지 행 수 · 쓰이는 코드 수 · FN-1 매핑 / 법인 수 · large / mid | |
| 리드 판정 목록(`W/_ROSTER.md` 번호 범위 — 확정값) | |
| 이번 웨이브 전용 결론 항목(신규 코드 · 새 업종 값 · DART 이력 짧은 회사 · 그룹 공용 메일 · 형제 이중 등록 · 별건 세기 등) | |
| `WT` = worktree 절대경로 · 브랜치 | |
| 반영일 = 서빙 날(모르면 예정일 — 공개 날이 다르면 고친다) | |
| 직전 리허설 폴더(`run.sh` · `cmp.py` 출발점) · 금융사 포함 여부 | |

---

## A. 감사 (Opus ×1)

목적: 이번 시드 `K` 파일을 **기존 코퍼스와 함께** 놓고 통합 준비 데이터를 만든다. 검증은 회사 안, 감사는 회사 **사이**와 코퍼스 전체. 여기서 통과한 것은 통합이 판단 없이 집행하고 곧 공개된다.
- **금지:** 리포 쓰기 · DB · git · 수집본(`W/collect/`) 수정. 감사는 **조치 목록과 모의 최종본**만 낸다. 새 웹 요청은 꼭 필요할 때만 · GET 만. 개인 정보를 보고서 · 조치에 옮기지 않는다(근거표에 있으면 §14 정정 목록). 작업 파일은 `W/audit/` 아래에만. **절(§) 하나 끝날 때마다 보고서 파일에 저장한다**(세션이 끊겨도 이어 쓴다).
- **검증 권고는 기본 채택이다** — §5 로 그대로 옮긴다. 뒤집는 것은 (a) 회사 사이 · 코퍼스 결론(일관성 · 어휘 · 핀)과 부딪힐 때 (b) 원문을 직접 확인해 틀렸을 때뿐이고, 이유를 적는다. 리드 판정은 확정값 — 다시 다투지 않는다(검증 권고와 엇갈리면 리드가 이긴다). 검증 「리드 판정 필요」에 리드 답이 없으면 그 기본안을 §5 에 넣고 §13 에 표시. 근거표 · 검증끼리 엇갈리면 원문(사본)을 직접 확인해 결론 — **판단이 남은 조치를 두지 않는다.**
- 경로: 감사 보고서 `W/audit/integration-audit.md` · 재현 스크립트 `W/audit/_audit.py`(출발점 = 직전 웨이브 `_audit.py` — 경로 · 어휘표만 바꾼다; `check-seed <폴더>` 하위 명령으로 그 폴더의 `K` 파일을 모의본과 행 단위 대조해 「형식 문제 n · 불일치 n」) · **모의 최종본** `W/audit/sim/<파일명>.sql`(수집본에 §5 조치를 적용한 결과 + 헤더 한 줄). 조치 문자열은 검증 보고서의 백틱 · JSON 을 **기계로 뽑아** 넣는다(손 옮김 0). 뼈대 본보기 = 직전 웨이브 `integration-audit.md`(지금은 `/home/ubuntu/loupit-evidence/2026-10-14-wave6/audit/integration-audit.md`).

**실제 임포트로 재현**(추측 금지): `db.seed.load._split_sql_statements`(전부 5문장 · 셋째 = `UPDATE TCOMPANY SET CAREERS_BENEFIT_URL`) · `db.seed.company_meta.parse_header_insert` · `ws_conditions` · `derive_work_style` · `generator.slug.slug_of`(코퍼스와 slug · 표시명 충돌 0) · `db.seed.backfill_dec2.derive_amt_source` · `_DATE_RE` · `_URL_RE` · `generator.benefit_rules` `load_pages` · `classify` · `text_hash` · `validate_all` · `_row_check.py` · `_len_check.py` · `_legal_scan.py`.

**BLOCK:** 파싱 실패 · 문장 수 ≠ 5 · slug · 표시명 충돌 · 머리말 정규식 불일치 · 필드 길이 초과 · 적재 게이트(`server/tests/test_seed_integrity.py` SI-9 · SI-11 · SI-12 · SI-13d · SI-B2)를 깰 행. 각 BLOCK 에 재현 명령 · 파일 · 행 위치.

### 심사 항목

1. **신규 BENEFIT_CD** — 어휘표 91종 밖 코드를 전수로(수집기가 「신규」라 적지 않은 것까지). 코드마다 **유지 / 흡수(→ 기존 코드) / 통합(신규끼리)** + 근거. 코퍼스 전문 grep 을 직접 다시(넓은 낱말로 · 1건에서 멈추지 않는다) · 이름은 제도 영역(지급 형태 · 속성 ✗ — 첫 공개 전에 정하는 게 싸다, `/find?b=<code>` 로 공개된다) · 원문에 없는 조건을 코드가 덧붙이지 않는다 · 형식 `^[a-z][a-z0-9_]{1,29}$`. 유지하면 카테고리 · 대표 이름 · 어휘표에 넣을 표 줄과 경계 줄(다음 판 `_VOCAB.md` 로) · 배선(보통 시드 · 어휘표만 — `/find` 대표 이름은 빌드가 뽑고 항목 페이지는 설정 파일이 있어야 생긴다).
2. **회사 간 일관성**(이번 웨이브 안 + 기존 코퍼스) — 같은 제도 다른 코드 · 같은 코드 다른 뜻 · 카테고리 ≠ 어휘표 · 휴가 · 성과급 · 대출 · 교육 코드 가르기 · 각주 세 꼴(수집 계약 3-5) · 부문 · 직군 한정 표기 · 기등록 형제 시드 문장과의 겹침(10자 이상 조각 대조). 사본 모드로 검증된 회사도 여기서 코퍼스 축과 한 번 더 맞춘다.
3. **금액** — 금액 행 전수 표(회사 · SORT · 코드 · 금액 · NOTE · 예측 AMT_SOURCE · 수집 계약 3-3 의 갈래 · 판정). stated = 원문 숫자 인용 · 합산 산술 / 추정 = 표지 · 넷 중 하나 · 타사 금액 · 틀 값 0 / NULL 이어야 할 것(한도 · 1회성 · 비율 · 조건부 · 대출 원금 · 합산 숫자 · 주기 없는 검진). **그 축 기존 최댓값의 2배를 넘는 값**은 급부 형태를 다시 본다. 게이트 SI-B2 · SI-9 · SI-12. 같은 (코드 · 금액) 겹침은 판단 근거가 아니다. 숫자가 있지만 비운 행 표 · 회사별 연 금액 합 · stated / 추정 행 수.
4. **등록 · 출처** — `K` 행 등록 표(`COMP_ENG_NM` · `slug_of` · `COMP_NM` · 유형 · 업종 · LOGO · 정본 URL · DART corp_code · 정식명 · 재무 · 직원 축 연수). DART 정식명 ≠ 표시명이면 별칭 필수 · corp_code_map note(§8). `INDUSTRY_NM` 기존 값 합류 여부 · 새 값이면 사유 · 같은 웨이브 안 바이트 동일 · trending 폴백 영향(짝 없는 업종 · 새 짝). 정본 URL 점검기 실측 모음(근거표 점검 ⑥ · 전체 모드 검증의 재실측 — `ok` · `robots`(배포 시 주의) · 그 밖은 BLOCK 후보) · PDF 정본(keyword None · 연도 파일명) · 한시 출처(공고)는 사본 + sha256 확인. **DART 재무가 CFS 로 몇 개년뿐이고 앞 연도가 OFS 만인 회사**는 적재 뒤 `python3 db/seed/dart_finance.py --probe <corp_code> --base-year <연도> --fs-div OFS` 로 보고 있으면 `TCORP.FS_DIV_CD = 'OFS'`(리드 · 운영) — 등록 자체는 막지 않는다(INV-6 = 복지 실데이터 보유).
5. **회사별 조치 목록(집행형 — 통합의 유일한 입력)** — 대상: 검증 보고서의 SUSPECT · REFUTED · MISSED 전수 + 그 밖 권고(문안 · 재코딩 · 칩 이름 · 항목 페이지 예외) + §1~§4 · §9 결론. 종류: 삭제 · 재코딩(코드 · 카테고리 · SORT 섹션) · 병합(받는 행 · 덧붙일 원문 구절) · 분리 · 문안 교체 · 이름 교체 · AMT NULL(`NULL` · NOTE → QUAL_DESC 새 글자 · `QUAL_YN TRUE`) · 추가(완성 VALUES 튜플). 대상 행 = 코드 + SORT, 새 값은 글자 그대로. **집행 규약**(5-0 에 적는다): 추가 행은 같은 카테고리 구역의 「바로 앞 SORT」 행 뒤 · 마지막 행이 되는 추가는 앞 행에 쉼표를 붙이고 자신은 쉼표 없이 · 삭제는 튜플과 뒤 쉼표를 지우고 빈 줄을 남기지 않는다(섹션 머리 주석은 남은 행 위에) · 재코딩 · 섹션 이동은 새 SORT 자리로. 회사마다 **헤더 한 줄** `-- 검증 · 감사 판정 반영(<날짜>): <무엇을 삭제 · 병합 · 재코딩 · 추가했는지> — 최종 N행`(참고 블록 끝 · 닫는 `-- ━━━` 줄 바로 위 · 따옴표 금지 · 참고 블록의 옛 문장은 고치지 않는다 — 이 한 줄이 「뒤집힘」을 적는다). 조치를 적용해 `W/audit/sim/` 을 쓰고 **검산**(분할기 5 · `_len_check` 0 · `_legal_scan` 총 행 · 검출 · 면제 수 · `_row_check` 총 오류 0 · `check-seed sim` 형식 0 · 불일치 0 · 조치로 길어진 문안이 200 · 500 을 넘지 않는지) · 회사별 최종 행 수 표(수집 · 삭제 · 추가 · 최종).
6. **핀**(리드 · 등록 단계가 고친다 — 감사는 파일 · 줄 · 새 값만. 줄 번호는 출발 `main` 에서 `grep -n` 으로 다시 확인):

| 핀 | 위치 | 새 값 |
|---|---|---|
| SD-3 회사 수 | `server/tests/test_seed_counts.py`(주석 꼬리 「+ 확장 웨이브 N K개사(반영일)」) | + K |
| SD-4 복지 총행 | 같은 파일 단언 · 메시지 · 산식 주석 · docstring 산식 줄 | + 최종 행 합(산식 「이전 + 합 = 새 값 (확장 웨이브 N — K개사 · 수집 − 삭제 + 추가)」) |
| CANON_BENEFITS | `server/tests/test_seed_member_rows.py` | SD-4 와 같은 값 |
| SI-8 · SM-1 회사 수 | `server/tests/test_seed_integrity.py` · `server/tests/test_seed_idempotency.py` | + K |
| FN-1 매핑 · 법인 · 재적용 매핑 | `server/tests/test_corp_load.py` 세 줄 | + corp_code 매핑 수(공유 corp_code 확인) |
| SB-10 실 URL 회사 집합 | `server/tests/test_seed_badge_backfill.py` `real_url_engs`(직전 웨이브 줄 다음) | `# 확장 웨이브 N(반영일, K) — 신규 등록, 전부 실 URL 헤더` + eng K개 |
| SI-9 `_MEAL_NO_TAIL_OK` | `server/tests/test_seed_integrity.py` | 월액 · 포인트 식대 회사가 있을 때만 eng 추가 |
| SI-13c 조건 칩 고정 · 맨 칩 단언 | 같은 파일 | 조건 칩(`cond`)이 생기는 회사 줄(합본 `build_company_meta` 실측) · 맨 칩으로 고정할 꼴(선택) |
| 쓰이는 코드 수 | `generator/tests/test_find_page.py`(docstring 포함) · `web/assets/js/find.test.js`(테스트 이름 「N종」 포함) — **두 곳** | + 유지한 신규 코드 수 |
| `/find` 표본 · `LABEL_OVERRIDE` | `generator/tests/data/find_label_cases.json`(리허설 DB 로 재생성) · `generator/pages/find.py` · `web/assets/js/find.js` **같은 줄** | 바뀔 대표 이름 표 · 고정할 이름 |
| 대문 「새로 등록된 회사」 | `generator/data/company_registrations.json` `waves` 맨 앞 | `{"date": "<반영일>", "label": "회사 확장 웨이브 N", "companies": [eng K개]}`(`test_home_page.py` 가 시드 회사 전부를 강제) |
| 금융사 | `db/seed/load_corp.py` `FINANCIAL_COMPANIES` · `server/tests/test_corp_load.py` `FINANCIAL_7` | 금융사가 있을 때만 |
| 고정 판 스냅숏 | `generator/tests/test_guide_report.py` 등 | 보통 변경 없음 — 확인만 |

  그 밖에 이번 eng · 바뀌는 코드를 박아 둔 테스트 · 픽스처를 `grep -rn`(generator/tests · server/tests · `web/assets/js/*.test.js` · generator/data · db/seed — 시드 제외)으로 찾아 적는다.
7. **이메일 도메인** — 근거표 관측 전수 + MX 실측(DNS — HTTP 아님) + `db/seed/company_email_domain.sql` 초안: `INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN) SELECT COMP_ID, '<도메인>', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = '<eng>';`. 웹 도메인 ≠ 메일 도메인 표. 그룹 공용 도메인: **사용자가 그룹 단위 인증을 정한 그룹(삼성 · SK)만** 기존 그룹 줄 `IN (...)` 에 병합(SED-5 — 그룹 공용은 한 문장). 코퍼스에 계열사가 하나뿐인 그룹 · 지주 공용 도메인은 넣지 않는다 — 그 도메인을 **어느 회사에도 넣지 않을 때만** `-- @rejected: <도메인> — <이유>`(SED-7 이 이유 문구를 본다). ⚠ **회사 하나만 그룹 줄에서 뺄 때는 `@rejected` 를 쓰지 않는다**(도메인 전체 보류로 읽혀 SED-7 이 깬다 — 평범한 주석). 형제 · 계열 공용일 수 있는 전용 도메인은 ⚠ 주석과 함께. 관측 0 이면 미등록(수동 승인 폴백). 주석에 따옴표 금지(분할기).
8. **업종 · 별칭 · corp_code 초안** — `generator/data/krx_sector.csv` K행(KRX 업종 이름만 — 새 값 금지 · 같은 업종 회사 선례 · 시장 · ⚠ **CRLF 파일이라 바이너리 append** `open(path,'ab')` + `\r\n`) · `db/seed/company_meta.py` `WAVE<N>_ALIASES`(직전 웨이브 사전 다음 · `build_company_meta()` 의 직전 별칭 루프 다음에 같은 꼴 — 구명 · 영문 · 약칭 · 법인 국문 상호만, **지주 · 형제 법인 이름 · 상표 금지**) · `db/seed/corp_code_map.csv` K행(comp_id 는 힌트 · 줄 끝 꼴은 바이트로 확인 · DART 정식명 ≠ 표시명이면 **note 에 DART 명을 홑따옴표로**(`load_corp.py` `_DART_NM_RE` — 없으면 조용히 comp_nm 폴백) · 같으면 note 에 「DART」 낱말 · 홑따옴표 · 쉼표를 쓰지 않는다) · 금융사면 두 집합.
9. **사용자 노출 문안** — `_legal_scan.py` 전수(검출 줄마다 허용 / 교체 / 삭제) · 수집 계약 3-11 금지 낱말 · 메모 낱말 · 「 — 」 꼬리 둘 · 「연차」 · 「반차」 · 「반반차」 · 조사 · 부사형 끝 · 법정 문구. 걸린 행마다 대체 문안을 글자 그대로(§5 로). 각주 세 꼴은 지우지 않는다.
10. **항목 페이지 · `/find`** — 검증이 권고한 예외를 모아 **모의 최종 문안 해시로** 다시 계산 · 메모리에서 적용해 `validate_all` 오류 0 · 같은 설정 파일은 배열을 합친다 → 「동반 조치(리드 집행)」 표(파일 · 추가할 객체 글자 그대로). `MIN_COMPANIES = 20` 문턱(법정 · `exclude` 뺀 회사 수)을 넘어 새로 생길 항목 페이지(설정 파일이 없으면 안 생긴다) · 신규 · 1~2회 코드와 동률 코드의 `/find` 대표 이름 변화(필요하면 `LABEL_OVERRIDE` 줄 권고).
11. **근무형태 칩** — 회사별 `derive_work_style`(remote · flex · refreshLeave · cond). 조건 칩이 생기는 회사는 §6 SI-13c 로. 이름이 조건처럼 보이는데 조건으로 안 읽히는 행(SI-13d)은 BLOCK.
12. **법정 · 업무 교육 표시** — 신규 회사는 `row_marks.json` 등록 0. 남아 있으면 §5 에 삭제 또는 상회분만.
13. **이번 웨이브 전용 결론 항목**(리드 칸) — 하나씩 결론. 🚨 2026-11-27 전 공개분은 난임 행 · 근거표 「11-27 재계산 대상」 전수 표(회사 · SORT · 지금 문구 · 11-27 뒤 문구 초안 · 원문이 법정 미달이 되는 회사)를 §14 에.

**보고 형식** — §0 한 줄 요약 표(회사별 수집 → 최종 · 조치 수 · 검증 모드 · C/S/R/M · 금액 행 · BLOCK) → §1 신규 코드 → §2 일관성 → §3 금액 → §4 등록 · 출처 → §5 조치(+ 5-0 규약 · 검산 · 최종 행 수) → §6 핀 → §7 이메일 → §8 업종 · 별칭 · corp_code → §9 문안 → §10 항목 페이지 · `/find` → §11 칩 → §12 표시 → §13 사용자 · 리드 결정(정책 문제만 · 기본안과 되돌리는 비용) → §14 별건 후속(코퍼스 기존 행 · 다음 계약에 넣을 것 · 근거표 정정 — 이번 시드 수정 목록에 넣지 않는다 · **등록하면 안 되는 형제 목록**) → §15 BLOCK / MED / LOW(재현 명령 · 위치) → §16 확인하지 못한 것. **최종 응답:** BLOCK / MED / LOW 수 · 최종 행 수와 SD-3 · SD-4 · §13 유무 · 보고서 · 모의본 경로.

---

## B. 통합 (Sonnet · 판단 없음)

감사 §5 · §9 가 확정한 조치를 수집본 `K` 파일에 **행 단위로 그대로 집행**해 `WT/db/seed/benefit/sql/<파일명>.sql` 을 쓴다. 코딩 작업이고 판단은 하지 않는다.
- 아래 경우에만 그 파일을 손대지 말고 「보류」: 조치끼리 충돌 · §5 문장이 둘 이상으로 읽힘 · 점검이 계약에 없는 이유로 깨짐. **계약에 없는 해결책 · 개선 · 정리 · 문구 다듬기 금지.** 「리드 판정 필요」로 남은 것은 집행하지 않고 보고.
- 입력: 수집본 `W/collect/<파일명>.sql`(출발점 · 읽기만) · **조치 정본 = 감사 §5(조치 · 헤더 한 줄 · 추가 튜플) · §9(대체 문안)** · 검증 보고서는 참고만(감사가 기각한 권고는 집행하지 않는다) · 형식은 수집 계약 §2.
- 🚨 **본체 체크아웃 `/home/ubuntu/loupit` 은 고치지 않는다** — `web/assets` 가 라이브 docroot 다(저장 = 즉시 운영). 쓰기는 `WT` 의 시드 폴더에만. 다른 파일(핀 · 등록 접점 · 설정 · 어휘표) · 기존 코퍼스 · git commit · push · 테스트 게이트 · 운영 DB · `loupit_test` · 수집본 · 모의본 수정 금지.

**집행 규칙**
1. **적힌 것만 바꾼다** — 적히지 않은 필드는 수집본 글자 그대로. 특히 금액 NOTE 의 「추정」 · 「환산」 · 식대 꼬리(빠지면 적재 때 공식 수치로 올라간다)와 각주 세 꼴(「(그룹 통합 채용 기준)」 · 「, ○○그룹 공통 문구」 · 「(… 통합 보고 기준)」)은 **절대 지우지 않는다.**
2. 추가 행은 §5 의 VALUES 튜플을 글자 그대로(SORT 도 준 값) — 그 밖의 새 행 금지.
3. 삭제는 튜플을 통째로 · SORT 를 다시 매기지 않는다(구멍 허용) · 마지막 행의 `,` / `;` 로 문법을 깨지 않는다 · 빈 줄을 남기지 않는다.
4. 병합은 남는 행 서술에 §5 의 원문 구절을 「, 」 또는 「 · 」로(「/」 금지) — 「 — 」 꼬리는 맨 끝 하나만.
5. 재코딩은 코드 · 카테고리 · SORT 를 함께 옮긴다. AMT NULL 은 §5 모양대로.
6. **따옴표를 새로 넣지 않는다**(주석 포함 — 아포스트로피는 U+2019 ’).
7. 헤더 한 줄은 참고 블록 끝(닫는 `-- ━━━` 바로 위)에. `-- 출처: AI 파싱 (…)` · `-- URL: …` 두 줄은 그대로.
8. **독립 집행** — 모의본(`W/audit/sim/`)은 점검 (a)~(e) 를 마친 **뒤에만** 연다(먼저 열어 베끼지 않는다 — §5 의 글과 감사의 모델이 같은 결과를 내는지 두 번 집행해 보는 단계다).

**점검**(순서대로 · 결과 줄을 보고에): (a) `python3 <_row_check.py> <K 파일> --corpus WT/db/seed/benefit/sql` → 총 오류 0(`[확인]` 줄은 감사 §3 · §11 과 같은지) · (b) `_len_check.py` → 0 violations · (c) `_legal_scan.py` → 총 행 · 검출 · 면제가 감사 §5 검산과 같다 · (d) 회사별 행 수 = 감사 §0 · stated / 추정 수 = 감사 §3 · (e) `python3 W/audit/_audit.py check-seed WT/db/seed/benefit/sql` → 형식 0 · 불일치 0(불일치면 §5 를 다시 읽는다 — 내 집행이 틀렸으면 고치고, 글과 모델이 어긋나 보이면 고치지 말고 둘 다 보류) · (f) 이제 `diff W/audit/sim/<파일명>.sql WT/…/<파일명>.sql` — 주석 위치 · 빈 줄 말고 차이는 전부 보고 · (g) `git -C WT status --short` 에 이번 `K` 새 파일(`??`)만.

**보고(짧게):** 회사별 최종 행 수 · 합계(감사 §0 대조) · (a)~(g) 결과 줄 · 보류 · 리드 판정 필요(없으면 「없음」) · `git status --short`.

---

## C. 등록 접점 · 핀 · 리허설 (Sonnet · 판단 없음)

통합이 끝난 `WT` 에 등록 접점 · 핀 · 항목 페이지 예외를 감사 글자 그대로 넣고, 격리 DB `loupit_test` 에 리허설 적재 → 복지검색 표본 재생성 → 전체 테스트. 감사 글과 실제 파일이 어긋나 집행이 둘 이상으로 읽히면 손대지 말고 「보류」.
- **금지:** 🚨 본체 `/home/ubuntu/loupit` 파일 수정(경로를 쓸 때마다 `WT` 로 시작하는지 본다) · 운영 DB `LOUPIT` 쓰기 · DDL(읽기 전용 덤프만) · 베타 DB `loupit_beta` · git commit · push · PR · 통합이 끝낸 `K` 시드 수정 · **`pytest` 직접 실행**(안전장치가 막는다 — `run_tests.sh` 로만) · OpenDART 호출(재무 · 직원 적재는 공개 때 리드).

**A. 파일 집행**(`<반영일>` 자리는 전부 리드 칸의 반영일 · 줄 번호는 내용으로 찾는다)
1. **핀** — 감사 §6 표 전부(「변경 없음」 핀은 손대지 않는다). 쓰이는 코드 수는 파이썬 · JS **두 곳**과 테스트 이름.
2. **대문 등록** — `WT/generator/data/company_registrations.json` `waves` 맨 앞에 감사 §6 객체(감사 순서 그대로 · 기존 객체 모양 · 들여쓰기).
3. **이메일 도메인** — 감사 §7 블록을 `WT/db/seed/company_email_domain.sql` 에(그룹 줄 병합은 그 줄 자리에, 새 블록은 파일 끝). 먼저 도메인마다 `dig +short MX <도메인>` 결과를 보고에 — **MX 가 비었거나 NXDOMAIN 이면 그 INSERT 를 빼고 보류.** 주석에 따옴표 금지. 넣은 뒤 `_split_sql_statements` 문장 수가 (전) + 넣은 INSERT 수인지.
4. **업종** — 감사 §8 줄을 `WT/generator/data/krx_sector.csv` 에 **바이너리 append**(`open(path,'ab')` · 줄마다 `\r\n`).
5. **별칭** — `WAVE<N>_ALIASES` 사전을 `WT/db/seed/company_meta.py` 직전 웨이브 사전 다음에, 루프를 `build_company_meta()` 의 직전 별칭 루프 다음에 같은 모양으로(행 끝 주석까지 감사 글 그대로).
6. **corp_code** — 감사 §8 줄을 `WT/db/seed/corp_code_map.csv` 끝에(기존 줄바꿈 꼴을 바이트로 확인해 같게).
7. **항목 페이지 예외** — 감사 §10 객체를 `WT/generator/data/benefit_pages/<파일>.json` 각 `overrides` 배열 끝에 글자 그대로(기존 들여쓰기 · 한 줄 꼴). 넣은 뒤 `load_pages` · `validate_all` 오류 0.
8. **`LABEL_OVERRIDE`**(감사 §10 에 있을 때) — `WT/generator/pages/find.py` 와 `WT/web/assets/js/find.js` **두 곳 같은 줄**(두 파일 머리 주석의 약속) · 기존 항목 옆 주석 꼴로 한 줄 이유.

**B. 리허설 적재**(`loupit_test`) — 출발점 = 리드 칸의 직전 리허설 `run.sh` · `cmp.py` 를 복사해 `W/rehearsal/` 로(출력 `W/rehearsal/out` · `WT` · 마이그레이션은 감사가 준 것만). 시작 때 `loupit_test` 가 비어 있지 않으면 **그 스키마의 테이블만** 지운다(대상 이름이 정확히 `loupit_test` 인지 먼저 assert).
1. 운영 참조 테이블 읽기 전용 덤프 → `loupit_test` → before 스냅숏.
2. `WT` 에서 `DB_NAME=loupit_test python3 db/seed/load.py`(적재 전 `SELECT DATABASE()` = `loupit_test` assert).
3. 대조 → `W/rehearsal/README.md` 결과 줄: 총 복지 행 · 회사 = 감사 SD-4 · SD-3? · `K` 사: `WT` 시드와 전 필드(명칭 · 금액 · 카테고리 · NOTE · 정성여부 · 서술 · SORT) 불일치 0 · `AMT_SOURCE` 분포 = 감사 §3 · 나머지 회사: before / after 행 증감 0 · 내용 변화 목록(있으면 전부) · `TCOMPANY` `K` 사 `CAREERS_BENEFIT_URL` · `WORK_STYLE_VAL`(감사 §11 대조) · 그 밖 변화 · 적재 로그 경고 줄 전부.
4. corp 적재 확인: `DB_NAME=loupit_test python3 db/seed/load_corp.py`(사용법은 파일 머리말) → `TCOMPANY_CORP` · `TCORP` 수 = 감사 FN-1 · `TCORP.CORP_NM` = DART 정식명.

**C. 복지검색 표본 다시 뽑기**
1. `cd WT && DB_NAME=loupit_test python3 generator/tests/data/make_find_label_cases.py` — 먼저 `server.config.get_settings()` 가 `DB_NAME` 을 따르는지 확인(아니면 bundle JSON 을 `loupit_test` 에서 덤프해 인자로).
2. `git -C WT diff generator/tests/data/find_label_cases.json` 에서 **label 이 바뀐 코드 전부** — 감사 §10 예상과 대조, 그 밖 변화는 보고(고치지 말고).
3. **동률 표본 테스트** — `WT/generator/tests/test_find_page.py` 「동률」 표본과 `WT/web/assets/js/find.test.js`(같은 쌍)를 새 픽스처로 다시 본다. 동률이 풀렸거나 대표 이름이 바뀐 쌍은 **지금 동률인 다른 코드**(새 픽스처 최다 빈도가 둘 이상 · 기대 문자열은 파이썬 `_most_common` 결과)로 바꾸고 파이썬 · JS 를 같게 · 기존 주석 꼴로 한 줄 이력.

**D. 전체 테스트**
```
cd <WT> && set -a && . /home/ubuntu/loupit/server/.env && set +a && env -u DB_NAME bash infra/deploy/run_tests.sh
```
- **foreground 로 돌린다**(백그라운드로 보내고 기다리면 결과를 놓친다) · timeout 넉넉히.
- 실패는 원인을 적는다 — A~C 집행 실수면 고치고 다시, 계약에 없는 원인이면 고치지 말고 보고.
- 끝나면 **`WT/package-lock.json` 이 새로 생겼으면 지운다**(`node_modules` 는 심볼릭 링크라 둔다).

**보고(짧게):** A 1~8 결과(파일 · 줄 수) · MX 표 · 보류 · B 결과 줄(README 와 같게) · C 바뀐 label · 동률 표본 교체 · D `run_tests.sh` 마지막 요약 줄(계층별 통과 · 실패) · `git -C WT status --short`.

---

## D. 공개 (리드 · 운영)

- **머지 순서:** 같은 시기의 다른 PR(코드 · 가이드)을 먼저 머지 · release 하고, 웨이브 PR 은 **공개 날** 머지 → load → release(`company_registrations.json` 에 DB 에 없는 회사가 실린 채 release 가 돌지 않게). 반영일이 예정과 다르면 대문 등록 · SB-10 주석의 날짜를 고친다.
- 공개 뒤 운영 조치: 감사 §4 의 OFS probe · 재무 · 직원 적재(OpenDART) · §13 사용자 결정.
- 근거표 · 사본을 공개 리포로 옮기기 전에 감사 §14 근거표 정정(개인 정보 · 오기)을 먼저.
- 감사 §14 의 「등록하면 안 되는 형제」 · 새 「이미 끝난 판정」은 수집 계약 1-9 에, 신규 코드 줄은 다음 판 `_VOCAB.md` 에 더한다(계약 본문 · 어휘표 경계 줄만 — 판례 번호는 넣지 않는다).
- 🚨 2026-11-27(난임 유급 4일) 이후 첫 웨이브 전에 수집 계약 3-2 · 어휘표의 난임 줄과 `legal_baseline.json` 을 함께 고친다(메모리 `loupit-legal-change-2026-11-27`).
