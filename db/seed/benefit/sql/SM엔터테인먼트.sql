-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SM엔터테인먼트 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://recruit.smentertainment.com/ko/benefit
-- badge: est
--
-- 참고:
--   정본: SM엔터테인먼트 채용 사이트(그리팅 기반 회사 계정 · 자기 도메인 recruit.smentertainment.com)
--     BENEFIT 페이지 하나 — Life Care · Health Care · Family Care · SM Exclusive 4묶음 25항목,
--     서버 렌더 HTML 텍스트(헤드리스 렌더 없음). 공식 홈 www.smentertainment.com 머리 메뉴에서
--     이 채용 사이트로 링크된다. 페이지 주어는 SM엔터테인먼트는 — 그룹 · 계열사 문구 0회라 각주 없음.
--   보조 출처: OpenDART 2026 반기보고서(접수 20260814002930) 그 밖에 경영활동 관련 중요사항 표 —
--     임직원 스탁그랜트 1행 · 2025 사업보고서(접수 20260317000781) 별도 재무제표 주석
--     기타장기종업원급여 — 장기근속 급부 1행. 두 보고서 모두 유연근무제도 사용 현황은 해당사항 없음.
--     공식 홈 www.smentertainment.com 은 robots 가 첫 화면 밖 전부 금지라 지속가능경영 ·
--     ESG 페이지와 보고서는 읽지 않았다.
--   금액: 원문에 원 · 만원 숫자 0건. 금액 행은 식대 1행뿐(중식비 현금 지원 → 하루 1끼 ×
--     1끼 12,000원 × 연 240일 = 288, 추정 · 야근식대 제외). stated 0행.
--   제외: SM과 함께하는 무한 성장(체류연한 없는 조기 승급 — 승급 제도) · 임원 보수 칸의
--     자녀학자금 · 명절상품권 문장(임원 산정 칸) · 우리사주조합(주주 표 한 칸 · 수량 없음).
--     법정 제도는 원문에 없다.
--   병합: 원픽 기념일 + 생일 선물 = birthday_gift · 문화공연 + 음악 스트리밍 = leisure_ticket ·
--     중식비 + 야근식대 = meal · 야근 택시비 + 대리운전 = transport · 종합건강검진 + 예방 접종 =
--     health_check. 휴게공간 한 항목은 lounge(수면실 · 안마의자룸) · nap_room(수유실) 두 행.
--   공고 근거 0행 / 전체 23행.
--   SORT 섹션: leisure 10 · perks 20 · compensation 30 · growth 40 · health 50 · work_env 60 ·
--     family 70 (정본 페이지 등장 순 · compensation 의 공시 2행은 같은 섹션 끝).
-- 검증 · 감사 판정 반영(2026-10-18): SM 포토부스 leisure_room 서술을 원문 낱말로 교체(공간 낱말 걷음) · 스탁그랜트 stock_grant 유지(주식기준보상 미운영 주석은 임원 보수 표 주석) · 무한 성장(조기 승급) 제외 유지 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 23행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sm_entertainment', 'SM엔터테인먼트',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '엔터테인먼트', 'S', 'https://recruit.smentertainment.com/ko/benefit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sm_entertainment');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.smentertainment.com/ko/benefit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 여가 (leisure) — 정본 Life Care · SM Exclusive ──
  (@comp_id, 'leisure_ticket', '문화공연 · 음악 스트리밍 지원', NULL, 'leisure',
   'est', NULL, TRUE, '뮤지컬, 콘서트 등 임직원의 문화공연 활동 지원, 다양한 음악 감상을 위한 음악 스트리밍 지원 (공식 채용 페이지 복리후생 Life Care 문화공연 지원 · 음악 스트리밍 지원 항목) — 지원 방식·금액·횟수 미기재', 10),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '업무를 벗어나 다양한 취미 활동을 할 수 있도록 다양한 동호회 지원 (공식 채용 페이지 복리후생 Life Care 동호회 활동 지원 항목) — 지원 금액·방식 미기재', 11),
  (@comp_id, 'company_event', 'S-MINGLING DAY', NULL, 'leisure',
   'est', NULL, TRUE, '분기마다 CEO와의 오픈토크를 통해 임직원들이 직접 참여하며 즐길 수 있는 행사 진행 (공식 채용 페이지 복리후생 SM Exclusive S-MINGLING DAY 항목) — 행사 구성 미기재', 12),
  (@comp_id, 'leisure_room', 'SM 포토부스', NULL, 'leisure',
   'est', NULL, TRUE, '우리 SM만의 이색문화, 다양한 아티스트 앨범 프레임으로 동료들과 함께 촬영할 수 있는 포토부스 (공식 채용 페이지 복리후생 SM Exclusive SM 포토부스 항목) — 설치 위치·이용 방식 미기재', 13),

  -- ── 생활 · 편의 (perks) — 정본 Life Care · Family Care ──
  (@comp_id, 'birthday_gift', '원픽 기념일 지원 · 생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '내가 Pick 한 소중한 분께 내가 Pick 한 소중한 날에 꽃 또는 과일패키지 전달, 임직원 생일에 상품권 혹은 선물 (공식 채용 페이지 복리후생 Life Care 원픽 기념일 지원 · 생일 선물 항목) — 선물 금액·지원 횟수 미기재', 20),
  (@comp_id, 'meal', '중식비 · 야근식대 지원', 288, 'perks',
   'est', '중식비를 현금으로 지원, 야근하는 임직원 야근식대 지원 (공식 채용 페이지 복리후생 Life Care 중식비 지원 · 야근식대 및 교통비 지원 항목) — 중식비 단가 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정, 야근식대 제외)', FALSE, NULL, 21),
  (@comp_id, 'snack_bar', '간식 지원 (층별 간식바)', NULL, 'perks',
   'est', NULL, TRUE, '사옥 각 층에 간식바가 마련되어 자유롭게 이용 (공식 채용 페이지 복리후생 Life Care 간식지원 항목) — 제공 품목 미기재', 22),
  (@comp_id, 'transport', '야근 택시비 · 대리운전 지원', NULL, 'perks',
   'est', NULL, TRUE, '야근하는 임직원을 위해 택시비 지원, 임직원의 안전한 귀가를 위해 대리운전 지원 (공식 채용 페이지 복리후생 Life Care 야근식대 및 교통비 지원 · 대리운전 지원 항목) — 지원 기준 시각·한도·이용 조건 미기재', 23),
  (@comp_id, 'housing_loan', '대여금 지원 (주택 구입·전세·결혼·생활안정)', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입, 전세, 결혼, 생활안정에 필요한 대여금 지원 (공식 채용 페이지 복리후생 Family Care 대여금 지원 항목) — 대여 한도·이율·상환 조건 미기재', 24),

  -- ── 보상 (compensation) — 정본 Life Care · 공시 ──
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '임직원과 가족 모두 따뜻한 명절을 보낼 수 있도록 상품권 혹은 선물 지급 (공식 채용 페이지 복리후생 Life Care 명절 선물 항목) — 금액·지급 시기 미기재', 30),
  (@comp_id, 'long_service_bonus', '장기근속 임직원 장기종업원급여', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 임직원에게 장기종업원급여 제공, 주로 5년 이상의 장기간 근무한 임직원에게 권리 부여 (2025 사업보고서 재무제표 주석 기타장기종업원급여 항목) — 급부 형태·금액 미기재', 31),
  (@comp_id, 'stock_grant', '스탁그랜트 (임직원 자사주 지급)', NULL, 'compensation',
   'est', NULL, TRUE, '임직원 스탁그랜트 지급을 위한 자기주식 처분 결정 2022년 2월 · 2024년 8월, 직원 대상 스톡그랜트 지급 등을 위한 자기주식취득 신탁계약 해지 결정 2024년 8월 (2026 반기보고서 그 밖에 경영활동과 관련된 중요한 사항 항목) — 지급 대상 범위·1인당 수량·지급 주기 미기재', 32),

  -- ── 성장 (growth) — 정본 Life Care · SM Exclusive ──
  (@comp_id, 'books', '도서 구매 지원', NULL, 'growth',
   'est', NULL, TRUE, '임직원들의 업무 및 역량계발을 위한 도서 구매 지원 (공식 채용 페이지 복리후생 Life Care 도서 구매 지원 항목) — 지원 한도·방식 미기재', 40),
  (@comp_id, 'career', 'SM 사내공모 제도', NULL, 'growth',
   'est', NULL, TRUE, '구성원들에게 직무 전환 및 커리어 개발을 위한 다양한 사내공모 지원 기회 (공식 채용 페이지 복리후생 SM Exclusive SM 사내공모 제도 항목) — 지원 자격·시행 주기 미기재', 41),

  -- ── 건강 (health) — 정본 Health Care ──
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '임직원의 각종 질병, 사고에 대비하여 단체상해보험 가입 지원 (공식 채용 페이지 복리후생 Health Care 단체상해보험 항목) — 보장 범위·가족 포함 여부 미기재', 50),
  (@comp_id, 'health_check', '종합건강검진 · 예방 접종 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원의 건강 관리를 위하여 매년 종합건강검진 지원, 독감과 같은 전염병 예방 접종 지원 (공식 채용 페이지 복리후생 Health Care 종합건강검진 · 예방 접종 지원 항목) — 검진 비용 지원 범위·가족 포함 여부 미기재', 51),
  (@comp_id, 'clinic', '의료진 건강상담', NULL, 'health',
   'est', NULL, TRUE, '매월 의료진이 직접 회사에 방문하여 임직원 건강상담 진행 (공식 채용 페이지 복리후생 Health Care 의료진 건강상담 항목) — 의료진 구성·상담 범위 미기재', 52),
  (@comp_id, 'mental', '심리상담 프로그램', NULL, 'health',
   'est', NULL, TRUE, '모든 임직원들의 마음 건강을 위하여 심리상담 프로그램 지원 (공식 채용 페이지 복리후생 Health Care 심리상담 프로그램 항목) — 상담 방식·횟수 미기재', 53),

  -- ── 근무 환경 (work_env) — 정본 Health Care 다양한 휴게공간 ──
  (@comp_id, 'lounge', '수면실 · 안마의자룸', NULL, 'work_env',
   'est', NULL, TRUE, '쾌적한 수면실과 휴식용 안마의자룸 자유 이용 (공식 채용 페이지 복리후생 Health Care 다양한 휴게공간 항목) — 설치 위치·운영 시간 미기재', 60),
  (@comp_id, 'nap_room', '수유실', NULL, 'work_env',
   'est', NULL, TRUE, '프라이빗한 수유실 자유 이용 (공식 채용 페이지 복리후생 Health Care 다양한 휴게공간 항목) — 설치 위치·운영 방식 미기재', 61),

  -- ── 가족 (family) — 정본 Family Care ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원과 가족의 경조사 지원 (공식 채용 페이지 복리후생 Family Care 경조사 지원 항목) — 대상 경조사 범위·금액 미기재', 70),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '취학 및 미취학 자녀의 학자금 지원 (공식 채용 페이지 복리후생 Family Care 자녀 학자금 지원 항목) — 지원 금액·학년 범위 미기재', 71),
  (@comp_id, 'parenting', '자녀 위탁 보육 지원', NULL, 'family',
   'est', NULL, TRUE, '어린이집과 위탁계약을 체결하여 임직원 자녀의 보육을 지원하는 제도 (공식 채용 페이지 복리후생 Family Care 자녀의 위탁 보육 지원 항목) — 위탁 어린이집·지원 비율 미기재', 72)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
