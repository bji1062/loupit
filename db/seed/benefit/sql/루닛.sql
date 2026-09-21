-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 루닛 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-14)
-- URL: https://www.lunit.io/ko/careers/
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 루닛 자기 도메인(lunit.io) 두 곳이다. 3자 사이트 인용 0건.
--       S1 정본 = 한국어 채용 페이지 섹션 「루닛에서 일하는 것이 즐거운 이유」
--         (section id -working-at-lunit-20-2840) — 카테고리 h3 3개 · 항목 h4 9개 · 항목마다 한 줄 설명.
--         WordPress SSR 이라 원본 HTML 에 텍스트로 있다. robots.txt 는 200 · 0바이트(전면 허용).
--       S2 보조 = 같은 도메인 지속가능성 페이지가 링크한 2025 루닛 지속가능경영보고서 PDF
--         (wp-content/uploads/2026/05, 88쪽, 텍스트 PDF). p.31 「다양한 복리후생 제도 운영」 표가
--         핵심이고 p.24(Luniversal·자격증 응시료) · p.26(우리사주·스톡옵션) · p.32(임신·출산 선물)로 보강.
--         설·추석 명절 선물 · DB형 퇴직연금 · 우리사주조합 등 한국에만 있는 제도이고, 표 16줄 중 7줄이
--         서울 오피스 기준 채용 페이지와 겹치며, 국내 사업장 노사협의회 안건(p.44)이 식대·주년 보상을 다루고,
--         보고서 인사 데이터가 일관되게 Lunit International 을 제외(p.8·70~73)해 본사 법인 (주)루닛 서술로 판단했다.
--         p.31 표 자체에는 범위 각주가 없다(p.32 각주는 육아휴직 표 전용).
--       ⚠ 반드시 /ko/ 경로로 호출한다. 루트는 /en/ 으로 301 되고 영문 채용 페이지에는
--         복지 섹션이 없어 0건으로 오판된다.
--       ⚠ S1 섹션 끝 한정 문구 「* 서울 오피스 기준이며, 오피스 위치에 따라 상이할 수 있습니다.」
--         서울 본사가 곧 상장 법인이라 귀속 문제는 아니지만, 한정을 지우면 허위라 S1 이 닿은
--         전 행의 QUAL_DESC(금액 행은 NOTE) 말미에 조건으로 남겼다. S2 단독 행에는 보고서 기준을 적었다.
--       ⚠ 쓰지 않은 경로: apply.workable.com/lunit/ (3자 ATS 경로 — 공고 목록뿐) ·
--         lunitinternational.bamboohr.com (영문 페이지에만 있는 자회사 Lunit International 채용).
--       S1 9항목 → 제외 2(훌륭한 동료 = 문화 서술 · 사내 세미나 = 회사 주도 교육) → 7항목 →
--         복합 라벨 3개 코드별 분해(+4) → 11행. S2 가 새 코드 12개를 더해 23행.
--       S2 에서 뺀 것: DB형 퇴직연금 · 법정 모성보호 휴가(법정) · 직무 발명 보상금(법정 보상) ·
--         직무 관련 전문가 강연 · LuniVersity 학습 플랫폼 · Knowledge Exchange · 팀 워크샵(회사 주도 교육·조직문화).
--       금액: 복지포인트 연간 120만원 1건만 BENEFIT_AMT(원문이 연액). 장기 근속 포상금 400만원은
--         S2 가 장기 근속자(5년) 대상이라고만 밝혀 연 환산할 수 없으므로 NULL 로 두고 서술에 적었다.
--       신규 코드 0. 섹션 순서는 S1 카테고리 등장 순서, S1 에 없는 flexibility·health·family 는 S2 표 순서로 뒤에 붙였다.
--       ⚠ 검증·감사 판정 반영(2026-09-15): 23 → 22행. SORT 21 에서 선별 부여 스톡옵션을 걷어내고 우리사주조합만 남겼다 ·
--       SORT 71 원격근무(remote_work) 삭제, 문구는 SORT 70 유연근무제 서술에 흡수. 복지포인트 120 은 원문 명시값이라 유지.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ⚠ 데이터 정리 2차(2026-09-21): SORT 43 카테고리 통일. db/migrations/20260921_data_cleanup_2.sql 동봉.
-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lunit', '루닛',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        'AI/의료', 'L', 'https://www.lunit.io/ko/careers/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lunit');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lunit.io/ko/careers/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) — S1 몰입할 수 있는 환경에서 일합니다 + S2 ──
  (@comp_id, 'work_tools', '최신형 장비 지원', NULL, 'work_env',
   'est', NULL, TRUE, '입사 시 최신 사양의 컴퓨터 장비(Mac, 4K 모니터 등)를 선택할 수 있고 3년마다 교체 지원 (공식 채용 페이지 몰입할 수 있는 환경에서 일합니다 항목 — 장비 예산·교체 비용 한도 미기재, 서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음)', 10),
  (@comp_id, 'office_furniture', '데스크테리어 비용 지원', NULL, 'work_env',
   'est', NULL, TRUE, '심리적 안정감 및 맞춤형 업무 공간 조성을 위해 신규 입사자에게 데스크테리어 비용 지원 (2025 지속가능경영보고서 복리후생 표 — 지원 한도·기존 직원 적용 여부 미기재)', 11),
  (@comp_id, 'nap_room', '릴렉스룸', NULL, 'work_env',
   'est', NULL, TRUE, '근골격계 질환 예방 및 심리적 회복을 위한 릴렉스룸(안마의자, 리클라이너) 운영 (2025 지속가능경영보고서 복리후생 표 — 설치 사업장·이용 시간 미기재)', 12),

  -- ── 보상·금전 (compensation) — S1 몰입할 수 있는 환경에서 일합니다 + S2 ──
  (@comp_id, 'long_service_bonus', '장기 근속 포상금', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 포상으로 포상금 400만원 지급, 2025 지속가능경영보고서는 장기 근속자(5년) 대상 장기근속 포상금 지급으로 기재 (공식 채용 페이지 「장기 근속 포상 - 포상금 400만원, 리프레시 휴가 2주」 항목 — 5년 이후 반복 지급 여부 미기재, 서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음)', 20),
  (@comp_id, 'stock_option', '우리사주조합', NULL, 'compensation',
   'est', NULL, TRUE, '우리사주조합 운영 (2025 지속가능경영보고서 복리후생 표·합리적인 보상 제도 — 회사 출연 여부·가입 조건 미기재)', 21),

  -- ── 휴가 (time_off) — S1 몰입할 수 있는 환경에서 일합니다 + S2 ──
  (@comp_id, 'long_service_leave', '장기 근속 리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기 근속 포상으로 리프레시 휴가 2주 부여, 2025 지속가능경영보고서는 장기 근속자(5년) 대상 유급휴가로 기재 (공식 채용 페이지 「장기 근속 포상 - 포상금 400만원, 리프레시 휴가 2주」 항목 — 5년 이후 반복 부여 여부 미기재, 서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음)', 30),

  -- ── 경제적 부가혜택 (perks) — S1 함께, 즐겁게 일합니다 + S2 ──
  (@comp_id, 'meal', '점심/저녁 식사 지원', NULL, 'perks',
   'est', NULL, TRUE, '점심·저녁 식사 지원, 2025 지속가능경영보고서는 지정 근로시간 내 중식 및 초과 근무 시 석식 비용 지원으로 기재 (공식 채용 페이지 「점심/저녁/간식지원」 항목 — 식대 단가 미기재, 서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음)', 40),
  (@comp_id, 'snack_bar', '간식·사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '간식 지원, 2025 지속가능경영보고서는 사내 카페/스낵바 운영으로 기재 (공식 채용 페이지 「점심/저녁/간식지원」 항목 — 무료 여부·이용 한도 미기재, 서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음)', 41),
  (@comp_id, 'welfare_point', '복지포인트', 120, 'perks',
   'est', '공식 채용 페이지 항목명 「복지포인트 연간 120만원 지원」 명시값 — 원하는 곳, 필요한 곳에 사용. 2025 지속가능경영보고서는 개개인의 라이프스타일에 맞춰 사용 가능한 복지포인트(Seluv-Be) 지급으로 기재 (서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음)', FALSE, NULL, 42),
  -- 카테고리 통일(2026-09-21): perks → compensation
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '설과 추석 명절 선물 지급 (2025 지속가능경영보고서 복리후생 표 — 선물 종류·금액 미기재)', 43),

  -- ── 여가·라이프 (leisure) — S1 함께, 즐겁게 일합니다 + S2 ──
  (@comp_id, 'company_event', '송년회·사내 이벤트', NULL, 'leisure',
   'est', NULL, TRUE, '한 해 동안 수고한 루니션(임직원)들을 위한 송년회(연말 파티) 개최, 2025 지속가능경영보고서는 다양한 사내 이벤트 진행으로 기재 (공식 채용 페이지 함께, 즐겁게 일합니다 항목 — 행사 규모·주기 미기재, 서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음)', 50),
  (@comp_id, 'club', '소모임 지원', NULL, 'leisure',
   'est', NULL, TRUE, '루니션 커뮤니티 형성을 위한 소모임 지원 (2025 지속가능경영보고서 복리후생 표 — 활동비 한도·운영 소모임 수 미기재)', 51),

  -- ── 성장·교육 (growth) — S1 성장하며 일합니다 + S2 ──
  (@comp_id, 'lang', '루니버셜 (사내 어학 프로그램)', NULL, 'growth',
   'est', NULL, TRUE, '업무 중에 틈틈이 영어 수업 수강, 2025 지속가능경영보고서는 사내 영어 강사의 1:1 및 그룹 클래스로 운영하는 사내 무료 어학 프로그램(Luniversal)이며 외국인 임직원은 한국어 수업 비용을 지원한다고 기재 (공식 채용 페이지 성장하며 일합니다 항목 루니버셜 — 수강 횟수·수강 대상 제한 미기재, 서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음)', 60),
  (@comp_id, 'conference', '학회 참석 지원', NULL, 'growth',
   'est', NULL, TRUE, '학회 참석, 2025 지속가능경영보고서는 학회 참석 비용 지원으로 기재 (공식 채용 페이지 「학회 참석, 교육비, 도서 구입비」 항목 — 지원 한도·국내외 구분 미기재, 서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음)', 61),
  (@comp_id, 'edu_support', '교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '교육비 (공식 채용 페이지 「학회 참석, 교육비, 도서 구입비」 항목 — 지원 한도·대상 교육 미기재, 서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음)', 62),
  (@comp_id, 'books', '도서 구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서 구입비, 2025 지속가능경영보고서는 도서 대여 및 구매 지원으로 기재 (공식 채용 페이지 「학회 참석, 교육비, 도서 구입비」 항목 — 연간 한도 미기재, 서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음)', 63),
  (@comp_id, 'self_development', '자격증 응시료 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무와 관련된 외부 자격증 취득 비용(응시료) 지원 (2025 지속가능경영보고서 임직원 역량 향상 — 대상 자격증·지원 횟수 미기재)', 64),

  -- ── 근무 유연성 (flexibility) — S2 즐거운 삶 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '시간과 장소 제약 없이 유연하게 결정하는 유연근무제 운영, 유연근무제와 원격근무로 업무 자율성 보장 (2025 지속가능경영보고서 복리후생 표·본문 — 코어타임·원격근무 허용 일수·적용 직무 미기재)', 70),

  -- ── 건강·의료 (health) — S2 건강한 삶 ──
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '전 직원 대상 연 1회 종합건강검진(정밀건강진단) 지원 (2025 지속가능경영보고서 복리후생 표 — 검진 비용 한도·가족 포함 여부 미기재)', 80),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '중증 질환 진단 비용과 도수 치료 등 실손 의료비를 포괄하는 임직원 단체상해보험 가입 (2025 지속가능경영보고서 복리후생 표 — 보장 한도·가족 포함 여부 미기재)', 81),

  -- ── 가족·돌봄 (family) — S2 안정적인 삶 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 지원금·휴가·선물 제공 (2025 지속가능경영보고서 복리후생 표 — 경조 구분별 금액·휴가 일수 미기재)', 90),
  (@comp_id, 'parenting', '임신·출산 축하 지원', NULL, 'family',
   'est', NULL, TRUE, '임신·출산 관련 지원금과 선물 제공 — 임신 축하 선물, 배우자 출산 시 출산 축하 선물 (2025 지속가능경영보고서 복리후생 표·가족 친화 및 모성 보호 제도 — 지원금 액수·선물 구성 미기재)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
