-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한미반도체 복리후생 데이터
-- 출처: AI 파싱 (2026-09-28)
-- URL: https://www.hanmisemi.com/index.php?module=Html&action=SiteComp&sSubNo=16
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 한미반도체 공식 홈페이지 인재채용 > 복리후생 (www.hanmisemi.com, 법인 자기 도메인 · GNB 인재채용 첫 메뉴).
--     서버 렌더 PHP 본문에 카드 7개 · 2박스(기숙사 · 포상제도 운용) · 경조사 제도 · 휴가 제도 및 기타가 들어 있다(헤드리스 불필요).
--     HTML 주석 속 옛 블록(복지신용카드 · 기숙사 월세 · 특별 휴가 · 학자금 · 사내 식사 · 포상제도 · 안마의자 한 줄)은 쓰지 않았다.
--     robots.txt = User-agent: * / Allow:/ (2026-09-28 확인). 본문 sha256 e4aa4eed…a36d7c1 (세션 쿠키는 헤더에만 있다).
--   보조 = 같은 도메인 ESG > Society 사회적 책임 (sSubNo=11) 의 임직원 만족 향상 3줄 — 기숙사 · 자녀 학비 · 아난티 리조트를 교차 확인.
--   채용정보 (sSubNo=17) 에는 복지 항목이 없다. 계열 그룹 채용 사이트는 없고 법인 자기 페이지라 각주 없음.
--   법정 제도: 원문에 법정 제도 문구가 없다. 추가 휴가 5일은 원문이 기본 법정 휴가 외 상회분이라 밝혀 수록.
--   금액: 원문 연액 2(welfare_point 연간 160만원 · child_edu 대학교 연간 600만원) · 구본 추정 승계 2(health_check 100 · resort 50) ·
--     미승계(excellence_award 50 1회성 · event 50 경조금 · books 20 전제 없음 · child_edu 200 원문값으로 교체 · refresh_leave 100 은 복지포인트 행으로 이동).
--   재코딩 3: fertility_support → parenting · holiday_gift → birthday_gift · long_service_bonus → long_service_leave. 신규 코드 0.
-- 재수집(2026-09-28): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-09-28, RV-3 레인 5): 조치 없음 — 복지포인트 160 한 행 · resort 50 · health_check 100 추정 승계 · 재코딩 3 유지 — 최종 18행

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanmi_semi', '한미반도체',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'H', 'https://www.hanmisemi.com/index.php?module=Html&action=SiteComp&sSubNo=16');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanmi_semi');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hanmisemi.com/index.php?module=Html&action=SiteComp&sSubNo=16'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 여가·라이프 (leisure) ── 카드 1 · 경조사 제도 4줄째
  (@comp_id, 'resort', '아난티 리조트 멤버십', 50, 'leisure',
   'est', '럭셔리 호텔·리조트 아난티 멤버십으로 아난티 리조트 연간 3박 무료 제공 (추정)', FALSE, NULL, 10),
  (@comp_id, 'welcome_kit', '입사 축하 선물', NULL, 'leisure',
   'est', NULL, TRUE, '입사 축하 선물 지급 (공식 복리후생 페이지 경조사 제도 항목)', 11),

  -- ── 경제적 부가혜택 (perks) ── 카드 2 · 카드 4 · 경조사 제도 3줄째
  (@comp_id, 'welfare_point', '복지포인트 (신한 제휴 복지카드)', 160, 'perks',
   'est', '한미반도체 신한 제휴카드로 연간 160만원 복지포인트 제공 — 설날·가정의 달·추석 각 20만원과 휴가비 지원 100만원', FALSE, NULL, 20),
  (@comp_id, 'meal', '중식·석식 무료 제공', NULL, 'perks',
   'est', NULL, TRUE, '삼성웰스토리 푸드 서비스로 중식·석식 무료 제공', 21),
  (@comp_id, 'birthday_gift', '생일 상품권', NULL, 'perks',
   'est', NULL, TRUE, '생일 상품권 지급 (공식 복리후생 페이지 경조사 제도 항목)', 22),

  -- ── 건강·의료 (health) ── 카드 3 · 휴가 제도 및 기타
  (@comp_id, 'health_check', '가천대 길병원 VIP 종합건강검진', 100, 'health',
   'est', '가천대 길병원 100만원 상당 VIP 종합검진 제공, 직계가족 50% 지원 — 검진 주기 미기재 (추정)', FALSE, NULL, 30),
  (@comp_id, 'fitness', '풋살장·농구장', NULL, 'health',
   'est', NULL, TRUE, '풋살장·농구장 운영', 31),

  -- ── 근무환경 (work_env) ── 카드 5·6 · 기숙사 박스 · 휴가 제도 및 기타
  (@comp_id, 'office_furniture', '모션 데스크·사무용 안마의자', NULL, 'work_env',
   'est', NULL, TRUE, '140만원 상당 퍼시스 모션 데스크와 110만원 상당 풀리오 사무용 안마의자(풀리오 웰워크) 제공', 40),
  (@comp_id, 'dormitory', '1인 1실 기숙사 무료 제공', NULL, 'work_env',
   'est', NULL, TRUE, '풀옵션을 갖춘 1인 1실 기숙사 무료 제공, 회사와 도보 약 2분 거리(주안 제이타워 2차)', 41),
  (@comp_id, 'parking', '주차장 제공', NULL, 'work_env',
   'est', NULL, TRUE, '주차장 제공', 42),

  -- ── 가족·돌봄 (family) ── 카드 7 · 경조사 제도
  (@comp_id, 'child_edu', '자녀 학자금 지원', 600, 'family',
   'est', '자녀 대학교 연간 600만원, 고등학교 연간 300만원 학자금 지원 (대학교 기준)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조사 제도 (결혼·장례)', NULL, 'family',
   'est', NULL, TRUE, '결혼 축하금 지급, 장례 조의금 지급과 상조서비스 예다함 제공', 51),
  (@comp_id, 'parenting', '출산 상품권', NULL, 'family',
   'est', NULL, TRUE, '출산 상품권 지급 (공식 복리후생 페이지 경조사 제도 항목)', 52),

  -- ── 보상·금전 (compensation) ── 포상제도 운용 박스
  (@comp_id, 'excellence_award', '포상제도 (발전공로·특허출원·제안)', NULL, 'compensation',
   'est', NULL, TRUE, '발전공로 상금 500만원과 상패, 특허출원 상금 최대 200만원과 상패, 제안 상금 최대 100만원과 상패 지급', 60),

  -- ── 시간·휴가 (time_off) ── 포상제도 운용 박스 · 휴가 제도 및 기타
  (@comp_id, 'long_service_leave', '장기근속 포상 (상품권·포상휴가)', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자에게 상품권 200만원과 포상휴가 지급', 70),
  (@comp_id, 'refresh_leave', '추가 휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '기본 법정 휴가 외 추가 휴가 5일 제공', 71),

  -- ── 성장·커리어 (growth) ── 포상제도 운용 박스 · 휴가 제도 및 기타
  (@comp_id, 'retirement_support', '정년퇴직 격려금', NULL, 'growth',
   'est', NULL, TRUE, '정년퇴직자에게 격려금 1,000만원과 상패 지급', 80),
  (@comp_id, 'books', '도서 구매비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서 구매비 지원', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
