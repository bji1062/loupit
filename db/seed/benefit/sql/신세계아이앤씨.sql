-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 신세계 I&C 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://shinsegae-inc.com/company/culture.do
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 CAREER > 인재경영 페이지(SSR · 원본 HTML 에 복지 7묶음 · 렌더 없음).
--     헤더 메뉴 goMenu(501010) 의 /company/career/culture.do 가 /company/culture.do 로 넘어가므로 넘어간 뒤 주소를 정본으로 둠.
--     www.shinsegae-inc.com 은 인증서에 www 가 없어 TLS 실패 — apex shinsegae-inc.com 만 씀.
--   보조 = 자기 도메인 ESG > 지속가능경영보고서 목록의 「신세계아이앤씨 지속가능경영보고서 2025」 PDF
--     (2026-06-29 게시 · 보고 기간 2025-01-01 ~ 2025-12-31 · 비재무 범위 = 신세계아이앤씨 국내 본사 · 데이터센터 별도)
--     45 · 46 · 48 · 49 · 60쪽, OpenDART 2026 반기보고서(20260814003752) · 2025 사업보고서(20260316001238) 유연근무제도 사용 현황 표.
--   귀속 = 이 법인 자기 도메인 페이지(주어 신세계아이앤씨)와 이 법인 단독 보고서 — 각주 없음.
--     기등록 형제 이마트(그룹 채용 포털 공고) · 신세계인터내셔날(그룹 포털 각주)과 같은 그룹 문구는 근거표 형제 절.
--   금액 = 금액 행 0. 콘도비 1년 최대 16만원은 한도라 NULL, 식당은 끼니 없음 · 식대 보조라 NULL.
--   제외 = 법정(육아기 근로시간 단축 · 보상시간 적립 휴가) · 업무 교육(SSG Academy 집합 직무 교육 · 전문가 양성 · 리더 · 입문 · 온보딩) ·
--     호칭 · 복장 문화 · 보건 안내 캠페인 · 사내 AI혁신상 사례 서술.
--   공고 근거 0행 / 전체 25행.
--   SORT 섹션 순서 = flexibility 10 · growth 20 · time_off 30 · perks 40 · family 50 · leisure 60 · compensation 70 · health 80.
-- 검증 · 감사 판정 반영(2026-10-22): 온라인 학습 플랫폼 행 꼬리를 글로벌 교육 플랫폼 이름 · 과정 수 미기재로(Spharos Academy 는 원문이 이름을 밝힘) · 연중휴가 5일은 이 법인 원문에 연차 외 낱말이 없어 leave_general 유지 · 항목 페이지 예외 4(통합 밖 리드 집행) — 최종 25행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('shinsegae_inc', '신세계 I&C',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        'IT서비스', 'S', 'https://shinsegae-inc.com/company/culture.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'shinsegae_inc');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://shinsegae-inc.com/company/culture.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 인재경영 1 Smart Working · 보고서 46쪽 · 공시 ──
  (@comp_id, 'flex_work', '유연근무제(선택적 근로시간제)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 : 직무 별 업무 패턴에 따라 출퇴근 시간 선택 가능 (공식 채용 페이지 인재경영 Smart Working 항목), 2018년부터 선택적 근로시간제를 월 단위 총근로시간 범위 내에서 구성원이 업무 특성과 개인 일정에 맞게 근무시간을 자율적으로 조정 · 자율 출퇴근 제도 운영 (2025 지속가능경영보고서 46쪽 유연하고 합리적인 근무환경 조성 항목), 선택근무제 사용자 수 2026년 반기 1,179명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 코어타임·신청 절차 미기재', 10),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 2026년 반기 645명, 2025년 871명, 2024년 970명 (2026 반기보고서 · 2025 사업보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 11),

  -- ── 성장·커리어 (growth) — 인재경영 3 자기계발 지원 프로그램 · 교육로드맵 · 보고서 45쪽 ──
  (@comp_id, 'edu_support', '온라인 학습 플랫폼·글로벌 교육 플랫폼', NULL, 'growth',
   'est', NULL, TRUE, 'Spharos Academy 이러닝·북러닝으로 IT/DT는 물론 인문, 글로벌, 리더십 교육까지 소프트 스킬 과정 제공, 기술 트렌드 파악 및 다양한 지식 함양을 위한 전 임직원 대상 글로벌 교육 전문 플랫폼 이용 지원 (공식 채용 페이지 인재경영 자기계발 지원 프로그램 항목), 원하는 과정을 언제든 편하게 선택해 수강 (같은 페이지 교육로드맵 역량교육 항목) — 글로벌 교육 플랫폼 이름·과정 수 미기재', 20),
  (@comp_id, 'lang', '외국어 교육', NULL, 'growth',
   'est', NULL, TRUE, '외국어 콘텐츠를 온라인 자체 교육 플랫폼 스파로스 아카데미 및 외부 글로벌 교육 플랫폼으로 상시 제공 (2025 지속가능경영보고서 45쪽 온라인 교육 플랫폼 제공 항목), 외국어 교육 (리더급) (같은 보고서 45쪽 교육 체계도 항목) — 외국어 과정 종류·수강 비용 지원 범위 미기재', 21),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무/직무/사업 관련 자격증 취득 시 자격증 응시 비용 지원, 자격증 취득 시 인센티브 지급 (SAP, 클라우드, DS 일부 자격증 한정) (공식 채용 페이지 인재경영 교육로드맵 자격증 취득 지원 항목), 특정 자격증(SAP, Cloud) 취득 시 인센티브 추가 지급 (2025 지속가능경영보고서 45쪽 자격증 취득 지원 항목) — 응시 비용 지원 한도·인센티브 금액 미기재', 22),

  -- ── 휴가·휴직 (time_off) — 인재경영 4 Work & Life Balance ──
  (@comp_id, 'leave_general', '리프레시 데이·연중휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '리프레시 데이, 한달에 한번 평일에 모든 직원이 쉰다, 다양한 휴가제도 1년에 5일 연중휴가 (공식 채용 페이지 인재경영 Work & Life Balance 항목) — 리프레시 데이 지정 요일·유급 여부, 연중휴가의 부여 조건·본인 휴가 차감 여부 미기재', 30),
  (@comp_id, 'long_service_leave', '장기근속휴가', NULL, 'time_off',
   'est', NULL, TRUE, '다양한 휴가제도 중 장기근속휴가 (공식 채용 페이지 인재경영 Work & Life Balance 항목) — 대상 근속 연수·휴가 일수 미기재', 31),

  -- ── 경제적 부가혜택 (perks) — 인재경영 4 · 5 Specialty · 6 Leisure & Life ──
  (@comp_id, 'meal', '직원식당·식대보조', NULL, 'perks',
   'est', NULL, TRUE, '직원식당 및 식대보조 (공식 채용 페이지 인재경영 Work & Life Balance 항목) — 제공 끼니·식대 보조 금액 미기재', 40),
  (@comp_id, 'transport', '교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '교통비 지원 (공식 채용 페이지 인재경영 Work & Life Balance 항목) — 지원 대상·지원 금액 미기재', 41),
  (@comp_id, 'discount', '신세계 계열사 이용 혜택', NULL, 'perks',
   'est', NULL, TRUE, '신세계백화점, 이마트, 스타벅스, 이마트24, 신세계푸드, 신세계면세점, 신세계라이브쇼핑, 신세계L&B, SSG랜더스 야구단 홈경기 등 신세계그룹의 모든 할인 혜택 제공 (공식 채용 페이지 인재경영 Specialty 신세계계열사 이용 혜택 항목) — 할인율·연간 한도 미기재', 42),
  (@comp_id, 'birthday_gift', '생일 선물 (SSG머니)', NULL, 'perks',
   'est', NULL, TRUE, '생일에는 SSG머니 선물 지급 (공식 채용 페이지 인재경영 Leisure & Life 선물 지급 항목) — 지급액 미기재', 43),

  -- ── 가족·돌봄 (family) — 인재경영 4 · 6 · 보고서 46쪽 ──
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 (공식 채용 페이지 인재경영 Work & Life Balance 항목) — 설치 위치·정원·대상 연령 미기재', 50),
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금 지원 (결혼, 수연, 조의, 출산 등) (공식 채용 페이지 인재경영 Leisure & Life 항목), 경조휴가 (같은 페이지 Work & Life Balance 다양한 휴가제도 항목) — 경조금 액수·경조휴가 일수 미기재', 51),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 학자금 지원 (유치원부터 대학생까지 학자금 지원) (공식 채용 페이지 인재경영 Leisure & Life 항목) — 지원 한도·자녀 수 제한 미기재', 52),
  (@comp_id, 'parenting', '임신·출산 축하 선물·임신 전 기간 단축근무·입학 자녀 돌봄 휴직', NULL, 'family',
   'est', NULL, TRUE, '임신 근로자 축하선물 과일바구니, 출산 축하 선물로 경조금과 아이 사랑 박스(출산 후 필요한 육아용품으로 구성) 지원, 임신 사실을 인지한 시점부터 출산휴가 전까지 임금삭감 없이 하루 2시간 단축 근무 (법적 기준 이상으로 임신 전 기간에 걸쳐 적용), 초등학교 입학 자녀를 둔 직원의 돌봄 휴직 제도 (입학한 때부터 1개월) (2025 지속가능경영보고서 46쪽 안정적인 출산 환경 조성 · 가족을 위한 유연근무제 항목) — 선물 금액·돌봄 휴직 유급 여부 미기재', 53),

  -- ── 여가·라이프 (leisure) — 인재경영 6 Leisure & Life · 보고서 46쪽 ──
  (@comp_id, 'resort', '콘도비·신세계그룹 숙박 시설 혜택', NULL, 'leisure',
   'est', NULL, TRUE, '콘도비 지원 (1년 최대 16만원), 신세계그룹 숙박 시설 관련 숙박/할인 혜택 제공 (포포인츠, 영랑호리조트, 조선호텔, 레스케이프, JW메리어트 호텔 등) (공식 채용 페이지 인재경영 Leisure & Life 여가생활 지원 항목), 임직원 휴양을 위한 휴양소 및 휴양비 지원 (2025 지속가능경영보고서 46쪽 워라밸 중심 복리후생 운영 항목) — 이용 횟수·성수기 조건 미기재', 60),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 동호회 활동 (축구, 볼링, 낚시, 독서, 클라이밍 등) (공식 채용 페이지 인재경영 Leisure & Life 항목) — 동호회 수·활동비 지원액 미기재', 61),
  (@comp_id, 'company_event', '그룹 연수시설 공연 관람·취미활동 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '그룹 연수시설에서의 공연 관람 및 취미활동 프로그램 지원 (2025 지속가능경영보고서 46쪽 워라밸 중심 복리후생 운영 항목) — 개최 주기·참여 대상 미기재', 62),

  -- ── 보상·금전 (compensation) — 인재경영 6 선물 지급 · 보고서 46 · 60쪽 ──
  (@comp_id, 'holiday_gift', '명절 선물 (SSG머니)', NULL, 'compensation',
   'est', NULL, TRUE, '설, 추석에는 SSG머니 선물 지급 (공식 채용 페이지 인재경영 Leisure & Life 선물 지급 항목), 명절 선물 제공 (2025 지속가능경영보고서 46쪽 워라밸 중심 복리후생 운영 항목) — 지급액 미기재', 70),
  (@comp_id, 'excellence_award', '봉사활동 CSR 마일리지 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '봉사시간에 따라 CSR 마일리지를 지급하여 일정수준 이상으로 쌓이면 상품권으로 교환해 주는 인센티브 제도 운영 (2025 지속가능경영보고서 60쪽 봉사활동 CSR 마일리지 항목) — 마일리지 적립 기준·교환 상품권 금액 미기재', 71),

  -- ── 건강·의료 (health) — 인재경영 7 Health & Care · 보고서 46 · 48 · 49쪽 ──
  (@comp_id, 'health_check', '정기 건강검진', NULL, 'health',
   'est', NULL, TRUE, '정기 건강 검진 지원 (공식 채용 페이지 인재경영 Health & Care 항목, 2025 지속가능경영보고서 46쪽 워라밸 중심 복리후생 운영 항목) — 검진 주기·비용 지원 범위 미기재', 80),
  (@comp_id, 'medical', '의료비 지원 (본인·배우자·자녀)', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (본인, 배우자, 자녀) (공식 채용 페이지 인재경영 Health & Care 항목), 임직원 본인 및 배우자와 자녀의 의료비 지원 (2025 지속가능경영보고서 46쪽 워라밸 중심 복리후생 운영 항목) — 연간 한도·지원 비율 미기재', 81),
  (@comp_id, 'insurance', '직원 보험 가입', NULL, 'health',
   'est', NULL, TRUE, '직원 보험 가입 (공식 채용 페이지 인재경영 Health & Care 항목) — 보험 종류·보장 범위 미기재', 82),
  (@comp_id, 'clinic', '건강지원실 (본사)', NULL, 'health',
   'est', NULL, TRUE, '본사 건강지원실 운영, 일상적으로 필요한 의약품 수령과 건강상담 · 건강체크 이용 (2025 지속가능경영보고서 48쪽 건강지원실 운영 항목) — 운영 시간·상주 인력 미기재', 83),
  (@comp_id, 'mental', 'EAP 심리상담', NULL, 'health',
   'est', NULL, TRUE, 'EAP(근로자 지원 프로그램) 운영, 한국EAP협회를 통한 전문적이고 비밀 보장이 가능한 심리상담 서비스를 임직원 및 가족이 대면·비대면으로 신청, 임신근로자 건강·심리상담 지원 (2025 지속가능경영보고서 49쪽 EAP 운영 · 임신근로자 건강·심리상담 지원 항목) — 연간 상담 횟수 한도 미기재', 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
