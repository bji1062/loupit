-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LX세미콘 복리후생 데이터 (신규 회사 — 웨이브 13)
-- 출처: AI 파싱 (2026-10-20)
-- URL: https://www.lxsemicon.com/kr/company/recruitment-information/personnel-management-system
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)엘엑스세미콘 자기 도메인 www.lxsemicon.com 채용정보 > 인사제도 페이지다
--   (SSR — 원본 HTML 에 임금체계 인센티브 · 성과급과 복리후생 Family Care · Health Care · Refresh Care 3묶음 19항목이 다 있다.
--   HTML 주석 7개는 영역 표시뿐이고 복지 블록은 없다).
--   보조 출처: 같은 도메인 지속가능경영 > 사회 > 구성원 페이지(조직문화 및 복리후생 · 심리상담실 · 상시 학습 문화 · 복리후생 표),
--   채용정보 > 인재육성 페이지, 자료실 Reports and Policies 에 올라 있는 2025-2026 지속가능경영보고서
--   (PDF 90쪽 · 2026-09 작성 · 보고 기간 2025-01-01~2025-12-31, 일부 2026 상반기 포함 · 보고 범위 본사 및 국내 사업장 중심,
--   해외 법인 일부 포함) 29 · 31 · 32 · 37쪽,
--   OpenDART 2026 반기보고서(접수 20260814003481) 유연근무제도 사용 현황 · 2025 사업보고서(접수 20260318001308) 재무제표 주석.
--   렌더: 헤드리스 렌더 없음(원본 HTML · PDF 텍스트 · OpenDART 원문 XML).
--   귀속: 정본 · 보조 페이지 · 보고서 문장 주어가 LX세미콘 단수이고 그룹 · 계열사 단서가 없다. 각주 없음.
--   기등록 형제 LX인터내셔널 · LX하우시스(각자 자기 도메인 정본)와 글자까지 겹치는 문장 없음 — LX 그룹 채용 사이트(lx.recruiter.co.kr)는 쓰지 않았다.
--   금액: meal 1행만 추정(조식 · 중식 · 석식 무상 3끼 × 12,000원 × 240일 = 864). 나머지 전 행 NULL(금액 미기재).
--   제외: 법정(출산휴가 및 육아기 근로제도 · 출산전후휴가 90일 · 배우자 출산휴가 20일 · 난임치료휴가 6일 중 최초 2일 유급 ·
--     가족돌봄휴가 10일 · 퇴직연금 · 일반 건강검진 · 재취업 지원 서비스(1년 이상 재직 50세 이상 정년퇴직 예정자 · 직원 1,417명)) ·
--     본인 휴가 사용 캠페인(권장휴가제) · 업무 교육(직무 · 신입 · 경력 · 직급 · 리더십 · 코칭 · 설계 아카데미 · 기술세미나 ·
--     주재원 파견 전 교육 · 법인 현채인 교육 · R&D 멘토링) · 자율복장제(대응 코드 없음) · 임원 보수 칸 · 우리사주조합 주주 표 한 칸 ·
--     패밀리데이(보고서 대응 전략 칸 이름뿐 — 판단 요청).
--   공고 근거 0행 / 전체 33행.
--   SORT 섹션 순서(정본 첫 등장 순): compensation · perks · family · health · time_off · leisure, 보조 출처만: flexibility · growth.
-- 검증 · 감사 판정 반영(2026-10-20): 우수 성과자 포상휴가를 excellence_award 에서 leave_general 로 재코딩(SORT 12 → 52 · 휴가만 주는 성과 포상) · 2025-2026 지속가능경영보고서 14쪽 패밀리데이 family_day 추가 · 참고 블록 제외 줄의 패밀리데이와 공고 근거 0행 / 전체 33행은 이 판정으로 뒤집힘(34행) — 최종 34행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lx_semicon', 'LX세미콘',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '반도체', 'L', 'https://www.lxsemicon.com/kr/company/recruitment-information/personnel-management-system');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lx_semicon');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lxsemicon.com/kr/company/recruitment-information/personnel-management-system'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 인사제도 페이지 임금체계 · Family Care · 보고서 29 · 31쪽 · 2025 사업보고서 ──
  (@comp_id, 'incentive', '인센티브·성과급', NULL, 'compensation',
   'est', NULL, TRUE, 'R&D프로젝트, 핵심과제 수행으로 사업성과 창출에 기여한 인원을 대상으로 인센티브 수시/정기 보상, 회사 경영 성과에 따른 지급여부 결정 및 개인 성과와 연계하여 지급 금액을 결정하는 성과급 (공식 채용 페이지 인사제도 임금체계 항목), 연봉 외 인센티브와 성과급을 별도로 지급하는 성과 보상 체계 (2025-2026 지속가능경영보고서 29쪽 성과 보상 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 (공식 채용 페이지 인사제도 복리후생 Family Care 항목), 장기 근속 포상 (2025-2026 지속가능경영보고서 31쪽 Refresh 항목), 장기 근속 임직원에게 장기종업원급여 제공 (2025 사업보고서 재무제표 주석 기타장기종업원급여 항목) — 근속 기준·급부 형태·금액 미기재', 11),

  -- ── 생활 · 금융 (perks) — 인사제도 페이지 Family Care · Health Care · Refresh Care · 구성원 페이지 · 보고서 31쪽 ──
  (@comp_id, 'housing_loan', '저금리 주택자금대출', NULL, 'perks',
   'est', NULL, TRUE, '저금리 주택자금대출 (공식 채용 페이지 인사제도 복리후생 Family Care 항목), 주택자금 대출 (공식 지속가능경영 구성원 페이지 복리후생 항목), 저금리 주택자금 대출 (2025-2026 지속가능경영보고서 31쪽 Life & Family 항목) — 대출 한도·이율·대상 미기재', 20),
  (@comp_id, 'commute_subsidy', '통근버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '근무지별 특성과 교통편을 고려한 통근버스 운영 (공식 채용 페이지 인사제도 복리후생 Health Care 항목) — 운행 노선·사업장 미기재', 21),
  (@comp_id, 'welfare_point', '선택적 복리후생 포인트', NULL, 'perks',
   'est', NULL, TRUE, '선택적 복리후생 포인트 지급 (공식 채용 페이지 인사제도 복리후생 Refresh Care 항목), 선택적 복리후생 제도(복지포인트) 지원 (공식 지속가능경영 구성원 페이지 복리후생 항목), 복지포인트 지급 (2025-2026 지속가능경영보고서 31쪽 Life & Family 항목) — 포인트 금액·사용처 미기재', 22),
  (@comp_id, 'meal', '사내 식당 (조식·중식·석식 무상 제공)', 864, 'perks',
   'est', '사내 식당 운영(조식, 중식, 석식 무상제공) (공식 지속가능경영 구성원 페이지 복리후생 Health 항목), Take-Out 전용 부스 운영 (2025-2026 지속가능경영보고서 31쪽 Health 항목) (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 23),
  (@comp_id, 'discount', '문화생활 할인', NULL, 'perks',
   'est', NULL, TRUE, '문화생활 할인(레저, 문화시설 등) (공식 지속가능경영 구성원 페이지 복리후생 Refresh 항목) — 제휴처·할인율 미기재', 24),

  -- ── 가족 (family) — 인사제도 페이지 Family Care · 구성원 페이지 · 보고서 31쪽 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (공식 채용 페이지 인사제도 복리후생 Family Care 항목), 자녀 학자금 전액 지원 (공식 지속가능경영 구성원 페이지 복리후생 Life & Family 항목) — 지원 학령·대상 자녀 수 미기재', 30),
  (@comp_id, 'event', '경조사 지원 (경조휴가·경조금·상조 서비스)', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원(경조휴가 및 경조금), 상조 서비스 (공식 채용 페이지 인사제도 복리후생 Family Care 항목), 경조사 및 재난재해 지원 (공식 지속가능경영 구성원 페이지 복리후생 항목), 결혼, 부모 회갑, 조의 등 경조사 지원, 경조휴가: 구성원 경조사 발생 시 부여, 재해 지원 (2025-2026 지속가능경영보고서 31쪽 경조사 지원·휴가 제도·Life & Family 항목) — 경조금 금액·휴가 일수 미기재', 31),
  (@comp_id, 'parenting', '출산 선물·자녀 입학 선물', NULL, 'family',
   'est', NULL, TRUE, '출산 선물, 자녀 입학 선물 (2025-2026 지속가능경영보고서 31쪽 경조사 지원 항목) — 선물 내용·금액 미기재', 32),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, 'LX세미콘 어린이집 운영 (공식 지속가능경영 구성원 페이지 복리후생 Life & Family 항목), 직장 어린이집 운영 (2025-2026 지속가능경영보고서 31쪽 운영제도 현황 항목) — 위치·정원·이용 대상 미기재', 33),

  -- ── 건강 (health) — 인사제도 페이지 Health Care · 구성원 페이지 · 보고서 31 · 37쪽 ──
  (@comp_id, 'medical', '본인·가족 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 의료비 지원, 임직원 가족 의료비 지원 (공식 채용 페이지 인사제도 복리후생 Health Care 항목), 본인 및 가족의료비 지원 (공식 지속가능경영 구성원 페이지 복리후생 Health 항목), 의료비 지원: 본인 및 배우자 대상 (2025-2026 지속가능경영보고서 31쪽 건강증진 지원 항목) — 지원 한도·가족 범위 미기재', 40),
  (@comp_id, 'health_check', '종합건강검진 (본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '본인 및 배우자 종합건강검진(만 35세 이상) (공식 채용 페이지 인사제도 복리후생 Health Care 항목), 근속 5년 이상 또는 만 35세 이상 구성원에게 종합검진 제공 (2025-2026 지속가능경영보고서 37쪽 구성원 건강관리 지원 항목) — 검진 주기·비용 지원 범위 미기재', 41),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 가입 (공식 채용 페이지 인사제도 복리후생 Health Care 항목), 단체 보험 가입(상해사망, 질병사망 등 대비) (2025-2026 지속가능경영보고서 31쪽 건강증진 지원 항목) — 보장 한도·가족 포함 여부 미기재', 42),
  (@comp_id, 'fitness', '체력단련실·헬스장', NULL, 'health',
   'est', NULL, TRUE, '체력단련실 운영 (공식 채용 페이지 인사제도 복리후생 Health Care 항목), 캠퍼스 내 헬스장 및 탁구장 운영 (공식 지속가능경영 구성원 페이지 복리후생 Health 항목) — 운영 캠퍼스·이용 시간 미기재', 43),
  (@comp_id, 'mental', '심리상담실 「The 공감」', NULL, 'health',
   'est', NULL, TRUE, '사내 심리상담실 「The 공감」 운영, 업무 스트레스, 대인관계, 가족 문제 등 심리상담 전문가와 연계한 전문적인 상담 및 맞춤형 솔루션 제공 (공식 지속가능경영 구성원 페이지 심리상담실 항목), 자녀 심리 프로그램 운영 (같은 페이지 복리후생 Life & Family 항목) — 이용 횟수·비용 지원 범위 미기재', 44),
  (@comp_id, 'clinic', '사내 건강관리실', NULL, 'health',
   'est', NULL, TRUE, '의료 지원: 사내 건강관리실 운영 (2025-2026 지속가능경영보고서 31쪽 건강증진 지원 항목), 캠퍼스 내 건강관리실 운영 (같은 보고서 37쪽 구성원 건강관리 지원 항목) — 운영 캠퍼스·상주 인력 미기재', 45),
  (@comp_id, 'smoking_cessation', '건강 프로그램 (금연·금주 등)', NULL, 'health',
   'est', NULL, TRUE, '건강 프로그램(금연, 금주 등) 제공 (공식 지속가능경영 구성원 페이지 복리후생 Health 항목), 금연·다이어트 등 다양한 테마와 연계한 건강관리 프로그램 및 캠페인 운영 (2025-2026 지속가능경영보고서 37쪽 구성원 건강관리 지원 항목) — 프로그램 내용·지원 금액 미기재', 46),

  -- ── 휴가 (time_off) — 인사제도 페이지 Refresh Care · 보고서 31쪽 ──
  (@comp_id, 'summer_leave', 'Refresh 하계 휴가', NULL, 'time_off',
   'est', NULL, TRUE, 'Refresh 하계 휴가 (공식 채용 페이지 인사제도 복리후생 Refresh Care 항목), 하계휴가: 연차 외 별도 하계휴가 부여 (2025-2026 지속가능경영보고서 31쪽 휴가 제도 항목) — 휴가 일수·유급 여부 미기재', 50),
  (@comp_id, 'long_service_leave', '안식휴가 (근속 5년 단위)', NULL, 'time_off',
   'est', NULL, TRUE, '5년 주기로 안식휴가 제공 (공식 채용 페이지 인사제도 복리후생 Refresh Care 항목), 안식휴가: 근속 만 5년 단위 안식휴가 부여, 포상휴가: 장기 근속에 따른 포상 (2025-2026 지속가능경영보고서 31쪽 휴가 제도 항목) — 휴가 일수 미기재', 51),
  (@comp_id, 'leave_general', '우수 성과자 포상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '포상휴가: 우수 성과자 대상 부여 (2025-2026 지속가능경영보고서 31쪽 휴가 제도 항목) — 선정 기준·휴가 일수 미기재', 52),

  -- ── 여가 (leisure) — 인사제도 페이지 Refresh Care · 구성원 페이지 · 보고서 31 · 32쪽 ──
  (@comp_id, 'resort', '생활연수원·콘도', NULL, 'leisure',
   'est', NULL, TRUE, '생활연수원/콘도 (공식 채용 페이지 인사제도 복리후생 Refresh Care 항목), 숙박지원(리조트, 연수원, 콘도 등) (공식 지속가능경영 구성원 페이지 복리후생 Refresh 항목), 리조트·콘도 등 숙박 제휴 (2025-2026 지속가능경영보고서 31쪽 Refresh 항목) — 이용 횟수·비용 지원 범위 미기재', 60),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 지원 (공식 채용 페이지 인사제도 복리후생 Refresh Care 동호회/야유회 지원 항목), 사내 동호회 지원 (공식 지속가능경영 구성원 페이지 복리후생 Growth 항목) — 지원 금액·동호회 종류 미기재', 61),
  (@comp_id, 'company_event', '야유회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '야유회 지원 (공식 채용 페이지 인사제도 복리후생 Refresh Care 동호회/야유회 지원 항목) — 개최 주기·지원 금액 미기재', 62),
  (@comp_id, 'sports_ticket', '스포츠 티켓 지원 (야구·축구)', NULL, 'leisure',
   'est', NULL, TRUE, '스포츠 티켓 지원(LG트윈스, 홈티켓) (공식 채용 페이지 인사제도 복리후생 Refresh Care 항목), 스포츠 티켓 지원(야구, 축구) (공식 지속가능경영 구성원 페이지 복리후생 Refresh 항목) — 지원 매수·대상 경기 미기재', 63),
  (@comp_id, 'library', '전자도서관', NULL, 'leisure',
   'est', NULL, TRUE, '전자도서관 운영 (2025-2026 지속가능경영보고서 31쪽 Growth 항목) — 이용 콘텐츠 범위 미기재', 64),
  (@comp_id, 'welcome_kit', '입사 축하 선물', NULL, 'leisure',
   'est', NULL, TRUE, '신규 입사자 온보딩 프로그램의 입사 축하 선물 (2025-2026 지속가능경영보고서 32쪽 온보딩 프로그램 항목) — 선물 내용 미기재', 65),

  -- ── 근무 유연성 (flexibility) — 구성원 페이지 · 보고서 31쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (월 단위 선택적 근로시간제)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제: 월 단위, 선택적 근로시간제 운영 (공식 지속가능경영 구성원 페이지 조직문화 및 복리후생 항목), 선택근무제 사용자수 2026 반기 1,396명, 2025년 1,417명, 2024년 1,460명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 코어타임·정산 방식 미기재', 70),
  (@comp_id, 'remote_work', '재택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무제: 모성보호 등 재택근무 적극 활용 (공식 지속가능경영 구성원 페이지 조직문화 및 복리후생 항목), 재택근무제: 주 1회 자택에서 업무 수행 (2025-2026 지속가능경영보고서 31쪽 근무환경 개선 항목), 원격근무제(재택근무 포함) 사용자수 2026 반기 805명, 2025년 982명, 2024년 834명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 71),
  (@comp_id, 'family_day', '패밀리데이', NULL, 'flexibility',
   'est', NULL, TRUE, '워라밸 정착을 위한 패밀리데이 제도 운영 (2025-2026 지속가능경영보고서 14쪽 중대성 평가 근로조건 대응 전략 항목) — 운영 주기·퇴근 시각 미기재', 72),

  -- ── 성장 · 교육 (growth) — 구성원 페이지 · 인재육성 페이지 · 보고서 31쪽 ──
  (@comp_id, 'lang', '어학 학습 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학학습 지원 (공식 지속가능경영 구성원 페이지 복리후생 Growth 항목), 어학 학습 지원(온·오프라인) (2025-2026 지속가능경영보고서 31쪽 Growth 항목) — 지원 언어·비용 지원 범위 미기재', 80),
  (@comp_id, 'books', '도서구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서구입비 지원 (공식 지속가능경영 구성원 페이지 복리후생 Growth 항목), 도서 구입비 지원 (2025-2026 지속가능경영보고서 31쪽 Growth 항목) — 지원 한도 미기재', 81),
  (@comp_id, 'edu_support', '학습동아리·온라인 학습', NULL, 'growth',
   'est', NULL, TRUE, '학습동아리 (공식 채용 페이지 인재육성 전문 역량 항목), 학습동아리 지원 (공식 지속가능경영 구성원 페이지 복리후생 Growth 항목), 사내 학습동아리 지원 (2025-2026 지속가능경영보고서 31쪽 Growth 항목), 다양한 주제의 동영상 강의로 온라인 학습 환경 제공 (공식 지속가능경영 구성원 페이지 상시 학습 문화 조성 항목) — 지원 금액·수강 범위 미기재', 82),
  (@comp_id, 'mba', '국내외 학위파견·MBA', NULL, 'growth',
   'est', NULL, TRUE, '국내·외 학위파견 및 MBA (공식 채용 페이지 인재육성 리더십 역량 항목), 국내·외 학위 파견 및 MBA (공식 지속가능경영 구성원 페이지 인재 육성 프로그램 항목) — 선발 기준·지원 범위 미기재', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
