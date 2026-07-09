# 회사 복지 데이터 수집·구조화 전략

> 목적: loupit 회사 복지 데이터를 **어떻게 수집·구조화·검증**하는 게 가장 좋은지에 대한 조사 기반 권장 전략과 확정 결정.
> 근거: 조사(기존 스크래퍼 실증 / 소스·법적[robots.txt 실측·판례] / 추출·검증 기법) + PRD `08-데이터-요구사항`(D1~D6)·`10-리스크`(R3/R5) + USECASE `05-회사상세페이지`(UC-41/42).
> loupit 불변 제약: 로그인 없음 · 읽기전용 백엔드 · 빌드타임 정적 생성 · 공개 200개 페이지(법적 리스크 R3) · 큐레이션 96개 SQL 재사용.

---

## 0. 확정 결정 (2026-07-09)

| # | 결정 | 내용 |
| --- | --- | --- |
| **DEC-1** | 보관 위치 | 본 전략을 `docs/RESEARCH`에 문서화. SPEC(6단계)·데이터요구사항이 참조. |
| **DEC-2** | 96개 신뢰도 | **96개 복지 데이터는 "공식 출처(official)"로 인정.** 단, 앵커로 **추정된 금액은 정직하게 별도 표기**(금액 신뢰도 분리). → 배지(복지 존재의 출처 신뢰도)와 금액 신뢰도를 **디커플링**한다(§4 신뢰도 모델, PRD D3.9 정교화). |

**DEC-2 배경**: 실측상 96개 SQL의 복지 행 1,522개는 대부분 `BADGE_CD='est'`로 자기라벨링(헤더 주석: "추정치 — 공식 확인 시 official로 변경")되어 있고 `'(추정)'` 금액이 다수다. 출처는 공식 채용/복지 페이지지만 **금액은 앵커 추정**인 상태. 따라서 전량을 `official`로 일괄 승격하면 추정 금액을 공식값으로 오표기(불확실성 밴드 ±20%→±5% 축소, R3 법적 노출↑). DEC-2는 이를 피하려고 **출처 신뢰도와 금액 신뢰도를 분리**한다.

---

## 1. 결론

**크롤링·재게시 모델을 버리고, 공식 1차 출처 기반 하이브리드 오프라인 배치를 채택한다:**

> ① 회사 1차 출처(공식 채용/복지 페이지·뉴스룸) + 공식 오픈 API만 오프라인 배치 수집
> → ② Playwright 헤드리스로 렌더 텍스트 확보
> → ③ Anthropic SDK 스키마 강제 LLM 파싱으로 `TCOMPANY_BENEFIT` 9카테고리 구조화(원문 근거 없으면 폐기=환각 억제)
> → ④ 출처 배지 + **금액 신뢰도 분리** + 카테고리별 TTL 만료 관리
> → ⑤ 기존 96개 SQL 포맷으로 emit → 빌드타임 DB 시드 → 정적 생성
>
> 원문 문장은 복제하지 않고 **사실만 재서술 + 출처 아웃링크**한다.

**핵심 근거 3가지**
1. **법적 포지션이 소스를 강제한다.** robots.txt 실측 결과 잡플래닛·블라인드·크레딧잡·캐치·원티드는 전부 봇 차단이고, 회사 공식 페이지·뉴스룸·공식 API만 열려 있다. 판례(사람인 vs 잡코리아 = DB권 침해 확정)상 loupit처럼 "3rd-party 콘텐츠를 재공개하는 경쟁 서비스"가 최고위험군 → "robots가 열어둔 곳(공식)만 쓰고 닫아둔 곳은 링크만 건다"가 소스 정책의 축.
2. **회사 200개 × 제각각 구조 = 정적 셀렉터 파싱 불가.** JS 렌더·이미지 인포그래픽이 많아 requests+BS4는 커버리지 미달, "200개 × 셀렉터"는 유지보수 지옥. **LLM 스키마 강제 파싱이 유일한 유지보수 가능 경로**이며, 기존 96개가 이미 이 방식(AI 파싱)으로 생산된 검증된 경로다.
3. **신뢰도 인프라는 이미 스키마에 완비, 남은 건 백필.** `TCOMPANY_BENEFIT`의 배지·출처·검증·만료 컬럼군(D3)이 데이터 계약으로 확정됐으나 96개 SQL은 `BADGE_SRC_CD`/`VERIFIED_DTM`/`EXPIRES_DTM`을 **0/96** 채움 → 이 백필이 R3 완화의 실질 작업.

