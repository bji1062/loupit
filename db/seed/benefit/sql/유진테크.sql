-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 유진테크 복리후생 데이터
-- 출처: AI 파싱 (2026-08-31)
-- URL: http://www.eugenetech.co.kr/recruit/page/sub04-4.php
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 근거는 전부 **유진테크 공식 도메인**(eugenetech.co.kr) 채용사이트.
--       주근거 = 인사제도>복리후생(sub04-4.php) 10개 항목. 보조근거 2건은
--       같은 채용사이트의 인사제도(sub04-2.php)·교육제도(sub04-3.php).
--       ⚠ URL 이 https 가 아니라 **http** 인 이유: 이 서버는 TLS1.2 + DHE 만 지원하고
--         ECDHE/TLS1.3 을 제공하지 않는다(인증서 자체는 LetsEncrypt 정상). 크롬은
--         2017년에 DHE 스위트를 전부 제거해서 https 로는 브라우저 접속이 실패한다.
--         http 는 200 으로 동일 내용을 주고, 사이트 자신의 og:url 도 http 다.
--       ⚠ 복리후생 페이지의 4개 블록(건강검진·사내 체력단련실·4대보험·상조회)은
--         HTML 주석 <!-- --> 안에 있어 **렌더링되지 않는다** → 회사가 스스로 내린
--         항목이라 수집하지 않았다.
--       금액은 복지포인트 1건만 페이지에 명시(연 120만원). 학자금·식사 2건은
--       구본(2026-04)의 앵커 추정치를 유지한 것(금액정책 (a)).
--       구본 incentive 의 100만원 앵커는 **승계하지 않았다** — 새 출처의
--       "최대 600% 특별 성과급"과 자릿수가 어긋나 오염으로 판단(evidence 참조).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('eugenetech', '유진테크',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'Y', 'http://www.eugenetech.co.kr/recruit/page/sub04-4.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'eugenetech');

-- 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본은 NULL — INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'http://www.eugenetech.co.kr/recruit/page/sub04-4.php'
 WHERE COMP_ID = @comp_id;

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '특별 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과에 따라 최대 600%의 특별 성과급 지급(매년 경영 성과에 따른 Profit Sharing)', 10),
  (@comp_id, 'excellence_award', '우수사원 표창/포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 표창/포상제도 운영', 11),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사 무상 제공', NULL, 'work_env',
   'est', NULL, TRUE, '임직원 주거권 보장을 위해 기숙사 무상 제공', 20),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'insurance', '단체 상해 의료보험', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 그 가족 대상 단체 상해보험 가입 — 의료비 부담 경감', 30),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', 200, 'family',
   'est', '임직원 자녀 중 고교·대학생 자녀에게 학자금 지원 (연 200만원 추정)', FALSE, NULL, 40),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 발생 시 경조휴가·경조금 등 지원', 41),
  (@comp_id, 'birthday_gift', '결혼기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '결혼기념일 축하 꽃바구니 지급(기념일 선물 — 삼성카드 birthday_gift 선례)', 42),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '사외·사이버 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무 맞춤형 사외교육, Cyber/독서통신 교육, 집체 교육 운영', 50),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설 이용지원', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 휴식을 위한 휴양시설 이용 지원', 60),
  (@comp_id, 'company_event', '사내 행사', NULL, 'leisure',
   'est', NULL, TRUE, '정기 야유회, 체육대회, 송년회 등 사내 행사 운영', 61),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', 120, 'perks',
   'est', '현금처럼 사용할 수 있는 복지포인트 연 120만원 지원 (페이지 명시)', FALSE, NULL, 70),
  (@comp_id, 'meal', '사내 식당 3끼 무상 제공', 432, 'perks',
   'est', '사내 식당에서 3끼 무상 제공 (연 432만원 환산 추정)', FALSE, NULL, 71)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
