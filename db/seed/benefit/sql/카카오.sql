-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 카카오 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kakao', '카카오',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        'IT/플랫폼', 'K', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '자율 출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연하고 탄력적인 근무시간, 월 1회 금요일 휴무, 매주 금요일 1시간 30분 조기 퇴근', 10),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '본인 지원, 가족 할인, 유급휴가 지원 (추정)', FALSE, NULL, 40),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '직원 및 가족 단체상해보험 (추정)', FALSE, NULL, 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산/육아 지원', NULL, 'family',
   'est', NULL, TRUE, '출산 선물, 배우자 유사산 휴가, 임신기간/육아기 단축근무', 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼/환갑/출산/조사 경조휴가, 경조금, 경조화환, 장례용품 지원', 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '입문교육, 직책자 리더십, 직무역량, 공통역량, 법정의무교육', 60),
  (@comp_id, 'self_development', '자기계발비', NULL, 'growth',
   'est', NULL, TRUE, '자기계발비 지원, 도서 구입 지원', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '전용 휴양시설', 50, 'leisure',
   'est', '(추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '동호회 활동', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 지원(등산, 골프, 필라테스 등)', 71),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 140, 'perks',
   'est', '총 140만원(연 2회) 복지포인트 지급, 카카오 공동체 카드', FALSE, NULL, 80),
  (@comp_id, 'meal', '식대 지원', 240, 'perks',
   'est', '월 20만원 식대 지원', FALSE, NULL, 81),
  (@comp_id, 'commute_subsidy', '통근버스/순환버스', 120, 'perks',
   'est', '통근버스 및 판교역 순환버스, 야근시 카카오T 업무택시 (추정)', FALSE, NULL, 82),
  (@comp_id, 'work_tools', '최신 업무장비', NULL, 'perks',
   'est', NULL, TRUE, '최신/최고급 맥북, 전동 스탠딩 데스크, 허먼밀러 의자', 83),
  (@comp_id, 'snack_bar', '사내 카페/스낵바', 144, 'perks',
   'est', 'kafe(커피/논커피/티/에이드), 무인 스낵바(전 제품 50% 할인) (추정)', FALSE, NULL, 84),
  (@comp_id, 'discount', '카카오프렌즈 할인', NULL, 'perks',
   'est', NULL, TRUE, '카카오프렌즈 골프샵 최대 30% 할인, 직영 아카데미 최대 20% 할인, 전자제품(Apple/LG/삼성) 할인', 85),
  (@comp_id, 'holiday_gift', '명절 귀향비/생일선물', 15, 'perks',
   'est', '명절 귀향비 10만원, 생일선물 5만원(카카오톡 선물하기)', FALSE, NULL, 86)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
