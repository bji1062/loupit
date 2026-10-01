-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 티씨케이 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://www.tck.co.kr/kor/recruit/benefit.php
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인 www.tck.co.kr 의 헤더 메뉴 인재채용 > 복리후생 페이지(/kor/recruit/benefit.php)다.
--   정적 PHP HTML 이라 원본 응답에 15항목 본문이 그대로 있다 — 헤드리스 렌더 없음. robots.txt 는 404(전 경로 허용).
--   보조 출처: 같은 사이트 인재채용 > 인사제도(/kor/recruit/personnel.php, 급여 성과급 · 인재육성),
--   ESG > 사회 > 임직원(/kor/system/social_05.php, 교육 프로그램 현황 어학 교육 열),
--   고객센터 > 자주묻는질문(/kor/center/faq.php, 기숙사 이용 기준), 영문판 Benefits · Personnel System(대조용).
--   채용 ATS tck.recruiter.co.kr 의 혜택 및 보상 페이지는 Next.js 셸이고 본문 데이터 호스트가 robots 전면 금지라 쓰지 않았다.
--   귀속: 법인 자기 도메인 페이지라 그룹 각주를 달지 않았다(꼬리말 TOKAI CARBON KOREA Co., Ltd.).
--   금액: 원문 금액 0. 구본 추정 승계 8(health_check 100 · insurance 30 · child_edu 200 · resort 50 · welfare_point 200 ·
--     meal 432 · commute_subsidy 120 · holiday_gift 30 — 전부 틀 값, NOTE 끝에 (추정)). meal 432 는 원문 조식 · 중식 · 석식 표기.
--     구본 추정치 medical 50(회사 고유값 · 전제 없음) · event 50(경조금)은 승계하지 않았다.
--   구본에서 뺀 행: edu_support (공통 · 글로벌 · 직무 · 계층 교육은 회사 주도 교육 과정).
--   재코딩: incentive → profit_sharing (원문 성과급은 목표 영업이익 초과분을 임직원 수로 나누는 이익 배분, 영문판 Profit Sharing).
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서, 정본에 없는 카테고리는 보조 출처 순서
--     (work_env 10 · perks 20 · leisure 30 · family 40 · compensation 50 · health 60 · growth 70).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-3): 19행 원문 확인 · 사내 영화관 library → leisure_room 재코딩(영화관은 도서관이 아니라 여가 시설) · 승계 추정 8행 유지 — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('tck', '티씨케이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체소재', 'T', 'https://www.tck.co.kr/kor/recruit/benefit.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'tck');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.tck.co.kr/kor/recruit/benefit.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) — 복리후생 기숙사 ──
  (@comp_id, 'dormitory', '기숙사 (안성 시내 아파트)', NULL, 'work_env',
   'est', NULL, TRUE, '출퇴근 거리에 따라 지정된 안성 시내 아파트 이용 (공식 홈페이지 인재채용 복리후생 기숙사 항목), 출퇴근 편도 거리 50km 이상 · 시간 1시간 이상이면 이용 가능 (공식 홈페이지 자주묻는질문 복리후생 항목)', 10),

  -- ── 경제적 부가혜택 (perks) — 사내 대출 제도 · 통근버스 · 선택적 복리 후생 제도 · 식비 지원 및 사내 카페테리아 운영 ──
  (@comp_id, 'housing_loan', '사내 대출 제도 (주택 · 긴급 자금)', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입 · 임차에 필요한 자금 일부를 저리로 대출, 특별한 사유로 일시적 자금이 필요한 사원에게도 저리 대출 (공식 홈페이지 인재채용 복리후생 사내 대출 제도 항목) — 대출 한도 · 금리 미기재', 20),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '회사 기숙사와 안성 주요 지점을 잇는 통근버스 운영 (공식 홈페이지 인재채용 복리후생 통근버스 항목) — 노선 · 운행 횟수 미기재 (추정)', FALSE, NULL, 21),
  (@comp_id, 'welfare_point', '선택적 복리후생 복지포인트', 200, 'perks',
   'est', '자기개발 · 건강증진 등에 자유롭게 쓰는 복지포인트 지급, 적용 범위 여행 · 어학원 수강 · 온라인 강좌 · 서적 · 영화 · 공연 · 헬스 및 요가 · 운동 용품 등 (공식 홈페이지 인재채용 복리후생 항목) — 지급 포인트 미기재 (추정)', FALSE, NULL, 22),
  (@comp_id, 'meal', '조식 · 중식 · 석식 무료 제공', 432, 'perks',
   'est', '근무시간에 관계없이 조식 · 중식 · 석식 무료 제공 (공식 홈페이지 인재채용 복리후생 식비 지원 및 사내 카페테리아 운영 항목) (추정)', FALSE, NULL, 23),
  (@comp_id, 'snack_bar', '사내 카페테리아 · 간식', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페테리아에서 커피 · 차 무료 제공, 현장직군 한정 간식 지급 (공식 홈페이지 인재채용 복리후생 식비 지원 및 사내 카페테리아 운영 항목)', 24),

  -- ── 여가·라이프 (leisure) — 휴양시설(콘도) 보유 · 동호회 활동 지원 · 회사행사 · 사내 영화관 ──
  (@comp_id, 'resort', '휴양시설 (콘도)', 50, 'leisure',
   'est', '전국 유명 휴양지 콘도 보유, 휴가기간 등에 저렴한 비용으로 가족 단위 휴양 (공식 홈페이지 인재채용 복리후생 휴양시설 항목) — 이용 요금 · 이용 횟수 미기재 (추정)', FALSE, NULL, 30),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '직원의 여가선용 · 취미생활을 위한 동호회 활동 지원, 현재 축구 · 야구 · 볼링 · 산악 · 자전거 · 영화 · 봉사 동아리 운영 (공식 홈페이지 인재채용 복리후생 동호회 활동 지원 항목) — 지원금 미기재', 31),
  (@comp_id, 'company_event', '회사행사', NULL, 'leisure',
   'est', NULL, TRUE, '전 임직원이 참여할 수 있는 사내 · 사외 행사 매년 실시 (공식 홈페이지 인재채용 복리후생 회사행사 항목) — 행사 내용 미기재', 32),
  (@comp_id, 'leisure_room', '사내 영화관', NULL, 'leisure',
   'est', NULL, TRUE, '퇴근 후 영화를 관람할 수 있는 사내 영화관 운영 (공식 홈페이지 인재채용 복리후생 사내 헬스장 및 영화관 운영 항목)', 33),

  -- ── 가족·돌봄 (family) — 자녀 학자금 · 경조금 및 경조휴가 ──
  (@comp_id, 'child_edu', '자녀 학자금 (유학 자녀 포함)', 200, 'family',
   'est', '고등학생 · 대학생 자녀 수업료 지원, 유학 자녀는 국내 사립대학교 계열별 등록금 중 수업료 해당 금액 지원 (공식 홈페이지 인재채용 복리후생 자녀 학자금 항목) — 자녀 수 제한 미기재 (추정)', FALSE, NULL, 40),
  (@comp_id, 'event', '경조금 및 경조휴가', NULL, 'family',
   'est', NULL, TRUE, '임직원과 가족의 경조사에 경조금과 경조휴가 부여 (공식 홈페이지 인재채용 복리후생 경조금 및 경조휴가 항목) — 경조 종류별 금액 · 휴가 일수 미기재', 41),

  -- ── 보상·금전 (compensation) — 기념일 · 인사제도 급여 성과급 ──
  (@comp_id, 'holiday_gift', '기념일 복지포인트 (명절 · 생일 · 결혼기념일)', 30, 'compensation',
   'est', '결혼 기념일 · 임직원 생일 · 명절(설날 · 추석) 등에 복지포인트 지급 (공식 홈페이지 인재채용 복리후생 기념일 항목) — 지급 포인트 미기재 (추정)', FALSE, NULL, 50),
  (@comp_id, 'profit_sharing', '성과급 (영업이익 초과분 배분)', NULL, 'compensation',
   'est', NULL, TRUE, '전사가 목표한 영업이익금을 초과 달성한 해에 해당 이익금의 특정 비율을 임직원 수로 나누어 지급 (공식 홈페이지 인재채용 인사제도 급여 항목) — 배분 비율 · 지급 시기 미기재', 51),

  -- ── 건강·의료 (health) — 의료비 · 종합건강검진 · 사내 헬스장 ──
  (@comp_id, 'medical', '본인 의료비 실비 지원', NULL, 'health',
   'est', NULL, TRUE, '상해 · 질병에 대한 임직원 본인 실비 지원 (공식 홈페이지 인재채용 복리후생 의료비 항목) — 지원 한도 미기재', 60),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '사고에 대비한 직원 생활보장 지원으로 단체 상해 보험 가입 (공식 홈페이지 인재채용 복리후생 의료비 항목) — 보장 내용 미기재 (추정)', FALSE, NULL, 61),
  (@comp_id, 'health_check', '종합건강검진 (본인 · 배우자)', 100, 'health',
   'est', '직원과 배우자 종합건강검진 실시, 지정병원 (공식 홈페이지 인재채용 복리후생 종합건강검진 항목) — 검진 주기 · 지원 한도 미기재 (추정)', FALSE, NULL, 62),
  (@comp_id, 'fitness', '24시간 사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '직원 건강증진을 위해 24시간 이용 가능한 사내 헬스장 운영 (공식 홈페이지 인재채용 복리후생 사내 헬스장 및 영화관 운영 항목)', 63),

  -- ── 성장·커리어 (growth) — ESG 사회 임직원 교육 프로그램 현황 어학 교육 · 인사제도 인재육성 글로벌 교육 ──
  (@comp_id, 'lang', '외국어 학습 비용 지원', NULL, 'growth',
   'est', NULL, TRUE, '외국어 학습 비용 지원 · 자격시험 비용 지원 (공식 홈페이지 ESG 사회 임직원 교육 프로그램 현황 어학 교육 항목), 사외 · 사내 · 온라인 어학 교육 (공식 홈페이지 인재채용 인사제도 인재육성 글로벌 교육 항목) — 지원 한도 · 대상 시험 미기재', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
