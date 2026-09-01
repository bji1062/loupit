-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 원익IPS 복리후생 데이터
-- 출처: AI 파싱 (2026-09-01)
-- URL: https://www.ips.co.kr/ko/careers/system.php
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 **원익아이피에스 자사 공식 도메인**(ips.co.kr).
--       주근거 = 인재채용>인사제도(system.php)의 복리후생 탭 15개 항목
--       (+ 같은 페이지 인사제도 탭의 인센티브, 인재교육 탭의 교육과정·멘토링).
--       보조근거 = 인재채용>조직문화(culture.php)의 근무·조직문화 제도.
--       ⚠ welfare.php / benefit.php 는 404 다. 복지 본문은 system.php 하나에 있다.
--       ⚠ 원익그룹 공용 채용포털(wonik.recruiter.co.kr)은 자사 도메인이 아니라
--         원익IPS 고유 복지로 귀속시킬 수 없어 근거에서 제외했다.
--       금액: 페이지가 금액을 단 한 건도 공개하지 않는다. 신규 회사라 승계할 앵커도
--       없으므로 **24행 전부 정성(QUAL_YN=TRUE, BENEFIT_AMT=NULL)** 이다.
--       ⚠ 검증 판정 반영(2026-09-01): 반증·규칙 위반 4행을 덜어내 28행 → 24행.
--         자율복장(uniform 반증)·사내 교육과정 체계·크로스 소통 3행 삭제,
--         가족친화프로그램은 company_event 행에 병합, 해외배낭여행은 travel_support 로 통일.
--       법정 제도(4대보험·법정 퇴직연금·법정 연차)는 수록하지 않았다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('wonik_ips', '원익IPS',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'W', 'https://www.ips.co.kr/ko/careers/system.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'wonik_ips');

-- 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본은 NULL — INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.ips.co.kr/ko/careers/system.php'
 WHERE COMP_ID = @comp_id;

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'excellence_award', '포상제도(공로상·경영기여상)', NULL, 'compensation',
   'est', NULL, TRUE, '분기별 공로상, 경영기여상 시상 등 포상제도 운영', 10),
  (@comp_id, 'incentive', '경영성과 성과급·프로젝트 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과(매출·이익 목표달성)에 따른 성과급 지급, 프로젝트 인센티브 지급', 11),
  (@comp_id, 'holiday_gift', '명절·기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '선물지급 제도 — 명절 선물 지급(결혼기념일 등 기념일 선물 포함)', 12),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사 운영', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 운영', 20),
  (@comp_id, 'lounge', '직원 휴게시설·사내 카페테리아', NULL, 'work_env',
   'est', NULL, TRUE, '사내 카페테리아, 직원 휴게실, 옥상하늘정원 운영', 21),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진 지원', 30),
  (@comp_id, 'insurance', '의료비 지원(단체상해·해외출장자 보험)', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 — 단체상해보험 및 해외출장자 보험', 31),
  (@comp_id, 'fitness', '사내 피트니스 시설', NULL, 'health',
   'est', NULL, TRUE, '직원휴게시설 내 피트니스 시설 운영', 32),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원 항목 중 자녀학자금', 40),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '본인 학자금', NULL, 'growth',
   'est', NULL, TRUE, '학자금 지원 항목 중 본인학자금', 50),
  (@comp_id, 'lang', '사내 외국어 교육', NULL, 'growth',
   'est', NULL, TRUE, '어학교육지원 — 사내외국어 교육', 51),
  (@comp_id, 'career', '멘토링 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '입사 후 3개월간 멘토(선배사원)-멘티(신규사원) 멘토링 프로그램 운영', 52),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영', 60),
  (@comp_id, 'resort', '휴양시설 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설 지원 — 대명, 한화, 무주, 휘닉스 등', 61),
  (@comp_id, 'massage', '안마의자', NULL, 'leisure',
   'est', NULL, TRUE, '직원휴게시설 내 안마의자 운영', 62),
  (@comp_id, 'culture_day', '문화가 있는 날', NULL, 'leisure',
   'est', NULL, TRUE, '매주 수요일 문화관람을 하는 직원에게 Flexible 근무 허용', 63),
  (@comp_id, 'company_event', '임직원 행복 이벤트', NULL, 'leisure',
   'est', NULL, TRUE, '힐링산행, 포차데이 등 조직문화 이벤트 시행. 가족친화프로그램(여행, 체험활동) 운영 및 가족 테마여행·레크리에이션 프로그램 지원', 64),
  (@comp_id, 'travel_support', '해외 배낭여행비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '해외배낭여행비 지원 — 년 3~4명 선발 후 지원', 65),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '사내식당 무상 식사', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 운영 — 조/중/석/간식 무상지급', 70),
  (@comp_id, 'transport', '교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '교통비 지원 — 직책/직무별 차등 지급', 71),
  (@comp_id, 'telecom', '통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '통신비 지원 — 직책/직무별 차등 지급', 72),
  (@comp_id, 'commute_subsidy', '통근버스/셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스/셔틀버스 운영', 73),
  (@comp_id, 'housing_support', '주거비 지원', NULL, 'perks',
   'est', NULL, TRUE, '기숙사 운영 항목의 주거비 지원', 74),
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '선물지급 제도 — 생일 선물 지급', 75)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
