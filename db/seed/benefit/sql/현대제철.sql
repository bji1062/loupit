-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대제철 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://hyundai-steel.recruiter.co.kr/career/benefit
-- badge: est
--
-- 참고:
--   정본은 현대제철 공식 채용 사이트(마이다스 잡플렉스 ATS — 기업 사이트 메뉴 인재채용이 링크) Benefits 페이지
--   /career/benefit 다. 제목 「현대제철 채용 | Benefits」. 본문은 robots 전면 금지 API 에서만 와서 자동 수집기가
--   읽지 못한다. 원문 = 사이트 운영자가 2026-10-02 브라우저로 페이지를 열어 붙여 넣은 화면 본문
--   (사본 hyundai_steel/user_paste_benefit_2026-10-02.txt · sha256 32b1e81e…9d65). 카드 15개.
--   보조 출처: 같은 법인 기업 사이트 지속가능경영 ESG 목록의 2026 지속가능경영보고서(국문 PDF, fileDownload/54871)
--     p.68 포상 제도 · p.70 상생의 노사관계 · p.71 주요 복리후생제도 · p.72 일과 삶의 균형 · p.77 임직원 건강증진,
--     2025 지속가능경영보고서(fileDownload/53434) p.77 · p.79. 보고서 근거 구절은 서술 괄호에 보고서 이름을 적어 구분했다.
--   귀속: 법인 단독 채용 사이트 · 법인 발행 보고서라 그룹 각주 없음. 현대자동차 · 기아 · 현대모비스 · 현대오토에버
--     정본 문장은 쓰지 않았다.
--   직군: 선택근무제 · PC 자동 제어는 원문이 일반·연구직 대상이라 서술에 적었다. 생산직 단협 수당은 원문에 복지 문장 없음.
--   금액: 원문 명시 1(fitness 체력단련비 80) · 원문 합산 2(holiday_gift 귀향여비 설 · 추석 각 80 → 160 ·
--     welfare_point 50 + 35 + 35 → 120) · 월액 환산 1(self_development 월 10만원 → 120, NOTE 에 환산) ·
--     구본 추정 승계 4(health_check 100 · child_edu 300 · commute_subsidy 120 · resort 50 — 전부 틀 값, NOTE 끝에 (추정)).
--     개인연금 3% · 할인율 · 의료비 비율 · 대출 원금 · 학자금 전액은 금액 칸에 넣지 않았다.
--   profit_sharing(2026-10-04 incentive 에서 재코딩 — 경영 성과급을 단독 제도로 밝힘)은 2026 보고서의 직원 성과급 문장(단체교섭 대상 · 육아휴직 기간 경영 성과급 지급 각주)으로 세웠다.
--   제외: Refresh 휴가(원문 괄호가 본인 휴가 5일 이상 사용 — 법정 휴가 사용) · Leader 휴가(이름뿐) · 법정 출산 · 육아 제도 ·
--     정년퇴직 예정자 교육(재취업 지원 서비스 — 1,000인 이상 법정).
--   구본에서 뺀 행: long_service_bonus (채용 사이트 · 보고서 모두 장기근속 포상 문장 없음).
--   재코딩: refresh_leave → summer_leave (구본 하기/리프레시 휴가 행 가운데 남는 제도는 유급 하기 휴가 5일).
--   SORT 섹션 순서 = 채용 사이트 Benefits 에서 카테고리가 처음 나온 순서, 보고서 근거 행은 해당 섹션 끝
--     (perks 10 · time_off 20 · family 30 · growth 40 · health 50 · compensation 60 · work_env 70 · leisure 80 ·
--     flexibility 90).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-4): 28행 전부 붙여넣기 원문 · 2026/2025 지속가능경영보고서와 글자 대조 · 합산 2행은 공식 수치(사용자 결정) · 최종 28행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(lang) · 재코딩 1(incentive → profit_sharing) — 최종 29행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_steel', '현대제철',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '철강', 'H', 'https://hyundai-steel.recruiter.co.kr/career/benefit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_steel');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://hyundai-steel.recruiter.co.kr/career/benefit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — Benefits 자동차 할인 · 개인연금 · 사내대출 · 복지포인트 · 통근버스 ──
  (@comp_id, 'discount', '현대/기아 자동차 할인', NULL, 'perks',
   'est', NULL, TRUE, '현대·기아 자동차 근속년수에 따라 9%~26% 할인(근속 2개월 이상 직원), 첫차 구매 시 20% 할인(근속 1년 이상 직원) (공식 채용 사이트 Benefits 현대/기아 자동차 할인 항목)', 10),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '직원이 3%, 회사가 3% 함께 쌓아가는 연금저축보험 (공식 채용 사이트 Benefits 개인연금 지원 항목) — 3%의 기준 금액 미기재', 11),
  (@comp_id, 'housing_loan', '사내대출 (주택구입·전세)', NULL, 'perks',
   'est', NULL, TRUE, '주택구입자금 1억원, 전세지원자금 5천만원 저금리 이자 지원 (공식 채용 사이트 Benefits 사내대출 항목) — 금리·상환 조건·대상 미기재', 12),
  (@comp_id, 'welfare_point', '선택형 복지포인트', 120, 'perks',
   'est', '설 복지포인트 50만원, 가정의 달(5월) 복지포인트 35만원, 휴양의 달(7월) 복지포인트 35만원 지급 (공식 채용 사이트 Benefits 귀향여비/선택형 복지포인트 지급 항목)', FALSE, NULL, 13),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '전 사업장 출퇴근 버스 운영 (공식 채용 사이트 Benefits 통근버스 항목) — 노선·본인 부담 미기재 (추정)', FALSE, NULL, 14),

  -- ── 시간·휴가 (time_off) — Benefits 휴가제도 ──
  (@comp_id, 'summer_leave', '하기 휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '하기 휴가 5일 (공식 채용 사이트 Benefits 휴가제도 항목), 유급 하기휴가 5일 부여 (2026 지속가능경영보고서 일과 삶의 균형 지원 휴가 제도 항목) — 사용 시기 미기재', 20),
  (@comp_id, 'leave_general', '승진 휴가·경조휴가', NULL, 'time_off',
   'est', NULL, TRUE, '승진 시 추가 휴가 5일 부여, 경조 사유별로 1~10일 경조휴가 (공식 채용 사이트 Benefits 휴가제도 항목)', 21),

  -- ── 가족·돌봄 (family) — Benefits 가족친화제도 · 자녀교육비 / 2026 보고서 출산지원 · 육아지원 ──
  (@comp_id, 'parenting', '육아휴직 최대 2년·휴직 중 경영 성과급', NULL, 'family',
   'est', NULL, TRUE, '육아휴직 2년 사용 (공식 채용 사이트 Benefits 가족친화제도 항목), 남녀 직원 모두 자녀 한 명당 최대 2년, 육아휴직 기간 내 경영 성과급 지급, 전 임직원(정규직·계약직 포함) 대상 (2026 지속가능경영보고서 주요 복리후생제도 육아지원 항목)', 30),
  (@comp_id, 'child_edu', '자녀교육비 지원', 300, 'family',
   'est', '자녀의 고등학교/대학교 입학금 및 등록금 전액 지원 (공식 채용 사이트 Benefits 자녀교육비 지원 항목) — 자녀 수 제한 미기재 (추정)', FALSE, NULL, 31),
  (@comp_id, 'fertility_support', '난임 치료 휴가 유급 5일', NULL, 'family',
   'est', NULL, TRUE, '난임 치료 휴가 유급 5일(법정 유급 2일에 3일 추가), 전 임직원(정규직·계약직 포함) 대상 (2026 지속가능경영보고서 주요 복리후생제도 출산지원 항목)', 32),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 설치 및 운영 (2026 지속가능경영보고서 육아지원 육아 지원 시설 운영 항목) — 운영 사업장·정원 미기재', 33),

  -- ── 성장·교육 (growth) — Benefits 자기계발지원금 ──
  (@comp_id, 'self_development', '자기계발 지원금', 120, 'growth',
   'est', '자기계발 지원금 매월 10만원 지급 (공식 채용 사이트 Benefits 자기계발지원금/체력단련비 지급 항목) — 월 10만원을 연 120만원으로 환산', FALSE, NULL, 40),
  (@comp_id, 'lang', '외국어 교육', NULL, 'growth',
   'est', NULL, TRUE, '전 임직원 대상 비즈니스 마인드와 외국어 구사 능력을 갖춘 글로벌 인재 육성을 위한 외국어 교육 (2026 지속가능경영보고서 65쪽 교육 체계 글로벌 항목) — 교육 형태·대상 어종·비용 부담 미기재', 41),

  -- ── 건강·의료 (health) — Benefits 체력단련비 · 의료지원 · 단체상해보험 · 사내 헬스장 / 2026 보고서 건강증진 ──
  (@comp_id, 'fitness', '체력단련비·사내 헬스장', 80, 'health',
   'est', '체력단련비 80만원 6월 지급, 사내 헬스장 및 사우나 운영 당진·인천·포항·순천 (공식 채용 사이트 Benefits 자기계발지원금/체력단련비 지급 · 사내 헬스장 운영 항목), 2025 지속가능경영보고서는 헬스장과 수영장 운영으로 기재', FALSE, NULL, 50),
  (@comp_id, 'health_check', '종합건강진단·PET-CT', 100, 'health',
   'est', '만 35세 이상 본인과 가족 1명 종합건강진단 (공식 채용 사이트 Benefits 의료지원 항목), 중증 질환 조기 발견 PET-CT 지원 (2026 지속가능경영보고서 건강검진 지원 항목) — 검진 비용 한도 미기재 (추정)', FALSE, NULL, 51),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '외래·입원비 건강보험급여 항목의 본인 부담금 지원, 본인 100%·가족 50% (공식 채용 사이트 Benefits 의료지원 항목) — 가족 범위·연간 한도 미기재', 52),
  (@comp_id, 'clinic', '사내 부속의원·물리치료실·한방의원', NULL, 'health',
   'est', NULL, TRUE, '사내 부속의원 운영 당진·인천·포항·순천 (공식 채용 사이트 Benefits 의료지원 항목), 물리치료실·운동처방실·한방의원·임상병리실 운영, 금연 프로그램·건강 체중 프로그램 운영 (2026 지속가능경영보고서 의료 지원·임직원 건강증진 항목)', 53),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '불의의 사고 시 보험금이 지급될 수 있도록 회사에서 상해보험 가입 및 보험료 납부 (공식 채용 사이트 Benefits 단체상해보험 항목) — 보장 범위·가족 포함 여부 미기재', 54),
  (@comp_id, 'mental', '심리상담센터', NULL, 'health',
   'est', NULL, TRUE, '사업장 내·외 심리상담센터와 비대면 정신건강센터 동시 운영 — 사내 마음의숲(판교)·그루터기(당진), 사외 인천·포항·순천·여수 상담센터, 온라인 비대면 상담 예약 (2026 지속가능경영보고서 정신건강 심리상담센터 항목)', 55),

  -- ── 보상·금전 (compensation) — Benefits 귀향여비 / 2026 보고서 포상 제도 · 노사관계 ──
  (@comp_id, 'holiday_gift', '명절 귀향여비', 160, 'compensation',
   'est', '설 귀향여비 80만원, 추석 귀향여비 80만원 지급 (공식 채용 사이트 Benefits 귀향여비/선택형 복지포인트 지급 항목)', FALSE, NULL, 60),
  (@comp_id, 'excellence_award', '혁신 리더상·챌린저상·모범사원상', NULL, 'compensation',
   'est', NULL, TRUE, '전사 차원 수시 포상 제도, 혁신적 아이디어로 회사 발전 및 경영 성과에 기여한 직원에 혁신 리더상, 10억원 이상의 성과에 대해 혁신성과 도전성 등을 종합 평가해 경제 효과 금액의 일부를 포상하는 챌린저상, 전사적 모범이 되는 우수 직원에 모범사원상, 본부별 특성 기반 포상 제도 자율 운영 (2026 지속가능경영보고서 포상 제도 항목) — 포상 금액 미기재', 61),
  (@comp_id, 'profit_sharing', '경영 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '경영 성과급 지급, 직원의 성과급은 교섭대표 노동조합과 매년 단체교섭으로 논의 및 결정 (2026 지속가능경영보고서 주요 복리후생제도 · 상생의 노사관계 항목) — 지급 기준·지급률 미기재', 62),

  -- ── 근무환경 (work_env) — Benefits 주거지원 / 2026 보고서 육아 지원 시설 ──
  (@comp_id, 'dormitory', '독신자 숙소', NULL, 'work_env',
   'est', NULL, TRUE, '독신자 숙소 운영 당진·포항·순천 (공식 채용 사이트 Benefits 주거지원 항목) — 입주 조건·비용 부담 미기재', 70),
  (@comp_id, 'nap_room', '모유 수유실', NULL, 'work_env',
   'est', NULL, TRUE, '사내 모유 수유실 설치 및 운영 (2026 지속가능경영보고서 육아지원 육아 지원 시설 운영 항목) — 운영 사업장 미기재', 71),

  -- ── 여가·라이프 (leisure) — Benefits 동아리 활동 지원 · 콘도/리조트 할인 ──
  (@comp_id, 'club', '동아리 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '취미 및 운동 등 다양한 동아리 활동 지원 (공식 채용 사이트 Benefits 동아리 활동 지원 항목) — 지원 금액 미기재', 80),
  (@comp_id, 'resort', '콘도/리조트 할인', 50, 'leisure',
   'est', '제주 해비치 호텔, 전국 리조트 할인가 적용 (공식 채용 사이트 Benefits 콘도/리조트 할인 항목) — 할인율·이용 횟수 미기재 (추정)', FALSE, NULL, 81),

  -- ── 근무 유연성 (flexibility) — 2026 보고서 일과 삶의 균형 지원 ──
  (@comp_id, 'flex_work', '선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '합리적이고 유연한 근로 시간 관리를 위해 스스로 근무시간을 선택하는 선택근무제, 일반·연구직 대상 (2026 지속가능경영보고서 일과 삶의 균형 지원 항목)', 90),
  (@comp_id, 'remote_work', '재택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '업무 몰입도 향상을 위한 자율적 근무 환경 조성 지원 재택근무제 (2026 지속가능경영보고서 일과 삶의 균형 지원 항목) — 대상·사용 일수 미기재', 91),
  (@comp_id, 'pc_off', 'PC 자동 제어', NULL, 'flexibility',
   'est', NULL, TRUE, '초과근무 관리 자동 PC 제어 프로그램 적용, 일정 수준 이상 초과근로가 예상되는 직원은 본인과 상위 관리자에게 메일 알림, 일반·연구직 대상 (2025·2026 지속가능경영보고서 일과 삶의 균형 지원 항목)', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
