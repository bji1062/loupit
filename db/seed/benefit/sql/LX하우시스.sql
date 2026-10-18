-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LX하우시스 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://www.lxhausys.co.kr/careers/welfare
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)엘엑스하우시스 자기 도메인 www.lxhausys.co.kr 인재채용 > 복리후생 페이지다
--   (SSR — 원본 HTML 에 Family · Health · Refresh · Gift · Etc 5묶음 21항목이 다 있다. HTML 주석 속 옛 안내 문단 1개는 걷었다).
--   보조 출처: 같은 도메인 인재채용 > 인사제도 > 보상제도 · 인재육성 페이지,
--   ESG > 지속가능경영 보고서 목록에 올라 있는 지속가능경영보고서 2026(PDF 102쪽 · 2026-06 발행 · 보고 기간 2025-01-01~2025-12-31,
--   일부 2026 상반기 포함 · 보고 범위 본사 및 국내 사업장 중심 + 해외 제조 법인 2곳) 34 · 52 · 54쪽,
--   OpenDART 2026 반기보고서(접수 20260814003556) · 2025 사업보고서(접수 20260316001555) 유연근무제도 사용 현황.
--   렌더: 헤드리스 렌더 없음(원본 HTML · PDF 텍스트 · OpenDART 원문 XML).
--   귀속: 정본 · 보조 페이지 · 보고서 문장 주어가 LX하우시스 단수이고 그룹 · 계열사 단서가 없다(보고서 54쪽 자회사 그린누리 문단은 쓰지 않음).
--   각주 없음. 기등록 형제 LX인터내셔널(자기 도메인 정본)과 겹치는 문장 없음 — LX 그룹 채용 사이트(lx.recruiter.co.kr)는 쓰지 않았다.
--   금액: 전 행 NULL(복지포인트 · 생일 포인트 금액 미기재 · 사내식당은 운영 시간만 있고 끼니 제공 · 지원 문구가 없어 NULL).
--   제외: 법정(배우자 출산휴가 20일 · 육아휴직 1년 · 육아기 단축 · 임신기 단축 · 태아 검진 휴가 · 출산휴가 · 가족돌봄휴직 ·
--     일반 · 특수 · 배치전후 검진 · 유소견자 상담 · 정년퇴직 예정자 재취업 지원 프로그램 · 근속 추가 유급 휴가) ·
--     업무 교육(직무 · 진급자 · 리더십 · 신규입사자 · 핵심인재 HPI · Biz Pro Talent 과정 · 학회 세미나 · Six Sigma) ·
--     권장휴가(리더 없는 날) · 급여성(자격수당 · 연봉제 · 역할급) · 임원 보수 칸 복리후생 포인트 · 협력사 대상 복지몰 · 노사협의회 논의 안건.
--   공고 근거 0행 / 전체 31행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(perks 10 · family 20 · health 30 · leisure 40 · time_off 50),
--     보조 출처에만 있는 compensation 60 · growth 70 · flexibility 80 · work_env 90.
-- 검증 · 감사 판정 반영(2026-10-18): 주택자금 housing_loan 꼬리의 이자 지원율 미기재를 지원 방식·한도 미기재로(원문에 이자 없음) · 항목 페이지 예외 2(통합 밖 리드 집행) · 24 난임 치료 휴가 유급 3일은 2026-11-27 개정 재계산 대상 — 최종 31행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lx_hausys', 'LX하우시스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '가구/인테리어', 'L', 'https://www.lxhausys.co.kr/careers/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lx_hausys');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lxhausys.co.kr/careers/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활 · 금융 (perks) — 복리후생 페이지 Family · Health · Gift · Etc · 보고서 54쪽 ──
  (@comp_id, 'housing_loan', '주택자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '임직원에게 안정적인 주거 생활을 위해 은행을 통한 전세/구입 주택자금 지원 (공식 인재채용 페이지 복리후생 Family 주택자금 항목) — 지원 방식·한도 미기재', 10),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '아침부터 저녁까지 이용가능한 사내 식당 운영, 사업장별 상이 (공식 인재채용 페이지 복리후생 Health 사내식당 항목) — 식대 지원 여부·본인 부담 미기재', 11),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '임직원의 필요/선택에 따라 현금과 동일하게 사용할 수 있는 복리후생 포인트 제공 (공식 인재채용 페이지 복리후생 Gift 복지포인트 항목) — 연간 지급 포인트 미기재', 12),
  (@comp_id, 'birthday_gift', '생일축하 포인트', NULL, 'perks',
   'est', NULL, TRUE, '임직원의 생일 축하 포인트 지급 (공식 인재채용 페이지 복리후생 Gift 생일축하 항목) — 포인트 금액 미기재', 13),
  (@comp_id, 'commute_subsidy', '셔틀지원', NULL, 'perks',
   'est', NULL, TRUE, '출/퇴근 통근 및 셔틀 버스 운영, 사업장별 상이 (공식 인재채용 페이지 복리후생 Etc 셔틀지원 항목) — 운행 노선·사업장 미기재', 14),
  (@comp_id, 'snack_bar', '사내 Z:IN Café', NULL, 'perks',
   'est', NULL, TRUE, '다양한 식·음료 제공과 편안한 휴식공간 제공 (공식 인재채용 페이지 복리후생 Etc 사내 Z:IN Café 운영 항목) — 이용 요금·운영 사업장 미기재', 15),
  (@comp_id, 'discount', '자사제품 할인', NULL, 'perks',
   'est', NULL, TRUE, '고품격, 고품질의 LX하우시스 제품 할인 (공식 인재채용 페이지 복리후생 Etc 자사제품할인 항목), 임직원의 소속감과 자긍심 고취를 위한 자사제품 할인 운영 (2026 지속가능경영보고서 54쪽 다양한 맞춤형 복리후생 자사제품 할인 항목) — 할인율·연간 한도 미기재', 16),
  -- ── 가족 (family) — 복리후생 페이지 Family · 보고서 54쪽 ──
  (@comp_id, 'child_edu', '자녀 장학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (공식 인재채용 페이지 복리후생 Family 장학자금 항목) — 지원 학령·한도 미기재', 20),
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금, 조화/화환, 장례지원 서비스 등 지원 (공식 인재채용 페이지 복리후생 Family 경조금·경조휴가 항목), 결혼 시 경조금 및 경조 휴가 제공 (2026 지속가능경영보고서 54쪽 결혼·출산·육아 장려 제도 결혼 경조금/휴가 항목) — 경조 사유별 금액·휴가 일수 미기재', 21),
  (@comp_id, 'parenting', '출산용품·출산축하금·자녀입학축하금', NULL, 'family',
   'est', NULL, TRUE, '자녀 출산을 축하하기 위한 출산용품 지원 (공식 인재채용 페이지 복리후생 Family 임신/출산 항목), 초/중/고등학교 자녀 입학에 맞춘 입학 축하금 지원 (같은 페이지 자녀입학축하금 항목), 임직원 자녀 출산 시 소정의 축하금 지급 · 임직원 자녀 초·중·고 입학 시 축하금 지원 (2026 지속가능경영보고서 54쪽 결혼·출산·육아 장려 제도 출산축하금 · 입학축하금 항목) — 축하금 금액·출산용품 품목 미기재', 22),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직원 자녀들 대상 어린이집 운영 (공식 인재채용 페이지 복리후생 Family 어린이집 항목), 사업장별 직장 어린이집 운영을 통한 사원들의 보육 활동 지원 (2026 지속가능경영보고서 54쪽 일·가정 양립 지원 보육시설 항목) — 정원·위치 미기재', 23),
  (@comp_id, 'fertility_support', '난임 치료 휴가 유급 3일 (법정 유급 2일에 1일 추가)', NULL, 'family',
   'est', NULL, TRUE, '난임 치료 휴가 유급 3일 지원, 법정 유급 2일에 1일 추가 (2026 지속가능경영보고서 54쪽 결혼·출산·육아 장려 제도 난임치료 지원 항목) — 난임 시술비 지원 여부 미기재', 24),
  -- ── 건강 (health) — 복리후생 페이지 Health · 보고서 34 · 54쪽 ──
  (@comp_id, 'health_check', '본인·배우자 종합건강진단', NULL, 'health',
   'est', NULL, TRUE, '임직원과 임직원의 배우자의 건강검진 비용 지원 (공식 인재채용 페이지 복리후생 Health 종합건강진단 항목), 종합검진 실시, 위내시경 / 복부초음파 / 갑상선초음파 / 혈액검사 추가 암검진 실시 (2026 지속가능경영보고서 34쪽 임직원 건강관리 건강검진 항목) — 검진 주기·비용 지원 한도 미기재', 30),
  (@comp_id, 'medical', '본인·배우자·자녀 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 임직원의 배우자와 자녀에게 의료비 지원 (공식 인재채용 페이지 복리후생 Health 의료비지원 항목), 임직원 본인, 배우자, 자녀의 의료비 지원 (2026 지속가능경영보고서 54쪽 스트레스 및 건강관리 의료비 지원 항목) — 지원 한도·본인 부담률 미기재', 31),
  (@comp_id, 'insurance', '단체정기보험 (3대 질병)', NULL, 'health',
   'est', NULL, TRUE, '3대 질병(암, 뇌졸증, 급성심근경색)에 대한 임직원 단체보험 지원 (공식 인재채용 페이지 복리후생 Health 단체정기보험 항목) — 보장 금액·가족 가입 여부 미기재', 32),
  (@comp_id, 'fitness', '사내 피트니스센터·걷기 챌린지', NULL, 'health',
   'est', NULL, TRUE, '언제든지 이용할 수 있는 사내 피트니스 운영, 사업장별 상이 (공식 인재채용 페이지 복리후생 Health 피트니스센터 항목), 2025년 2년 연속 걷기 챌린지를 시행하여 걷기 습관 형성과 신체 활동 촉진 (2026 지속가능경영보고서 34쪽 건강 증진 프로그램 항목) — 운영 사업장·이용 요금 미기재', 33),
  (@comp_id, 'mental', '심리상담실', NULL, 'health',
   'est', NULL, TRUE, '전문 심리 상담가와 함께하는 심리상담실 (공식 인재채용 페이지 복리후생 Health 심리상담실 항목), 직원들의 스트레스 관리를 위한 심리상담실 운영 지원 (2026 지속가능경영보고서 54쪽 스트레스 및 건강관리 스트레스 관리 항목) — 상담 횟수·가족 이용 여부 미기재', 34),
  (@comp_id, 'clinic', '사업장 건강관리실·운동처방', NULL, 'health',
   'est', NULL, TRUE, '주요 사업장 내 건강관리실의 일상적인 건강 관리 지원과 응급 상황 대응, 문진과 상담을 통한 질병 예방 및 건강 유지·증진 프로그램 (2026 지속가능경영보고서 34쪽 건강 증진 프로그램 항목), 주 1회 근골격계 통증 호소자 대상 운동처방사 운동처방 실시, 전기 핫팩·파라핀치료기 등 의료기기 비치 (같은 쪽 임직원 건강관리 운동처방사 치료 · 의료기기 비치 항목) — 의료 인력·운영 시간 미기재', 35),
  -- ── 여가 (leisure) — 복리후생 페이지 Refresh · 보고서 54쪽 ──
  (@comp_id, 'resort', '리조트·콘도', NULL, 'leisure',
   'est', NULL, TRUE, '곤지암, 엘리시안, 한화리조트 등 각지의 최고급 리조트·콘도 예약/할인 지원 (공식 인재채용 페이지 복리후생 Refresh 리조트·콘도 항목), 휴양시설 지원 (2026 지속가능경영보고서 54쪽 임직원 복리후생 주요 복지 제도 항목) — 이용 횟수·본인 부담 미기재', 40),
  (@comp_id, 'club', '인포멀그룹·스포츠 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '축구, 등산, 액티비티, 문화체험 등 사내 인포멀 가입, 사업장별 상이 (공식 인재채용 페이지 복리후생 Refresh 인포멀그룹 항목), 등산, 야구, 축구 등 다양한 사내 스포츠 동호회 운영 지원 (2026 지속가능경영보고서 54쪽 스트레스 및 건강관리 스포츠 동호회 지원 항목) — 동호회별 지원 금액 미기재', 41),
  -- ── 휴가 (time_off) — 복리후생 페이지 Refresh · Gift · 보고서 52쪽 ──
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, 'W&L Balance와 업무 몰입의 근무 환경 정착을 위한 하계휴가 제공 (공식 인재채용 페이지 복리후생 Refresh 하계휴가 항목) — 본인 휴가 사용일인지·휴가 일수·유급 여부 미기재', 50),
  (@comp_id, 'long_service_leave', '장기근속 포상휴가·기념품', NULL, 'time_off',
   'est', NULL, TRUE, '장기 근속 임직원에게 포상 휴가 및 기념품 제공 (공식 인재채용 페이지 복리후생 Gift 장기근속포상·기념품 항목), 5년~35년(5년 단위) 근속 직원에 대한 기념품 및 휴가, 여행 경비 등 지원 (2026 지속가능경영보고서 52쪽 임직원 성과 및 보상 보상체계 항목) — 근속 단계별 휴가 일수·여행 경비 금액 미기재', 51),
  -- ── 보상 (compensation) — 인사제도 보상제도 페이지 · 보고서 52쪽 ──
  (@comp_id, 'profit_sharing', '성과급 (Profit Sharing)·경영성과급', NULL, 'compensation',
   'est', NULL, TRUE, '조직성과와 조직평가에 따른 Profit Sharing (공식 인재채용 페이지 인사제도 보상제도 변동급 성과급 항목), 조직 성과를 반영한 경영성과급 (2026 지속가능경영보고서 52쪽 임직원 성과 및 보상 보상체계 항목) — 지급 기준·지급률 미기재', 60),
  (@comp_id, 'incentive', '인센티브 (On-Spot Incentive)', NULL, 'compensation',
   'est', NULL, TRUE, '우수한 성과를 창출한 임직원에 대한 즉시 보상 (공식 인재채용 페이지 인사제도 보상제도 변동급 인센티브 항목), 우수한 성과 창출에 대한 포상제도인 On-Spot Incentive (2026 지속가능경영보고서 52쪽 임직원 성과 및 보상 보상체계 항목) — 지급 기준·금액 미기재', 61),
  (@comp_id, 'excellence_award', 'R&D·우수 혁신활동 포상제도', NULL, 'compensation',
   'est', NULL, TRUE, 'R&D 및 우수 혁신활동에 대한 포상 (공식 인재채용 페이지 인사제도 보상제도 각종 포상제도 항목), 미래 성장 동력 제고를 위한 R&D 포상제도 운영 (2026 지속가능경영보고서 52쪽 임직원 성과 및 보상 보상체계 항목) — 포상 내용·금액 미기재', 62),
  -- ── 성장 (growth) — 인사제도 인재육성 페이지 · 보고서 52 · 54쪽 ──
  (@comp_id, 'mba', '중장기 연수 (MBA·EMBA)', NULL, 'growth',
   'est', NULL, TRUE, '글로벌 역량강화를 위해 국내외 전문교육기관을 통해 일정기간 동안 집중교육을 제공하는 제도로 MBA 등 다양한 교육 지원 (공식 인재채용 페이지 인사제도 인재육성 Global 미래사업가 양성 프로그램 중장기 연수 항목), LX 예비 사업가 육성을 위한 차세대 CTO, Aalto EMBA 등 교육 지원 (2026 지속가능경영보고서 52쪽 임직원 역량 개발 프로그램 중장기 연수 항목) — 선발 기준·지원 범위 미기재', 70),
  (@comp_id, 'lang', '어학교육 (해외사업 인력 중심)', NULL, 'growth',
   'est', NULL, TRUE, '해외사업 인력을 중심으로 1:1회화, 글로벌 어학과정, 단기집중어학과정 등 지원 (공식 인재채용 페이지 인사제도 인재육성 Global 미래사업가 양성 프로그램 어학교육 항목), 해외사업 인력 및 팀장을 중심으로 글로벌 어학 과정 등 지원 (2026 지속가능경영보고서 52쪽 임직원 역량 개발 프로그램 어학교육 항목) — 그 밖 직원 수강 가능 여부·비용 지원 범위 미기재', 71),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '임직원의 직무 및 직무 외 자기계발을 위한 자격증 취득 지원 (2026 지속가능경영보고서 54쪽 다양한 맞춤형 복리후생 자격증 취득 지원 항목) — 지원 자격증 범위·비용 한도 미기재', 72),
  -- ── 근무 유연성 (flexibility) — 보고서 54쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '선택적 근로시간제·시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '임직원의 효율적인 근무지원을 위한 선택적 근로시간제 시행 (2026 지속가능경영보고서 54쪽 다양한 맞춤형 복리후생 유연근무 제도 항목), 시차출퇴근제 사용자 수 1,854명 · 선택근무제 사용자 수 1,854명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 핵심 근무시간대·적용 대상 미기재', 80),
  -- ── 근무 환경 (work_env) — 보고서 54쪽 ──
  (@comp_id, 'lounge', '여성휴게실·사옥 내 휴식 공간', NULL, 'work_env',
   'est', NULL, TRUE, '사옥 내 휴식 공간 제공 (2026 지속가능경영보고서 54쪽 임직원 복리후생 주요 복지 제도 항목), 사업장별 수유실(여성휴게실 포함) 운영 (같은 쪽 일·가정 양립 지원 수유실 운영 항목) — 공간 규모·운영 사업장 미기재', 90),
  (@comp_id, 'nap_room', '사업장별 수유실', NULL, 'work_env',
   'est', NULL, TRUE, '사업장별 수유실(여성휴게실 포함) 운영을 통한 여성들의 육아활동 지원 환경 조성 (2026 지속가능경영보고서 54쪽 일·가정 양립 지원 수유실 운영 항목) — 운영 사업장·설비 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
