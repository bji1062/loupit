-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 두산에너빌리티 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('doosan_enerbility', '두산에너빌리티',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '에너지/발전', 'D', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'doosan_enerbility');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'refresh_leave', '리프레시/집중 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '여름2주+연말1주 권장, 연중 리프레시 휴가, 하계 휴가비, 선진문화탐방(미국/캐나다/유럽 항공비+교통비)', 30),
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '근속년수별 포상, 35년 부부동반 해외여행, 정년퇴직 기념패+금열쇠', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '매년 전 직원+배우자 종합검진', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인/배우자/자녀 수술+제반 의료비 (추정)', FALSE, NULL, 41),
  (@comp_id, 'clinic', '사내의원', NULL, 'health',
   'est', NULL, TRUE, '의사/간호사/물리치료사/운동처방사 상주, 계절독감/신종플루 예방접종', 42),
  (@comp_id, 'mental', '심리상담센터', NULL, 'health',
   'est', NULL, TRUE, '미소담(미소를 담는 공간) 심리상담센터, 임직원+가족 스트레스 해소', 43),
  (@comp_id, 'insurance', '단체보험/저축보험', 30, 'health',
   'est', '노후대비+재해시 생활안정 (추정)', FALSE, NULL, 44),
  (@comp_id, 'fitness', '헬스장/수영장', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장/수영장/탁구장/당구장 운영', 45),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '임신/출산/육아', NULL, 'family',
   'est', NULL, TRUE, '출산축하 신생아용품, 출산휴가/육아휴직/근로시간단축/가족돌봄 휴직, 난임시술비 지원', 50),
  (@comp_id, 'childcare', '푸르니 어린이집', NULL, 'family',
   'est', NULL, TRUE, '최고수준 푸르니 어린이집, 연령별 특성화 보육프로그램', 51),
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '초등~대학 학자금, 두산 Dormitory(서울 아파트 기숙사) (추정)', FALSE, NULL, 52),
  (@comp_id, 'event', '경조사 지원', 50, 'family',
   'est', '경조휴가/경조금, 상조 장례 Total Service (추정)', FALSE, NULL, 53),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육연수', NULL, 'growth',
   'est', NULL, TRUE, '온라인스튜디오/연수원/기술교육센터, 전자도서관 15,000권+오디오북', 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도', 50, 'leisure',
   'est', '법인 콘도 객실 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회/페스티벌', NULL, 'leisure',
   'est', NULL, TRUE, '두산 페스티벌(가족문화제/체육대회), 사내 동아리 활동 지원', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'housing_loan', '주거지원', NULL, 'perks',
   'est', NULL, TRUE, '기숙사/사택, 이사비/대출이자 지원, 신용협동조합(주택구입/전세/생활안정 무이자/저금리)', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
