-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 주성엔지니어링 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://jusung.career.greetinghr.com/ko/life
-- badge: est
--
-- 참고:
--   정본은 주성엔지니어링 브랜드 채용 사이트(그리팅, 꼬리말 주성엔지니어링 · 광주본사 경기도 광주시 오포로 240 ·
--   recruit@jusung.com · 본문 HOME PAGE 버튼 = www.jusung.com)의 헤더 메뉴 LIFE 페이지다. 서버 렌더 HTML 과
--   __NEXT_DATA__ 에 복지제도 4개 묶음(생활 안정 · 건강 · 여가 · 자기 계발) 17항목과 슬라이드 2장(용인 Fitness 센터 ·
--   1인 수면용 빈백)이 글자로 있다 — 헤드리스 렌더 없음.
--   보조 출처: 같은 사이트 상시채용 공고 /ko/o/174118 · 병역특례 공고 /ko/o/152117 의 복리 후생 이미지(같은 파일 하나,
--   841x542 PNG) — LIFE 페이지와 같은 항목 + 핵심인력 학위 지원 · 휴양시설(콘도) 지원.
--   자기 도메인 www.jusung.com 은 robots.txt 만 응답하고 페이지 본문 요청이 모두 시간 초과라 쓰지 못했다.
--   귀속: 단독 법인 채용 사이트 — 그룹 각주 없음. 직원 485명(DART 2025) — 1,000인 미만.
--   제외: 점심시간 2시간은 행 코드가 없어 사내식당 행 NOTE 에 함께 적었다. 근골격계 질환 예방 프로그램(산업안전보건 조치) ·
--     직무/역량 개발 온라인 강의(회사 주도 교육 과정, 비용 지원 문구 없음)는 싣지 않았다.
--   금액: 원문 금액 0 · 구본 추정 승계 6(child_edu 200 · holiday_gift 20 · health_check 100 · insurance 30 ·
--     meal 432(조식/중식/석식 명시) · resort 50 — 전부 틀 값, NOTE 끝에 (추정)). transport 30 은 회사 고유값이라
--     전제가 원문에 없어 승계하지 않았다.
--   구본에서 뺀 행: family_day(기념일 조기퇴근) · refresh_leave(1달 휴가) — 현행 원문에 없음. 재코딩 없음. 신규 코드 없음.
--   SORT 섹션 순서 = LIFE 페이지 목록에서 카테고리가 처음 나온 순서
--     (work_env 10 · perks 20 · family 30 · compensation 40 · time_off 50 · health 60 · leisure 70 · growth 80).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-6): 19행 LIFE 페이지와 공고 복리후생 이미지 독립 대조와 일치 · 자기 도메인 www 본문은 검증 때도 응답 없음 · 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('jusung', '주성엔지니어링',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'J', 'https://jusung.career.greetinghr.com/ko/life');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'jusung');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://jusung.career.greetinghr.com/ko/life'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) — LIFE 생활 안정 기숙사 운영 · 여가 휴게공간 제공 · 슬라이드 1인 수면용 빈백 ──
  (@comp_id, 'dormitory', '기숙사 운영 (경기 광주)', NULL, 'work_env',
   'est', NULL, TRUE, '원거리 거주자 기숙사 제공 (경기 광주) (공식 채용 사이트 LIFE 생활 안정 항목 · 채용 공고 복리후생 기숙사 운영) — 비용 부담·입주 조건 미기재', 10),
  (@comp_id, 'nap_room', '휴게공간 (1인 수면용 빈백)', NULL, 'work_env',
   'est', NULL, TRUE, '빈백소파 공간 제공 (공식 채용 사이트 LIFE 여가 항목 휴게공간 제공), 임직원이 편안한 휴식을 가진 뒤 업무에 집중할 수 있도록 별도 장소를 마련해 1인 수면용 빈백 제공 (같은 페이지 복리후생 소개)', 11),

  -- ── 경제적 부가혜택 (perks) — LIFE 생활 안정 통근버스 운영 · 안전 귀가 지원 / 건강 사내식당 운영 / 여가 사내카페 운영 ──
  (@comp_id, 'commute_subsidy', '사업장 간 통근버스 (경기 광주·용인)', NULL, 'perks',
   'est', NULL, TRUE, '사업장 간 통근버스 운영 (경기 광주/용인) (공식 채용 사이트 LIFE 생활 안정 항목) — 노선·운행 시간 미기재', 20),
  (@comp_id, 'transport', '안전 귀가 지원 (심야 택시비·대리운전비)', NULL, 'perks',
   'est', NULL, TRUE, '임직원 심야 퇴근 안전지킴 택시비 지원, 대리운전비 지원 (분기 3회) (공식 채용 사이트 LIFE 생활 안정 항목 안전 귀가 지원) — 1회 지원 한도 미기재', 21),
  (@comp_id, 'meal', '사내식당 (조식·중식·석식)', 432, 'perks',
   'est', '사내식당 조식/중식/석식 제공, 점심시간 12시~14시 2시간 운영 (공식 채용 사이트 LIFE 건강 · 여가 항목) — 식대 부담 미기재 (추정)', FALSE, NULL, 22),
  (@comp_id, 'snack_bar', '사내카페', NULL, 'perks',
   'est', NULL, TRUE, '자유롭고 간편하게 사내카페 이용 가능 (공식 채용 사이트 LIFE 여가 항목 사내카페 운영) — 이용 비용 미기재', 23),

  -- ── 가족·돌봄 (family) — LIFE 생활 안정 학자금 지원 · 경조사 지원 ──
  (@comp_id, 'child_edu', '고등·대학생 자녀 학자금', 200, 'family',
   'est', '임직원 대상 고등/대학생 자녀 학자금 지원 (공식 채용 사이트 LIFE 생활 안정 항목 · 채용 공고 복리후생) — 지원 한도·자녀 수 미기재 (추정)', FALSE, NULL, 30),
  (@comp_id, 'event', '경조사 휴가·경조금', NULL, 'family',
   'est', NULL, TRUE, '임직원의 경조사 휴가, 경조금 지원 (공식 채용 사이트 LIFE 생활 안정 항목 경조사 지원) — 경조 종류별 금액·휴가 일수 미기재', 31),

  -- ── 보상·금전 (compensation) — LIFE 생활 안정 명절 선물 지원 ──
  (@comp_id, 'holiday_gift', '명절 선물포인트', 20, 'compensation',
   'est', '명절 선물포인트 지급 (공식 채용 사이트 LIFE 생활 안정 항목 명절 선물 지원) — 포인트 금액 미기재 (추정)', FALSE, NULL, 40),

  -- ── 시간·휴가 (time_off) — LIFE 생활 안정 장기근속 포상 ──
  (@comp_id, 'long_service_leave', '5년 주기 장기근속 포상 (포상금·여행경비·휴가)', NULL, 'time_off',
   'est', NULL, TRUE, '5년 주기 장기근속 포상금/여행경비/휴가 지원 (공식 채용 사이트 LIFE 생활 안정 항목 장기근속 포상) — 근속연수별 포상금·여행경비 금액·휴가 일수 미기재', 50),

  -- ── 건강·의료 (health) — LIFE 건강 건강검진 지원 · 건강 프로그램 운영 · 단체 상해 보험 / 슬라이드 용인 Fitness 센터 ──
  (@comp_id, 'health_check', '건강검진 (40세 이상 종합검진 격년·배우자 포함)', 100, 'health',
   'est', '매년 임직원 대상 건강검진 시행, 만 40세 이상 직원 종합 건강검진 격년 지원(배우자 포함) (공식 채용 사이트 LIFE 건강 항목) — 지원 한도 미기재 (추정)', FALSE, NULL, 60),
  (@comp_id, 'mental', '매월 스트레스 상담', NULL, 'health',
   'est', NULL, TRUE, '매월 스트레스 상담 (공식 채용 사이트 LIFE 건강 항목 건강 프로그램 운영) — 상담 방식·상담 기관 미기재', 61),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '매년 단체 상해보험 가입/운영 (공식 채용 사이트 LIFE 건강 항목) — 보장 내용 미기재 (추정)', FALSE, NULL, 62),
  (@comp_id, 'fitness', '용인 Fitness 센터 (요가·웨이트)', NULL, 'health',
   'est', NULL, TRUE, '요가 및 웨이트 프로그램과 운동 시설 제공 (공식 채용 사이트 LIFE 복리후생 소개 용인 Fitness 센터) — 이용 비용·운영 시간 미기재', 63),

  -- ── 여가·라이프 (leisure) — LIFE 여가 법인 명의 리조트 ──
  (@comp_id, 'resort', '법인 명의 리조트 (콘도)', 50, 'leisure',
   'est', '법인 명의 리조트 사용으로 휴식 지원 (공식 채용 사이트 LIFE 여가 항목), 휴양시설(콘도) 지원 (채용 공고 복리후생) — 이용 일수·비용 부담 미기재 (추정)', FALSE, NULL, 70),

  -- ── 성장·교육 (growth) — LIFE 자기 계발 도서 구입비 지원 · 교육 프로그램 지원 / 채용 공고 핵심인력 학위 지원 ──
  (@comp_id, 'books', '도서 구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무 및 자기계발 관련 도서 구입비 지원 (공식 채용 사이트 LIFE 자기 계발 항목) — 지원 한도 미기재', 80),
  (@comp_id, 'conference', '외부 교육·학회·워크숍 지원', NULL, 'growth',
   'est', NULL, TRUE, '외부 교육 및 학회, 워크숍 지원 (공식 채용 사이트 LIFE 자기 계발 항목 교육 프로그램 지원) — 지원 범위·한도 미기재', 81),
  (@comp_id, 'lang', '어학 학습·시험 응시료 지원 (영어·중국어)', NULL, 'growth',
   'est', NULL, TRUE, '어학 학습 및 시험 응시료 지원 (영어, 중국어 대상) (공식 채용 사이트 LIFE 자기 계발 항목 교육 프로그램 지원) — 지원 한도·횟수 미기재', 82),
  (@comp_id, 'mba', '핵심인력 학위 지원', NULL, 'growth',
   'est', NULL, TRUE, '핵심인력 학위 지원 (공식 채용 사이트 채용 공고 복리후생 자기계발 항목) — 대상 선정 기준·지원 학위·비용 범위 미기재', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
