-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 엘앤에프 복리후생 데이터
-- 출처: AI 파싱 (2026-10-05)
-- URL: https://landf.recruiter.co.kr/career/culture
-- badge: est
--
-- 참고:
--   정본은 엘앤에프 새 채용 사이트(마이다스 ATS landf.recruiter.co.kr)의 복리후생 제도 소개 페이지다. 옛 채용 사이트
--     https://recruit.landf.co.kr/info/bok_01.html 은 2026-10-05 주간 점검에서 content_lost — 응답이 새 사이트로 보내는 JS 한 줄뿐(채용 사이트 이전).
--   새 페이지 본문은 JS 렌더라 사용자가 2026-10-05 브라우저로 열어 붙여 넣은 화면 본문을 썼다
--     (사본 loupit-evidence/2026-10-05-hold-recollect/landf/user_paste_ats_benefit_2026-10-05.txt · sha256 349ccae9…1b56). 5구역 15항목.
--   페이지 주소 = 새 사이트 /career/culture(사용자 확인 2026-10-05). robots 일반 페이지 허용(리드 확인) · 본문은 JS 렌더.
--   금액: 원문 고정 금액 합산 1(holiday_gift 설 · 추석 각 50만원 → 100) · 1포인트 1원 환산 1(welfare_point 연간 100만 포인트 → 100).
--     자녀 학자금 200만원 · 종합건강검진 30만원은 한도라 금액 칸에 넣지 않았다.
--   업무 교육(직무 역량 강화를 위한 사내 교육 프로그램)은 넣지 않았다. 법정 제도 문구 없음. 귀속: 법인 단독 채용 사이트 — 그룹 각주 없음.
--   SORT 섹션 번호는 웨이브 1 그대로 두고 새 카테고리 growth 를 90 으로 붙였다(뺀 행 자리는 비워 둠).
--   구본에서 뺀 행 11: long_service_bonus · long_service_leave · foundation_day_leave · leave_general(연중휴가 3일) · refresh_leave ·
--     remote_work · medical(제휴병원) · lounge(공장 편의시설) · resort · club · commute_subsidy — 새 채용 사이트 복리후생 제도 소개에 없음
--     (옛 사이트 recruit.landf.co.kr 은 2026-10 새 사이트로 이동 · 사용자 결정 2026-10-05 빼기). holiday_gift 의 옛 근로자의날 · 명절 선물 구절도 걷었다.
-- 웨이브 1(2026-09-01): 옛 채용 사이트 4페이지(bok_01 일과 삶의 행복 · bok_02 생활안정 지원 · bok_03 건강증진 지원 · bok_04 회사생활 영위) 14항목으로 신규 등록 20행
-- 후속 정리 5(2026-10-05, 보류 · 붙여넣기): 채용 사이트 이전에 따라 새 복리후생 본문으로 다시 세움 — 갱신 9 · 새 행 4(excellence_award · welfare_point · discount · edu_support) · 구본에서 뺀 행 11 — 최종 13행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2026-10-06 식대 기준 금액 1끼 12,000원(리드 판정 (82)) — meal 행 금액 = 1끼 단가 × 끼니 × 연 240일, 꼬리에 식 공개

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('landf', '엘앤에프',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '2차전지소재', 'L', 'https://landf.recruiter.co.kr/career/culture');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'landf');

