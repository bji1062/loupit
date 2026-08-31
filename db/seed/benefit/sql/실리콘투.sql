-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 실리콘투 복리후생 데이터
-- 출처: AI 파싱 (2026-08-31)
-- URL: https://www.siliconii.com/sub/sub04_02.php
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 근거는 전부 **실리콘투 공식 도메인**(siliconii.com) 채용>Benefit 페이지의
--       「복리후생」 섹션 24개 항목. robots.txt = `User-agent: * / Allow:/` (전면 허용).
--       페이지는 금액을 단 한 곳(임직원 추천 채용 포상 100만원)만 명시하며 그마저
--       연간 정기 지급이 아니라 1회성 포상이라 BENEFIT_AMT 에 넣지 않았다
--       (연간 환산 불가 — QUAL_DESC 에 원문 그대로 기재).
--       health_check 의 100 은 구본(2026-04-15)의 앵커 추정치를 유지한 것
--       (금액정책 (a) — 서술·출처는 새 페이지, 금액은 기존 앵커 보존 →
--        note 의 "추정" 표기로 DG-2 가 estimated 로 도출).
--       제외 4건(4대 보험 · 퇴직연금(DC) · 판교 위치 · 휴가비)의 사유는 evidence 참조.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('silicon2', '실리콘투',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '화장품유통', 'S', 'https://www.siliconii.com/sub/sub04_02.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'silicon2');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본은 NULL — INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.siliconii.com/sub/sub04_02.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 지급', 1),
  (@comp_id, 'holiday_gift', '명절 상여', NULL, 'compensation',
   'est', NULL, TRUE, '명절 상여 지급', 2),
  (@comp_id, 'excellence_award', '임직원 추천 채용 포상', NULL, 'compensation',
   'est', NULL, TRUE, '사내 임직원 추천 채용 지원 — 피추천자 6개월 근무 시 100만원 포상(1회성, 연간 정기 지급 아님)', 3),

  -- ── 유연근무 (flexibility) ──
  (@comp_id, 'flex_work', '자율 출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '8시~10시 자율 출퇴근제', 10),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'lounge', '휴게 공간', NULL, 'work_env',
   'est', NULL, TRUE, '휴게 공간 운영(사내 카페, 안마의자)', 20),
  (@comp_id, 'uniform', '유니폼 제공', NULL, 'work_env',
   'est', NULL, TRUE, '유니폼 제공(여름용ㆍ겨울용)', 21),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '연차/반차/반반차', NULL, 'time_off',
   'est', NULL, TRUE, '연차, 반차, 반반차 사용', 30),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 지원', 100, 'health',
   'est', '건강검진 지원 (연 100만원 추정)', FALSE, NULL, 40),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원', 50),
  (@comp_id, 'parenting', '출산휴가/육아휴직', NULL, 'family',
   'est', NULL, TRUE, '출산 휴가, 육아 휴직 제도', 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '직무 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무 교육비 지원(자기계발 및 도서 구입비 지원)', 60),
  (@comp_id, 'books', '도서 구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서 구입비 지원(직무 교육비 지원에 포함)', 61),
  (@comp_id, 'career', '해외 지사 근무', NULL, 'growth',
   'est', NULL, TRUE, '해외 지사 근무 가능(미국, 유럽, 중동, 동남아 등 해외법인 순환 근무 가능)', 62),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도 회원권', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 회원권 제공(소노 호텔 회원가 이용)', 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '주 5회 점심 제공', NULL, 'perks',
   'est', NULL, TRUE, '주 5회 점심 제공', 80),
  (@comp_id, 'snack_bar', '사내 카페테리아/음료·간식', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페테리아 운영, 음료 및 간식 무료 제공', 81),
  (@comp_id, 'team_dinner', '팀 회식비 지원', NULL, 'perks',
   'est', NULL, TRUE, '팀 회식비 지원', 82),
  (@comp_id, 'discount', '임직원 할인(자사몰·제휴)', NULL, 'perks',
   'est', NULL, TRUE, '자사 쇼핑몰 제품 할인, 외부 제휴 복지 서비스 제공(LG전자 복지몰, 병원, 호텔 등), 외부 제휴 식음료 할인 제공(음식점, 카페)', 83),
  (@comp_id, 'parking', '차량 지원', NULL, 'perks',
   'est', NULL, TRUE, '차량 지원(법인차량 및 주차비 지원)', 84),
  (@comp_id, 'visa_support', '비자 발급 지원', NULL, 'perks',
   'est', NULL, TRUE, '비자 발급 지원', 85)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
