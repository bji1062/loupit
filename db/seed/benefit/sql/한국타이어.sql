-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한국타이어앤테크놀로지 복리후생 데이터
-- 출처: AI 파싱 (2026-09-01)
-- URL: https://hankooktire.recruiter.co.kr/career/benefits
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 한국타이어앤테크놀로지 공식 자산 3개.
--       (C) hankooktire.recruiter.co.kr/career/benefits — 전용 복리후생 페이지.
--           Next.js CSR 이라 Playwright 헤드리스 렌더로 본문 확보. 15개 항목이
--           아이콘+제목+설명 카드로, 이어서 사업장 시설 사진 캡션 9개가 붙는다.
--           ATS 벤더 도메인이지만 공식 홈 hankooktire.com 이 이 사이트를 링크한다
--           (A·B 두 페이지 모두 hankooktire.recruiter.co.kr/appsite/company/index 링크 보유).
--       (A) www.hankooktire.com/global/ko/esg/responsible-engagement.html — 임직원 Care.
--       (B) www.hankooktire.com/global/ko/career/proactive-culture.html — Proactive Work & Life Balance.
--       ⚠ A·B 는 기본 UA 로 403 (WAF). 브라우저 UA 필요. AEM 서버 렌더라 JS 는 불필요.
--       ⚠ 지주사 한국앤컴퍼니(hankookandcompany.com)와 별개 법인 — 혼동 금지.
--       ⚠ career/proactive-hr.html 의 「복리후생」 3건은 HR 직무기술서 오탐이라 미사용.
-- 금액: 페이지가 연간 금액을 일절 명시하지 않는다. 신규 회사라 앵커도 없다
--       → 전 행 BENEFIT_AMT NULL + QUAL_YN TRUE (금액정책 명시값만, stated 0건).
--       타이어 90% 할인은 할인율이라 연간 만원 환산 근거가 아니므로 금액 없음.
-- 미수록: 육아기 근로시간 단축제도(A 에 명시되나 남녀고용평등법 제19조의2 법정제도라
--       회사 재량 상회분 아님) · Family Day(B 의 뉴스 카드라 제도 근거 아님).
-- 신규 코드: car_wash (정식 어휘에 세차 서비스에 대응하는 코드가 없음).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hankook_tire', '한국타이어앤테크놀로지',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '타이어', 'H', 'https://hankooktire.recruiter.co.kr/career/benefits');

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hankook_tire');

-- 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://hankooktire.recruiter.co.kr/career/benefits'
 WHERE COMP_ID = @comp_id;

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 유연근무 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 유연근무제도', NULL, 'flexibility',
   'est', NULL, TRUE, '임직원이 근로 시간을 탄력적으로 조정할 수 있는 선택적 유연근무제도 시행', 10),
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', 'Residence 사택', NULL, 'work_env',
   'est', NULL, TRUE, '대전/금산 근무자 대상 멀티플렉스형 레지던스(Residence) 지원', 20),
  (@comp_id, 'lounge', '사내 라운지', NULL, 'work_env',
   'est', NULL, TRUE, '사업장 시설 Proactive Lounge, Play Lounge 운영', 21),
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강검진', NULL, 'health',
   'est', NULL, TRUE, '종합검진 지원', 30),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원(건강검진 항목과 함께 안내)', 31),
  (@comp_id, 'clinic', '사내 건강관리실', NULL, 'health',
   'est', NULL, TRUE, '사내 건강관리실 운영(한의원 포함), 사내 웰니스 센터 운영', 32),
  (@comp_id, 'mental', '심리 상담실', NULL, 'health',
   'est', NULL, TRUE, '사내 건강관리실 내 심리 상담실 운영', 33),
  (@comp_id, 'fitness', '피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '사내 피트니스 센터(Fitness Center) 운영', 34),
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집 H-KIDZ', NULL, 'family',
   'est', NULL, TRUE, '본사·연구소·공장 등 주요 사업장마다 사내 어린이집 H-KIDZ 직접 운영(연령별 커리큘럼, 유기농 식단). 정부 지원금을 제외한 운영비 전액을 회사가 부담해 임직원은 무료 이용', 40),
  (@comp_id, 'child_edu', '유치원 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '외부 어린이집·유치원에 다니는 자녀를 둔 직원에게 유치원 학자금 일부 지원', 41),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼·출산·장례 등 경조사에 휴가 및 경조비 지원', 42),
  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'edu_support', '사내/사외 교육', NULL, 'growth',
   'est', NULL, TRUE, '리더십·직무·디지털 등 사내/사외 교육 지원', 50),
  (@comp_id, 'lang', '외국어 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '외국어 교육 지원(사내/사외 교육 프로그램)', 51),
  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회 CoP', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회(CoP) 활동비 매달 지원', 60),
  (@comp_id, 'resort', '콘도/연수원', NULL, 'leisure',
   'est', NULL, TRUE, '호텔·리조트 제휴 및 연수원 제공', 61),
  (@comp_id, 'welcome_kit', 'Welcome Kit', NULL, 'leisure',
   'est', NULL, TRUE, 'Welcome Message/Kit 지급', 62),
  (@comp_id, 'library', '사내 도서공간 The Library', NULL, 'leisure',
   'est', NULL, TRUE, '사업장 시설 The Library 운영', 63),
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '사내식당 식사 제공', NULL, 'perks',
   'est', NULL, TRUE, '사내식당에서 조식·중식·석식 제공(일부 사업장은 조식·중식 제공)', 70),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '사업장별 다양한 셔틀 노선 운영', 71),
  (@comp_id, 'welfare_point', '복지포인트/복지카드', NULL, 'perks',
   'est', NULL, TRUE, '현금처럼 사용 가능한 복지포인트/복지카드 지급', 72),
  (@comp_id, 'discount', '자사 타이어 할인', NULL, 'perks',
   'est', NULL, TRUE, '자사 타이어 제품 90% 할인', 73),
  (@comp_id, 'car_wash', '세차 서비스', NULL, 'perks',
   'est', NULL, TRUE, '차량 내/외부 세차 서비스 지원(사업장 시설 동그라미 세차장)', 74)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
