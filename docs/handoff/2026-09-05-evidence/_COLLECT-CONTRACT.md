# 웨이브 2 수집 계약 (W-1) — 2026-09-05

회사 1곳의 복지를 **공식 1차 출처에서만** 수집해 (a) 시드 SQL 1파일 (b) 근거표 1파일을 만든다. 신규 회사라 구본·앵커가 없다.
**DB 접속·기록 금지. `/home/ubuntu/loupit` 리포는 읽기만** — 산출물은 전부 스크래치패드에 쓴다.

## 산출물 (스크래치패드 `…/scratchpad/wave2/`)

1. `wave2/<파일명>.sql` — `db/seed/benefit/sql/심텍.sql`(라벨만 있는 회사)·`KB금융.sql`(SPA)·`현대건설.sql`(서술형) 을 먼저 읽고 **그 형식 그대로**.
   - 헤더 주석: `-- 출처: AI 파싱 (2026-09-05)` · `-- URL: <정본 URL>` · `-- badge: est` · `-- 참고:` 몇 줄(출처 경로·렌더 방식·판단 요약).
   - 1) `INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)` — **이 문장이 실제 등록**이다.
     `COMP_ENG_NM` = snake_case 영문 slug(기존 113 과 충돌 금지 — `grep -h "VALUES ('" db/seed/benefit/sql/*.sql` 로 확인), `COMP_NM` = 표시명(DART 정식명 기준, 통용 표기),
     `COMP_TP_CD` ∈ large(대기업집단·대형 상장사) / mid(중견) / public(공기업) — 웨이브 1 선례: LG CNS·KB금융·현대건설·고려아연 large, 원익IPS·심텍·엘앤에프·하나마이크론 mid.
     `INDUSTRY_NM` = 짧은 업종명(예 '반도체기판'·'건설'·'IT서비스'), `LOGO_NM` = **영문명 이니셜 대문자 1자**(코퍼스 관례: 고려아연 K·심텍 S·엘앤에프 L — 한글 초성 아님. ⚠ 2026-09-05 수집기 지시엔 한글 초성으로 잘못 나갔고 통합 단계에서 일괄 교정).
   - 2) `SET @comp_id` · 3) `UPDATE … CAREERS_BENEFIT_URL` · 4) `DELETE … BADGE_CD='est'` · 5) `INSERT INTO TCOMPANY_BENEFIT … ON DUPLICATE KEY UPDATE` — 심텍.sql 과 동일 구조.
   - 행: `(@comp_id, 'code', '명칭', AMT|NULL, 'ctgr', 'est', NOTE|NULL, QUAL_YN, QUAL_DESC|NULL, SORT)`.
     카테고리 ∈ compensation·health·family·leisure·perks·growth·time_off·flexibility·work_env. SORT 는 카테고리별 10단위 섹션(첫 섹션 10, 다음 20 … 섹션 안은 +1). 섹션 순서는 원문 페이지 순서를 따르면 된다(웨이브 1 실측: 회사마다 다름).
     금액 없는 행 = `NULL, 'est', NULL, TRUE, '<원문 근거 요약 (출처 페이지·미기재 항목 명시)>'`. 금액 있는 행 = `AMT, 'est', '<명시값 근거>', FALSE, NULL`.
   - **주석·문자열에 홑따옴표·겹따옴표 금지**(load.py 분할기가 깨진다 — 「」 사용). BENEFIT_CD 는 회사당 UNIQUE(같은 코드 2행 금지 — 병합해 QUAL_DESC 에 양쪽 서술).
2. `wave2/<파일명>.evidence.md` — `docs/handoff/2026-09-01-evidence/wave1/KB금융.evidence.md`(SPA)·`심텍.evidence.md`(이미지) 형식. 필수 절: 출처 표(채택/제외 URL·robots·렌더) · 행별 인용표(행마다 원문 문장 그대로) · 코드 매핑 판단·어휘 함정 회피 · 법정 제도 미수록 확인 · 금액 · 제외 목록 · 이메일 도메인 관측 · 배포 시 주의.

## 규칙 (웨이브 1 계약 그대로 — 번호 유지)

