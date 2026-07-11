-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 아이패밀리에스씨 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ifamilysc', '아이패밀리에스씨',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '화장품', 'I', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ifamilysc');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '오전 8~10시 자율 출근', 10),
  (@comp_id, 'remote_work', '주 1회 재택근무 (금요일)', NULL, 'flexibility',
   'est', NULL, TRUE, '매주 금요일 재택근무', 11),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'birthday_leave', '생일 선물+조기퇴근', NULL, 'time_off',
   'est', NULL, TRUE, '생일 선물 지급 및 조기 퇴근', 30),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조금/명절 상품권', NULL, 'family',
   'est', NULL, TRUE, '각종 경조금 지원, 명절 상품권 지급', 50),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'self_development', '자기계발 지원금', NULL, 'growth',
   'est', NULL, TRUE, '자기계발 지원금 지원', 60),
  (@comp_id, 'books', '도서 구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서 구입비 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '법인 리조트/여기어때', 50, 'leisure',
   'est', '임직원 전용 법인 리조트, 여기어때 할인가 지원 (추정)', FALSE, NULL, 70),
  (@comp_id, 'welcome_kit', '웰컴키트 (롬앤/누즈)', NULL, 'leisure',
   'est', NULL, TRUE, '신규 입사자 웰컴키트 (롬앤/누즈 상품)', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'snack_bar', '사내 카페 (월 3만원 포인트)', 36, 'perks',
   'est', '월 3만원 카페 포인트 x 12개월', FALSE, NULL, 80),
  (@comp_id, 'housing_loan', '무이자 사내대출 (최대 5천만원)', NULL, 'perks',
   'est', NULL, TRUE, '무이자 사내 대출 최대 5천만원 지원', 81),
  (@comp_id, 'discount', '자사 제품 직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '자사 제품 직원 할인가 지원', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
