-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 대상 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://www.daesang.com/kr/recruit/talented/welfare.jsp
-- badge: est
--
-- 참고:
--   정본 = 대상주식회사 자기 도메인 www.daesang.com 채용정보 인사제도 복리후생 페이지(SSR · 8개 칸 22개 항목 · 꼬리말 대상주식회사).
--     페이지 주어가 「대상그룹은」 이고 이 페이지에는 계열사별 상이 단서가 없다 → 이 페이지 근거 행은 출처 괄호 안
--     「, 대상그룹 공통 문구」 각주. 같은 목록이 그룹 통합 채용 사이트 career.daesang.com/ko/benefits 에도 있고
--     그쪽에는 「계열사 또는 근무지에 따라 일부 차이」 단서가 붙어 있다(근거표 판단 요청 1).
--   보조 1 = 대상㈜ 자기 발행 2026 지속가능경영보고서 국문 PDF(2026-08 생성 · 보고 기간 2025-01-01~12-31 · 일부 2026 상반기 ·
--     비재무 보고 범위 대상㈜ 본사) 52 · 57 · 58 · 59쪽 — 주어가 대상㈜는 인 문장만. 보고서 근거 행은 각주 없음.
--   보조 2 = 같은 도메인 인사제도 페이지(personnel_system.jsp · 주어 「대상은」) 영업부문 성과 배분제 1행.
--   공시 = 2026 반기보고서(정정 접수 20260911000415) · 2025 사업보고서(정정 접수 20260327000936) 유연근무제도 표 ·
--     별도 재무제표 주석 장기종업원급여 문장.
--   렌더 = 원본 HTML · PDF 텍스트 추출(PyMuPDF) · 헤드리스 렌더 없음 · 사이트 키 사용 없음.
--   금액: 금액 행 0(stated 0 · 추정 0) — 원문에 원 단위 금액 없음 · 식대 원문 없음.
--   제외: 출산전후휴가 90일 · 임신기 단축근무 · 배우자 출산휴가 20일 · 유산 사산 난임 휴가(일수 미기재) · 육아휴직 1년 ·
--     무급 가족 돌봄휴가 · 퇴직연금 DB · 재취업 지원 서비스(직원 5,106명 · 비자발적 이직자) · 미사용 휴가 금전 보상 ·
--     초과근무수당 · 보상휴가(법정) · 장기 Refresh 휴가와 연중휴가(보고서가 장기 연차 사용 독려로 설명) ·
--     최소 연속 5일 이상 휴가 사용 의무화(본인 휴가 사용) · 남성 육아휴직 장려(의무 아님) ·
--     직무 리더십 강화 교육 · 온보딩 · AX · 글로벌 · 전략전문가 과정(업무 교육) · 온라인 교육 시스템(법정 교육 문단) ·
--     인사이트 특강(직무 트렌드 학습) · WE대한상상 사내벤처(대응 코드 없음) · 임원 보수 칸 복리후생성 지원금과 특별격려금 ·
--     우리사주조합(주주 표 한 칸뿐) · 원격근무제(공시 세 기간 모두 사용자 없음) · 협력사 대상 복리후생 지원(다른 법인).
--   공고 근거 0행 / 전체 30행.
--   SORT 섹션 순서(정본 페이지에 처음 나온 순서): leisure 10 · perks 20 · family 30 · compensation 40 · flexibility 50 ·
--     health 60 · growth 70 · 보조 출처에만 있는 time_off 80 · work_env 90.
-- 검증 · 감사 판정 반영(2026-10-18): 그룹 단서 판정은 가능(그룹 각주) 유지(리드 판정 158) · 성과 배분제 incentive 에 2026 지속가능경영보고서 76쪽 성과급 산정 구절 추가 · parenting 이름에 법적 사항 외 살림 · 하계휴가 summer_leave 서술의 법조문 낱말 걷기 · 온라인 교육 시스템을 edu_support 에 병합 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 30행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('daesang', '대상',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품', 'D', 'https://www.daesang.com/kr/recruit/talented/welfare.jsp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'daesang');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.daesang.com/kr/recruit/talented/welfare.jsp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 여가 (leisure) — 정본 생활 복지 · 조직문화 칸 + 보고서 58쪽 ──
  (@comp_id, 'resort', '콘도 · 하계휴양소 운영', NULL, 'leisure',
   'est', NULL, TRUE, '콘도·하계휴양소 운영 (공식 홈페이지 채용정보 복리후생 생활·복지 항목, 대상그룹 공통 문구), 하계휴가를 활용해 연중 이용가능한 콘도 신청 · 여름철 한달 동안 하계 휴양소 운영 · 매년 약 300여 명의 임직원이 가족과 함께 방문 (2026 지속가능경영보고서 58쪽 하계휴가 및 하계 휴양소 프로그램 항목) — 이용 비용 지원 범위 미기재', 10),
  (@comp_id, 'club', '사내동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 활동 지원 (공식 홈페이지 채용정보 복리후생 조직문화 항목, 대상그룹 공통 문구) — 지원 금액·동호회 종류 미기재', 11),
  (@comp_id, 'culture_day', 'Culture Day', NULL, 'leisure',
   'est', NULL, TRUE, 'Culture Day (공식 홈페이지 채용정보 복리후생 조직문화 항목, 대상그룹 공통 문구) — 운영 주기·내용 미기재', 12),
  -- ── 생활 · 금융 · 주거 (perks) — 정본 생활 복지 · 포상 보상 · 근무편의 칸 + 보고서 52 · 59쪽 ──
  (@comp_id, 'housing_loan', '주택 · 생활안정자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택·생활안정자금 대출 (공식 홈페이지 채용정보 복리후생 생활·복지 항목, 대상그룹 공통 문구) — 대출 한도·이율·대상 미기재', 20),
  (@comp_id, 'discount', '정원이샵 · 웰라이프몰 직원할인', NULL, 'perks',
   'est', NULL, TRUE, '정원이샵, 웰라이프몰 직원할인 (공식 홈페이지 채용정보 복리후생 생활·복지 항목, 대상그룹 공통 문구) — 할인율·대상 품목 미기재', 21),
  (@comp_id, 'birthday_gift', '생일 선물 지급', NULL, 'perks',
   'est', NULL, TRUE, '생일 선물 지급 (공식 홈페이지 채용정보 복리후생 포상·보상 항목, 대상그룹 공통 문구) — 선물 내용·가액 미기재', 22),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 지원 (공식 홈페이지 채용정보 복리후생 포상·보상 항목, 대상그룹 공통 문구), 1년 이상 근속한 임직원 중 희망자가 개인연금 상품에 가입하면 회사가 납입금의 일정 비율 지원 (2026 지속가능경영보고서 59쪽 개인연금 지원 항목) — 지원 비율·한도 미기재', 23),
  (@comp_id, 'commute_subsidy', '출 · 퇴근 버스 지원', NULL, 'perks',
   'est', NULL, TRUE, '출·퇴근 버스 지원 (공식 홈페이지 채용정보 복리후생 근무편의 항목, 대상그룹 공통 문구) — 운행 사업장·노선 미기재', 24),
  (@comp_id, 'relocation', '타지역 전출 지원 제도', NULL, 'perks',
   'est', NULL, TRUE, '타지역 전출 지원 제도 운영 (공식 홈페이지 채용정보 복리후생 근무편의 항목, 대상그룹 공통 문구) — 지원 내용·금액 미기재', 25),
  (@comp_id, 'housing_support', '지방 사업장 근무 인력 주거비 지원', NULL, 'perks',
   'est', NULL, TRUE, '지방 사업장 근무 인력의 안정적인 확보를 위한 주거비 지원 제도 운영 (2026 지속가능경영보고서 52쪽 채용 전략 및 프로세스 항목) — 지원 금액·기간·대상 사업장 미기재', 26),
  (@comp_id, 'transport', '지방 사업장 근무 인력 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '지방 사업장 근무 인력의 안정적인 확보를 위한 교통비 지원 제도 운영 (2026 지속가능경영보고서 52쪽 채용 전략 및 프로세스 항목) — 지원 금액·방식·대상 사업장 미기재', 27),
  -- ── 가족 (family) — 정본 가족친화 칸 + 보고서 57 · 58쪽 ──
  (@comp_id, 'child_edu', '자녀학자금 지급', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금 지급 (공식 홈페이지 채용정보 복리후생 가족친화 항목, 대상그룹 공통 문구) — 지원 학령·한도 미기재', 30),
  (@comp_id, 'parenting', '입학축하금 · 임신 및 출산 축하선물 · 법적 사항 외 산전 휴가제도', NULL, 'family',
   'est', NULL, TRUE, '입학축하금 지급 (공식 홈페이지 채용정보 복리후생 가족친화 항목, 대상그룹 공통 문구), 법적 사항 외 산전 휴가제도 · 임신 및 출산 축하선물 지급 (2026 지속가능경영보고서 57쪽 GWP 프로그램 출산 및 육아 지원 항목), 산전 무급휴직 제도 운영 · 출산 축하선물 제공 (같은 보고서 58쪽 임신 및 출산지원 항목) — 축하금 금액·선물 내용·산전 휴가 일수 미기재', 31),
  (@comp_id, 'event', '경조금 및 경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금 및 경조휴가 지원 (공식 홈페이지 채용정보 복리후생 가족친화 항목, 대상그룹 공통 문구) — 경조 사유별 금액·휴가 일수 미기재', 32),
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '서울 종로사옥, 군산공장, 마곡연구소에 직장어린이집 운영 (2026 지속가능경영보고서 58쪽 직장어린이집 운영 항목) — 정원·이용 조건 미기재', 33),
  -- ── 보상 · 금전 (compensation) — 정본 가족친화 · 포상 보상 칸 + 공시 주석 + 인사제도 페이지 ──
  (@comp_id, 'holiday_gift', '가정의달 행복지원금 · 명절 · 창립기념 선물', NULL, 'compensation',
   'est', NULL, TRUE, '가정의달 행복지원금 지급 (공식 홈페이지 채용정보 복리후생 가족친화 항목, 대상그룹 공통 문구), 명절·창립기념 선물 지급 (공식 홈페이지 채용정보 복리후생 포상·보상 항목, 대상그룹 공통 문구) — 지원금 금액·선물 내용 미기재', 40),
  (@comp_id, 'long_service_bonus', '장기근속상 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속상 포상 (공식 홈페이지 채용정보 복리후생 포상·보상 항목, 대상그룹 공통 문구), 장기 근속 임직원에게 장기종업원급여 제공 · 주로 10년 이상 근무한 임직원 대상 · 지급 목적의 별도 사내근로복지기금 운영 (2025 사업보고서 재무제표 주석 종업원급여 항목) — 근속 기준별 포상 내용·금액 미기재', 41),
  (@comp_id, 'incentive', '성과 배분제 (영업부문)', NULL, 'compensation',
   'est', NULL, TRUE, '영업부문 성과 배분제 실시로 영업력 극대화 도모 (공식 홈페이지 채용정보 인사제도 성과 배분제 항목), 경영진과 유관부서 임직원의 공급망 ESG 관리 KPI 달성률을 연봉 및 성과급 산정에 활용 (2026 지속가능경영보고서 76쪽 공급망 ESG 관리 성과평가 항목) — 배분 기준·지급률 미기재', 42),
  -- ── 근무 유연성 (flexibility) — 정본 휴가 근무 칸 + 보고서 57 · 59쪽 + 공시 ──
  (@comp_id, 'flex_work', '부서별 시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '정시퇴근제 도입 이후 부서별 시차 출퇴근제 등 유연근무제도 병행 운영 (2026 지속가능경영보고서 59쪽 유연근무제 항목), 시차출퇴근제도 운영 (공식 홈페이지 채용정보 복리후생 휴가·근무 항목, 대상그룹 공통 문구), 시차출퇴근제 사용자 수 2026년 반기 291명 · 2025년 391명 (2026 반기보고서 · 2025 사업보고서 유연근무제도 항목) — 출퇴근 시간대·적용 부서 미기재', 50),
  (@comp_id, 'pc_off', 'PC-OFF 제도 · 정시퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF 제도 운영 · 매일 퇴근 시간 30분 전 알림 · 퇴근 시간이 되면 PC 자동 종료 (2026 지속가능경영보고서 59쪽 근로시간 및 초과근로 관리 항목), 정시퇴근제 실시 (같은 보고서 57쪽 GWP 프로그램 일과 삶의 균형 항목) — 적용 예외 기준 미기재', 51),
  (@comp_id, 'workation', '워크스테이 운영', NULL, 'flexibility',
   'est', NULL, TRUE, '워크스테이 운영 (공식 홈페이지 채용정보 복리후생 휴가·근무 항목, 대상그룹 공통 문구) — 운영 장소·기간·대상 미기재', 52),
  -- ── 건강 (health) — 정본 건강관리 칸 + 보고서 59쪽 ──
  (@comp_id, 'insurance', '단체상해보험 가입', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험가입 (공식 홈페이지 채용정보 복리후생 건강관리 항목, 대상그룹 공통 문구), 단체상해보험으로 임직원의 상해 및 질병, 입원 및 통원 치료 의료비 지원 · 보장 유형 2가지 중 필요에 따라 선택 (2026 지속가능경영보고서 59쪽 단체상해보험 가입 항목) — 보장 한도·가족 포함 여부 미기재', 60),
  (@comp_id, 'health_check', '종합건강검진 · 독감예방접종 지원', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진 제공, 독감예방접종 지원 (공식 홈페이지 채용정보 복리후생 건강관리 항목, 대상그룹 공통 문구) — 검진 주기·대상 범위·비용 지원 범위 미기재', 61),
  (@comp_id, 'mental', '웰니스 프로그램 Respect Stay', NULL, 'health',
   'est', NULL, TRUE, '멘탈 헬스와 웰니스를 위한 1박 2일 웰니스 프로그램 Respect Stay 운영 · 2025년 6월부터 2026년 1월까지 임직원 108명 대상 · 임직원의 휴식과 사색을 위한 공간 창혜원에서 진행 (2026 지속가능경영보고서 59쪽 웰니스 프로그램 항목) — 참여 대상 선정 방식·운영 주기 미기재', 62),
  -- ── 성장 · 교육 (growth) — 정본 교육 성장 칸 + 보고서 52쪽 ──
  (@comp_id, 'self_development', '자기계발 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기계발 교육 비용 지원 (공식 홈페이지 채용정보 복리후생 교육·성장 항목, 대상그룹 공통 문구) — 지원 한도·대상 과정 미기재', 70),
  (@comp_id, 'lang', '어학교육비 지원 · 어학교육 지원제도', NULL, 'growth',
   'est', NULL, TRUE, '어학교육비 지원 (공식 홈페이지 채용정보 복리후생 교육·성장 항목, 대상그룹 공통 문구), 어학교육 지원제도 (2026 지속가능경영보고서 52쪽 인재육성 제도 및 인프라 항목) — 지원 한도·대상 언어 미기재', 71),
  (@comp_id, 'edu_support', '사외교육 지원제도 · 온라인 교육 시스템', NULL, 'growth',
   'est', NULL, TRUE, '사외교육 지원제도 · 온라인 교육 시스템 (2026 지속가능경영보고서 52쪽 인재육성 제도 및 인프라 항목) — 지원 대상·범위·한도·수강 과정 미기재', 72),
  -- ── 휴가 (time_off) — 보고서 57 · 58쪽 ──
  (@comp_id, 'summer_leave', '하계휴가 4일', NULL, 'time_off',
   'est', NULL, TRUE, '연차휴가 외 별도로 하계휴가 4일 부여 (2026 지속가능경영보고서 58쪽 하계휴가 및 하계 휴양소 프로그램 항목) — 유급 여부·사용 시기 미기재', 80),
  (@comp_id, 'leave_general', '휴무예고제 (無一有二 Day) · 長 Up-Day', NULL, 'time_off',
   'est', NULL, TRUE, '법정휴일 외에도 연간 휴무일을 사전에 안내하는 휴무예고제 운영 · 無一有二 Day 로 전 임직원 휴무예고 기간을 연속 2일로 확대 (2026 지속가능경영보고서 58쪽 휴무예고제 항목), 직책자의 휴가 사용을 의무화하는 長 Up-Day 제도 운영 (같은 보고서 58쪽 長 Up-Day 항목) — 연차 사용일인지·일수·유급 여부 미기재', 81),
  -- ── 근무 환경 (work_env) — 보고서 57쪽 ──
  (@comp_id, 'lounge', '여성 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '여성 휴게실 운영 (2026 지속가능경영보고서 57쪽 GWP 프로그램 출산 및 육아 지원 항목) — 설치 사업장·규모 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