---

## 2. 소스 티어링 (정확·합법 순)

| 티어 | 소스 | 사용 방식 | robots/법적 |
| --- | --- | --- | --- |
| **1군(우선)** | 회사 공식 채용/인재영입/복지 페이지 | URL 발견 → robots 확인 → Playwright 렌더 → LLM 파싱. 사실만 재서술 + 출처 URL을 `BADGE_SRC_URL_CTNT`에 기록 | 회사가 홍보 목적 공개, 열림. 저작권만 유의(표현 복제 금지) |
| **1군(우선)** | 회사 뉴스룸/보도자료 | 복지 신설·개편 소식의 최적 출처, 사실 인용 자유. 공식 페이지 보강 | 회사 공표, 열림 |
| **1군(보강)** | OpenDART · 국민연금 가입사업장 오픈 API | **공식 API 직접 호출**(크롤링 불필요). 직원수·평균급여·규모 보강 | 정식 API, 출처표시 조건 재배포 허용 |
| **2군(조건부)** | 원티드/사람인/잡코리아 채용공고 | 회사 등록 준1차 정보라 신뢰도 높으나 무단 스크래핑 금지. 공식 제휴/API 경로로만. **MVP 미사용 권장** | 사람인 판례의 직접 무대, robots·ToS 리스크 |
| **폴백1** | 3rd-party 집계(bokziri 등) | 공식 실패 시 최후 폴백. `scrape_fallback`/`est`. **회사명 오염(과거 148/770 계열사 오매핑) 때문에 회사명 일치 검증기 통과분만.** MVP 배제 권장 | 3rd-party ToS·재공개 위험 |
| **폴백2** | 기업유형 프리셋(`TBENEFIT_PRESET`) | 공식·집계 모두 실패 시 유형별 기본 복지로 폴백(D2.5). `est`. 회사는 절대 빈 복지로 남지 않음(D2.6) | 자체 큐레이션 상수, 이슈 없음 |
| **⛔배제** | 잡플래닛·블라인드·크레딧잡·캐치·원티드 직접 크롤 | robots Disallow/403. 우회 시 침입죄·부정경쟁 방향. 상세는 링크만 | 명시적 봇 차단 |

**개인정보 배제**: 복지 "제도·사실"(재택 주2일, 식대 월20만)은 회사 정보라 개인정보보호법 대상 아님. **재직자 실명·식별 가능 후기는 절대 미수집** → 개인정보 리스크 제거.

---

## 3. 추출 파이프라인 (빌드타임 오프라인 배치)

