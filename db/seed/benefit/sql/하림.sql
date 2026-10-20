-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 하림 복리후생 데이터 (신규 회사 — 웨이브 13)
-- 출처: AI 파싱 (2026-10-20)
-- URL: https://www.harim.com/main/?menu=116
-- badge: est
--
-- 참고:
--   정본은 하림 자기 도메인 www.harim.com 헤더 메뉴 채용정보 → 복리후생 페이지(/main/?menu=116)의 10칸 목록이다.
--   서버 렌더 HTML 에 항목 본문이 그대로 있다(헤드리스 렌더 없음). 꼬리말 법인명 (주)하림 · 익산시 망성면 망성로 14.
--   robots 는 Disallow / + Allow /main/ 이라 /main/ 아래만 받았다.
--   보조 출처: 자기 도메인 ESG 평가 자료실의 2025 지속가능경영보고서(2026-06-30 게시 · 보고 기간 2025-01~12 · 보고 범위 하림 본사와 지점 ·
--     하림 단독 발행) 73쪽 유연근무제도 · 72쪽 인권 리스크 대응전략 · 75쪽 복리후생제도 표 · 90쪽 임직원 건강관리 ·
--     하림그룹 채용 사이트 harimcareers.com 의 하림 전용 복리후생 페이지(/harimholdings/page/user/harim/benefit — 경로 · 꼬리말이 하림 법인,
--     형제 올품 페이지와 항목 구성이 달라 템플릿 아님) 15칸 · 2025 사업보고서 · 2026 반기보고서(정정) 공시는 복지 행 근거 없음.
--   귀속: 정본 · 보고서는 하림 단독 도메인 · 단독 발행이고 채용 사이트 페이지는 하림 법인 전용 페이지라 각주 없음.
--     지주 하림지주(harimgroup.com) 페이지 · 그룹 공통 문장은 쓰지 않았다. 기등록 형제 팬오션과 겹치는 문장 없음.
--   금액: 추정 1(meal 하루 2끼 576 — 중식 제공 · 중 석식비 지원). 나머지 NULL(금액 원문 없음).
--   제외: 법정(생리휴가 · 출산 전후 휴가 90일 · 임신기 단축근무 · 육아휴직 · 일반 · 특수 건강진단 · 유소견자 상담 · 퇴직연금 · 법정 의무 교육 ·
--     퇴직예정자과정) · 업무 교육(직무 · 리더십 · 신입사원 집체교육 · 사내특강) · 급여성 수당(직책 · 자격증 수당) · 영업 일비 ·
--     안전 교육 · 비상 대피 훈련 · 금연 캠페인 · 외국인 근로자 상담 창구 · 퇴직 특별위로금(재량) · 사내 마켓(혜택 내용 없음).
--   공고 근거 0행 / 전체 29행.
--   SORT 섹션 순서 = 정본 페이지에 카테고리가 처음 나온 순서(leisure 10 · work_env 20 · family 30 · perks 40 · health 50 ·
--     compensation 60), 보조 출처에만 있는 growth 70 · flexibility 80.
-- 검증 · 감사 판정 반영(2026-10-20): 81쪽 보상 문단의 직급별 평가 연간 성과 상여를 incentive 이름과 서술로 · 초과이익 배분 profit_sharing · 퇴직 특별위로금 severance_plus (특별 사유 시) 추가 · 사내 카페 및 마켓 운영을 snack_bar 에 병합 · 27쪽 자기계발 지원을 edu_support 에 병합 · 신규 코드 laundry 유지 · 항목 페이지 예외 2(통합 밖 리드 집행) · 참고 블록 제외 줄의 퇴직 특별위로금과 사내 마켓은 이 판정으로 뒤집힘 — 최종 31행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('harim', '하림',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품', 'H', 'https://www.harim.com/main/?menu=116');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'harim');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.harim.com/main/?menu=116'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 여가 (leisure) — 정본 · 보고서 75쪽 · 채용 사이트 ──
  (@comp_id, 'club', '사내 동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '직원 상호 간의 친목 도모와 명랑한 직장 분위기 조성을 위해 동호회 활동 지원 (공식 홈페이지 채용정보 복리후생 동호회활동 항목), 사내 동호회 활동 지원 (2025 지속가능경영보고서 75쪽 복리후생제도 취미/여가/교육 지원 항목) — 지원 금액·동호회 종류 미기재', 10),
  (@comp_id, 'summer_vacation_subsidy', '하기 휴가비 지급', NULL, 'leisure',
   'est', NULL, TRUE, '하기 휴가 시 전 사원들에게 휴가비 지원 (공식 홈페이지 채용정보 복리후생 휴가비 지급 항목), 휴가비 지급 (공식 채용 사이트 하림 복리후생 항목) — 지급 금액 미기재', 11),
  (@comp_id, 'resort', '콘도 운영 · 휴양시설 지원', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 운영 (공식 홈페이지 채용정보 복리후생 항목), 법인 리조트 및 호텔 등 휴양시설 지원 (2025 지속가능경영보고서 75쪽 복리후생제도 취미/여가/교육 지원 항목) — 이용 횟수·비용 지원 범위 미기재', 12),
  (@comp_id, 'company_event', '체육행사 · 월별 사내 이벤트', NULL, 'leisure',
   'est', NULL, TRUE, '체육행사 (공식 홈페이지 채용정보 복리후생 기타 항목), 월별 사내 이벤트 (2025 지속가능경영보고서 75쪽 복리후생제도 기타 지원 항목) — 행사 내용·참가 대상 미기재', 13),
  (@comp_id, 'culture_day', '문화의 날 문화 활동비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '문화의 날 문화 활동비 지원 (2025 지속가능경영보고서 75쪽 복리후생제도 기타 지원 항목) — 지원 금액·주기 미기재', 14),
  (@comp_id, 'welcome_kit', '신입사원 웰컴키트 지급', NULL, 'leisure',
   'est', NULL, TRUE, '신입사원 웰컴키트 지급 (공식 채용 사이트 하림 복리후생 항목) — 구성품 미기재', 15),
  -- ── 근무 환경 (work_env) — 정본 · 채용 사이트 · 보고서 75쪽 ──
  (@comp_id, 'dormitory', '기숙사 · 사택 운영', NULL, 'work_env',
   'est', NULL, TRUE, '사원들의 편의를 위해 기숙사 운영 (공식 홈페이지 채용정보 복리후생 기숙사 항목), 사택 운영 (공식 채용 사이트 하림 복리후생 항목) — 입주 자격·비용 부담 미기재', 20),
  (@comp_id, 'lounge', '휴게 공간 제공', NULL, 'work_env',
   'est', NULL, TRUE, '휴게 공간 제공 (2025 지속가능경영보고서 75쪽 복리후생제도 기타 지원 항목) — 위치·시설 구성 미기재', 21),
  -- ── 가족 (family) — 정본 · 보고서 75쪽 · 채용 사이트 ──
  (@comp_id, 'event', '경조사 지원 (경조휴가 · 경조비)', NULL, 'family',
   'est', NULL, TRUE, '애경사 시 특별 휴가 및 경조비 지급 (공식 홈페이지 채용정보 복리후생 경조사 지원 항목), 경조사 지원 (2025 지속가능경영보고서 75쪽 복리후생제도 기타 지원 항목) — 경조 유형별 금액·휴가 일수 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금지원 (공식 홈페이지 채용정보 복리후생 항목), 자녀 학자금 지원 (2025 지속가능경영보고서 75쪽 복리후생제도 생활 지원 항목) — 지원 학령·금액 미기재', 31),
  (@comp_id, 'parenting', '영유아 자녀 보육위탁비용 · 수능 자녀 선물', NULL, 'family',
   'est', NULL, TRUE, '영유아 자녀 보육위탁비용 지원 (2025 지속가능경영보고서 75쪽 복리후생제도 생활 지원 항목), 수능 자녀 선물 (공식 채용 사이트 하림 복리후생 항목) — 지원 금액·선물 내용 미기재', 32),
  -- ── 생활 · 편의 (perks) — 정본 · 보고서 75쪽 · 채용 사이트 ──
  (@comp_id, 'commute_subsidy', '통근버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 편의를 제공하기 위해 통근버스 운행 (공식 홈페이지 채용정보 복리후생 통근버스 운영 항목), 출퇴근 통근버스 운영 (2025 지속가능경영보고서 75쪽 복리후생제도 기타 지원 항목) — 운행 노선·사업장 미기재', 40),
  (@comp_id, 'meal', '중식 제공 · 중·석식비 지원', 576, 'perks',
   'est', '하림의 맛있는 중식제공 (공식 홈페이지 채용정보 복리후생 항목), 중·석식비 지원 (2025 지속가능경영보고서 75쪽 생활 지원 항목) — 1끼 단가 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 41),
  (@comp_id, 'laundry', '세탁소 운영', NULL, 'perks',
   'est', NULL, TRUE, '세탁소 운영 (공식 홈페이지 채용정보 복리후생 기타 항목) — 이용 대상·비용 부담 미기재', 42),
  (@comp_id, 'telecom', '통신비 지원 (영업 사원 · 부서장)', NULL, 'perks',
   'est', NULL, TRUE, '영업 사원 및 부서장 통신비 지원 (2025 지속가능경영보고서 75쪽 복리후생제도 생활 지원 항목) — 지원 금액 미기재', 43),
  (@comp_id, 'discount', '제휴업체 할인 · 사내판매 운영', NULL, 'perks',
   'est', NULL, TRUE, '제휴업체(호텔 및 병원기관 등) 할인 혜택 제공 (2025 지속가능경영보고서 75쪽 복리후생제도 취미/여가/교육 지원 항목), 사내판매 운영 (공식 채용 사이트 하림 복리후생 항목) — 할인율·판매 품목 미기재', 44),
  (@comp_id, 'team_dinner', '부서별 복리후생비 지원', NULL, 'perks',
   'est', NULL, TRUE, '부서별 복리후생비 지원 (2025 지속가능경영보고서 75쪽 복리후생제도 기타 지원 항목) — 지원 금액·사용 용도 미기재', 45),
  (@comp_id, 'birthday_gift', '생일 축하금 지원', NULL, 'perks',
   'est', NULL, TRUE, '생일 축하금 지원 (2025 지속가능경영보고서 75쪽 복리후생제도 기타 지원 항목), 생일자 축하금 지원 (공식 채용 사이트 하림 복리후생 항목) — 지급 금액 미기재', 46),
  (@comp_id, 'snack_bar', '사내 카페 · 마켓 운영', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페 및 마켓 운영 (2025 지속가능경영보고서 75쪽 복리후생제도 기타 지원 항목) — 이용 요금·운영 사업장·판매 품목 미기재', 47),
  -- ── 건강 (health) — 정본 · 보고서 75 · 90 · 72쪽 ──
  (@comp_id, 'clinic', '사내 한방 진료실 · 건강관리실', NULL, 'health',
   'est', NULL, TRUE, '사내 한방 진료실 및 건강관리실 운영 (공식 홈페이지 채용정보 복리후생 의료지원 항목), 건강관리실 운영 간호사 상주 익산 신선식품공장·가공식품공장, 정읍 가공공장 (2025 지속가능경영보고서 90쪽 임직원 건강관리 항목) — 진료 과목·이용 시간 미기재', 50),
  (@comp_id, 'health_check', '건강검진 지원 (연 1회)', NULL, 'health',
   'est', NULL, TRUE, '건강검진 지원 (연 1회) (2025 지속가능경영보고서 75쪽 복리후생제도 생활 지원 항목) — 검진 항목·비용 지원 범위 미기재', 51),
  (@comp_id, 'fitness', '운동 공간 제공', NULL, 'health',
   'est', NULL, TRUE, '운동 공간 제공 (2025 지속가능경영보고서 75쪽 복리후생제도 기타 지원 항목) — 위치·운동 시설 구성 미기재', 52),
  (@comp_id, 'mental', '심리상담 프로그램', NULL, 'health',
   'est', NULL, TRUE, '성희롱 리스크 대응전략의 심리상담 프로그램 제공 (2025 지속가능경영보고서 72쪽 주요 인권 리스크 및 대응 전략 항목) — 이용 대상·상담 방식 미기재', 53),
  -- ── 보상 (compensation) — 정본 · 채용 사이트 · 보고서 75쪽 ──
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (공식 홈페이지 채용정보 복리후생 기타 항목), 장기근속 포상 (공식 채용 사이트 하림 복리후생 항목) — 근속 기준·포상 내용 미기재', 60),
  (@comp_id, 'holiday_gift', '명절 · 노동절 · 창립기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 및 노동절, 창립기념일 선물 지급 (2025 지속가능경영보고서 75쪽 복리후생제도 기타 지원 항목) — 선물 내용·금액 미기재', 61),
  (@comp_id, 'incentive', '연간 성과 상여 · 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '직급별 평가 결과에 따라 연간 성과 상여 지급 (2025 지속가능경영보고서 81쪽 보상 항목), 인센티브 (같은 보고서 75쪽 복리후생제도 기타 지원 수당 제도 운영 항목) — 지급 기준·지급률 미기재', 62),
  (@comp_id, 'profit_sharing', '초과이익 배분', NULL, 'compensation',
   'est', NULL, TRUE, '매년 회사의 경영목표 달성과 성과에 따른 초과이익을 임직원에게 배분 (2025 지속가능경영보고서 81쪽 보상 항목) — 배분 기준·지급률 미기재', 63),
  (@comp_id, 'severance_plus', '퇴직 특별위로금 (특별 사유 시)', NULL, 'compensation',
   'est', NULL, TRUE, '회사에 현저한 공적이 있거나 업무상 상병 등 특별한 사유가 있는 경우 퇴직 시 별도의 특별위로금 지급 (2025 지속가능경영보고서 81쪽 인재경영 항목) — 지급 기준·금액 미기재', 64),
  -- ── 성장 (growth) — 보고서 75쪽 · 채용 사이트 ──
  (@comp_id, 'edu_support', '임직원 교육비 지원 · 온라인 교육 플랫폼', NULL, 'growth',
   'est', NULL, TRUE, '임직원 교육 프로그램 운영 및 교육비 지원 (2025 지속가능경영보고서 75쪽 복리후생제도 취미/여가/교육 지원 항목), 온라인 교육 플랫폼 제공 (공식 채용 사이트 하림 복리후생 항목), 자기계발 지원 (같은 보고서 27쪽 임직원 고용 및 복리후생 항목) — 교육비 지원 범위·수강 과정 미기재', 70),
  -- ── 근무 유연성 (flexibility) — 보고서 73쪽 ──
  (@comp_id, 'flex_work', '유연근무제도 (탄력적 근로시간제 · 시차 출퇴근제)', NULL, 'flexibility',
   'est', NULL, TRUE, '탄력적 근로시간제 업무량 증감에 따라 1일 근로시간을 사전 설정, 시차 출퇴근제 소정근로시간을 유지하고 출퇴근시각을 변경 근무 유형 구성원 자녀의 양육 목적 (2025 지속가능경영보고서 73쪽 유연근무제도 항목) — 적용 부서·신청 조건 미기재', 80),
  (@comp_id, 'remote_work', '재택근무제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '재택 근무제 상황에 따라 장소 제약 없이 근무장소 설정 근무 유형 건강관리가 필요한 직원(임산부 등) (2025 지속가능경영보고서 73쪽 유연근무제도 항목) — 사용 기간·신청 절차 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
