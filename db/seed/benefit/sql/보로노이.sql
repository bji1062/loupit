-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 보로노이 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://voronoi.career.greetinghr.com/ko/culture1
-- badge: est
--
-- 참고:
--   정본은 회사가 운영하는 그리팅 채용 사이트(voronoi.career.greetinghr.com, 서버 렌더 HTML)의 국문 How We Work 페이지다.
--     공식 홈(voronoi.io, Copyright VORONOI, Inc.) Careers 페이지가 이 채용 사이트로 링크하고, 채용 사이트 꼬리말은 Voronoi, Inc. Function and People Team.
--     복지 혜택 4칸(배우고 성장할 기회 · 경조사 지원 · 명절 선물 · 합리적 지원) 13줄 + 성과 및 보상 체계 절.
--   보조: 공식 홈 voronoi.io/careers.html 영문 Benefits 4묶음(같은 제도 11줄 — 교차 확인).
--     OpenDART 2026 반기보고서(정정, 접수 20261002000482) 유연근무제도 사용 현황 — 시차출퇴근제 활용 → flex_work.
--     같은 보고서 임원 보수 산정기준의 명절상여금 전 직원 동일 기준 문장 — holiday_gift 보조.
--   공고 근거 0행: 게시 중 공고 1건(미국 근무 Medical Writer)에 복리후생 블록 없음.
--   귀속: 단독 법인(2023-05 자회사 보로노이바이오 · 비투에스바이오 흡수합병). 미국 자회사 VORONOI USA 공고 문구는 쓰지 않았다.
--   법정 제도: 원문에 법정 문구 없음. 직원 149명(2025 사업보고서) — 재취업지원 의무 대상 아님.
--   금액: 원문 금액 2(holiday_gift 연 100만 원 · meal 중식 월 24만 원 × 12 환산). 구본 추정 승계 3(health_check 100 · snack_bar 30 · incentive 100).
--   구본에서 뺀 행: parking. 재코딩 0. 신규 코드 0. 행 분리: 구본 leave_general 경조휴가·창립일 휴무 → leave_general 경조휴가 + foundation_day_leave.
--   SORT 섹션 순서 = 복지 혜택 칸 순서에서 카테고리가 처음 나온 순서(growth 10 · time_off 20 · work_env 30 · perks 40 · family 50 · compensation 60 · health 70), 공시 flexibility 80.
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-7): 13행 원문 확인 · 행 조치 없음(경조사비와 경조휴가 두 행 · 무료 카페테리아 snack_bar · 그리팅 정본 유지 · 원격근무 1명 미수록) — 최종 13행
-- 후속 정리 5(2026-10-05, 보류 · 붙여넣기): 보류에서 넣기로 정한 줄(사용자 결정 2026-10-05) — 새 행 1(welfare_fund_loan 2026 반기 · 2025 사업보고서 주석 임직원대출금관련 질권설정 · 반기말 15억 원은 회사 담보라 금액 칸 비움) — 최종 14행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('voronoi', '보로노이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오', 'B', 'https://voronoi.career.greetinghr.com/ko/culture1');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'voronoi');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://voronoi.career.greetinghr.com/ko/culture1'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장·교육 (growth) — 복지 혜택 칸 1 배우고 성장할 기회 ──
  (@comp_id, 'edu_support', '외부 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '외부 교육비 지원 (공식 채용 페이지 복지 혜택 항목), Full support for external training and education (공식 홈페이지 Careers Benefits 항목) — 지원 한도·대상 교육 범위 미기재', 10),
  (@comp_id, 'books', '직무 관련 도서 구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '관련 도서 구입비 지원 (공식 채용 페이지 복지 혜택 항목), Book purchase support for role-related learning (공식 홈페이지 Careers Benefits 항목) — 지원 한도 미기재', 11),

  -- ── 시간·휴가 (time_off) — 복지 혜택 칸 2 · 칸 3 ──
  (@comp_id, 'foundation_day_leave', '창립기념일 휴무', NULL, 'time_off',
   'est', NULL, TRUE, '창립기념일 휴무 (공식 채용 페이지 복지 혜택 항목), Day off on our company anniversary (공식 홈페이지 Careers Benefits 항목) — 휴무 날짜 미기재', 20),
  (@comp_id, 'leave_general', '경조휴가', NULL, 'time_off',
   'est', NULL, TRUE, '경조사비 및 경조휴가 지원 중 경조휴가 (공식 채용 페이지 복지 혜택 항목), Leave and financial support for family events (공식 홈페이지 Careers Benefits 항목) — 경조 범위별 휴가 일수·유급 여부 미기재', 21),

  -- ── 근무환경 (work_env) — 복지 혜택 칸 2 ──
  (@comp_id, 'lounge', '휴게 공간', NULL, 'work_env',
   'est', NULL, TRUE, '쾌적한 휴게 공간 (공식 채용 페이지 복지 혜택 항목) — 위치·이용 방식 미기재', 30),

  -- ── 경제적 부가혜택 (perks) — 복지 혜택 칸 2 · 칸 4 / 2026 반기보고서 주석 ──
  (@comp_id, 'snack_bar', '간식 무제한·무료 카페테리아', 30, 'perks',
   'est', '다양한 간식 무제한 제공, 무료 카페테리아 운영 (공식 채용 페이지 복지 혜택 항목) — 1인당 금액·운영 방식 미기재 (추정)', FALSE, NULL, 40),
  (@comp_id, 'transport', '야근 택시비 지원', NULL, 'perks',
   'est', NULL, TRUE, '야근 택시비 지원 (공식 채용 페이지 복지 혜택 항목), Late night taxi support (공식 홈페이지 Careers Benefits 항목) — 적용 시간대·지원 한도 미기재', 41),
  (@comp_id, 'meal', '식대 지급 (중식 월 24만 원)·석식 법인카드', 288, 'perks',
   'est', '급여 외 별도 식대 지급 중식 월 24만 원, 월액 × 12 환산 · 석식은 회사 법인카드 제공 (공식 채용 페이지 복지 혜택 항목)', FALSE, NULL, 42),
  (@comp_id, 'welfare_fund_loan', '임직원 대출 담보 제공 (정기예금 질권설정)', NULL, 'perks',
   'est', NULL, TRUE, '임직원 대출금 관련 회사 정기예금 질권설정 (2026 반기보고서 · 2025 사업보고서 재무제표 주석 사용이 제한된 금융상품 항목) — 대출 기관·용도·한도·금리·대상 미기재', 43),

  -- ── 가족·돌봄 (family) — 복지 혜택 칸 3 ──
  (@comp_id, 'event', '경조사비 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사비 및 경조휴가 지원 중 경조사비 (공식 채용 페이지 복지 혜택 항목), Leave and financial support for family events (공식 홈페이지 Careers Benefits 항목) — 경조금 금액·경조 범위 미기재', 50),

  -- ── 보상 (compensation) — 복지 혜택 칸 3 · 성과 및 보상 체계 ──
  (@comp_id, 'holiday_gift', '명절 상여금', 100, 'compensation',
   'est', '명절 상여금 연 100만 원 지급 (공식 채용 페이지 복지 혜택 항목) — 명절별 지급 시기 미기재', FALSE, NULL, 60),
  (@comp_id, 'incentive', '성과 인센티브', 100, 'compensation',
   'est', '연 1회 성과 평가에 따른 인센티브 상여 (공식 홈페이지 Careers Benefits 항목), 프로젝트별·개인 성과에 따른 보상제도 운영 (공식 채용 페이지 성과 및 보상 체계 항목) — 지급 기준·지급률 미기재 (추정)', FALSE, NULL, 61),

  -- ── 건강·의료 (health) — 복지 혜택 칸 4 ──
  (@comp_id, 'health_check', '연 1회 종합건강검진', 100, 'health',
   'est', '연 1회 종합건강검진 지원 (공식 채용 페이지 복지 혜택 항목) — 비용 한도·가족 포함 여부 미기재 (추정)', FALSE, NULL, 70),

  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용, 시차출퇴근제 운영 (2026 반기보고서 직원 등의 현황 유연근무제도 사용 현황 항목) — 적용 대상·출퇴근 시간대 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