```
[0] 회사 목록(200: KOSPI100+KOSDAQ100, D2.3)
[1] 발견·수집  공식(a)(g): 검색 → robots 확인(허용분) → Playwright 렌더 → innerText
              공공(f): OpenDART/국민연금 오픈 API 호출
              이미지 페이지(텍스트<500자 & 키워드<3 & 큰 이미지) → 스크린샷 비전 분기
[2] 정제       DOM 프루닝(script/style/nav/footer 제거) → txt 아티팩트 저장
              (메타헤더 SOURCE/URL/SCRAPED_AT + 본문) ★재현성의 단일 소스
[3] LLM 파싱   Anthropic SDK 배치 client.messages.parse(output_config.format=JSONSchema)
              모델: 파싱 claude-sonnet-5 / 공식성 검증 claude-haiku-4-5 / 난해·이미지 claude-opus-4-8
              출력: Benefit{benefit_cd, benefit_nm, benefit_ctgr_cd(enum 9종),
                    benefit_amt(int|null), amt_source(stated/estimated/none),  ← DEC-2 핵심
                    qual_yn, qual_desc, note, evidence_quote}
              환각 억제: evidence_quote 비면 폐기 / 원문에 회사 없으면 빈 배열 → 프리셋 폴백
              비용: Batch API(50%↓) + 프롬프트 캐싱 + KILL_COST_USD 킬스위치
[4] 카테고리 매핑  enum 9종 스키마 강제. 경계 규칙 프롬프트 주입
              (식대·통근·복지포인트·자사할인·생일·경조사·카페→perks; 사택·기숙사→work_env;
               장기근속포상→compensation)
[5] 금액 환산(연간 만원)  명시금액→amt_source=stated / 추정→estimated + note에 산출식
              앵커: 식대~432(일1.8만×240일)·통근~120·복지포인트~200·건강검진~100
              정성복지→benefit_amt=null, qual_yn=true, amt_source=none
[6] 배지 부여  BADGE_CD(출처 신뢰도) + amt_source(금액 신뢰도) 분리(§4)
              BADGE_SRC_CD(scrape_official/scrape_fallback/ai_parse/manual)
              VERIFIED_DTM=@scraped_at, EXPIRES_DTM=VERIFIED+카테고리TTL, BADGE_SRC_URL_CTNT=근거URL
[7] (선택) 검수  대량은 자동 통과. 다음 빌드 재실행 안전(official 보존 DELETE 패턴)
[8] SQL/DB 시드  sql/{회사}.sql (INSERT IGNORE TCOMPANY + DELETE WHERE BADGE_CD='est'(official 보존)
              + INSERT ON DUPLICATE KEY UPDATE) → mysql < *.sql → TCOMPANY_BENEFIT
              실데이터 없는 회사 → TBENEFIT_PRESET 폴백(D2.5)
[9] 정적 생성  DB → 회사 상세 200개 정적 HTML(JS 없이 본문, UC-44) + 인기 조합(F5)
              + reference/all 번들(D6) + sitemap.xml → Nginx 서빙, API 1시간 캐시
```

**소스별 추출법**: 공식 페이지·뉴스룸 = 헤드리스 + LLM 파싱(이미지는 비전). 공공 = 오픈 API 직접. 집계 폴백 = 헤드리스 + LLM + 회사명 일치 검증 필수. 프리셋 = 상수 직접 시드.

---

## 4. 신뢰도·신선도 모델 (DEC-2 반영 — 디커플링)

**핵심: 두 가지 신뢰도를 분리한다.**

| 축 | 의미 | 필드 | loupit 96개 적용 |
| --- | --- | --- | --- |
| **출처 신뢰도** | 이 회사가 이 복지를 제공한다는 사실의 확실성 | `BADGE_CD` (`official`/`est`) | **`official`** (공식 페이지 기반, DEC-2) |
| **금액 신뢰도** | 금액 수치가 공식 명시값인지 추정인지 | `amt_source` (`stated`/`estimated`/`none`) | 명시=`stated`, 앵커추정=`estimated`, 정성=`none` |

### 4.1 배지·출처 컬럼(D3) 채움 규칙
| 컬럼 | 규칙 |
| --- | --- |
| `BADGE_CD` | 공식 출처 기반 = **`official`**(DEC-2). 집계 폴백·프리셋 = `est` |
| `amt_source` | 원문 명시 금액=`stated` / 앵커 추정=`estimated` / 정성·금액없음=`none` (신규 개념, 백필 시 도출) |
| `BADGE_SRC_CD` | 공식=`scrape_official` / 집계=`scrape_fallback` / LLM=`ai_parse` / 수동=`manual` |
| `BADGE_SRC_URL_CTNT` | 근거 URL(법적 출처표기 핵심). 기존 `수동 입력` 유실분은 재발견으로 복원 |
| `VERIFIED_DTM` | 수집/검증 일시 |
| `EXPIRES_DTM` | `VERIFIED_DTM + 카테고리 TTL`(§4.2) |

### 4.2 불확실성 밴드 (클라이언트 비교 계산, D3.9 정교화)
밴드는 **금액 신뢰도(`amt_source`) 기준**으로 정하고, 출처 배지(`official`)와 무관하게 추정 금액엔 넓은 밴드를 유지한다.

| 조건 | 밴드 |
| --- | --- |
| `amt_source=stated` (공식 명시) | **±5%** |
| `amt_source=estimated` (앵커 추정) | **±20%** |
| `EXPIRES_DTM` 경과(만료) | **±15% 가산 확대** + UI "재확인 필요" 표기(UC-34/42) |

