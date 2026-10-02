-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 테크윙 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.techwing.co.kr/kor/recruit/recruit04.asp
-- badge: est
--
-- 참고:
--   정본은 테크윙 공식 홈페이지 www.techwing.co.kr 헤더 메뉴 인재채용 → 복리후생(/kor/recruit/recruit04.asp)이다.
--   본문은 이미지 1장(/kor/images/recruit/recruit04.jpg, 850x598)에 4칸 라벨 31개(Health 7 · Education 6 · Family 7 ·
--   Office Life 11)로 실려 있어 내려받아 판독했다. 같은 사이트 영문판 Recruit → Welfare 이미지가 같은 목록을 영문으로 싣는다
--   (리조트 숙박료 20% 지원은 영문판에만 있다).
--   보조 출처: 같은 사이트 인재채용 → 인사제도(/kor/recruit/recruit03.asp 이미지) 보상제도 문장 ·
--     ESG → 사회 → 구성원 안전/보건(/kor/esg/esg0402.asp 본문) · 구성원 삶의질 향상(/kor/esg/esg0403.asp 이미지).
--   채용 ATS techwing.recruiter.co.kr 는 robots 가 /career/ 를 막아 읽지 않았다(붙여넣기 요청 대상).
--   robots: www.techwing.co.kr 는 Allow / (제한 없음).
--   금액: 구본 추정 승계 6(health_check 100 · insurance 30 · welfare_point 200 · commute_subsidy 120 · child_edu 200 ·
--     resort 50 — 전부 틀 값, NOTE 끝에 (추정)). event 50 은 경조금이라, excellence_award 50 은 회사 고유값인데 전제가
--     원문에 없어 승계하지 않았다.
--   제외 항목: 온라인 어학강좌 운영 · 신입사원/승진자 교육 · 전사 조직활성화 교육 · 직급별 역량 강화 교육(회사 주도 교육 과정) ·
--     직원 대출제도 운영(용도 미기재) · 가족수당 · 사업장 수당(급여성 수당) · 성과에 기반한 연봉제(급여 체계).
--   구본에서 뺀 행: edu_support(회사 주도 교육 과정) · housing_loan(용도 미기재 대출). 재코딩 long_service_leave → long_service_bonus.
--   SORT 섹션 순서 = 복리후생 이미지에서 카테고리가 처음 나온 순서
--     (health 10 · perks 20 · growth 30 · family 40 · leisure 50 · compensation 60 · work_env 70).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-6): resort NOTE 와 club 서술의 영문 출처 페이지명을 실제 메뉴 이름 Benefits 로 고침 — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('techwing', '테크윙',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'T', 'https://www.techwing.co.kr/kor/recruit/recruit04.asp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'techwing');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.techwing.co.kr/kor/recruit/recruit04.asp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) — 복리후생 Health 칸 / ESG 구성원 안전/보건 건강증진 프로그램 ──
  (@comp_id, 'fitness', '체력단련실·야외 운동장', NULL, 'health',
   'est', NULL, TRUE, '체력 단련실 운영, 야외 운동장(풋살, 농구 등) (공식 채용 페이지 복리후생 Health 항목) — 이용 시간·운영 사업장 미기재', 10),
  (@comp_id, 'health_check', '종합 건강검진 (본인+배우자)', 100, 'health',
   'est', '종합 건강검진 지원(본인+배우자) (공식 채용 페이지 복리후생 Health 항목), 인근 병원과 연계한 종합건강검진 지원 (ESG 구성원 안전/보건 페이지) — 지원 한도·주기 미기재 (추정)', FALSE, NULL, 11),
  (@comp_id, 'clinic', '건강관리실 (정규직 간호사)', NULL, 'health',
   'est', NULL, TRUE, '건강관리실 운영(정규직 간호사) (공식 채용 페이지 복리후생 Health 항목), 의무실 운영 및 외부 기관과 연계한 마음건강·간건강·뇌심혈관질환·건강체중 프로그램 운영 (ESG 구성원 안전/보건 페이지 건강증진 프로그램)', 12),
  (@comp_id, 'insurance', '단체보험 (상해+질병)', 30, 'health',
   'est', '단체보험 가입(상해+질병) (공식 채용 페이지 복리후생 Health 항목) — 보장 내용·가입 대상 미기재 (추정)', FALSE, NULL, 13),
  (@comp_id, 'smoking_cessation', '금연수당', NULL, 'health',
   'est', NULL, TRUE, '금연수당 지원 (공식 채용 페이지 복리후생 Health 항목) — 지급 조건·금액 미기재', 14),

  -- ── 경제적 부가혜택 (perks) — 복리후생 Health · Family · Office Life 칸 ──
  (@comp_id, 'meal', '사내 직영 식당', NULL, 'perks',
   'est', NULL, TRUE, '사내 직영 식당 운영 (공식 채용 페이지 복리후생 Health 항목) — 제공 끼니·식비 부담 미기재', 20),
  (@comp_id, 'promotion_gift', '승진자 축하선물', NULL, 'perks',
   'est', NULL, TRUE, '승진자 축하선물 지급 (공식 채용 페이지 복리후생 Family 항목) — 선물 품목·금액 미기재', 21),
  (@comp_id, 'birthday_gift', '결혼기념일 축하 선물', NULL, 'perks',
   'est', NULL, TRUE, '결혼 기념일 축하 선물 지급 (공식 채용 페이지 복리후생 Family 항목) — 선물 품목·금액 미기재', 22),
  (@comp_id, 'welfare_point', '선택적 복리후생 포인트', 200, 'perks',
   'est', '선택적 복리후생 포인트 지급 (공식 채용 페이지 복리후생 Office Life 항목) — 연간 배정액 미기재 (추정)', FALSE, NULL, 23),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '통근버스 운행 (공식 채용 페이지 복리후생 Office Life 항목) — 노선·운행 사업장 미기재 (추정)', FALSE, NULL, 24),
  (@comp_id, 'transport', '교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '교통비 지원 (공식 채용 페이지 복리후생 Office Life 항목) — 지원 대상·금액 미기재', 25),

  -- ── 성장·교육 (growth) — 복리후생 Education 칸 ──
  (@comp_id, 'lang', '어학 자기계발비', NULL, 'growth',
   'est', NULL, TRUE, '어학 자기계발비 지원 (공식 채용 페이지 복리후생 Education 항목) — 지원 한도·대상 과정 미기재', 30),

  -- ── 가족·돌봄 (family) — 복리후생 Education · Family 칸 / ESG 구성원 삶의질 향상 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', 200, 'family',
   'est', '자녀 학자금 지원 (공식 채용 페이지 복리후생 Education 항목), 자녀학비 지원 (ESG 구성원 삶의질 향상 페이지) — 지원 학교급·한도 미기재 (추정)', FALSE, NULL, 40),
  (@comp_id, 'event', '경조휴가·경조물품 지원', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 물품 지원 (공식 채용 페이지 복리후생 Family 항목) — 경조 종류별 휴가 일수·물품 미기재', 41),

  -- ── 여가·라이프 (leisure) — 복리후생 Family · Office Life 칸 / ESG 구성원 삶의질 향상 ──
  (@comp_id, 'resort', '리조트 회원권·숙박료 지원', 50, 'leisure',
   'est', '리조트 지원(대명, 한화 등 회원권 보유)·리조트 숙박료 지원 (공식 채용 페이지 복리후생 Family 항목), 숙박료 20% 지원 (영문 Benefits 페이지), 법인콘도 제공 (ESG 페이지) — 이용 횟수 미기재 (추정)', FALSE, NULL, 50),
  (@comp_id, 'club', '동호회 활동', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 (공식 채용 페이지 복리후생 Office Life 항목), 동호회 활동 지원 (영문 Benefits 페이지) — 지원 금액 미기재', 51),
  (@comp_id, 'library', '북카페·전자도서관', NULL, 'leisure',
   'est', NULL, TRUE, '북카페 운영, 전자도서관 운영 (공식 채용 페이지 복리후생 Office Life 항목)', 52),
  (@comp_id, 'leisure_room', '복지동', NULL, 'leisure',
   'est', NULL, TRUE, '복지동 운영(스쿼시, 스크린골프, 실내야구, 노래방 등) (공식 채용 페이지 복리후생 Office Life 항목)', 53),

  -- ── 보상·금전 (compensation) — 복리후생 Office Life 칸 / 인사제도 보상제도 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 (공식 채용 페이지 복리후생 Office Life 항목), 장기근속자 포상으로 노력과 공로 격려 (인사제도 페이지 보상제도) — 근속 기준·포상 내용 미기재', 60),
  (@comp_id, 'excellence_award', '공로상·우수사원·제안/특허 포상', NULL, 'compensation',
   'est', NULL, TRUE, '공로상/우수사원 포상 (공식 채용 페이지 복리후생 Office Life 항목), 모범사원 및 각종 제안과 특허에 대한 포상 (인사제도 페이지 보상제도) — 포상 기준·금액 미기재', 61),

  -- ── 근무환경 (work_env) — 복리후생 Office Life 칸 / ESG 구성원 삶의질 향상 ──
  (@comp_id, 'dormitory', '사내 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '사내 기숙사 운영 (공식 채용 페이지 복리후생 Office Life 항목), 기숙사 제공 (ESG 구성원 삶의질 향상 페이지) — 입주 조건·비용 부담 미기재', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
