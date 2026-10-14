-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LX인터내셔널 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.lxinternational.com/kr/recruit
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)엘엑스인터내셔널 자기 도메인 www.lxinternational.com 채용소개 페이지(채용정보 · 교육 · 혜택 절)다.
--   SSR 이라 원본 HTML 에 LXI Benefits 9블록과 교육 절 텍스트가 다 있다(HTML 주석 66개는 걷었고 복지 블록은 없다).
--   보조 출처: 같은 도메인 ESG > Social 페이지 일과 삶의 균형 임직원 복리후생 4항목, 자료실에 올라 있는
--   2026 지속가능경영보고서(PDF 132쪽 · 2026-08 작성 · 보고 기간 2025-01-01~2025-12-31 · 보고 범위 국내 사업장 중심,
--   자회사 LX판토스 · LX글라스 등은 별도 표기) 61 · 70 · 71 · 72 · 73 · 74 · 75 · 81쪽,
--   OpenDART 2026 반기보고서(접수 20260814001146) 직원 등 현황 · 유연근무제도 사용 현황.
--   귀속: 정본과 Social 페이지 주어가 LX인터내셔널 단수이고 그룹 · 계열사 단서가 없다. 보고서 문장도 LX인터내셔널 주어만 썼다
--   (자회사 표기 문단 제외). 각주 없음. 코퍼스 · 대기 폴더에 LX 형제 없음.
--   금액: meal 1행만 추정(조식 1끼 × 12,000원 × 240일 = 288). 출산 축하금 100만원은 1회성이라 NULL. 나머지 전 행 NULL.
--   제외: 법정(가족돌봄휴직 · 휴가 · 임신기 근로시간 단축 · 퇴직연금) · 업무 교육(신입 · 경력 입문 · 온보딩 · 멘토링 ·
--     직급별 필수 교육 · 해외현장연수 · 주재원 파견 전 교육 · 리더십 · 최고경영자 과정 · 코칭 · 선발교육 전문자격 취득 과정) ·
--     급여성(직책수당) · 자율복장(대응 코드 없음) · 팀 단위 워크숍 · 가족친화인증 지자체 할인(회사 급부 아님) ·
--     임원 보수 칸 복리후생 문장 · LX MDI 마켓 인텔리전스(업무 정보).
--   공고 근거 0행 / 전체 29행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(growth 10 · perks 20 · leisure 30 · health 40 · family 50),
--     보조 출처에만 있는 compensation 60 · flexibility 70 · time_off 80.
-- 검증 · 감사 판정 반영(2026-10-14): 직무별 사외 교육 · 세미나 conference 삭제(업무 교육) · 어학 행 꼬리 정정 · 팀 단위 워크숍을 행사 행에 병합(참고 블록 제외 줄의 팀 단위 워크숍은 이 판정으로 뒤집힘) · 89쪽 금연 클리닉 smoking_cessation · 본사 건강관리실 clinic 추가 — 최종 30행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lx_international', 'LX인터내셔널',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '종합상사', 'L', 'https://www.lxinternational.com/kr/recruit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lx_international');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lxinternational.com/kr/recruit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 (growth) — 채용소개 교육 절 · 보고서 71 · 72 · 73 · 74 · 75쪽 ──
  (@comp_id, 'mba', '국내외 MBA 파견', NULL, 'growth',
   'est', NULL, TRUE, '국내외 MBA파견 (공식 채용 페이지 교육 전문교육 프로그램 항목), LX Aalto MBA (2026 지속가능경영보고서 72쪽 인재 육성 체계 선발교육 항목) — 선발 기준·지원 범위 미기재', 10),
  (@comp_id, 'lang', '사내 어학교육·자율 어학교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '중국어, 인도네시아어, 베트남어 등에 대한 집중 어학 코스 및 사내 정기 어학교육, 자율적인 어학교육 지원 (공식 채용 페이지 교육 어학교육 항목), 상·하반기 사내 어학 과정으로 영어 및 제2외국어를 입문·초급·중급·고급 수준별로 외부 강사 초빙 주 2~3회 회당 1시간 진행 (2026 지속가능경영보고서 74쪽 임직원 대상 교육 활동 항목), 공인 어학 Test 응시비용 지원 (같은 보고서 75쪽 인재 확보 및 육성 로드맵 2024 항목) — 수강료 지원 범위·응시비용 지원 한도 미기재', 11),
  (@comp_id, 'edu_support', '사내 스터디·사내 특강·온라인 교육', NULL, 'growth',
   'est', NULL, TRUE, '교재비, 온라인 강의비, 중식비 등을 지원하는 사내 스터디 제도, 인문학·산업 분석·시장 현황·국제 정세 등을 주제로 한 사내 특강 정기 운영, 온라인 교육 플랫폼을 통한 다양한 학습 콘텐츠 제공 (2026 지속가능경영보고서 73쪽 사내 스터디 제도 · 사내 특강 · 온라인 학습 인프라 구축 항목) — 스터디별 지원 한도 미기재', 12),
  (@comp_id, 'retirement_support', '퇴직 임직원 전직 지원', NULL, 'growth',
   'est', NULL, TRUE, '필요 시 전문 컨설팅 업체를 통한 1:1 개별 컨설팅과 교육·워크숍을 제공하여 퇴직 임직원의 원활한 전직과 경력 연속성 지원 (2026 지속가능경영보고서 71쪽 퇴직자 지원 항목) — 대상 연령·지원 기간 미기재', 14),
  -- ── 생활 · 금융 (perks) — 채용소개 LXI Benefits · 보고서 74쪽 ──
  (@comp_id, 'welfare_point', '선택적 복리후생', NULL, 'perks',
   'est', NULL, TRUE, '건강관리, 자기계발, 문화/여가 용도로 물품 구입 또는 서비스 이용시 한도내 지원 (공식 채용 페이지 LXI Benefits 선택적 복리후생 항목), 선택적 복리후생 지원 (2026 지속가능경영보고서 74쪽 임직원 복리후생 여가 및 문화 항목) — 연간 한도 금액 미기재', 20),
  (@comp_id, 'housing_loan', '주택자금 대출 이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택전세 및 구입시 대출 이자 지원 (공식 채용 페이지 LXI Benefits 주택자금 대출 지원 항목), 주택자금 대출 지원 (2026 지속가능경영보고서 74쪽 임직원 복리후생 생활 항목) — 대출 한도·이자 지원율 미기재', 21),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 (공식 채용 페이지 LXI Benefits ETC 항목, 2026 지속가능경영보고서 74쪽 임직원 복리후생 근무 항목) — 운행 노선·사업장 미기재', 22),
  (@comp_id, 'meal', '조식 제공', 288, 'perks',
   'est', '매일 조식 제공 (2026 지속가능경영보고서 74쪽 임직원 복리후생 항목) — 중식·석식 제공 여부·식대 단가 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 23),
  (@comp_id, 'snack_bar', '오후 과일컵', NULL, 'perks',
   'est', NULL, TRUE, '오후 과일컵 제공 (2026 지속가능경영보고서 74쪽 임직원 복리후생 항목) — 제공 장소·대상 사업장 미기재', 24),
  (@comp_id, 'birthday_gift', '본인 생일자 지원', NULL, 'perks',
   'est', NULL, TRUE, '본인 생일자 지원 (2026 지속가능경영보고서 74쪽 임직원 복리후생 경조사 항목) — 지원 형태·금액 미기재', 25),
  -- ── 여가 (leisure) — 채용소개 LXI Benefits · 보고서 73 · 74 · 81쪽 ──
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '야구, 축구, 스노우보드 등 동호회 활동 지원 (공식 채용 페이지 LXI Benefits 스포츠 활동 지원 항목), 사내 동호회 지원 확대 (2026 지속가능경영보고서 81쪽 조직 문화 활성화 항목) — 동호회별 지원 금액 미기재', 30),
  (@comp_id, 'sports_ticket', '홈경기 스포츠 티켓 지원', NULL, 'leisure',
   'est', NULL, TRUE, '홈경기 스포츠 티켓 지원 (LG트원스) (공식 채용 페이지 LXI Benefits 스포츠 활동 지원 항목) — 지원 매수·신청 방식 미기재', 31),
  (@comp_id, 'resort', '콘도·생활연수원 이용', NULL, 'leisure',
   'est', NULL, TRUE, '회사 보유 콘도회원권 이용, LG생활연수원 무료 이용 (공식 채용 페이지 LXI Benefits 콘도/생활연수원 이용 항목), 콘도/생활연수원 이용 (2026 지속가능경영보고서 74쪽 임직원 복리후생 여가 및 문화 항목) — 이용 횟수·콘도 본인 부담 미기재', 32),
  (@comp_id, 'company_event', '임직원 행사·사내 스포츠 행사', NULL, 'leisure',
   'est', NULL, TRUE, '가정의 달·복날 등 연중 특별한 시기에 임직원 행사 운영 (2026 지속가능경영보고서 73쪽 조직문화 프로그램 운영 항목), 사내 탁구 대회 등 스포츠 행사 (같은 보고서 81쪽 조직 문화 활성화 항목), 팀 단위 워크숍 지원 (같은 보고서 73쪽 조직문화 프로그램 운영 항목) — 행사 내용·참가 대상·워크숍 지원 범위 미기재', 33),
  (@comp_id, 'library', '사내 전자 도서관', NULL, 'leisure',
   'est', NULL, TRUE, '사내 전자 도서관을 통한 자유로운 독서 활동과 학술논문 열람 (2026 지속가능경영보고서 73쪽 온라인 학습 인프라 구축 항목) — 이용 가능 자료 범위 미기재', 34),
  -- ── 건강 (health) — 채용소개 LXI Benefits · ESG Social 페이지 · 보고서 74쪽 ──
  (@comp_id, 'health_check', '본인·배우자 정기 건강검진', NULL, 'health',
   'est', NULL, TRUE, '본인 및 배우자 정기 건강검진 실시 (공식 채용 페이지 LXI Benefits 건강검진/의료비 보험 지원 항목), 종합검진 대상 연령 하향 적용 (2026 지속가능경영보고서 74쪽 임직원 복리후생 건강 항목) — 검진 주기·종합검진 대상 연령·비용 지원 범위 미기재', 40),
  (@comp_id, 'medical', '본인·가족 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '본인 및 가족 의료비 지원 (공식 채용 페이지 LXI Benefits 건강검진/의료비 보험 지원 항목), 의료비 보험지원 (2026 지속가능경영보고서 74쪽 임직원 복리후생 건강 항목) — 지원 한도·가족 범위 미기재', 41),
  (@comp_id, 'overseas_safety', '해외 출장자·주재원 지원', NULL, 'health',
   'est', NULL, TRUE, '해외 상해보험 및 납치보험 가입, 급지근무지 응급 후송지원 및 부식지원 (공식 채용 페이지 LXI Benefits 해외 출장자 / 주재원 지원 항목), 해외 출장자 및 주재원 지원 (2026 지속가능경영보고서 74쪽 임직원 복리후생 생활 항목) — 보험 보장 범위 미기재', 42),
  (@comp_id, 'mental', '마음n마음 심리상담실', NULL, 'health',
   'est', NULL, TRUE, '마음n마음 심리상담실 상시(월~금) 운영, 모든 임직원이 업무 스트레스부터 일상생활 고민까지 상담 가능 (공식 ESG Social 페이지 일과 삶의 균형 심리상담실 운영 항목) — 상담 횟수·가족 이용 여부 미기재', 43),
  (@comp_id, 'smoking_cessation', '금연 클리닉', NULL, 'health',
   'est', NULL, TRUE, '종로구 보건소와 연계한 전문 금연 상담, 니코틴 보조제 제공, 코티닌 검사 등 금연 클리닉 프로그램 운영 (2026 지속가능경영보고서 89쪽 금연 클리닉 운영 항목) — 참여 대상·운영 기간 미기재', 44),
  (@comp_id, 'clinic', '본사 건강관리실', NULL, 'health',
   'est', NULL, TRUE, '본사 건강관리실 운영, 임직원의 건강 상태 상시 관리 (2026 지속가능경영보고서 89쪽 건강관리실 및 의무실 운영 항목) — 의료 인력·운영 시간 미기재', 45),
  -- ── 가족 (family) — 채용소개 LXI Benefits · ESG Social 페이지 · 보고서 74 · 75쪽 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '고등학교 및 대학교 학자금 지원, 자녀수 제한 없이 입학금, 등록금 일체 (공식 채용 페이지 LXI Benefits 자녀 학자금 지원 항목), 자녀 학자금 지원 (2026 지속가능경영보고서 74쪽 임직원 복리후생 가족 지원 항목) — 지원 학기 수 미기재', 50),
  (@comp_id, 'event', '경조금·경조화환·상조용품', NULL, 'family',
   'est', NULL, TRUE, '본인 및 직계가족의 결혼, 조의 등 경조금 지급, 경조화환 및 상조용품 지원 (공식 채용 페이지 LXI Benefits 경조사 지원 항목), 경조사 지원 (2026 지속가능경영보고서 74쪽 임직원 복리후생 경조사 항목) — 경조 사유별 금액 미기재', 51),
  (@comp_id, 'childcare', '직장 내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 내 어린이집 설치 (2026 지속가능경영보고서 74쪽 임직원 복리후생 가족 지원 항목), 직장 내 어린이집 운영 (같은 보고서 75쪽 출산 및 육아 지원 제도 항목, 공식 ESG Social 페이지 출산 및 육아 지원제도 항목) — 정원·위치 미기재', 52),
  (@comp_id, 'parenting', '자녀 출산 축하금·임신·출산·입학 선물', NULL, 'family',
   'est', NULL, TRUE, '2025년 신설 자녀 출산 축하금 100만원, 임직원 자녀 출산, 초중고 입학 등 선물 지급 (2026 지속가능경영보고서 74쪽 임직원 복리후생 가족 지원 항목), 임신 및 출산 축하 선물 지급 (같은 보고서 75쪽 출산 및 육아 지원 제도 항목) — 선물 품목·금액 미기재', 53),
  -- ── 보상 (compensation) — 보고서 61 · 70 · 81쪽 · 2026 반기보고서 ──
  (@comp_id, 'incentive', '경영성과급·개인성과급·수시성과급', NULL, 'compensation',
   'est', NULL, TRUE, '업무 성과에 따른 차별화를 통한 동기부여를 위하여 경영성과급, 개인성과급, 수시성과급 등 지급 (2026 지속가능경영보고서 70쪽 성과 평가 항목), 전사 구성원에 대한 경영성과급 (2026 반기보고서 직원 등 현황 항목) — 지급 기준·지급률 미기재', 60),
  (@comp_id, 'excellence_award', '우수인재상·모범인재상 등 포상제도', NULL, 'compensation',
   'est', NULL, TRUE, '우수인재상/모범인재상 등의 포상제도 (2026 지속가능경영보고서 70쪽 성과 평가 항목), 조직문화 기여자 포상 (같은 보고서 81쪽 조직 문화 활성화 항목), 사회공헌 활동 참여 횟수와 시간을 종합 산정해 상·하반기 연 2회 봉사왕 1명과 다수의 참여 우수자를 선정하는 LEXT 봉사왕 및 참여 우수자 포상 (같은 보고서 61쪽 사회공헌 임직원 포상 제도 항목) — 포상 내용·1인당 금액 미기재', 61),
  -- ── 근무 유연성 (flexibility) — ESG Social 페이지 · 보고서 74 · 75쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '근무시간 자율관리제 (자율 출퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '2018년부터 근무시간 자율관리제 도입, 임직원 스스로 출퇴근 시간 지정 (공식 ESG Social 페이지 근무시간 자율관리제 항목), 핵심 근무시간을 준수하는 범위 내에서 출퇴근 시간을 자유롭게 설정 (2026 지속가능경영보고서 75쪽 근무시간 자율관리제 및 유연근무제도 항목), 자율 출퇴근제, 유연근무제도 시행 (같은 보고서 74쪽 임직원 복리후생 근무 항목), 선택근무제 (2026 반기보고서 유연근무제도 사용 현황 항목) — 핵심 근무시간대 미기재', 70),
  (@comp_id, 'remote_work', '원격근무 지원', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무 지원 (2026 지속가능경영보고서 74쪽 임직원 복리후생 근무 항목) — 대상 직무·사용 조건 미기재', 71),
  -- ── 휴가 (time_off) — ESG Social 페이지 ──
  (@comp_id, 'long_service_leave', '장기근속 포상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 구성원이 리프레시 기간으로 활용할 수 있는 장기근속휴가 포상 제도, 10년·15년 근속 시 각각 3일, 20년·25년·30년·35년 근속 시 각각 5일의 별도 휴가 부여 (공식 ESG Social 페이지 장기근속 포상휴가 항목) — 유급 여부 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