-- 3) 출처 URL 갱신 (INSERT IGNORE 는 기존 행을 갱신하지 않는다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://landf.recruiter.co.kr/career/culture'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ── Family 명절 상여금 · Growth & Refresh 우수사원 포상 제도
  (@comp_id, 'holiday_gift', '명절 상여금', 100, 'compensation',
   'est', '설과 추석에 각각 50만원 상당의 상여금(현금) 지급 (공식 채용 사이트 복리후생 제도 소개 명절 상여금 항목)', FALSE, NULL, 11),
  (@comp_id, 'excellence_award', '우수사원 포상 제도', NULL, 'compensation',
   'est', NULL, TRUE, '매년 우수한 성과를 달성한 임직원에게 CEO 명의로 포상 및 포상금 지급 (공식 채용 사이트 복리후생 제도 소개 우수사원 포상 제도 항목) — 포상금 금액·선정 인원 미기재', 12),

  -- ── 근무 유연성 (flexibility) ── Work & Life Balance
  (@comp_id, 'flex_work', '선택적 근로시간제·주 4.5일제·4조 2교대', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로시간제로 월간 근무시간을 자율 관리, 사무/연구직 대상 주 4.5일 근무제, 제조기술직 4조 2교대 근무제로 교대조 근무 부담 경감과 충분한 휴식 여건 보장 (공식 채용 사이트 복리후생 제도 소개 유연근무제 운영 · 주 4.5일제 운영 · 4조 2교대 운영 항목) — 코어타임·주 4.5일제 운영 요일 미기재', 20),

  -- ── 건강·의료 (health) ── Wellness
  (@comp_id, 'health_check', '종합건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '만 35세 이상 임직원 종합건강검진 비용 전액 실비 지원(30만원 한도), 만 40세 이상부터 배우자·부모님까지 지원 (공식 채용 사이트 복리후생 제도 소개 종합건강검진 지원 항목) — 검진 주기 미기재', 40),
  (@comp_id, 'fitness', '사내 피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '직원들이 편리하게 운동할 수 있도록 사내 피트니스 센터 운영 (공식 채용 사이트 복리후생 제도 소개 사내 피트니스 센터 운영 항목) — 이용 시간·위치 미기재', 42),

  -- ── 가족·돌봄 (family) ── Family
  (@comp_id, 'child_edu', '자녀 학자금 (대학생)', NULL, 'family',
   'est', NULL, TRUE, '대학생 자녀 학자금 200만원 한도 내 지원 (공식 채용 사이트 복리후생 제도 소개 자녀 학자금 지원 항목) — 자녀 수 제한·지급 주기 미기재', 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼, 출산, 부모님 회갑 등 주요 가족 행사에 경조 휴가와 경조사비·화환·용품 제공 (공식 채용 사이트 복리후생 제도 소개 경조사 지원 항목) — 경조금 금액·휴가 일수 미기재', 51),

  -- ── 여가·라이프 (leisure) ── Growth & Refresh
  (@comp_id, 'sports_ticket', '삼성라이온즈 관람권 추첨', NULL, 'leisure',
   'est', NULL, TRUE, '삼성라이온즈 야구 구단과 MOU를 체결해 임직원 전용 실내 관람석(스윗박스) 운영, 홈 경기 관람권 추첨 지급 (공식 채용 사이트 복리후생 제도 소개 스포츠 경기 관람권 추첨 항목) — 추첨 주기·지급 매수 미기재', 71),

  -- ── 경제적 부가혜택 (perks) ── Wellness 사내 식당 · Benefit
  (@comp_id, 'pension_support', '개인연금 1:1 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 1:1 지원, 개인연금상품 가입 시 회사에서 추가로 지원 (공식 채용 사이트 복리후생 제도 소개 개인연금 1:1 지원 항목) — 지원 한도 미기재', 80),
  (@comp_id, 'meal', '사내 식당 (1일 2식 무상)', 576, 'perks',
   'est', '「본우리집밥」 입점 사내 식당에서 균형 잡힌 식단 기반의 다양한 메뉴 제공, 1일 2식 무상 지원, 다이어트를 위한 간편식 별도 제공 (공식 채용 사이트 복리후생 제도 소개 사내 식당 항목) — 제공 끼니 구성 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정, 간편식 제외)', FALSE, NULL, 82),
  (@comp_id, 'welfare_point', '복지포인트 (연간 100만 포인트)', 100, 'perks',
   'est', '현대이지웰 복지몰 운영, 연간 100만 포인트를 모든 임직원에게 제공 (공식 채용 사이트 복리후생 제도 소개 복지포인트 지급 항목 — 1포인트 1원 기준 환산)', FALSE, NULL, 83),
  (@comp_id, 'discount', '제휴 할인 혜택', NULL, 'perks',
   'est', NULL, TRUE, '가족친화 인증기업으로 식음료, 쇼핑, 숙박/레저 등 다양한 영역의 제휴 할인 혜택 제공 (공식 채용 사이트 복리후생 제도 소개 제휴 할인 혜택 항목) — 제휴처·할인율 미기재', 84),

  -- ── 성장·교육 (growth) ── Growth & Refresh 사내 교육 프로그램(사외 교육비 · 온라인 교육 플랫폼)
  (@comp_id, 'edu_support', '사외 교육비 전액·온라인 교육 플랫폼', NULL, 'growth',
   'est', NULL, TRUE, '사외 교육 수강 시 교육 비용 전액 지원, 온라인 교육 플랫폼 상시 운영 (공식 채용 사이트 복리후생 제도 소개 사내 교육 프로그램 항목) — 대상 교육 범위·연간 한도 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