1. **출처**: 회사 자기 도메인 또는 공식 홈에서 링크된 회사 브랜드 ATS 서브도메인만. SPA 면 번들·API 를 추적해 본문을 확보하고 경로를 기록(하드코딩 청크 해시는 index → 청크 순으로 추적). 이미지 안 항목은 이미지를 내려받아 판독하고 URL·크기·sha256 기록. 3자 사이트(사람인·잡코리아·잡플래닛·캐치·인크루트·블라인드·원티드) 인용 0건. 검색엔진 스니펫도 근거가 아니다.
2. **원문 근거 필수**: 행마다 원문 문장을 인용. 없는 것을 만들지 말고, 뉴스 카드·인터뷰·인재상·비전 문구는 제도 근거가 아니다.
3. **법정 제도 미수록**: 4대보험·퇴직연금(DC/DB)·주5일·법정 연차·법정 육아휴직/육아기 단축·법정 출산휴가는 행으로 만들지 않는다. 회사 재량 상회분(기간 연장·급여 보전·추가 휴가)만, 원문이 상회 조건을 밝힐 때 수록.
4. **금액은 명시값만**: 원문에 연 환산 가능한 금액이 있을 때만 BENEFIT_AMT(만원/년, SI-B2: 월액×12). 없으면 NULL — 타사 앵커·추정치 금지. 대출 원금 한도는 금액이 아니다(정성).
5. **어휘**: 새 코드를 만들기 전에 `docs/handoff/2026-09-05-evidence/_VOCAB.md`(85종) 에서 같은 뜻을 찾는다. 함정: `family_day`=조기퇴근(가족 행사는 `company_event`) · `long_service_leave`=휴가만(포상금은 `long_service_bonus`) · `work_tools`=IT 장비 · `insurance`=단체상해보험 · `pension_support`=개인연금 지원 · `uniform`=근무복(자율복장 아님) · `housing_loan`(대출)≠`housing_support`(지원금) · `meal` 은 끼니·단가 명시 없으면 NULL. 대응 어휘가 정말 없을 때만 신규 코드(evidence 에 「신규 코드」절로 사유 기재).
6. **귀속**: 그룹 공통 복지를 개별 법인에 갖다 붙이지 않는다. 그룹 통합 페이지를 정본으로 쓸 수밖에 없으면 프로브가 확인한 귀속 경로를 헤더에 적고 **전 행 QUAL_DESC 말미에 「(그룹 통합 채용 기준)」 각주** — 이 각주는 귀속의 전제라 절대 떨구지 않는다. 부문·자회사·임원 한정 항목은 제외(한정을 지우면 허위).
7. **이메일 도메인 관측**: 채용 페이지·문의처에서 관측된 회사 공식 이메일 도메인을 evidence 에 기록(재직인증용, 없으면 「미관측」).
8. **비용 지원 = 복지 ○ / 회사 주도 교육 커리큘럼 = 복지 ×**(웨이브 1 확립). 명시적 비용 지원(학자금·자격증 취득비·어학비)만 growth 행.
8-1. **파견형 육성 기준**(웨이브 2 감사 확립): 학위·해외 파견형(MBA·EMBA·석사·학술연수·지역전문가·주재원)은 `mba`(학위) 또는 `career`(파견·경력)에 수록, 사내 아카데미·집중과정·직무 커리큘럼은 제외. 배정은 원문이 독립 항목이고 그 회사에 `career` 행이 있으면 `career`, 없으면 `mba` 행 서술에 흡수(행 신설 금지), MBA 와 한 복합 라벨이면 `mba`.
8-2. **어휘 함정 추가**: 예식장·웨딩홀 대관 = `event` 서술(`wedding` 은 현금 축하금+휴가) · `dormitory`=사택·기숙사 등 주거 **시설** / `housing_support`=임차비·주거비 **현금** / `housing_loan`=대출·이자 · `lounge`=휴게·카페 공간만(업무 공간은 `smart_office`, 옥외 조경은 행 아님) · 급여성 수당(학위 수당·초임)은 복지가 아니다 · 조직문화 담당자 역할(GWP·서포터즈)은 혜택이 아니다.
8-3. **사용자 노출 필드 문안**: QUAL_DESC_CTNT·NOTE_CTNT·BENEFIT_NM 은 `/api/v1/companies` 와 비교 엔진으로 그대로 노출된다. 허용 = 원문 라벨 + 출처 페이지명(「공식 채용 페이지 … 항목」) + 조건 + 미기재 사항. 금지 = 판단 근거·법조문·행 구조·「코퍼스」「선례」「병합」「판독」「규칙 N」「⚠」. 그런 설명은 전부 evidence 로.
9. **행 수 목표 12~25**. 원문 항목이 그보다 적으면 억지로 늘리지 않는다(라벨만 있는 회사는 라벨 수 그대로). 병합은 같은 코드로 귀결되는 항목만.

## 예절

UA 일반 브라우저 · `--max-time 20` · 요청 간 ≥1초 · 회사당 요청 ≤60회 · 내려받은 파일은 `…/scratchpad/wave2/<eng>/` 아래. Playwright 가능(`from playwright.sync_api import sync_playwright`).
