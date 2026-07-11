-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CJ 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 원본 txt 내용은 CJ올리브네트웍스 (CJ 계열사)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('cj', 'CJ올리브네트웍스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품/유통/엔터', 'C', NULL);

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj');

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '주 2일 이상 재택근무 지향', 10),
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '탄력적/선택적 근무시간제, 시차출퇴근제, CJ Work On 공유오피스(전국)', 11),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', 'CREATIVE WEEK', NULL, 'time_off',
   'est', NULL, TRUE, '근속 3/5/7/10년 이상 2주 유급휴가, 10년 이후 5년마다 갱신', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '건강검진 지원', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '의료비 지원 (추정)', FALSE, NULL, 41),
  (@comp_id, 'mental', '심리상담', NULL, 'health',
   'est', NULL, TRUE, '상담포유 심리상담서비스', 42),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '임신/출산/육아', NULL, 'family',
   'est', NULL, TRUE, '임신축하선물/택시쿠폰, 태아검진휴가, 출산선물, 초등입학 돌봄휴가 최대4주, 난임시술비, 장애자녀 양육비', 50),
  (@comp_id, 'childcare', 'CJ키즈빌', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 CJ키즈빌 운영', 51),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '실비 지원 (추정)', FALSE, NULL, 52),
  (@comp_id, 'event', '경조사/생일', 50, 'family',
   'est', '웨딩/상조 지원, 생일쿠폰 (추정)', FALSE, NULL, 53),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'books', '전자도서관', NULL, 'growth',
   'est', NULL, TRUE, 'E-Book 서비스 제공', 60),
  (@comp_id, 'lang', '외국어 검정비', NULL, 'growth',
   'est', NULL, TRUE, '외국어 검정비용 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '숙박 지원', 50, 'leisure',
   'est', '전국 콘도/호텔/리조트 제휴, 해외여행/제주렌터카 지원 (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 지원, 전사 체전 ON Match', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '카페테리아 포인트', 100, 'perks',
   'est', '연간 1,000p(100만원), 문화/예술공연 특가', FALSE, NULL, 80),
  (@comp_id, 'discount', 'CJ 계열사 할인', NULL, 'perks',
   'est', NULL, TRUE, 'CJ계열사 40% 할인(뚜레쥬르/VIPS/올리브영/CGV 등), CJ Mall 특별할인, N타워, 나인브릿지', 81),
  (@comp_id, 'housing_loan', '주택자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 무이자 2천만원, 비연고지 주택/부임비/이사비 지원', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
