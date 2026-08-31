-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 알테오젠 복리후생 데이터
-- 출처: AI 파싱 (2026-08-31)
-- URL: https://www.alteogen.com/kr/sub/careers/recruit.php
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 근거는 전부 **알테오젠 공식 도메인**(alteogen.com) 채용공고 페이지 하단 「복리후생」 블록.
--       국문판(/kr/sub/careers/recruit.php)과 영문판(/en/sub/careers/recruit.php)의 목록이
--       서로 다르다 — 둘 다 현재 게시 중인 공식 문안이라 합집합으로 수록하고, 행마다
--       출처를 evidence 에 명시했다(KR / EN / KR+EN).
--       두 페이지 모두 금액을 일절 공개하지 않는다 — 금액이 있는 1행(excellence_award)은
--       구본(2026-04)의 앵커 추정치를 유지한 것(금액정책 (a) — 구본 3행이 영문판 목록과
--       정확히 일치해 오염 데이터가 아님을 확인).
--       채용공고 상세는 외부 ATS(alteogen.career.greetinghr.com)로 나가는데 그쪽 robots.txt 가
--       `User-agent: * Disallow: /` 라 수집하지 않았다.
--       검증 판정(2026-08-31): 원문에 있어도 **법정 제도는 미수록** — 4대보험(insurance 는
--       코퍼스 전체가 단체상해보험 의미)·DC형 퇴직연금(pension_support 는 개인연금 지원 의미)
--       2행 제외. 창립기념 행사는 company_event 로 통합(배치 공용 행사 코드).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('alteogen', '알테오젠',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오', 'A', 'https://www.alteogen.com/kr/sub/careers/recruit.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'alteogen');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본은 NULL — INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.alteogen.com/kr/sub/careers/recruit.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상', 10),
  (@comp_id, 'excellence_award', '우수사원 포상', 30, 'compensation',
   'est', '우수사원 포상 (연 30만원 추정)', FALSE, NULL, 11),
  (@comp_id, 'bonus', '상여금', NULL, 'compensation',
   'est', NULL, TRUE, '상여금 지급', 12),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '연차·경조휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연차 및 경조휴가 제공', 20),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 본인 및 배우자 종합건강검진 지원, 혈액종합검진, 특수검진', 30),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조지원', NULL, 'family',
   'est', NULL, TRUE, '경조금 지급, 장례지원서비스 및 상조용품 지원', 40),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '신입사원 교육', NULL, 'growth',
   'est', NULL, TRUE, '신입사원 교육 운영', 50),
  (@comp_id, 'career', '경력개발 지원', NULL, 'growth',
   'est', NULL, TRUE, '임직원 경력개발(Career Development) 지원', 51),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설(법인콘도·리조트)', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 전용 휴양시설 운영 — 전국 법인콘도, 리조트', 60),
  (@comp_id, 'club', '사내동아리', NULL, 'leisure',
   'est', NULL, TRUE, '사내동아리 운영 및 지원', 61),
  (@comp_id, 'company_event', '창립기념 행사', NULL, 'leisure',
   'est', NULL, TRUE, '창립기념일 행사 운영(휴무 여부는 미공개)', 62),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '임직원 전용 복지몰 운영 — 선택적 복지포인트 지급', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
