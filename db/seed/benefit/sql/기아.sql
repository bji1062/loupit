-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 기아 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 주의: 원본 txt 내용은 "전기아이피" (게임IP사) — 기아자동차 데이터 부재
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kia', '기아',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '자동차', 'K', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kia');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 주 2~3일 (팀별 상이), 원격근무 가능', 10),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상제도', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 60, 'health',
   'est', '60만원 이내(부모/배우자 가능)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '(추정)', FALSE, NULL, 41),
  (@comp_id, 'fitness', '스포츠센터', NULL, 'health',
   'est', NULL, TRUE, '이용률 60% 이상시 무료 지원', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀학자금/입학축하금', 200, 'family',
   'est', '학자금 지원 + 입학 축하금 (추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조사/명절', 70, 'family',
   'est', '경조금/경조휴가/상조서비스/화환, 명절 신세계상품권 20만원 (추정)', FALSE, NULL, 51),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설', 50, 'leisure',
   'est', '대명리조트 지원 (추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '연간 200만원 페이코 (사용처 제한 없음, 소득공제)', FALSE, NULL, 80),
  (@comp_id, 'meal', '식사 지원', 312, 'perks',
   'est', '아침/점심(월26만 페이코), 야근시 석식 13,000원', FALSE, NULL, 81),
  (@comp_id, 'snack_bar', '사내 카페', 50, 'perks',
   'est', '다양한 음료 무제한 무료, 탕비실 별도 (추정)', FALSE, NULL, 82),
  (@comp_id, 'commute_subsidy', '야근 교통비', 30, 'perks',
   'est', '23시~07시 택시 교통비 지원 (추정)', FALSE, NULL, 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
