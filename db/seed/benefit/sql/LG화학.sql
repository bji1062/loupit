-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG화학 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://www.lgchem.com/career/life/care
-- badge: est
--
-- 참고:
--   정본은 LG화학 법인 자기 도메인 www.lgchem.com 의 CAREERS > Life > Care 페이지(/career/life/care)다.
--   Care 는 복리후생 12항목(의료비 · 선택적 복리후생 · 건강 검진 · 하계휴가 · 심리 상담 · 휴양시설 ·
--   경조사 · 육아 · 난임 치료 · 입학 축하선물 및 학자금 · 출산축하금 · 주거)을 담은 서버 렌더 HTML 이다.
--   같은 메뉴의 Growth · Work · Recognition 페이지(/career/life/growth · work · recognition)가 성장 ·
--   근무환경 · 보상 항목을 나눠 싣는다. 헤드리스 렌더 불필요. robots 는 /kr/ · /global/ · /asset/ 를 막지만
--   /career/ 와 /upload/ 경로는 막지 않는다(사이트맵에 네 페이지가 모두 있다).
--   보조 출처: LG화학 지속가능경영보고서 2025 국문 PDF(같은 도메인 /upload/file/sustainability-reports/)
--     54 · 68 · 69 · 70쪽 — 임신 · 출산 · 육아 단계별 지원 제도 · 자격증 취득 지원 · 유연근무 · 웰빙 · Connect HR 성과.
--   그룹 통합 채용 careers.lg.com 은 근거로 쓰지 않았다 — 법인 자기 도메인에 정본이 있다. 다른 LG 계열사 문구는 옮기지 않았다.
--   금액: 원문 명시 연 환산 금액 0건. 승계 추정치 5행(incentive 500 · medical 100 · health_check 100 ·
--     resort 50 · welfare_point 200 — 모두 같은 값을 추정치로 쓴 다른 회사가 3곳 이상, NOTE 끝에 (추정)).
--     구본 공식 수치 child_edu 300 은 원문에 그 숫자가 없어 승계하지 않았다. event 50 은 1회성 경조금이라 NULL.
--     출산 축하금 100만 원(1회성)과 자격증 지원 연간 100만 원(한도)은 금액 칸에 넣지 않고 서술에 적었다.
--   재코딩 0. 구본 housing_loan(주택자금/사택)의 기숙사 · 주거비 서술은 dormitory · housing_support 로 나눴다(housing_loan 은 대출만).
--   구본에서 뺀 행: edu_support(회사 주도 교육 과정). lang(외국어 e-learning)은 2026-10-04 규칙 8 개정으로 되살렸다(SORT 73).
--   법정 제도 제외: 휴가사용촉진제도 · 유산 사산 휴가 · 법정 육아휴직 기간 · 난임 휴가와 배우자 출산 휴가 기본 일수.
--   재취업지원서비스 대상(1,000인 이상)이나 원문에 퇴직 · 재취업 항목이 없다.
--   SORT 섹션 순서 = 정본 Care 페이지에서 카테고리가 처음 나온 순서(health 10 · perks 20 · time_off 30 · leisure 40 ·
--     family 50 · work_env 60), 이어서 메뉴 순서 Growth(growth 70) · Work(flexibility 80) · Recognition(compensation 90).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-2): medical 비고에 질병 휴직 급여 일부 지급 흡수(보고서 70쪽 · 현대모비스 선례) · 나머지 28행 원문 확인 · 승계 추정 5행 유지(이 법인 옛 데이터) — 최종 29행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(lang) — 최종 30행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_chem', 'LG화학',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화학', 'L', 'https://www.lgchem.com/career/life/care');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_chem');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lgchem.com/career/life/care'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '배우자·자녀·부모의 질병과 부상에 대한 의료비 지원 (공식 채용 페이지 Care 항목 — 지원 한도·본인 포함 여부 미기재), 업무 외 사고나 질병으로 근로가 어려울 때 휴직 제도 운영과 휴직 기간 급여 일부 지급 (2025 지속가능경영보고서 70쪽 — 휴직 기간·급여 수준 미기재) (추정)', FALSE, NULL, 10),
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '배우자·부모의 건강을 살필 수 있도록 건강검진 지원 (공식 채용 페이지 Care 항목 — 검진 주기·비용 한도 미기재) (추정)', FALSE, NULL, 11),
  (@comp_id, 'mental', '심리 상담', NULL, 'health',
   'est', NULL, TRUE, '응원과 위로, 문제 해결이 필요할 때 APP 을 통한 무료 심리 상담 지원 (공식 채용 페이지 Care 항목). 2025 지속가능경영보고서 70쪽에는 외부 전문 기관과 연계한 심리상담 서비스로 기재 — 상담 횟수 한도 미기재', 12),
  (@comp_id, 'clinic', '사내 부속의원·건강관리실', NULL, 'health',
   'est', NULL, TRUE, '사내 부속의원과 건강관리실 운영, 구성원 특성에 맞춘 의료 서비스와 건강증진 프로그램 제공 (2025 지속가능경영보고서 54쪽 건강관리 및 질환 예방) — 설치 사업장·진료 과목 미기재', 13),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생 포인트', 200, 'perks',
   'est', '언제 어디서나 쓸 수 있는 선택적 복리후생 포인트로 여가 생활 지원 (공식 채용 페이지 Care 항목 — 연간 포인트 금액 미기재) (추정)', FALSE, NULL, 20),
  (@comp_id, 'housing_loan', '주택 마련 저리 대출', NULL, 'perks',
   'est', NULL, TRUE, '내 집 마련의 부담을 낮출 수 있도록 저리 대출 지원 (공식 채용 페이지 Care 주거 지원 항목 — 대출 한도·이율 미기재)', 21),
  (@comp_id, 'housing_support', '지방 사업장 주거비용 지원', NULL, 'perks',
   'est', NULL, TRUE, '지방 사업장 근무자가 안정적으로 생활할 수 있도록 주거비용 지원 (공식 채용 페이지 Care 주거 지원 항목 — 지원 금액·대상 사업장 미기재)', 22),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '편안한 출퇴근 길이 될 수 있도록 통근버스 운영 (공식 채용 페이지 Work 항목 — 노선·이용료 미기재)', 23),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인 연금 제도 신설, 회사가 월별 지원금 지급 (2025 지속가능경영보고서 70쪽 2025년 Connect HR 주요 성과) — 월 지원 금액·가입 조건 미기재', 24),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'summer_leave', '하계휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '개인과 가족의 휴식을 위해 별도로 5일의 휴가 제공 (공식 채용 페이지 Care 항목). 2025 지속가능경영보고서 70쪽에는 하계 휴가를 연중 원하는 시기에 사용할 수 있도록 운영한다고 기재', 30),
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '개인 상황에 따라 휴가를 하루 단위뿐 아니라 2시간 단위로도 나누어 사용 (2025 지속가능경영보고서 70쪽 효율적인 업무 환경 구축)', 31),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설 지원', 50, 'leisure',
   'est', '전국 리조트를 할인된 가격으로 이용 지원 (공식 채용 페이지 Care 항목 — 할인율·이용 횟수 미기재) (추정)', FALSE, NULL, 40),
  (@comp_id, 'club', '생활체육 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 축구·야구·농구·테니스 등 생활체육 동호회 운영, 구성원의 자발적 참여를 기반으로 한 건강 증진과 교류 지원 (2025 지속가능경영보고서 70쪽 구성원 건강 및 웰빙 지원) — 활동비 지원 금액 미기재', 41),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '가족의 기쁨과 슬픔을 함께 할 수 있도록 월 급여에 준하는 경조금과 경조 휴가 제공 (공식 채용 페이지 Care 항목 — 경조 종류별 지급 기준·휴가 일수 미기재)', 50),
  (@comp_id, 'parenting', '육아휴직 추가 1년·출산 축하금·입학 축하 선물', NULL, 'family',
   'est', NULL, TRUE, '기본 육아휴직 기간 외에 추가로 1년의 육아휴직, 출산 축하금 지급, 자녀 입학 축하 선물 (공식 채용 페이지 Care 육아 지원·출산축하금·입학 축하선물 및 학자금 항목). 2025 지속가능경영보고서 68쪽 구성원 생애주기 지원 제도에는 출산 축하금 100만 원과 임신·출산 의료비 지원으로 기재 — 임신·출산 의료비 한도·입학 선물 내용 미기재', 51),
  (@comp_id, 'fertility_support', '난임 치료 지원', NULL, 'family',
   'est', NULL, TRUE, '아이를 기다리는 부부를 위해 난임 검사와 시술 지원 (공식 채용 페이지 Care 항목). 2025 지속가능경영보고서 68쪽에는 난임 휴직 최대 6개월과 난임 치료비(검사비용·유산방지제·착상유도제 등 비급여 비용) 지원으로 기재 — 시술 지원 횟수·금액 한도 미기재', 52),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀의 성장을 함께 지켜보는 자녀 학자금 지원 (공식 채용 페이지 Care 입학 축하선물 및 학자금 항목 — 지원 학교급·한도·자녀 수 미기재)', 53),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '자녀를 믿고 맡길 수 있는 직장 어린이집 운영 (공식 채용 페이지 Care 육아 지원 항목). 2025 지속가능경영보고서 68쪽에는 본사·마곡 사업장·대전 R&D캠퍼스·여수·대산·청주사업장 등 사업장별 어린이집 총 6곳 운영으로 기재 — 정원·보육료 부담 미기재', 54),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '지방 사업장 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '지방 사업장 근무자가 안정적으로 생활할 수 있도록 기숙사 지원 (공식 채용 페이지 Care 주거 지원 항목 — 입주 조건·비용 부담 미기재)', 60),
  (@comp_id, 'nap_room', '모성보호실', NULL, 'work_env',
   'est', NULL, TRUE, '수유·임산부 휴게를 위한 전용 공간인 모성보호실 제공 (2025 지속가능경영보고서 68쪽 근무환경 지원) — 설치 사업장 미기재', 61),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'career', 'Career Market (사내공모)·Global Mobility', NULL, 'growth',
   'est', NULL, TRUE, '사내공모로 타 조직의 Job Posting 에 지원하는 Career Market, 국내 구성원의 해외 파견과 해외 구성원의 국내 파견 Global Mobility (공식 채용 페이지 Growth 항목). 2025 지속가능경영보고서 68쪽에는 2020년부터 사내 공모 제도 운영, 70쪽에는 사내 공모제도 지원 횟수 제한 폐지로 기재 — 파견 선발 기준 미기재', 70),
  (@comp_id, 'mba', '해외 중장기 연수·Global MBA', NULL, 'growth',
   'est', NULL, TRUE, '최고의 직무 전문가와 Global 리더 양성을 위해 해외 학위 취득이 가능한 선발 프로그램 지원 (공식 채용 페이지 Growth 항목 — 선발 인원·비용 부담 범위 미기재)', 71),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무와 개인 역량 강화를 위한 자격증 취득 수강료와 교재비를 연간 100만 원 한도 내에서 지원 (2025 지속가능경영보고서 69쪽 경력 개발 지원 프로그램)', 72),
  (@comp_id, 'lang', '외국어 e-learning·상시 인터넷 어학', NULL, 'growth',
   'est', NULL, TRUE, '외국어 e-learning 교육으로 언제 어디서든 누구나 외국어 역량 함양 (공식 채용 페이지 Growth 어학 역량 향상 항목), 연중 상시 인터넷 어학 제공 (2025 지속가능경영보고서 70쪽 Connect HR 주요 성과) — 비용 부담·수강 한도 미기재', 73),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제도', NULL, 'flexibility',
   'est', NULL, TRUE, '출퇴근 시간을 유연하게 조정해 일과 삶을 균형 있게 관리하는 유연근무제도 (공식 채용 페이지 Work 항목). 2025 지속가능경영보고서 70쪽에는 시차출퇴근제와 탄력근로시간제 운영으로 기재 — 코어 타임·정산 기간 미기재', 80),
  (@comp_id, 'remote_work', '재택근무·스마트 워크 시스템', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 제도 운영 (2025 지속가능경영보고서 70쪽), 언제 어디서나 일할 수 있도록 스마트 워크 시스템과 툴 지원 (공식 채용 페이지 Work 항목) — 재택 사용 일수·대상 직무 미기재', 81),
  (@comp_id, 'satellite_office', '거점오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '사는 곳 가까이에서 효율적으로 일할 수 있도록 거점 오피스 운영 (공식 채용 페이지 Work 항목 — 거점 위치·이용 조건 미기재)', 82),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', 'Personal Incentive·On-Spot Incentive', 500, 'compensation',
   'est', '개인 목표를 달성한 만큼 일년에 두 번 주는 Personal Incentive, 개인별 성과 창출 시점에 수시로 주는 On-Spot Incentive (공식 채용 페이지 Recognition 항목 — 지급 기준·지급률 미기재) (추정)', FALSE, NULL, 90),
  (@comp_id, 'profit_sharing', '경영성과급', NULL, 'compensation',
   'est', NULL, TRUE, '회사의 목표 달성을 함께 축하할 수 있도록 경영 성과에 따라 지급 여부와 수준을 결정해 지급 (공식 채용 페이지 Recognition 항목 — 산정 기준·지급 시기 미기재)', 91),
  (@comp_id, 'excellence_award', '포상·Peer Bonus', NULL, 'compensation',
   'est', NULL, TRUE, '우수한 성과와 혁신적인 도전·과정을 인정하는 다양한 포상제도, 동료에게 감사와 칭찬 그리고 소액의 보너스를 전하는 Peer Bonus (공식 채용 페이지 Recognition 항목). 공식 채용 페이지 Growth 항목에는 연구원 대상 새롭고 도전적인 연구에 대한 포상제도로도 기재 — 포상 금액 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
