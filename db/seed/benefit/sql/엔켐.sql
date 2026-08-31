-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 엔켐 복리후생 데이터
-- 출처: AI 파싱 (2026-08-31)
-- URL: https://www.enchem.net/home/sub.php?menukey=473
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 근거는 전부 **엔켐 공식 도메인**(enchem.net) RECRUIT > 채용정보 페이지의
--       「복리후생」 블록. 5개 소섹션(생활지원 / 포상 / 건강 / 자기계발 / 기타지원) 기준.
--       'lang' 1행만 같은 RECRUIT 섹션의 인재육성 페이지(menukey=472) 근거.
--       페이지는 금액을 일절 공개하지 않는다 — 금액이 있는 3행은 구본(2026-04)의
--       앵커 추정치를 유지한 것(금액정책 (a) → note 의 "추정" 표기로 DG-2 가 estimated 로 도출).
--       구본 6행 중 incentive/stock_option/parking 3행은 공식 근거가 없어 제외(DELETE 로 소거).
--       법정 최저기준(4대 보험·연차)은 의도적으로 제외 — 사유는 엔켐.evidence.md 참조.
--       검증 판정(2026-08-31): pension_support(법정 퇴직급여 — 코퍼스 코드 의미는 개인연금
--       지원)·lang(인재육성 커리큘럼 체리픽) 2행 제외, 유니폼·복장은 uniform 코드로 통합
--       (work_tools 는 코퍼스 전부 IT 장비 의미라 오염).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('enchem', '엔켐',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '배터리소재', 'E', 'https://www.enchem.net/home/sub.php?menukey=473');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'enchem');

-- 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본은 NULL — INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.enchem.net/home/sub.php?menukey=473'
 WHERE COMP_ID = @comp_id;

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'excellence_award', '우수사원 포상', 30, 'compensation',
   'est', '우수사원 포상 (연 30만원 추정)', FALSE, NULL, 10),
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '기념일 선물(명절) 지급', 11),
  (@comp_id, 'youth_savings', '청년내일채움공제', NULL, 'compensation',
   'est', NULL, TRUE, '청년 내일채움공제 제도 운영(정부 제도 — 현행 신규가입 가능 여부는 미확인, 페이지 기재 기준)', 12),
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사 지원', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 지원', 20),
  (@comp_id, 'lounge', '휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '휴게실(남/여) 운영', 21),
  (@comp_id, 'uniform', '유니폼·복장', NULL, 'work_env',
   'est', NULL, TRUE, '유니폼/사원증 지급, 캐쥬얼 복장 허용', 22),
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '건강검진 지원', 30),
  (@comp_id, 'fitness', '체력단련 지원', NULL, 'health',
   'est', NULL, TRUE, '체력단련 지원', 31),
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원', 40),
  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '교육비·직무교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '교육비 지원, 능력개발 지원(온·오프 사외교육), 신입사원 OJT·직무교육, 사내 멘토링 제도', 50),
  (@comp_id, 'self_development', '자기계발비 지원', 50, 'growth',
   'est', '자기계발비 지원 (연 50만원 추정)', FALSE, NULL, 51),
  (@comp_id, 'career', '해외 주재원 제도', NULL, 'growth',
   'est', NULL, TRUE, '해외 주재원 제도 운영', 52),
  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 운영(골프, 볼링, 배드민턴 등)', 60),
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '조식·중식·석식·야식 지원', 432, 'perks',
   'est', '조식/중식/석식/야식 지원 (연 432만원 환산 추정)', FALSE, NULL, 70),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 지원', 71),
  (@comp_id, 'relocation', '초기 정착금', NULL, 'perks',
   'est', NULL, TRUE, '초기 정착금 지원', 72)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
