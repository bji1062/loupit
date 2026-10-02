-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대오토에버 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://career.hyundai-autoever.com/ko/life
-- badge: est
--
-- 참고:
--   정본은 현대오토에버 채용 사이트 career.hyundai-autoever.com (회사 홈 www.hyundai-autoever.com 헤더 메뉴
--   RECRUIT → 지원하기 링크 · 그리팅 ATS) 헤더 메뉴 Life 페이지(/ko/life)다. 서버 렌더 HTML 에 항목 본문이 그대로 있다
--   — 헤드리스 렌더 없음. 사무실 · 직원식당 사진 슬라이드는 사진뿐이라 판독 대상이 아니다.
--   보조 출처: 같은 사이트 헤더 메뉴 People 페이지(/ko/people)의 근무환경과 성장 제도 절(When · Where · What EVER).
--   귀속: 꼬리말 현대오토에버 · 사업자등록번호 104-81-53190 · 채용 메일 recruit@hyundai-autoever.com — 법인 단독
--     채용 사이트라 그룹 각주 없음. 현대자동차 talent.hyundai.com · 기아 · 현대모비스 · 현대건설 정본 문구는 쓰지 않았다.
--   robots: www 는 /common/ · /files/ 등만 금지 — 지속가능경영보고서 파일과 보도자료 목록 스크립트가 금지 경로라
--     읽지 않았다. career 는 지원서 경로(/o/*/apply 등)만 금지.
--   금액: 구본 추정 승계 7(welfare_point 200 · child_edu 200 · health_check 100 · medical 100 · insurance 30 ·
--     resort 50 · telecom 30 — 전부 틀 값, NOTE 끝에 (추정)). 통신비 원문 월 최대 6만원은 한도라 금액 칸에
--     넣지 않고 NOTE 에 적었다. event 50 은 경조금이라 승계하지 않았다.
--   제외 항목: 사무실 사진 · 출산 전/후 휴가제도(산전후 · 배우자 출산 · 태아검진 · 난임치료 휴가 — 법정 제도) ·
--     수평적인 조직문화(호칭) · 온보딩 프로그램 · 맞춤형 직무교육 · 이러닝/전화화상 교육 · 성장 Lab(혜택 미기재).
--   구본에서 뺀 행: 없음. 구본 별도 휴가 행의 백신 접종 휴가는 현행 원문에 없어 걷었다.
--   재코딩: refresh_leave → summer_leave (원문 항목명이 하계 휴가 · 추가 5일).
--   SORT 섹션 순서 = Life 페이지에서 카테고리가 처음 나온 순서, People 페이지 항목은 해당 섹션 끝
--     (perks 10 · family 20 · compensation 30 · health 40 · time_off 50 · leisure 60 · growth 70 ·
--     flexibility 80 · work_env 90).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-4): 통신비 틀 값 30 (추정) 승계 — 원문 월 최대 6만원은 한도라 NOTE 에만 적음 · 최종 26행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_autoever', '현대오토에버',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        'IT서비스', 'H', 'https://career.hyundai-autoever.com/ko/life');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_autoever');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://career.hyundai-autoever.com/ko/life'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — Life 직원식당 · 복지포인트 · 통신비 · 주거 지원금 · 차량구입지원금 / People 중식 · 심야귀가 ──
  (@comp_id, 'meal', '직원식당·중식 제공', NULL, 'perks',
   'est', NULL, TRUE, '직원식당 운영 (공식 채용 사이트 Life 직원식당 항목), 쾌적한 사내식당에서 맛있는 한 끼 중식 제공 — 사내식당 운영 또는 중식비 지원은 사업장별 상이 (같은 사이트 People 맛있고 든든한 중식 제공 항목)', 10),
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '여가 생활부터 자기 계발까지 폭넓게 사용 가능한 복지포인트 지급 (공식 채용 사이트 Life 복지포인트 항목) — 연간 배정액 미기재 (추정)', FALSE, NULL, 11),
  (@comp_id, 'telecom', '휴대전화 통신비 지원', 30, 'perks',
   'est', '휴대전화 통신비 월 최대 6만원 지원 (공식 채용 사이트 Life 통신비 지원 항목) — 월 한도이며 실제 지원액 미기재 (추정)', FALSE, NULL, 12),
  (@comp_id, 'housing_loan', '주거 지원금 (주택 구입·임차 사내 대출)', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입·임차 시 사내 대출제도 이용 지원 (공식 채용 사이트 Life 주거 지원금 항목) — 대출 한도·이율 미기재', 13),
  (@comp_id, 'discount', '차량구입지원금', NULL, 'perks',
   'est', NULL, TRUE, '현대자동차그룹 차량 구입 시 최대 30%의 차량구입지원금 지원, 입사 후 첫 차 구입 시 20% 지원 (공식 채용 사이트 Life 차량구입지원금 항목) — 구입 주기·횟수 미기재', 14),
  (@comp_id, 'transport', '심야귀가 택시 지원', NULL, 'perks',
   'est', NULL, TRUE, '늦게까지 일한 직원을 집까지 심야 비즈니스 택시로 귀가 지원 (공식 채용 사이트 People 안전한 심야귀가 지원 항목) — 적용 시각·이용 조건 미기재', 15),

  -- ── 가족·돌봄 (family) — Life 어린이집 · 경조사 지원 · 자녀 학자금 지원 · 자녀 초등학교 입학선물 ──
  (@comp_id, 'childcare', '현대오토에버 어린이집', NULL, 'family',
   'est', NULL, TRUE, '근무지 바로 옆 어린이집 운영, 서울시 강남구 내 총 2개소 (공식 채용 사이트 Life 현대오토에버 어린이집 항목)', 20),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼·출산·장례 등 경조사 시 경조휴가 및 경조비 등 지원 (공식 채용 사이트 Life 경조사 지원 항목) — 경조 종류별 금액·휴가 일수 미기재', 21),
  (@comp_id, 'child_edu', '자녀 학자금 지원', 200, 'family',
   'est', '유치원부터 대학교까지 자녀 학자금 지원 (공식 채용 사이트 Life 자녀 학자금 지원 항목) — 지원 금액·자녀 수 제한 미기재 (추정)', FALSE, NULL, 22),
  (@comp_id, 'parenting', '자녀 초등학교 입학선물', NULL, 'family',
   'est', NULL, TRUE, '자녀 초등학교 입학 시 입학 선물 세트 지급 (공식 채용 사이트 Life 자녀 초등학교 입학선물 항목) — 선물 구성 미기재', 23),

  -- ── 보상·금전 (compensation) — Life 명절 귀향비 ──
  (@comp_id, 'holiday_gift', '명절 귀향비', NULL, 'compensation',
   'est', NULL, TRUE, '설과 추석 명절에 귀향비 지급 (공식 채용 사이트 Life 명절 귀향비 항목) — 지급액 미기재', 30),

  -- ── 건강·의료 (health) — Life 종합검진 지원 · 의료비 지원 · 독감 예방접종 · 단체 상해보험 · EAP ──
  (@comp_id, 'health_check', '종합검진·독감 예방접종', 100, 'health',
   'est', '직원 본인 및 가족 대상 종합 건강검진 지원, 전국 의료기관에서 수검 가능 (공식 채용 사이트 Life 종합검진 지원 항목), 본인 및 가족 독감 예방접종 지원 (같은 페이지) — 지원 한도 미기재 (추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '직원 본인 및 가족 대상 의료비 지원 (공식 채용 사이트 Life 의료비 지원 항목) — 지원 범위·한도 미기재 (추정)', FALSE, NULL, 41),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '직원 본인 및 가족 대상 단체상해보험 지원 (공식 채용 사이트 Life 단체 상해보험 항목) — 보장 내용 미기재 (추정)', FALSE, NULL, 42),
  (@comp_id, 'mental', 'EAP 외부 전문가 상담', NULL, 'health',
   'est', NULL, TRUE, '업무 고민부터 법률 상담까지 다양한 영역의 외부 전문가 상담 서비스 지원 (공식 채용 사이트 Life EAP 항목) — 이용 횟수·가족 이용 여부 미기재', 43),

  -- ── 시간·휴가 (time_off) — Life 하계 휴가 ──
  (@comp_id, 'summer_leave', '하계 휴가 5일 추가', NULL, 'time_off',
   'est', NULL, TRUE, '구성원의 충분한 휴식을 위해 추가 5일의 하계 휴가 제공 (공식 채용 사이트 Life 하계 휴가 항목) — 사용 시기 미기재', 50),

  -- ── 여가·라이프 (leisure) — Life 하계 휴가비 · 휴양소 이용 지원 · 사내 동호회 / People 전자책 구독 서비스 ──
  (@comp_id, 'summer_vacation_subsidy', '하계 휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '더욱 즐거운 하계 휴가를 위한 휴가비 지급 (공식 채용 사이트 Life 하계 휴가비 항목) — 지급액 미기재', 60),
  (@comp_id, 'resort', '휴양소 이용 지원', 50, 'leisure',
   'est', '직원과 가족의 재충전을 위해 전국 40여 개 인기 리조트 이용 지원 (공식 채용 사이트 Life 휴양소 이용 지원 항목) — 이용 일수·비용 부담 미기재 (추정)', FALSE, NULL, 61),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 분야의 사내 동호회 운영 지원 (공식 채용 사이트 Life 사내 동호회 항목) — 활동비 금액 미기재', 62),
  (@comp_id, 'library', '전자책 구독 서비스', NULL, 'leisure',
   'est', NULL, TRUE, '전자책 구독 서비스 지원 (공식 채용 사이트 People 전자책 구독 서비스 지원 항목) — 서비스명·이용 범위 미기재', 63),

  -- ── 성장·교육 (growth) — Life 학자금 대출 이자 지원 / People 자기주도 학습 · 자격증 · 어학 교육비 · 커리어 챌린지 ──
  (@comp_id, 'edu_support', '자기주도 학습·학자금 대출 이자 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무에 필요한 도서부터 온라인 강의, 구독 서비스까지 스스로 학습할 자원 제공 (공식 채용 사이트 People 자기주도 학습 지원 항목), 한국장학재단에서 실행하는 본인 학자금 대출의 발생 이자 지원 (같은 사이트 Life 학자금 대출 이자 지원 항목)', 70),
  (@comp_id, 'self_development', '자격증 취득/갱신 지원', NULL, 'growth',
   'est', NULL, TRUE, '취득하고 싶은 업무 관련 자격증과 갱신 비용 지원 (공식 채용 사이트 People 자격증 취득/갱신 지원 항목) — 대상 자격증·지원 한도 미기재', 71),
  (@comp_id, 'lang', '어학 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학교육비 지원 (공식 채용 사이트 People 어학 교육비 지원 항목) — 지원 한도·대상 언어 미기재', 72),
  (@comp_id, 'career', '커리어 챌린지 (사내공모제도)', NULL, 'growth',
   'est', NULL, TRUE, '자기주도적인 커리어 개발을 위한 사내공모제로 원하는 방향에 도전할 기회 제공 (공식 채용 사이트 People 커리어 챌린지 항목)', 73),

  -- ── 근무 유연성 (flexibility) — People 선택적 근로시간제 ──
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '필요한 시간에 출근해 코어시간에 함께 일하는 선택적 근로시간제 (공식 채용 사이트 People 선택적 근로시간제 항목) — 코어시간대 미기재', 80),

  -- ── 근무환경 (work_env) — People 자율 좌석제 ──
  (@comp_id, 'free_seating', '자율 좌석제', NULL, 'work_env',
   'est', NULL, TRUE, '선착순 자율 좌석제, Smart Work Place 앱으로 좌석 선점과 회의실 예약 (공식 채용 사이트 People 자율 좌석제 항목)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
