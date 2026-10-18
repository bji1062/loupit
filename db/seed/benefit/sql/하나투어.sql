-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 하나투어 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://www.hanatourcompany.com/kr/careers/life/benefit
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)하나투어(영문 HANATOUR SERVICE INC.)의 회사 소개 도메인 www.hanatourcompany.com
--   CAREERS > 하나인 생활 > 하나인 혜택 페이지다(소비자 사이트 www.hanatour.com 꼬리말 회사소개 링크로 연결).
--   SSR 이라 원본 HTML 에 TRAVEL · REFRESH · LIFE · GROWTH 4블록 20라벨이 다 있다. 헤드리스 렌더 · 이미지 판독 불필요.
--   보조 출처: 같은 도메인 ESG > 사회 > 인권 및 안전보건 페이지 중점 관리사항 활동 표(신체 건강 세부 프로그램
--   건강검진 · 체력단련비 · 힐링라운지 운영) · OpenDART 2026 반기보고서(접수 20260814004029) 직원 등 현황
--   유연근무제도 사용 현황(시차출퇴근제 사용자 수) · 2025 사업보고서(접수 20260319001345) 같은 표. 직원 1,337명(2025).
--   지속가능경영보고서 목록과 채용공고 · FAQ · 보도자료 목록은 POST 로만 불려 와 받지 않았다.
--   귀속: 페이지 주어가 하나투어 단수이고 계열사 · 그룹 공통 단서가 없다. 하나금융그룹과 무관(최대주주 사모펀드).
--   코퍼스에 같은 그룹 법인 없음. 각주 불필요.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL. 저녁 식대는 초과근무 조건부라 NULL.
--   제외: 업무 교육(온보딩 프로그램) · 선발형 직무 육성(직무 전문가 제도) · 임원 보수 산정 칸(사업보고서 ·
--     반기보고서 기타 근로소득 복리후생비) · 공시 표의 선택근무제 · 원격근무제(세 기간 모두 사용자 없음 ·
--     활용 여부 칸 시차출퇴근제만) · 우리사주조합 주주 표 한 칸 · ESG 표의 건강검진(이름만).
--   공고 근거 0행 / 전체 18행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(perks 10 · time_off 20 · leisure 30 · flexibility 40 · health 50 ·
--     compensation 60 · family 70), ESG 페이지에만 있는 work_env 80.
-- 검증 · 감사 판정 반영(2026-10-18): 행 조치 없음 · 수집본 18행 그대로 · 임직원 전용 여행상품 discount 유지 · 입사 1년 미만 여행과 2시간 단위 휴가 leave_general 한 행 · 새 업종 여행 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 18행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanatour', '하나투어',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '여행', 'H', 'https://www.hanatourcompany.com/kr/careers/life/benefit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanatour');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hanatourcompany.com/kr/careers/life/benefit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활 (perks) — 공식 채용 페이지 하나인 혜택 ──
  (@comp_id, 'discount', '임직원 전용 여행상품 및 항공권', NULL, 'perks',
   'est', NULL, TRUE, '임직원 전용 여행상품 및 항공권, 다양한 상품의 직원 혜택 (공식 채용 페이지 하나인 혜택 TRAVEL 항목) — 혜택 방식·혜택 폭·이용 횟수 미기재', 10),
  (@comp_id, 'birthday_gift', '하나투어 마일리지 지원 (생일)', NULL, 'perks',
   'est', NULL, TRUE, '생일에 하나투어 마일리지 제공 (공식 채용 페이지 하나인 혜택 LIFE 하나투어 마일리지 지원 항목) — 마일리지 규모·사용처 미기재', 11),
  (@comp_id, 'meal', '저녁 식대 지원', NULL, 'perks',
   'est', NULL, TRUE, '초과근무 시 식대 지원 (공식 채용 페이지 하나인 혜택 LIFE 저녁 식대 지원 항목) — 1끼 단가·지급 방식 미기재', 12),
  -- ── 휴가 (time_off) — 공식 채용 페이지 하나인 혜택 ──
  (@comp_id, 'leave_general', '입사 1년 미만 특별 혜택 · 2시간 단위 휴가 제도', NULL, 'time_off',
   'est', NULL, TRUE, '입사 1년 이내 직원은 하나투어 상품으로 연차와 별도로 여행 1회 (공식 채용 페이지 하나인 혜택 TRAVEL 입사 1년 미만 특별 혜택 항목), 2시간 단위로 휴가를 효율적으로 사용 (같은 페이지 REFRESH 2시간 단위 휴가 제도 항목) — 여행 일수·여행 경비 부담 여부 미기재', 20),
  (@comp_id, 'refresh_leave', '안식년 제도', NULL, 'time_off',
   'est', NULL, TRUE, '안식년 제도를 활용한 자기계발 및 재충전의 시간 (공식 채용 페이지 하나인 혜택 REFRESH 안식년 제도 항목) — 휴가 일수·부여 조건 미기재', 21),
  -- ── 여가 (leisure) — 공식 채용 페이지 하나인 혜택 ──
  (@comp_id, 'resort', '국내 유명 휴양시설 지원', NULL, 'leisure',
   'est', NULL, TRUE, '국내 주요 휴양 시설을 법인 회원가로 제공 (공식 채용 페이지 하나인 혜택 TRAVEL 국내 유명 휴양시설 지원 항목) — 이용 가능 시설·이용 횟수 미기재', 30),
  (@comp_id, 'club', '사내 동호회 운영 및 지원', NULL, 'leisure',
   'est', NULL, TRUE, '공통의 관심사를 가진 직원들과 네트워크를 형성하는 사내 동호회 운영 및 지원 (공식 채용 페이지 하나인 혜택 REFRESH 항목) — 지원 금액·지원 방식 미기재', 31),
  -- ── 근무 유연성 (flexibility) — 공식 채용 페이지 하나인 혜택 · 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근 제도를 통한 일과 삶의 균형 (공식 채용 페이지 하나인 혜택 REFRESH 시차출퇴근제 항목), 시차출퇴근제 사용자 455명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 출퇴근 시간대·대상 직무 미기재', 40),
  (@comp_id, 'family_day', '가정의 날 조기퇴근', NULL, 'flexibility',
   'est', NULL, TRUE, '매월 급여일이 있는 주 금요일은 하나투어 가정의 날로 1시간 일찍 퇴근 (공식 채용 페이지 하나인 혜택 REFRESH 가정의 날 조기퇴근 항목)', 41),
  -- ── 건강 (health) — 공식 채용 페이지 하나인 혜택 · ESG 페이지 ──
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강 관리를 위해 건강보험공단 주기에 맞춰 종합 건강검진 지원 (공식 채용 페이지 하나인 혜택 LIFE 건강검진 지원 항목) — 검진 항목·비용 지원 범위·가족 적용 여부 미기재', 50),
  (@comp_id, 'fitness', '체력단련비', NULL, 'health',
   'est', NULL, TRUE, '임직원 신체 관리지원 세부 프로그램 체력단련비 (공식 홈페이지 ESG 인권 및 안전보건 중점 관리사항 활동 표 신체 건강 항목) — 지원 금액·지급 주기 미기재', 51),
  -- ── 보상 (compensation) — 공식 채용 페이지 하나인 혜택 ──
  (@comp_id, 'holiday_gift', '하나투어 마일리지 지원 (명절 · 창립기념일)', NULL, 'compensation',
   'est', NULL, TRUE, '명절과 창립기념일에 하나투어 마일리지 제공 (공식 채용 페이지 하나인 혜택 LIFE 하나투어 마일리지 지원 항목) — 마일리지 규모·사용처 미기재', 60),
  (@comp_id, 'excellence_award', '슈퍼스타 H', NULL, 'compensation',
   'est', NULL, TRUE, '매년 하나투어 발전에 큰 기여를 한 우수 직원과 팀을 선정하여 포상 (공식 채용 페이지 하나인 혜택 GROWTH 슈퍼스타 H 항목) — 포상 내용·선정 규모 미기재', 61),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 직원에게 그 공로를 인정한 포상 제공 (공식 채용 페이지 하나인 혜택 GROWTH 장기근속 포상 항목) — 근속 기준·포상 내용·금액 미기재', 62),
  -- ── 가족 (family) — 공식 채용 페이지 하나인 혜택 ──
  (@comp_id, 'event', '경조금 · 경조휴가', NULL, 'family',
   'est', NULL, TRUE, '기쁜 날은 축하하고 슬픈 날엔 함께 나누는 경조금 및 경조휴가 (공식 채용 페이지 하나인 혜택 LIFE 경조금 및 경조휴가 항목) — 경조 사유별 금액·휴가 일수 미기재', 70),
  (@comp_id, 'childcare', '워킹맘, 워킹대디를 위한 직장 어린이집 지원', NULL, 'family',
   'est', NULL, TRUE, '만 0세~만 5세의 임직원 자녀를 위한 직장 어린이집 운영 (공식 채용 페이지 하나인 혜택 LIFE 직장 어린이집 지원 항목) — 정원·위치 미기재', 71),
  (@comp_id, 'child_edu', '학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀의 대학교 학자금 지원 (공식 채용 페이지 하나인 혜택 LIFE 학자금 지원 항목) — 지원 한도·자녀 수 제한 미기재', 72),
  -- ── 근무 환경 (work_env) — 공식 홈페이지 ESG 인권 및 안전보건 ──
  (@comp_id, 'lounge', '힐링라운지 운영', NULL, 'work_env',
   'est', NULL, TRUE, '임직원 신체 관리지원 세부 프로그램 힐링라운지 운영 (공식 홈페이지 ESG 인권 및 안전보건 중점 관리사항 활동 표 신체 건강 항목) — 시설 구성·위치 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
