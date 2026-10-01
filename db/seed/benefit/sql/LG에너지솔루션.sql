-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG에너지솔루션 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://www.lgensol.com/kr/career/system-welfare-benefits
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 법인 자기 도메인 www.lgensol.com 의 인재채용 > 인사제도 > 복리후생 페이지(/kr/career/system-welfare-benefits).
--     서버 렌더 HTML 에 복리후생 절(선택적 복리후생 · 주거 및 생활안전 지원 · 의료 및 건강증진 · 여가활동 · 일-가정 양립 지원 ·
--     우리사주제도 · 퇴직지원제도)이 그대로 있다 — 헤드리스 불필요. HTML 주석 안 블록은 쓰지 않았다(복리후생 S/E 표지 주석 사이의 본문만).
--     robots.txt = User-agent: * / Allow: / / Disallow: /lgbadm/ 뿐(2026-10-01 확인). 본문 sha256 8a73fb88…b02e31b5.
--   보조 1 = 같은 도메인 인사원칙 페이지(/kr/career/personnel-principle) 보상제도 절 — 경영성과급 · 정기인센티브 · 수시인센티브.
--   보조 2 = 같은 도메인 소통 문화 페이지(/kr/career/culture-communication) — Thank you, ENSOL · EnTalk 개선 사례.
--   보조 3 = LG에너지솔루션 ESG REPORT 2025 국문 PDF(같은 도메인 /upload/file/download/, 167쪽, 생성 2026-09-28) p.88 · 101 · 103 · 104 · 105 · 106 · 107.
--   보조 4 = 같은 도메인 뉴스룸 보도자료 seq 8552(2023-06-12 키즈&SOL어린이집 개원) · seq 8445(2022-01-03 조직문화 혁신 방안).
--   LG 그룹 계열이나 출처가 전부 LG에너지솔루션 법인 자기 문서라 그룹 통합 각주 없음. LG화학 · LG · LG유플러스 행은 섞지 않았다.
--     그룹 통합 채용 careers.lg.com 은 요청하지 않았다(법인 자기 도메인에 정본이 있다).
--   법정 제도 제외(직원 12,922명 — 1,000인 이상): 퇴직지원제도(만 50세 이상 비자발퇴직자 재취업 교육 = 고령자고용법 재취업지원서비스) ·
--     출산전후 휴가 · 배우자 출산휴가 · 임신기 단축 · 육아기 단축 · 모성보호 휴가(태아 검진) · 유사산 휴가 · 수유시간 · 난임 휴가 6일 ·
--     가족돌봄휴가 10일 · 가족돌봄휴직 90일 · 4대 보험 · 퇴직연금. 육아휴직은 회사 상회분(최대 2년 · 한부모 등 2년 6개월)만.
--   금액: 원문 명시 연 금액 0건. 구본 추정치 승계 4행(welfare_point 200 · health_check 100 · medical 100 · resort 50 — 같은 값을
--     추정치로 쓴 다른 회사 3곳 이상인 틀 값, NOTE 끝 (추정)). 미승계: child_edu 300(구본 공식 수치 — 원문에 숫자 없음) ·
--     event 50(1회성 경조금) · incentive 500(원문은 경영성과급을 따로 둔 다른 구조) · fitness 30(회사 고유값, 전제인 건강증진비가 원문에 없음).
--     출산축하금 100만원은 1회성이라 금액 칸에 넣지 않았다.
--   재코딩 1: summer_leave → refresh_leave(원문 리프레쉬휴가 5일, 하계 표기 없음). 구본 edu_support(회사 주도 교육 과정) 삭제.
--   구본 housing_loan 의 공장 사택 · 기숙사는 dormitory 로 나눴다. 신규 코드 0.
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서
--     (perks 10 · work_env 20 · family 30 · health 40 · flexibility 50 · time_off 60 · leisure 70 · compensation 80 · growth 90).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-2): leave_general 월말휴무 삭제(일수·유급 여부가 없어 법정 휴가 사용일과 가를 수 없음) · 나머지 30행 원문 확인 · 승계 추정 4행 유지(이 법인 옛 데이터) — 최종 30행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_energy', 'LG에너지솔루션',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '배터리', 'L', 'https://www.lgensol.com/kr/career/system-welfare-benefits');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_energy');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lgensol.com/kr/career/system-welfare-benefits'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ── 복리후생 페이지 선택적 복리후생 · 주거 및 생활안전 지원 · ESG 보고서 p.107
  (@comp_id, 'welfare_point', '선택적 복리후생', 200, 'perks',
   'est', '개인에게 지급된 복지 포인트를 건강증진 · 자기계발 · 여가&생활 · 복지매장(e-shop) 4개 항목 중 자율 선택해 사용 (공식 채용 페이지 복리후생 선택적 복리후생 항목 — 포인트 금액 미기재) (추정)', FALSE, NULL, 10),
  (@comp_id, 'housing_loan', '주택자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택구입자금 및 전세자금 지원 (공식 채용 페이지 복리후생 주거 및 생활안전 지원 항목 — 지원 방식 · 한도 · 이율 미기재)', 11),
  (@comp_id, 'housing_support', '지방사업장 주거 지원', NULL, 'perks',
   'est', NULL, TRUE, '오창 · 대전 신규입사자 월세 지원 (공식 채용 페이지 복리후생 지방사업장 주거 지원 항목 — 지원 금액 · 기간 미기재)', 12),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 가입자에게 매월 회사부담금 지원 (2025 ESG 보고서 107쪽 노후 및 재무 안정 지원 — 회사부담금 금액 미기재)', 13),

  -- ── 근무환경 (work_env) ── 복리후생 페이지 주택자금 지원 · 일-가정 양립 지원 · ESG 보고서 p.103
  (@comp_id, 'dormitory', '사택 · 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '공장 근무자 사택 · 기숙사 제공 (공식 채용 페이지 복리후생 주택자금 지원 항목 — 입주 조건 · 비용 부담 미기재)', 20),
  (@comp_id, 'nap_room', '모유수유실', NULL, 'work_env',
   'est', NULL, TRUE, '사업장 내 모유수유실 운영 (공식 채용 페이지 복리후생 일-가정 양립 지원 항목)', 21),
  (@comp_id, 'lounge', '힐링공간 엔트럴파크', NULL, 'work_env',
   'est', NULL, TRUE, '임직원 소통 및 힐링공간 「엔트럴파크」 운영 (2025 ESG 보고서 103쪽 심신 Wellness 지원 — 위치 · 시설 구성 미기재)', 22),

  -- ── 가족·돌봄 (family) ── 복리후생 페이지 경조금 · 자녀출산/입학선물 · 결혼 경비 · 학자금 · 일-가정 양립 지원
  (@comp_id, 'event', '경조금 · 결혼 경비 지원', NULL, 'family',
   'est', NULL, TRUE, '본인 · 가족 결혼, 회갑 등 각종 경조사 경조금 및 경조 휴가 부여, 국내 신혼여행 경비 지원 (공식 채용 페이지 복리후생 경조금 지원 · 결혼 경비 지원 항목 — 경조금 금액 · 휴가 일수 미기재)', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '중 · 고 · 대학 자녀의 학자금 지원 (공식 채용 페이지 복리후생 학자금 지원 항목 — 지원 한도 · 자녀 수 기준 미기재)', 31),
  (@comp_id, 'parenting', '임신 · 출산 · 육아 지원', NULL, 'family',
   'est', NULL, TRUE, '육아휴직 최대 2년(유급 육아휴직 1년 및 추가 휴직 1년, 한부모 가정 등 특정 사유 시 최대 2년 6개월), 임신 직원 안정적 출산을 위한 임신 휴직 10개월, 자녀 입양 시 유급휴가, 자녀 출산 시 출산축하금 100만원과 출산 선물, 초 · 중 · 고 · 대학 입학 및 초등 4학년 진학 자녀 학습 지원 선물 (공식 채용 페이지 복리후생 자녀출산/입학선물 · 일-가정 양립 지원 항목, 2025 ESG 보고서 107쪽)', 32),
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '국내 사업장 내 근무지 소속 임직원 자녀를 위한 어린이집 운영 — 본사 으쓱(ESG)엔솔키즈 어린이집, 오창 에너지플랜트 키즈&SOL 어린이집 (공식 채용 페이지 복리후생 직장어린이집 운영 항목, 2025 ESG 보고서 107쪽)', 33),
  (@comp_id, 'fertility_support', '난임 휴직 · 치료비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 진단을 받은 직원에게 휴직 6개월 부여, 난임 치료비 지원 및 난임 관련 비급여 항목(유산방지제 주사료) 지원 (공식 채용 페이지 복리후생 일-가정 양립 지원 항목, 2025 ESG 보고서 104 · 105 · 107쪽 — 치료비 지원 한도 미기재)', 34),

  -- ── 건강·의료 (health) ── 복리후생 페이지 의료 및 건강증진 · ESG 보고서 p.88 · p.103
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인 및 배우자, 자녀, 부모 의료비 지원 (공식 채용 페이지 복리후생 의료 및 건강증진 항목 — 지원 비율 · 한도 미기재) (추정)', FALSE, NULL, 40),
  (@comp_id, 'health_check', '종합건강진단', 100, 'health',
   'est', '만 35세 이상 또는 근속 5년 이상 본인(1년 1회) 및 배우자(2년 1회) 건강진단 실시 (공식 채용 페이지 복리후생 의료 및 건강증진 항목 — 검진 비용 한도 미기재) (추정)', FALSE, NULL, 41),
  (@comp_id, 'clinic', '건강관리실 · 부속의원', NULL, 'health',
   'est', NULL, TRUE, '국내외 사업장 내 건강관리실 및 부속 의료원 운영, 임직원 건강증진활동 및 1차 진료 지원 — 본사 · 오창 에너지플랜트 1 · 기술연구원(대전) 부속의원, 건강진단 유소견자 전문의 1:1 상담 (공식 채용 페이지 복리후생 의료 및 건강증진 항목, 2025 ESG 보고서 88쪽)', 42),
  (@comp_id, 'mental', '심리상담실', NULL, 'health',
   'est', NULL, TRUE, '사내 심리상담실 마음그린 심리상담실 운영, 가족지원 프로그램으로 초등학교 자녀 육아 상담과 배우자 상담 및 부부 상담 지원 (공식 채용 페이지 복리후생 심리상담실 가족지원 프로그램 항목, 2025 ESG 보고서 88쪽)', 43),
  (@comp_id, 'fitness', 'GX 프로그램', NULL, 'health',
   'est', NULL, TRUE, '요가 · 필라테스 · 명상 등 다양한 GX 프로그램 지원 (2025 ESG 보고서 103쪽 심신 Wellness 지원 — 운영 사업장 · 이용 비용 미기재)', 44),

  -- ── 근무유연성 (flexibility) ── 복리후생 페이지 근무시간/휴가제도 · ESG 보고서 p.106
  (@comp_id, 'flex_work', '유연근무제(Flextime)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제(Flextime) 실시 — 임직원 스스로 출퇴근 시간을 정하는 완전 Flextime 제도 (공식 채용 페이지 복리후생 근무시간/휴가제도 항목, 2022-01-03 공식 보도자료)', 50),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '전사 배포된 원격근무 가이드를 기반으로 한 재택근무 운영 (2025 ESG 보고서 106쪽 자율근무 문화 — 적용 직군 · 사용 횟수 미기재)', 51),
  (@comp_id, 'satellite_office', '거점 오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '국내 주요 공유 오피스 운영사와의 계약으로 거점 오피스 지점 확보 (2025 ESG 보고서 106쪽 자율근무 문화 — 지점 수 · 이용 조건 미기재)', 52),

  -- ── 시간·휴가 (time_off) ── 복리후생 페이지 근무시간/휴가제도 · ESG 보고서 p.106
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '리프레시 휴가 5일 실시 (공식 채용 페이지 복리후생 근무시간/휴가제도 항목 — 사용 시기 · 유급 여부 미기재)', 60),
  (@comp_id, 'foundation_day_leave', '창립기념일 · 노조창립기념일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '창립기념일, 노조창립기념일 휴가 (공식 채용 페이지 복리후생 근무시간/휴가제도 항목)', 61),

  -- ── 여가·라이프 (leisure) ── 복리후생 페이지 휴양시설 운영 · 사내 동호회 · ESG 보고서 p.103
  (@comp_id, 'resort', '법인 콘도', 50, 'leisure',
   'est', '임직원(가족) 이용 가능한 법인 콘도 운영 (공식 채용 페이지 복리후생 휴양시설 운영 항목 — 콘도 위치 · 이용 횟수 · 비용 부담 미기재) (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '산악회, 음악동호회, 볼링회 등 사업장별 동호회 운영 및 지원 (공식 채용 페이지 복리후생 사내 동호회 항목 — 지원 금액 미기재)', 71),
  (@comp_id, 'company_event', '가족 초청 · 가족 Care 활동', NULL, 'leisure',
   'est', NULL, TRUE, '가족 및 지인 회사 초청(연간 1만여 명 방문), 임직원 자녀 수능 격려 등 가족 생애주기별 Care 활동, 가정의 달 토토가 행사, 주요 시즌별 공연 · 강연 · 이벤트 (2025 ESG 보고서 103쪽 임직원 프라이드 제고 Care 활동)', 72),

  -- ── 보상·금전 (compensation) ── 복리후생 페이지 우리사주제도 · 인사원칙 페이지 보상제도 · 소통 문화 페이지
  (@comp_id, 'stock_option', '우리사주제도', NULL, 'compensation',
   'est', NULL, TRUE, '엘지에너지솔루션 우리사주조합 운영 — 가입 대상은 근로복지기본법상 가입 제한 근로자(등기임원, 최대주주, 일용직 등)를 제외한 계약직 포함 모든 근로자 (공식 채용 페이지 우리사주제도 항목)', 80),
  (@comp_id, 'profit_sharing', '경영성과급', NULL, 'compensation',
   'est', NULL, TRUE, '회사의 경영성과(재무성과 및 경쟁성과 등)에 따른 보상 (공식 채용 페이지 인사원칙 보상제도 항목 — 지급 기준 · 지급률 미기재)', 81),
  (@comp_id, 'incentive', '정기 · 수시 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '개인 평가 결과에 따른 차등 보상인 정기인센티브(Personal Incentive)와 개인의 성과 창출 시점에 즉시 보상하는 수시인센티브(On-Spot Incentive) (공식 채용 페이지 인사원칙 보상제도 항목 — 지급률 미기재)', 82),
  (@comp_id, 'excellence_award', '칭찬 격려 프로그램 Thank you, ENSOL', NULL, 'compensation',
   'est', NULL, TRUE, '전 임직원이 매년 12개의 Energy 를 받아 고마운 동료에게 메시지와 함께 보내고, 본인이 받은 Energy 는 1개당 1만 원으로 정산 (공식 채용 페이지 소통 문화 항목, 2025 ESG 보고서 106쪽 — 받는 개수에 따라 정산액이 달라짐)', 83),

  -- ── 성장·커리어 (growth) ── ESG 보고서 p.101
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '소속 조직이나 현재 업무와 연관된 직무 관련 자격증 취득 지원 — 안전관리 · 소방 · 환경 · 보건 · 위험물 · 전기 · 에너지 분야의 기능사 · 기사 · 산업기사 · 기능장 · 기술사와 품질 · 기계 등 업무상 필수 분야 (2025 ESG 보고서 101쪽 자격증 취득 지원 제도 — 지원 방식 · 금액 미기재)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
