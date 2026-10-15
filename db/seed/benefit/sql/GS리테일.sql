-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- GS리테일 복리후생 데이터 (신규 회사 — 웨이브 6)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://hpimg.gsretail.com/_ui/desktop/common/docs/gsr_sustainability_report_2025.pdf
-- badge: est
--
-- 참고:
--   정본은 법인 (주)GS리테일이 자기 도메인에 올린 2025 GS리테일 지속가능경영보고서 PDF
--   (보고 기간 2025-01-01~12-31, 대표이사 인사말 2026년 6월, 지금 올라 있는 가장 새 판) 59쪽
--   인재경영 > 조직문화 확립 > 복리후생 프로그램 표 20항목(ENGAGEMENT · LEISURE · LIFE · WORK).
--   PDF 텍스트 레이어는 프로그램명과 설명을 따로 뽑으므로 쪽 좌표(같은 y)와 쪽 이미지로 20쌍을
--   맞췄다. GROW-UP DAY 의 설명은 자기개발 및 Well-being을 위한 여름 휴가제도 로 확인됐다.
--   보조 출처: 같은 보고서 58쪽 가족친화제도 · 56쪽 자기주도 학습 · 55쪽 보상 · 107쪽 데이터 표,
--   자기 사이트 www.gsretail.com 지속가능경영 > 사회적 책임 > 권익보호 > 인재경영 의
--   인재경영 지표 탭 24항목(Work · Engagement · Life · Leisure)과 인재육성체계 탭.
--   웹은 Vue SPA 라 원본 HTML 에 항목이 없고 정적 JS 청크 hpsimg.gsretail.com/public/js/4413.3500ae00.js
--   의 i18n 객체 protect.talentmanagement.part_2 · part_3 에서 읽었다. 헤드리스 렌더 0회.
--   퇴직자 창업지원 1행은 같은 사이트 인재경영 실적자료 탭의 PDF(퇴직자 지원 창업·재고용 제도,
--   문서 개정 2018-01-01, 게시 2021-02-19)와 보고서 107쪽 2025년 이용 인원이 근거다.
--   귀속: 보고 범위가 비재무성과 별도 기준이고 주어가 전부 GS리테일 이다. GS그룹 공통 문구 ·
--   계열사별 상이 단서 없음 · 기등록 형제 GS건설 시드와 글자 겹침 0 이라 각주 없음.
--   금액: 원 단위 금액 0건이라 25행 전부 BENEFIT_AMT NULL. 할인율 · 보상 배수 · 대출 한도는 금액 아님.
--   제외: 법정(일반 정기 검진 · 75퍼센트 휴가촉진제 · 육아휴직 법정분) · 업무 교육(직무 · 리더십 ·
--   GS Way · 온보딩) · 파트너사와 가맹 경영주 대상 복리후생 · 물류센터 폭염 휴게공간(안전 조치) ·
--   정년 재고용(회사 필요 시 계약직) · 잔여 휴가 1.5배 보상(판단 요청).
--   공고 근거 0행 / 전체 25행.
--   SORT 섹션 순서(59쪽 표에 처음 나온 순서, 보조 출처에만 있는 카테고리는 끝):
--   health 10 · time_off 20 · perks 30 · compensation 40 · family 50 · leisure 60 · growth 70 · flexibility 80
-- 검증 · 감사 판정 반영(2026-10-14): 신규 코드 leave_buyout 미사용 휴가 1.5배 보상 추가(참고 블록 제외 목록의 해당 줄은 이 판정으로 뒤집힘) · 유치원 보조비를 child_edu 로 · 아이 사랑 휴직을 육아 행 서술에 흡수 · 자기주도 학습 행을 자기 몫만 — 최종 26행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('gs_retail', 'GS리테일',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '유통', 'G', 'https://hpimg.gsretail.com/_ui/desktop/common/docs/gsr_sustainability_report_2025.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'gs_retail');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://hpimg.gsretail.com/_ui/desktop/common/docs/gsr_sustainability_report_2025.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 보고서 59쪽 심리상담 · 건강검진 · 의료비 / 58쪽 / 웹 인재경영 지표 ──
  (@comp_id, 'mental', '심리상담 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 본인 및 배우자, 자녀, 부모 대상 심리 상담 및 법률·세무·재무코칭 등 상담 서비스 제공 (2025 지속가능경영보고서 59쪽 심리상담 지원 항목), 근로자 심리 상담 제공 (공식 홈페이지 인재경영 지표 Engagement 심리 상담 지원 항목) — 상담 횟수·비용 지원 범위 미기재', 10),
  (@comp_id, 'health_check', '종합검진 지원 (임직원·배우자)', NULL, 'health',
   'est', NULL, TRUE, '연령 등 지원 기준에 따라 임직원 및 배우자 대상 종합검진 지원 (2025 지속가능경영보고서 59쪽 건강검진 지원 항목), 의료비/건강검진 지원 (공식 홈페이지 인재경영 지표 Life 항목) — 검진 주기·지원 연령 기준·비용 지원 범위 미기재', 11),
  (@comp_id, 'medical', '의료비 지원 (본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '질병, 사고에 대해 본인 및 배우자까지 의료비 지원 (2025 지속가능경영보고서 59쪽 의료비 지원 항목 · 58쪽 가족친화제도 배우자 의료비 지원) — 지원 비율·한도 미기재', 12),

  -- ── 휴가 (time_off) — 보고서 59쪽 장기근속 포상 · GROW-UP DAY / 웹 인재경영 지표 ──
  (@comp_id, 'long_service_leave', '장기근속 포상·휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기 근속 구성원 대상 포상 제도 운영 (2025 지속가능경영보고서 59쪽 장기근속 포상 항목), 장기근속 구성원에게 감사의 마음을 담아 포상 및 휴가 제공 (공식 홈페이지 인재경영 지표 Engagement 장기근속 포상 항목) — 근속 연수 기준·포상 내용·휴가 일수 미기재', 20),
  (@comp_id, 'summer_leave', '하계휴가 추가 지원 (GROW-UP DAY)', NULL, 'time_off',
   'est', NULL, TRUE, '법정 연차 외에 별도로 부여되는 여름휴가 (공식 홈페이지 인재경영 지표 Leisure 하계휴가 추가 지원 항목), 자기개발 및 Well-being을 위한 여름 휴가제도 (2025 지속가능경영보고서 59쪽 GROW-UP DAY 항목) — 휴가 일수·유급 여부 미기재', 21),

  -- ── 생활 편의 (perks) — 보고서 59쪽 임직원 할인 · 통근버스 · 원거리 지원금 / 웹 이동통신비 ──
  (@comp_id, 'discount', '임직원 할인 (GS SHOP·GS THE FRESH)', NULL, 'perks',
   'est', NULL, TRUE, 'GS SHOP, GS THE FRESH 최대 25% 할인 제공 (2025 지속가능경영보고서 59쪽 임직원 할인 제공 항목), GS SHOP & GS THE FRESH에서 임직원 한정 할인 제공 (공식 홈페이지 인재경영 지표 Engagement 임직원 할인 제공 항목) — 품목별 할인율·이용 한도 미기재', 30),
  (@comp_id, 'commute_subsidy', '통근·셔틀버스 운영', NULL, 'perks',
   'est', NULL, TRUE, 'GS타워 근무자와 수도권 거주자 대상 통근버스 및 셔틀버스 지원 (2025 지속가능경영보고서 59쪽 통근버스 운영 항목), 셔틀/통근버스 운영 (공식 홈페이지 인재경영 지표 Work 항목) — 노선·운행 사업장 미기재', 31),
  (@comp_id, 'housing_support', '원거리 지원금', NULL, 'perks',
   'est', NULL, TRUE, '업무로 인해 친인척이 없는 지역으로 원거리 발령되는 경우 지원금 지급 (2025 지속가능경영보고서 59쪽 원거리 지원금 항목), 실제 근무 지역과 연고지가 일정 거리 이상일 경우 주거비 일부 지원 (공식 홈페이지 인재경영 지표 Work 원거리 지원금 항목) — 거리 기준·지원 금액 미기재', 32),
  (@comp_id, 'telecom', '이동통신비 지원 (업무상 통화가 잦은 구성원)', NULL, 'perks',
   'est', NULL, TRUE, '업무상 통화할 일이 잦은 구성원을 위해 이동통신비 지원 (공식 홈페이지 인재경영 지표 Work 이동통신비 지원 항목) — 대상 직무·지원 금액 미기재', 33),

  -- ── 보상 (compensation) — 보고서 59쪽 축하 선물 지급(명절 상품권) / 55쪽 보상 / 웹 명절 선물 ──
  (@comp_id, 'holiday_gift', '명절 자사 상품권·선물', NULL, 'compensation',
   'est', NULL, TRUE, '설날 및 추석 자사 상품권 지급 (2025 지속가능경영보고서 59쪽 축하 선물 지급 항목), 명절 선물 지급 (공식 홈페이지 인재경영 지표 Engagement 명절 선물 지급 항목) — 상품권 금액·선물 내용 미기재', 40),
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '회사/BU/개인 성과를 가시화하여 공유하고 맞춤형 성과급 제공 (2025 지속가능경영보고서 55쪽 평가 및 보상 보상 항목) — 지급 기준·지급률 미기재', 41),
  (@comp_id, 'leave_buyout', '미사용 휴가 1.5배 보상', NULL, 'compensation',
   'est', NULL, TRUE, '휴가촉진제 실시 후 25% 범위 내 미사용분에 대해 1.5배 보상 (2025 지속가능경영보고서 59쪽 휴가 보상 항목), 미사용 분에 대해 일부 1.5배 보상 (공식 홈페이지 인재경영 지표 Leisure 휴가 보상 항목) — 보상 기준 금액 미기재', 42),

  -- ── 가족 (family) — 보고서 59쪽 축하 선물 · 자녀 교육비 · 경조사 · 재해 · 사내 어린이집 / 58쪽 / 웹 ──
  (@comp_id, 'parenting', '출산 축하금·선물·보육비·자녀 입학 선물', NULL, 'family',
   'est', NULL, TRUE, '출산 축하금 및 선물 지원 (2025 지속가능경영보고서 59쪽 축하 선물 지급 항목), 출산 축하 선물 및 다자녀 출산 경조금 (공식 홈페이지 인재경영 지표 Engagement 축하 선물 지급 항목), 자녀 양육 지원 보육비 지급과 다자녀 출산 지원금, 법정 기준을 초과한 육아휴직 제도 운영 (같은 보고서 58쪽 가족친화제도), 아이 사랑 휴직 (인재경영 지표 Life 항목), 임직원 자녀 입학 선물 (인재경영 지표 Life 항목) — 축하금·보육비 금액, 지원 연령, 육아휴직 초과 기간·휴직 중 급여 미기재', 50),
  (@comp_id, 'child_edu', '자녀 학자금 (고교·대학 입학금·등록금)·유치원 보조비', NULL, 'family',
   'est', NULL, TRUE, '근속 년수에 따라 국·내외 고등학생, 대학생 자녀가 있는 임직원에게 입학금과 등록금 지원 (2025 지속가능경영보고서 59쪽 자녀 교육비 지원 항목), 유치원 보조비 지급 (같은 보고서 58쪽 가족친화제도 자녀 양육 지원 항목), 유치원 보조비, 자녀 학자금 지원 (공식 홈페이지 인재경영 지표 Life 항목) — 근속 연수 기준·지원 한도·유치원 보조비 금액·자녀 수 제한 미기재', 51),
  (@comp_id, 'event', '경조사·재해 지원·작은 사랑 나눔회', NULL, 'family',
   'est', NULL, TRUE, '본인 및 가족의 결혼, 사망 시 경조금과 휴가 부여 (2025 지속가능경영보고서 59쪽 경조사 지원 항목), 임직원 본인 혹은 직계 존비속을 대상으로 가옥 침수, 농지 피해 및 화재피해 등에 대한 지원금 지급 (같은 보고서 59쪽 재해 지원 항목), 구성원의 갑작스러운 어려움에 함께 힘을 보태는 상생 지원 제도 (공식 홈페이지 인재경영 지표 Life 작은 사랑 나눔회 항목) — 경조 종류별 금액·휴가 일수, 재해 지원금 금액, 나눔회 지원 내용·재원 미기재', 52),
  (@comp_id, 'childcare', '사내 어린이집 (GS강서타워·GS강남타워)', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 대상 사내 어린이집 운영 (2025 지속가능경영보고서 59쪽 사내 어린이집 운영 항목 · 58쪽 푸르니 어린이집), GS강서타워 / GS강남타워 사내 어린이집 운영 (공식 홈페이지 인재경영 지표 Life 항목) — 정원·이용 비용 미기재', 53),

  -- ── 여가 (leisure) — 보고서 59쪽 스포츠 티켓 · 휴양 시설 · 인포멀 / 58쪽 패밀리 데이 ──
  (@comp_id, 'sports_ticket', '스포츠 티켓 지원 (FC서울·GS칼텍스·LG트윈스)', NULL, 'leisure',
   'est', NULL, TRUE, 'FC서울 축구, GS칼텍스 배구, LG트윈스 야구 경기 티켓 지원 (2025 지속가능경영보고서 59쪽 스포츠 티켓 지원 항목) — 지원 매수·횟수 미기재', 60),
  (@comp_id, 'resort', '휴양시설 지원', NULL, 'leisure',
   'est', NULL, TRUE, '연중 무료 또는 저렴한 가격에 휴양시설 이용 지원 (2025 지속가능경영보고서 59쪽 휴양 시설 항목), 휴양시설 할인 혜택 지원 (공식 홈페이지 인재경영 지표 Leisure 휴양시설 지원 항목) — 시설 위치·이용 횟수 미기재', 61),
  (@comp_id, 'club', '인포멀 (사내 동호회) 활동비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '조직 생활을 영위하도록 돕는 동호회 활동비 지원 (2025 지속가능경영보고서 59쪽 인포멀 항목), 인포멀(사내 동호회) (공식 홈페이지 인재경영 지표 Leisure 항목) — 활동비 금액 미기재', 62),
  (@comp_id, 'company_event', '패밀리 데이 (임직원 가족 초청)', NULL, 'leisure',
   'est', NULL, TRUE, '2025년 가정의 달을 맞아 임직원 가족을 초청하는 패밀리 데이 운영, 사무공간 탐방·체험형 프로그램·소통 중심 활동 (2025 지속가능경영보고서 58쪽 가족친화제도 항목) — 정례 개최 여부 미기재', 63),

  -- ── 성장 (growth) — 보고서 59쪽 어학 · 대학원 · 자격증 / 56쪽 자기주도 학습 / 실적자료 퇴직자 지원 ──
  (@comp_id, 'lang', '어학 지원 (응시료·학습비)', NULL, 'growth',
   'est', NULL, TRUE, '자기개발 지원을 위해 어학 시험 응시료 및 어학 학습비 지원 (2025 지속가능경영보고서 59쪽 어학 지원 항목), 구성원의 자기계발을 위한 어학 학습 비용 지원 (공식 홈페이지 인재경영 지표 Work 어학 지원 항목) — 지원 한도·횟수 미기재', 70),
  (@comp_id, 'mba', '대학원 학위취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무 연관 전공분야 학위 취득을 위한 대학원 학비 지원 (2025 지속가능경영보고서 59쪽 대학원 학위취득 지원 항목) — 지원 비율·선발 기준 미기재', 71),
  (@comp_id, 'self_development', '자격증 학습비 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무 관련 자격등 취득비용 지원 (2025 지속가능경영보고서 59쪽 자격증 학습비 지원 항목), 자격증 학습에 필요한 비용 지원 (공식 홈페이지 인재경영 지표 Work 자격증 지원 항목) — 지원 한도·대상 자격증 미기재', 72),
  (@comp_id, 'edu_support', '자기주도 학습 지원 (이러닝·특강·사외교육)', NULL, 'growth',
   'est', NULL, TRUE, '내일On (이러닝 플랫폼), 전사 인사이트 특강, 자기주도학습/사외과정 지원제도 (2025 지속가능경영보고서 56쪽 자기주도 학습 · 공식 홈페이지 인재육성체계 자기주도 학습 항목), 홈쇼핑BU에서는 구성원이 원하는 사외교육을 자율적으로 선택해 학습할 수 있도록 연간 교육비 한도 내에서 지원 (같은 보고서 56쪽) — 교육비 한도 금액 미기재', 73),
  (@comp_id, 'retirement_support', '퇴직자 창업지원 (New Start Program)', NULL, 'growth',
   'est', NULL, TRUE, '50세 이후 퇴직 시 GS리테일 운영 가맹점(GS25, GS THE FRESH) 최초 창업 시 창업비용 지원, 재직 시 학자금 지원 기준으로 자녀 학자금 지급, 퇴직 후 가맹점 창업 대출이자 지원 (공식 홈페이지 인재경영 실적자료 퇴직자 지원 창업·재고용 제도, 2018년 1월 개정), 2025년 New Start Program 3명 (2025 지속가능경영보고서 107쪽) — 창업비용 지원 금액 미기재', 74),

  -- ── 근무 유연성 (flexibility) — 웹 인재경영 지표 시차근무제 / 보고서 58쪽 ──
  (@comp_id, 'flex_work', '시차근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '일의 몰입도와 삶의 균형을 위해 출퇴근 시간을 유연하게 조율 (공식 홈페이지 인재경영 지표 Work 시차근무제 항목), 유연근무제 운영 (2025 지속가능경영보고서 58쪽 일·가정 양립 우수기업 항목) — 출퇴근 시간대 범위·적용 대상 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
