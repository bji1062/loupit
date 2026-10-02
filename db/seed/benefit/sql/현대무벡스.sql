-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대무벡스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.hyundaimovex.com/recruit/personnelPolicy.php
-- badge: est
--
-- 참고:
--   정본은 현대무벡스 자기 도메인(hyundaimovex.com) 헤더 메뉴 인재채용 → 인사정책 페이지의 복지제도 절이다
--   (생활자금 지원 9 · 사내지원 7 · 기타 4 항목). 서버 렌더 PHP HTML 에 항목 본문이 그대로 있다 — 헤드리스 렌더 없음.
--   HTML 주석 속 옛 항목(전국콘도 및 휴양소 지원 · 출산 선물 지급 · 자녀 입학 선물 지급 · 교육제도 절 · 승진체계)은
--   화면에 나오지 않아 근거로 쓰지 않았다.
--   보조 출처: 같은 사이트 헤더 메뉴 ENGLISH → HR Policy 페이지(/en/recruit/personnelPolicy.php)의
--     Welfare System 절 — 국문에 없는 Employee dormitories 1항목만 dormitory 행 근거로 썼다.
--   귀속: 현대그룹(현대엘리베이터 계열)이다 — 현대자동차그룹이 아니다. OpenDART 2025 사업보고서 최대주주 현황에서
--     최대주주 현대엘리베이터(주) 48.90퍼센트. 꼬리말 서울특별시 종로구 율곡로 194 현대그룹빌딩 ·
--     COPYRIGHT 2018 HYUNDAI MOVEX CO., LTD. 법인 자기 도메인이라 그룹 각주 없음. 현대엘리베이터 · 현대그룹 공통 페이지 미사용.
--   직원 수 551명(OpenDART 2025 직원 현황) — 1,000인 미만. 원문에 재취업지원 문구 없음.
--   금액: 원문 값 3(welfare_point 160 직급별 구간 중간값 · 지급 주기 미기재라 추정 표기 · pension_support 월 3만~5만원 중간값 4만원 연 48 환산 ·
--     club 월 1만원 연 12 환산) · 구본 추정 승계 5(health_check 100 · medical 100 · insurance 30 · child_edu 200 · snack_bar 50 —
--     전부 틀 값, NOTE 끝에 추정 표기 · snack_bar 50 은 원문 월 6만원 한도 안). transport 120 은 회사 고유값이고
--     통근차량을 commute_subsidy 로 나눠 전제가 바뀌어, parenting 30 은 1회성이라, event 50 은 경조금이라 승계하지 않았다.
--   재코딩: long_service_bonus → long_service_leave (원문이 포상금과 휴가를 한 줄에 적음).
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서, 영문 페이지 항목은 끝
--     (perks 10 · health 20 · family 30 · growth 40 · time_off 50 · leisure 60 · compensation 70 · work_env 80).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-4): 구간 금액 2행(welfare_point · pension_support)의 표기값을 하한에서 중간값으로 바꿈(160 추정 · 48 환산) · snack_bar 50 추정 승계(월 6만원 한도 안) — 최종 22행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_muvex', '현대무벡스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '산업기계', 'H', 'https://www.hyundaimovex.com/recruit/personnelPolicy.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_muvex');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hyundaimovex.com/recruit/personnelPolicy.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 복지제도 생활자금 지원 · 사내지원 · 기타 ──
  (@comp_id, 'welfare_point', '개인별 복지카드', 160, 'perks',
   'est', '개인별 복지카드 130만~190만원 직급별 차등 지급 (공식 홈페이지 인사정책 복지제도 생활자금 지원 항목) — 표기값은 직급별 구간의 중간값, 지급 주기 미기재 (추정)', FALSE, NULL, 10),
  (@comp_id, 'pension_support', '개인연금 지원', 48, 'perks',
   'est', '개인연금 가입비의 50퍼센트, 월 3만~5만원 지원 (공식 홈페이지 인사정책 복지제도 생활자금 지원 항목) — 표기값은 월 3만~5만원의 중간값 4만원을 연 48만원으로 환산', FALSE, NULL, 11),
  (@comp_id, 'transport', '시내교통비·명절 귀향비', NULL, 'perks',
   'est', NULL, TRUE, '시내교통비 지원 (공식 홈페이지 인사정책 복지제도 기타 항목), 명절 귀성·귀향 시 교통비 지원 (같은 페이지 생활자금 지원 명절 귀향비 항목) — 지급액 미기재', 12),
  (@comp_id, 'snack_bar', '복지카페 지원', 50, 'perks',
   'est', '복지카페 사용금액의 50퍼센트 지원, 월 6만원 한도 (공식 홈페이지 인사정책 복지제도 사내지원 항목) — 실지급액 미기재 (추정)', FALSE, NULL, 13),
  (@comp_id, 'meal', '구내식당', NULL, 'perks',
   'est', NULL, TRUE, '구내식당 운영, 중식·석식 제공 (공식 홈페이지 인사정책 복지제도 사내지원 항목) — 1식 단가 미기재', 14),
  (@comp_id, 'birthday_gift', '직원 생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '직원 생일 선물 지급 (공식 홈페이지 인사정책 복지제도 사내지원 각종 기념일 선물 항목) — 선물 내용·금액 미기재', 15),
  (@comp_id, 'commute_subsidy', '통근차량 운영', NULL, 'perks',
   'est', NULL, TRUE, '통근차량 운영, 연지사옥 약 40개 노선·청라 2개 노선 (공식 홈페이지 인사정책 복지제도 기타 항목)', 16),

  -- ── 건강·의료 (health) — 복지제도 생활자금 지원 · 사내지원 ──
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인 및 가족 의료비 연간 500만원 한도 지원 (공식 홈페이지 인사정책 복지제도 생활자금 지원 항목) — 실지급액 미기재 (추정)', FALSE, NULL, 20),
  (@comp_id, 'insurance', '단체상해보험 지원', 30, 'health',
   'est', '질병·상해 사망 1억~3억원, 주요 질병 진단 시 500만~4,000만원 보장 (공식 홈페이지 인사정책 복지제도 생활자금 지원 항목) — 회사 부담 보험료 미기재 (추정)', FALSE, NULL, 21),
  (@comp_id, 'health_check', '건강검진·예방접종 지원', 100, 'health',
   'est', '본인 및 배우자 종합검진 시행, 독감 및 파상풍 예방접종 지원 (공식 홈페이지 인사정책 복지제도 생활자금 지원 항목) — 검진 비용 미기재 (추정)', FALSE, NULL, 22),
  (@comp_id, 'fitness', '스포츠 센터', NULL, 'health',
   'est', NULL, TRUE, '스포츠 센터 운영 (공식 홈페이지 인사정책 복지제도 사내지원 항목) — 위치·이용 조건 미기재', 23),

  -- ── 가족·돌봄 (family) — 복지제도 생활자금 지원 · 사내지원 각종 기념일 선물 ──
  (@comp_id, 'child_edu', '자녀 학자금', 200, 'family',
   'est', '자녀 학자금 지급 (공식 홈페이지 인사정책 복지제도 생활자금 지원 학자금 지원 항목) — 지원 학교급·한도 미기재 (추정)', FALSE, NULL, 30),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '사유별 경조금 및 화환·상조 용품 지원 (공식 홈페이지 인사정책 복지제도 생활자금 지원 항목), 수술·입원 시 쾌유 기원 선물 (같은 페이지 사내지원 각종 기념일 선물 항목) — 경조 종류별 금액 미기재', 31),
  (@comp_id, 'parenting', '자녀 출산·입학 축하 선물', NULL, 'family',
   'est', NULL, TRUE, '자녀 출산 축하 선물, 자녀 입학 선물 — 유치원·초등학교 학용품 세트, 중학교·고등학교 최신 가방 (공식 홈페이지 인사정책 복지제도 사내지원 각종 기념일 선물 항목)', 32),

  -- ── 성장·커리어 (growth) — 복지제도 생활자금 지원 학자금 지원 ──
  (@comp_id, 'self_development', '본인 학자금', NULL, 'growth',
   'est', NULL, TRUE, '본인 학자금 지급 (공식 홈페이지 인사정책 복지제도 생활자금 지원 학자금 지원 항목) — 지원 학위 과정·한도 미기재', 40),

  -- ── 시간·휴가 (time_off) — 복지제도 사내지원 ──
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계휴가 유급 4일 부여 (공식 홈페이지 인사정책 복지제도 사내지원 항목)', 50),
  (@comp_id, 'long_service_leave', '장기근속 포상금 및 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상금 및 휴가 지원 (공식 홈페이지 인사정책 복지제도 사내지원 항목) — 근속 구간·포상금액·휴가 일수 미기재', 51),

  -- ── 여가·라이프 (leisure) — 복지제도 사내지원 · 기타 ──
  (@comp_id, 'resort', '블룸비스타 숙박권', NULL, 'leisure',
   'est', NULL, TRUE, '블룸비스타 숙박권 연간 1인 2매 지급 (공식 홈페이지 인사정책 복지제도 사내지원 항목)', 60),
  (@comp_id, 'club', '동호회 활동 지원', 12, 'leisure',
   'est', '동호회 활동 인당 월 1만원 지원 (공식 홈페이지 인사정책 복지제도 기타 항목) — 월 1만원을 연 12만원으로 환산', FALSE, NULL, 61),

  -- ── 보상·금전 (compensation) — 복지제도 사내지원 각종 기념일 선물 ──
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '설·추석 명절 선물, 근로자의 날 선물 지급 (공식 홈페이지 인사정책 복지제도 사내지원 각종 기념일 선물 항목) — 선물 내용·금액 미기재', 70),

  -- ── 근무환경 (work_env) — 복지제도 기타 · 영문 페이지 Welfare System ──
  (@comp_id, 'uniform', '피복 지원', NULL, 'work_env',
   'est', NULL, TRUE, '하계·동계 피복 지급 (공식 홈페이지 인사정책 복지제도 기타 항목) — 대상 직군 미기재', 80),
  (@comp_id, 'dormitory', '임직원 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '임직원 기숙사 (영문 공식 홈페이지 HR Policy 페이지 Welfare System 항목 Employee dormitories) — 위치·입주 대상·비용 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