→ **96개는 배지 `official`이되, 추정 금액 항목은 ±20% 밴드를 유지**한다(DEC-2). "공식 출처지만 금액은 추정" 상태가 UI·계산에 정직하게 반영된다.

### 4.3 카테고리별 만료 TTL (조사 권장, 튜닝 가능 — **오픈이슈 OI-3**)
| 카테고리 | TTL |
| --- | --- |
| `compensation`(성과급·상여) | 6개월 |
| `perks`(식대·복지포인트·통신비) | 9개월 |
| `time_off` / `flexibility` | 12개월 |
| `work_env`/`health`/`growth`/`leisure`/`family` | 18개월 |

※ 기존 `benefit_service.py` TTL(flexibility 180일/health·family 730일)과 상충 → 하나로 확정 필요(OI-3).

---

## 5. 법적 안전장치 (R3·R5 완화)

1. **robots/ToS 준수** — Disallow·403·로그인 게이트 소스는 미사용(우회는 침입죄·부정경쟁 방향). 공식 페이지만 대상, AI봇 차단 회사 존중.
2. **사실만, 재서술로** — "재택 주2회 / 식대 월20만" 같은 사실 항목만 자체 표·문장으로 재구성. 원문 리뷰·설명문 복붙 금지. `qual_desc`는 짧은 발췌만.
3. **출처표기 의무화** — 항목마다 `BADGE_SRC_URL_CTNT`(출처) + `VERIFIED_DTM`(수집일) 노출(UC-42). 공공데이터는 출처표시 시 재배포 허용.
4. **원본 미복제 + 아웃링크** — 상세는 회사 공식 페이지로 출처 링크("대체" 아닌 "안내"). 한 소스 전량 미러링 금지(DB 상당부분 복제 회피).
5. **면책 문구** — 복지·연봉은 참고용·실제와 다를 수 있음을 정책 페이지(F7)에 명시(D4.1). `est`·`estimated`·만료 배지가 UI 상시 노출(D3.10).
6. **회사 정정요청 대응(신고 기능 前 임시안)** — MVP는 런타임 신고 없음(D4.6). 정책 페이지(F7)에 정정 요청 연락처 게시 → 접수 시 해당 행 수정/무효화(`manual`)하고 다음 빌드 재배포 반영(R5). 배포 주기 종속이 잔여 리스크.
7. **개인정보 배제** — 복지 제도·사실만, 재직자 식별정보 미수집.

---

## 6. 기존 자산 재사용 vs 재작업

### KEEP
| 자산 | 위치 | 용도 |
| --- | --- | --- |
| 9카테고리 체계·분석 | `job_change/benefit.md`(동의어·가중치·classify 의사코드) | 카테고리 매핑·비교 로직 최우선 자산 |
| 큐레이션 96개 SQL | `job_change/server/seed/benefit/sql/*.sql` | D2.4 보존(v1 gold set, 오염 없음) |
| SQL 포맷 계약 | 위 96개 | `INSERT IGNORE` + `DELETE WHERE BADGE_CD='est'`(official 보존) + `ON DUPLICATE KEY UPDATE` |
| 발견 파이프라인 | `discover_and_scrape.py` | robots·레이트리밋·비용 킬스위치·resume/retry |
| 헤드리스 스크래퍼 | `scrape_benefits.py`(`scrape_page`) | innerText 추출, 안티봇 위장, double-close 버그 수정됨 |
| `BENEFIT_KEYWORDS` 정규식맵 | `scrape_benefits.py` | 비전 분기·품질 게이트 |
| 금액 앵커·경계 규칙 | `parse-benefits/SKILL.md` | 프롬프트 상수 |

### CHANGE
| 대상 | 변경 |
| --- | --- |
| 파싱 | 대화형 `/parse-benefits` → **SDK `client.messages.parse()` 배치**(재현·자동검증) |
| **96개 백필** | `BADGE_SRC_CD`/`VERIFIED_DTM`/`EXPIRES_DTM` 0/96 → 백필. **BADGE_CD를 `official`로 설정(DEC-2)** + `amt_source` 도출(stated/estimated) |
| URL 복원 | `CAREERS_BENEFIT_URL='수동 입력'` → 공식 페이지 재발견으로 실 URL 복원(출처표기용) |
| 모델 | 별칭 `claude-haiku-4-5`/`claude-sonnet-5`/`claude-opus-4-8` + Batch API + 프롬프트 캐싱 |

