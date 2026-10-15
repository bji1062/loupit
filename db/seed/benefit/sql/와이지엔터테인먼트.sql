-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 와이지엔터테인먼트 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://ygfamily.com/ko/sustainability/esg
-- badge: est
--
-- 참고:
--   정본은 상장 법인 와이지엔터테인먼트의 자기 도메인 ygfamily.com 지속가능경영(ESG) 페이지다. SSR 이고 robots.txt 는 404(규칙 없음).
--   이 페이지의 지속가능경영보고서 목록에 올라 있는 2026 지속가능경영보고서(국문 PDF 86쪽 · 첨부 경로 2026/09 · PDF 생성 2026-08)가 본문 근거다.
--   보고 기간 2025-01-01~2025-12-31(일부 정성 2026 상반기) · 보고 범위 = ESG 데이터는 와이지엔터테인먼트 국내 사업장(숙소 제외) —
--   종속회사(YG PLUS · YG JAPAN)는 온실가스만 포함. 법인 단독 자기 발행 보고서라 각주 없음.
--   주 근거 = 32쪽 임직원 복리후생 활동 표(구분 · 복지 제도 · 복지 프로그램) · 보조 = 31쪽 복리후생 정책 · 57쪽 자기계발 교육 ·
--   68쪽 임직원 건강 복지 활동 · 18쪽 중대 이슈 관리 표(임직원 성과급).
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814004237) 직원 등 현황 유연근무제도 사용 현황 표(시차출퇴근제 · 원격근무제). 직원 438명.
--   채용 사이트 yg-entertainment.recruiter.co.kr/career/benefits 는 공식 홈 Recruit 메뉴의 회사 계정 ATS 이지만
--   원본 HTML 에 복리후생 본문이 없고 본문이 벤더 API 호스트(robots Disallow 전체)에서 오므로 읽지 않았다 — 붙여넣기 보강 후보.
--   금액: 원 단위 숫자는 복지포인트 연간 최대 130만 원 하나(한도 표현이라 NULL) — 금액 행은 식대 1행(추정, 하루 2끼 × 12,000원 × 240일).
--   제외: 법정(출산휴가 · 육아휴직 · 유사산휴가 · 배우자 출산휴가 · 임신기 · 육아기 근로시간 단축 · 2년 1회 직장인 의무검진 · 재해보상 ·
--     법정의무교육) · 업무 교육(온보딩 · 직무 · 직군 · 리더십 · 승진자 · 전사공통 교육) · 사업장 밖 간주근로시간제(산정 방식) ·
--     임원 보수 칸(리프레시 휴가비 · 명절상품 과세 문장) · 아티스트 · 연습생 대상 지원 · 협력사 대상 문화행사 관람권.
--   공고 근거 0행 / 전체 31행.
--   SORT 섹션 순서 = 32쪽 표 등장 순(flexibility 10 · perks 20 · work_env 30 · health 40 · family 50 · growth 60 · time_off 70 ·
--     compensation 80 · leisure 90).
-- 검증 · 감사 판정 반영(2026-10-15): 주택 전세 자금 행 꼬리에서 원문 밖 대출 낱말 걷기 · 성과급 행에 반기보고서 전사 구성원 특별 상여금 구절 병합 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 31행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('yg_entertainment', '와이지엔터테인먼트',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '엔터테인먼트', 'Y', 'https://ygfamily.com/ko/sustainability/esg');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'yg_entertainment');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://ygfamily.com/ko/sustainability/esg'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 유연근무 (flexibility) — 2026 지속가능경영보고서 32쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (시차출퇴근제·탄력근무제)', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제, 탄력근무제 등 다양한 형태로 유연근무제 운영 (2026 지속가능경영보고서 32쪽 임직원 복리후생 활동 유연근무제도 운영 항목), 2026년 상반기 시차출퇴근제 사용자 수 320명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 코어타임·적용 대상 미기재', 10),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 활용, 2026년 상반기 사용자 수 20명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 11),

  -- ── 경제적 부가혜택 (perks) — 2026 지속가능경영보고서 32쪽 ──
  (@comp_id, 'meal', '사내 카페테리아·구내식당 (중·석식 무료)', 576, 'perks',
   'est', '사내 카페테리아/구내식당 중·석식 무료 이용 (2026 지속가능경영보고서 32쪽 사내 편의시설 운영 항목) — 운영 시간 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 20),
  (@comp_id, 'snack_bar', '사내 편의점', NULL, 'perks',
   'est', NULL, TRUE, '편의시설(편의점) 운영 (2026 지속가능경영보고서 32쪽 사내 편의시설 운영 항목) — 운영 품목·할인 여부 미기재', 21),
  (@comp_id, 'housing_loan', '주택 전세 자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '생활 안정을 지원하고자 주택 전세 자금 지원 (2026 지속가능경영보고서 32쪽 주택 전/월세 자금 지원 항목) — 지원 방식·한도·자격 요건 미기재', 22),
  (@comp_id, 'housing_support', '주택 월세 자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '생활 안정을 지원하고자 주택 월세 자금 지원 (2026 지속가능경영보고서 32쪽 주택 전/월세 자금 지원 항목) — 지원 방식·금액·자격 요건 미기재', 23),
  (@comp_id, 'telecom', '업무 통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '매월 업무 통신비 지원 (2026 지속가능경영보고서 32쪽 업무 통신비 지원 항목) — 월 지원 금액·대상 미기재', 24),
  (@comp_id, 'birthday_gift', '생일·결혼기념일 모바일 상품권', NULL, 'perks',
   'est', NULL, TRUE, '생일 및 결혼기념일 모바일 상품권 지원 (2026 지속가능경영보고서 32쪽 생일 및 결혼기념일 지원 항목) — 상품권 금액 미기재', 25),
  (@comp_id, 'welfare_point', '자기계발비 지원 (복지포인트·복지카드)', NULL, 'perks',
   'est', NULL, TRUE, '연간 최대 130만 원 복지포인트 지원, 복지카드 신규 도입으로 오프라인 사용처 확대, 전용복지몰 사이트를 통해 자기계발, 여행, 상품구매 등 이용 (2026 지속가능경영보고서 32쪽 자기계발비 지원 항목) — 개인별 배정 기준 미기재', 26),
  (@comp_id, 'discount', 'YG 임직원 제휴 혜택', NULL, 'perks',
   'est', NULL, TRUE, '카페, 호텔, 연극 등 다양한 제휴처 혜택 (2026 지속가능경영보고서 32쪽 YG 임직원 제휴 혜택 항목) — 제휴처 목록·할인율 미기재', 27),

  -- ── 근무 환경 (work_env) — 2026 지속가능경영보고서 32쪽 ──
  (@comp_id, 'lounge', '사내 안마의자', NULL, 'work_env',
   'est', NULL, TRUE, '사내 안마의자 등 배치 (2026 지속가능경영보고서 32쪽 사내 편의시설 운영 항목) — 설치 장소·이용 시간 미기재', 30),

  -- ── 건강·의료 (health) — 2026 지속가능경영보고서 32쪽 · 68쪽 ──
  (@comp_id, 'fitness', '피트니스 센터 (전문 트레이너 상주)', NULL, 'health',
   'est', NULL, TRUE, '피트니스 센터 및 전문 트레이너 상주 (2026 지속가능경영보고서 32쪽 헬스케어 항목) — 이용 요금·운영 시간 미기재', 40),
  (@comp_id, 'health_check', '종합건강검진 비용·독감 예방접종 지원', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진 비용 지원, 사내 보건담당자와의 1:1 상담을 통한 개인별 맞춤 건강검진 프로그램 추천, 매년 독감 예방접종 비용 지원 (2026 지속가능경영보고서 68쪽 건강관리 지원 항목), 연간 1회 연계 병원 본인 독감예방접종비용 지원 (32쪽 본인 독감예방접종비용 지원 항목) — 검진 주기·지원 금액·가족 포함 여부 미기재', 41),
  (@comp_id, 'mental', 'EAP 전문상담서비스·미술심리상담', NULL, 'health',
   'est', NULL, TRUE, '외부 전문 심리상담 서비스 이용 비용 연 8회 전액 지원, 사내 미술심리상담 프로그램 정기 진행 (2026 지속가능경영보고서 68쪽 심리상담 프로그램 진행 항목), 직무·재무·스트레스 관리 등 다양한 주제 상담 가능 (32쪽 EAP 전문상담서비스 운영 항목), 연 1회 정신건강의 날 기념 YG 휴(休) Station Day 프로그램 (68쪽 YG 휴 Station Day 항목) — 상담 이용 대상 범위 미기재', 42),
  (@comp_id, 'clinic', '정기 건강상담 (월 1회)', NULL, 'health',
   'est', NULL, TRUE, '산업보건의 및 간호사가 사옥에 방문해 혈압, 혈당, 콜레스테롤 수치 등 기본 건강상담 월 1회 시행 (2026 지속가능경영보고서 68쪽 건강상담 캠페인 항목), 건강상담 프로그램 운영 (32쪽 건강&보건 프로그램 운영 항목) — 상담 시간·장소 미기재', 43),
  (@comp_id, 'insurance', '단체상해질병 실손보험·생명보험', NULL, 'health',
   'est', NULL, TRUE, '입사 시 단체상해질병 실손보험 가입 (2026 지속가능경영보고서 32쪽 임직원 단체상해질병 실손보험 가입 지원 항목), 상해보험 및 생명보험 가입 비용 지원 (68쪽 건강관리 지원 항목) — 보장 범위·가족 포함 여부 미기재', 44),
  (@comp_id, 'overseas_safety', 'YG Wellness Kit (해외출장 상비의약품 키트)', NULL, 'health',
   'est', NULL, TRUE, '잦은 해외 출장 임직원을 위해 이용 가이드, 상비약 4종, 구급용품 등이 포함된 키트 연 1회 지급 (2026 지속가능경영보고서 68쪽 YG Wellness Kit-상비의약품 키트 항목) — 지급 대상 기준 미기재', 45),
  (@comp_id, 'smoking_cessation', '금연 캠페인 및 교육', NULL, 'health',
   'est', NULL, TRUE, '서울금연지원센터와 협업한 사내 금연 캠페인 및 금연 교육 (2026 지속가능경영보고서 68쪽 금연 캠페인 및 교육 항목) — 운영 주기·개별 지원 내용 미기재', 46),

  -- ── 가족·돌봄 (family) — 2026 지속가능경영보고서 32쪽 ──
  (@comp_id, 'child_edu', '자녀학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금 지원 (2026 지속가능경영보고서 32쪽 (자녀/본인) 학자금 제도 항목) — 지원 학령·한도·자녀 수 미기재', 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사비, 휴가, 상조서비스, 화환 등 지원, 대상 본인·조부모·(배우자)부모·자녀 등 (2026 지속가능경영보고서 32쪽 경조사 지원 항목) — 경조금 액수·휴가 일수 미기재', 51),
  (@comp_id, 'parenting', '출산축하금·과일바구니·아이돌봄서비스', NULL, 'family',
   'est', NULL, TRUE, '출산축하금 및 과일바구니 지원, 아이돌봄서비스 지원 (2026 지속가능경영보고서 32쪽 임신, 출산, 육아 지원 항목) — 축하금 금액·돌봄서비스 지원 범위 미기재', 52),

  -- ── 성장·교육 (growth) — 2026 지속가능경영보고서 32쪽 · 57쪽 ──
  (@comp_id, 'self_development', '본인 학자금 (대학·대학원)', NULL, 'growth',
   'est', NULL, TRUE, '역량개발지원 대학(원) 본인 학자금 지원 (2026 지속가능경영보고서 32쪽 (자녀/본인) 학자금 제도 항목) — 지원 비율·한도·근속 요건 미기재', 60),
  (@comp_id, 'books', '도서 구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무관련도서 구입비 지원 (2026 지속가능경영보고서 32쪽 도서 구입비 지원 항목) — 연간 한도 미기재', 61),
  (@comp_id, 'lang', '외국어 학습 지원 (전화 외국어 교육)', NULL, 'growth',
   'est', NULL, TRUE, '외국어 능력 향상을 위한 온라인 교육 플랫폼 지원 (2026 지속가능경영보고서 32쪽 외국어 학습 지원 항목), 임직원이 자율적으로 선택해 참여하는 전화 외국어 교육(중국어/영어/일본어) (57쪽 자기계발 교육 항목) — 비용 부담 범위·수강 한도 미기재', 62),
  (@comp_id, 'edu_support', '온라인 강의 플랫폼·전문가 초빙 교육', NULL, 'growth',
   'est', NULL, TRUE, '직무/리더십/라이프스타일 등 온라인 교육 지원 (2026 지속가능경영보고서 32쪽 온라인 강의 플랫폼 지원 항목), 임직원이 자율적으로 선택해 참여하는 마이크로러닝 플랫폼(재테크/비즈니스/라이프 스타일)과 전문가 초빙 교육 프로그램 (57쪽 자기계발 교육 항목) — 수강 한도 미기재', 63),

  -- ── 휴가 (time_off) — 2026 지속가능경영보고서 32쪽 ──
  (@comp_id, 'refresh_leave', '리프레시 휴가 (2년 주기)', NULL, 'time_off',
   'est', NULL, TRUE, '2년 주기의 정기적인 리프레시 휴가(비) 지원 (2026 지속가능경영보고서 32쪽 리프레시 휴가 지원 항목) — 휴가 일수·휴가비 금액·부여 조건 미기재', 70),

  -- ── 보상·금전 (compensation) — 2026 지속가능경영보고서 32쪽 · 18쪽 ──
  (@comp_id, 'holiday_gift', '명절 상품(권) 지원', NULL, 'compensation',
   'est', NULL, TRUE, '설·추석 상품(권) 지원 (2026 지속가능경영보고서 32쪽 명절 상품(권) 지원 항목) — 상품 종류·금액 미기재', 80),
  (@comp_id, 'incentive', '임직원 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '임직원 성과급 지급 관련 보상위원회 안건을 통해 이사회 보고 (2026 지속가능경영보고서 18쪽 근로조건 및 복리후생 증진 관리 항목), 2025년 상반기 경영성과 개선과 연내 성과 달성 전망을 반영하여 전사 구성원 특별 상여금 지급 (2026 반기보고서 임원 보수 산정 기준 항목) — 지급 기준·지급률 미기재', 81),

  -- ── 여가·행사 (leisure) — 2026 지속가능경영보고서 32쪽 ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영, 동호회 활동비 지원 (2026 지속가능경영보고서 32쪽 사내 동호회 운영 항목) — 활동비 금액·동호회 수 미기재', 90),
  (@comp_id, 'welcome_kit', '신규입사자 과일·꽃바구니', NULL, 'leisure',
   'est', NULL, TRUE, '신규입사자 과일&꽃바구니 지원 (2026 지속가능경영보고서 32쪽 신규입사자 선물 지원 항목) — 지급 시기 미기재', 91),
  (@comp_id, 'company_event', '입사 동기 Welcome Table', NULL, 'leisure',
   'est', NULL, TRUE, '소통과 교류를 위한 입사 동기 Welcome Table 운영 (2026 지속가능경영보고서 32쪽 입사 동기 Welcome Table 운영 항목) — 운영 주기·지원 내용 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
