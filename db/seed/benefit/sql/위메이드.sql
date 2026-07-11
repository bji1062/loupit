-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 위메이드 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 원본 txt는 '위메이드플레이' 데이터
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('wemade', '위메이드',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '게임', 'W', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'wemade');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '리프레쉬 휴가+여행비', NULL, 'time_off',
   'est', NULL, TRUE, '리프레쉬 휴가와 여행 비용 지급', 30),
  (@comp_id, 'birthday_leave', '생일/결혼기념일 조기퇴근', NULL, 'time_off',
   'est', NULL, TRUE, '생일 및 결혼기념일 강제 조기퇴근, 매월 생일파티+상품권 지급', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강검진', 100, 'health',
   'est', '(추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 41),
  (@comp_id, 'fitness', '피트니스비 지원', NULL, 'health',
   'est', NULL, TRUE, '피트니스비 지원', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산/입학 선물', NULL, 'family',
   'est', NULL, TRUE, '자녀 출산 시 축하 선물 배송, 초/중/고/대 입학 시 맞춤 선물', 50),
  (@comp_id, 'event', '경조금/경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금+경조휴가 지원, 직계 가족 조사 시 상조용품 지원', 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'conference', '컨퍼런스/세미나', NULL, 'growth',
   'est', NULL, TRUE, '국내외 컨퍼런스 및 세미나 참석, 교육비 지원', 60),
  (@comp_id, 'books', '도서 구매비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서 구매비 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도/펜션 비용 지원', 50, 'leisure',
   'est', '콘도 및 전국 펜션 비용 지원 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회/해외 플레이샵', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 지원, 전 사원 해외 플레이샵, 워크샵 지원', 71),
  (@comp_id, 'welcome_kit', '웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '신규 입사자 웰컴키트 제공', 72),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생', 200, 'perks',
   'est', '(추정)', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '사내 간식/아침 제공', 144, 'perks',
   'est', '매일 아침 빵/시리얼/과일 등 제공, 사내 간식 지원', FALSE, NULL, 81),
  (@comp_id, 'housing_loan', '주택 자금 대출 이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택 자금 대출 이자를 회사가 지원', 82),
  (@comp_id, 'holiday_gift', '명절 상품권', NULL, 'perks',
   'est', NULL, TRUE, '설날/추석 백화점 상품권 지급', 83),
  (@comp_id, 'discount', '사내 게임 쿠폰', NULL, 'perks',
   'est', NULL, TRUE, '사내 게임 쿠폰 매달 지급', 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
