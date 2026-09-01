-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LS ELECTRIC 복리후생 데이터
-- 출처: AI 파싱 (2026-09-01)
-- URL: https://www.ls-electric.com/ko/recruit/intro
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 LS ELECTRIC 공식 도메인(ls-electric.com) 채용소개 페이지의
--       복리후생 블록 7개 항목. 같은 URL 에 탭 5개(WHY LS ELECTRIC / 인재상 /
--       인사운영방식 / 복리후생 / 인재육성)가 한 문서로 서버 렌더되므로,
--       HTML 주석 쌍으로 감싸인 복리후생 블록만 잘라 파싱했다(인재상·인재육성 혼입 차단).
--       LS그룹 공통 페이지(lsholdings.com)는 계열사별 차이가 있을 수 있음을 스스로
--       명시하므로 회사 귀속 근거로 미사용. 채용 ATS(recruiter.co.kr)도 미사용.
--       + 같은 문서 인사운영방식 탭의 성과급 제도(경영성과급 PS·개별성과급 PI) 1행.
--       페이지가 금액·일수를 일절 공개하지 않아 12행 전부 정성행(QUAL_YN TRUE, 금액 NULL).
--       7개 항목 중 4개가 서로 다른 축을 한 문장에 묶고 있어 코드 단위로 분리했다:
--       주택지원=주택자금+기숙사/사택, 건강진단/의료비=검진+가족의료비,
--       경조사=경조금/화환+경조휴가, 장기근속상=포상금/여행+휴가.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ls_electric', 'LS ELECTRIC',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '전력기기', 'L', 'https://www.ls-electric.com/ko/recruit/intro');

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ls_electric');

-- 기존 행이 있을 경우 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.ls-electric.com/ko/recruit/intro'
 WHERE COMP_ID = @comp_id;

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속상 — 장기근속에 따른 여행 혹은 포상금 지원', 10),
  (@comp_id, 'incentive', '경영성과급(PS)·개별성과급(PI)', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과급(PS) — 조직 실적에 따른 성과급 지급. 개별성과급(PI) — 성과가 뛰어난 사원에게 별도의 인센티브 지급', 11),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사/사택', NULL, 'work_env',
   'est', NULL, TRUE, '주택지원 제도 — 지방사업장 근무 시 기숙사 또는 사택 제공', 20),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속상 — 장기근속에 따른 휴가 지원', 30),
  (@comp_id, 'leave_general', '경조휴가', NULL, 'time_off',
   'est', NULL, TRUE, '경조사 지원 — 각종 경조사별 경조휴가 지원', 31),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강진단', NULL, 'health',
   'est', NULL, TRUE, '건강진단/의료비지원 — 임직원 및 배우자 종합검진 지원', 40),
  (@comp_id, 'medical', '가족 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '건강진단/의료비지원 — 가족 의료비 지원', 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사별 경조금 및 화환 지원', 50),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '중학교·고등학교·전문대학·대학교 취학자녀 학자금 지원', 51),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 여가생활을 위한 휴양시설 운영', 60),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'housing_loan', '주택자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택지원 제도 — 주택마련 자금 및 전세 자금 지원', 70),
  (@comp_id, 'welfare_point', '사원복지카드', NULL, 'perks',
   'est', NULL, TRUE, '기념일(생일 혹은 결혼기념일) 및 명절(설/추석) 맞이 복지포인트 지급', 71)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