### DROP
로그인 결합 신뢰도 워크플로우 전부: `promote_to_official()` 런타임 API, `TBENEFIT_REPORT`, `TCOMPANY_BENEFIT_BADGE_LOG`, `VERIFIED_BY_ID`(FK→TMEMBER), 모든 쓰기 경로. / bokziri 오염 770개(MVP 배제). / 정적 정규식 파서 SQL 생성.

---

## 7. 단계적 실행안

| 단계 | 범위 | 산출물 | 대략 공수 |
| --- | --- | --- | --- |
| **Phase 0 — 재이식 + 백필** (MVP 필수) | 96개 SQL → `TCOMPANY_BENEFIT` 로더. `BADGE_CD=official`(DEC-2)·`amt_source`·출처·TTL 백필 | 200개 전부 비지 않음(96 실데이터 + 104 프리셋, D2.6) | 2~3일 |
| **Phase 1 — 정적 생성 + 론칭** (MVP 필수) | DB 시드 → 회사 200개 정적 HTML + reference/all + sitemap. 면책·정책(F7) | AdSense 승인 콘텐츠(R1), 색인 자산(R4) | 3~5일 |
| **Phase 2 — LLM 배치 파싱 자동화** (2차) | 파싱을 SDK 배치로 교체, `amt_source`·`evidence_quote` 도입, URL 복원·신선도 갱신 | 재현·자동검증 파이프라인, 갱신·확충 | 1~2주 |
| **Phase 3 — 증분·확장** (2차+) | 비전 분기, 만료 기반 롤링 재파싱, 분기 배치 + 시즌 전 전수 | 신선도 자동 유지 | 지속 |

**핵심 판단: Phase 0+1만으로 MVP 론칭 가능.** 96개가 D2.4 보존 대상이고 200개가 폴백으로 비지 않으므로, 신규 LLM 스크래핑(Phase 2)은 **론칭 차단요소가 아니라 갱신·확충 도구**다. "코드는 새로, 데이터는 보존" 원칙과 정합.

---

## 8. 오픈이슈 (미결 — SPEC/TASK 단계에서 확정)

| ID | 이슈 | 비고 |
| --- | --- | --- |
| OI-1 | 96개가 200개(KOSPI/KOSDAQ) 목록에 모두 포함되는지 교집합 확인 | 불일치 시 폴백 커버리지 재계산 |
| OI-3 | 카테고리 TTL 값 확정 (조사 권장 vs 기존 benefit_service.py 상충, §4.3) | 하나로 고정 |
| OI-4 | 집계 폴백(bokziri) 채택 여부 — MVP 배제 권장 | 96 초과 확장 시 회사명 검증분만 조건부 |
| OI-5 | Phase 2 착수 시점 + 비용 예산(Serper/CSE 키, KILL_COST_USD) | 론칭 필수 아님 |
| OI-6 | `amt_source` 백필 정확도 — 기존 `'(추정)'` 표기·note로 stated/estimated 판별 규칙 | Phase 0 백필 로직 |
| OI-7 | 정정요청 SLA(신고 기능 부재로 배포 주기 종속) — 목표 반영 시한 정책 명시 여부 | R5 |

**해결됨**: (구 OI-2, 론칭 전 official 승격 범위) → **DEC-2로 확정**: 96개 전부 출처 `official`, 추정 금액은 `amt_source=estimated`로 정직 표기.

---

### 참조
- 데이터 계약: `docs/PRD/08-데이터-요구사항.md` (D1~D6)
- 리스크: `docs/PRD/10-리스크.md` (R3/R5)
- 열람 UX: `docs/USECASE/05-회사상세페이지.md` (UC-40~44), `docs/USECASE/04-비교리포트.md` (UC-34)
- 재사용 자산: `job_change/server/tools/discover_and_scrape.py`·`scrape_benefits.py`·`.claude/skills/parse-benefits/SKILL.md`·`server/seed/benefit/sql/*.sql`(96개)
