-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 매일유업 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://www.maeil.com/management/operation.jsp
-- badge: est
--
-- 참고:
--   정본은 상장 법인 매일유업 주식회사(2017-05 분할 신설 · 지주 매일홀딩스 31.8%)의 자기 도메인 www.maeil.com
--   상생 · 윤리경영 > 가족친화 경영 페이지다. SSR 이라 원본 HTML 에 가족친화 운영 프로그램 표(7분류)가 있다.
--   표 머리 문장 주어가 매일유업이고 그룹 · 계열사 단서가 없다 — 각주 없음. 표에 게시 날짜는 없고
--   같은 페이지의 주요활동 사항 목록은 2020년에서 끝난다. 2026 반기보고서(접수 20260814003071)
--   정부의 인증사항 절이 출산 및 양육 지원제도 · 탄력적 근무제도 · 패밀리 데이를 시행중이라고 적어 현행을 받친다.
--   보조 출처: 2026 반기보고서 · 2025 사업보고서(접수 20260319001065) 직원 등 현황 유연근무제도 사용 현황 표와
--   2025 사업보고서 별도 재무제표 주석 장기종업원급여 문장, 같은 도메인 ESG 정보 공개 > 사회적 가치 게시물
--   임직원 교육훈련 프로그램 실적(게시 2026-05-07 · 2025년 실적 1쪽 PDF).
--   채용 사이트 maeil.recruiter.co.kr/career/benefit 은 본문이 벤더 API 호스트(robots Disallow 전체)에만 있어 읽지 않았다.
--   금액: 원 숫자는 출산축하지원금 · 분유 이유식 지원뿐이고 둘 다 1회성이라 전 행 BENEFIT_AMT NULL.
--   제외: 법정(산전후휴가 · 배우자출산휴가 · 임산부근로시간 단축 · 육아휴직 · 육아기근로시간단축) ·
--     임원처우규정 복리후생(공시 임원 보수 칸) · 우리사주조합과 사내근로복지기금(공시 주주 표 칸뿐) ·
--     선택근무제(공시 세 기간 사용자 모두 -) · 업무 교육(직급별 · 직무별 · 경력사원 입문 · 팀장 과정) ·
--     2015~2020 주요활동 목록(옛 행사 기록).
--   공고 근거 0행 / 전체 25행.
--   SORT 섹션 순서 = 정본 표 등장 순(family 10 · work_env 20 · health 30 · flexibility 40 · leisure 50 ·
--     time_off 60 · perks 70 · compensation 80), 보조 출처에만 있는 growth 90.
-- 검증 · 감사 판정 반영(2026-10-18): 날짜 없는 정본 현행 인정 · ESG 정보 공개 게시물(이해관계자 소통 2026-06-25 · 주요 안전보건 활동 2026-02-26) 근거 워케이션 workation · 건강관리실 clinic · 체력단련실 fitness 추가 · 휴게실을 여성휴게실 lounge 행에 병합(리드 판정 154) · 참고 블록 보조 출처 줄에 두 게시물이 없는 것은 이 판정으로 뒤집힘 — 최종 28행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('maeil_dairies', '매일유업',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '식품', 'M', 'https://www.maeil.com/management/operation.jsp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'maeil_dairies');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.maeil.com/management/operation.jsp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — 공식 홈페이지 가족친화 운영 프로그램 ──
  (@comp_id, 'fertility_support', '난임시술비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임시술비 지원 (공식 홈페이지 가족친화 운영 프로그램 출산지원 항목) — 지원 한도·횟수 미기재', 10),
  (@comp_id, 'parenting', '출산축하지원금·출산축하선물·육아지원금·입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '출산축하지원금 (1자녀 400만원, 2자녀 600만원, 3자녀이상 1,000만원), 출산축하선물지원, 유아분유 및 이유식 지원 (약 200만원상당), 베이비샤워/베이비문 프로그램 운영 (공식 홈페이지 가족친화 운영 프로그램 출산지원 항목), 돌 축하선물 지원, 영유아 육아지원금 보조, 중학교/고등학교 입학 축하금 지원 (공식 홈페이지 가족친화 운영 프로그램 근로자 자녀양육지원 항목) — 육아지원금 금액·대상 연령, 입학 축하금 금액 미기재', 11),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (유치원, 초등학교, 중학교, 고등학교, 대학교) (공식 홈페이지 가족친화 운영 프로그램 근로자 자녀양육지원 항목) — 지원 금액·자녀 수 한도 미기재', 12),
  (@comp_id, 'event', '경조휴가·경조비·상조 서비스', NULL, 'family',
   'est', NULL, TRUE, '경조 휴가 및 경조비 지원, 상조 서비스 지원 (장례용품, 장례지도서비스, 장례음료 등) (공식 홈페이지 가족친화 운영 프로그램 복리 및 가족경조사 지원 항목) — 경조 범위·금액·휴가 일수 미기재', 13),
  -- ── 근무 환경 (work_env) — 공식 홈페이지 가족친화 운영 프로그램 ──
  (@comp_id, 'nap_room', '수유실', NULL, 'work_env',
   'est', NULL, TRUE, '수유실 운영 (공식 홈페이지 가족친화 운영 프로그램 출산지원 항목) — 설치 사업장 미기재', 20),
  (@comp_id, 'lounge', '여성휴게실·휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '여성휴게실 운영 (공식 홈페이지 가족친화 운영 프로그램 출산지원 항목), 휴게실/체력단련실 52개소 (공식 홈페이지 ESG 정보 공개 주요 안전보건 활동 2025년 시설현황 항목) — 사업장별 설치 수 미기재', 21),
  -- ── 건강 (health) — 공식 홈페이지 가족친화 운영 프로그램 ──
  (@comp_id, 'medical', '자녀 의료·재활교육비 지원', NULL, 'health',
   'est', NULL, TRUE, '자녀의료/재활교육비 지원 (공식 홈페이지 가족친화 운영 프로그램 근로자 자녀양육지원 항목) — 지원 대상·한도 미기재', 30),
  (@comp_id, 'insurance', '임직원 단체보험·자녀단체보험', NULL, 'health',
   'est', NULL, TRUE, '임직원 단체 보험 가입 (공식 홈페이지 가족친화 운영 프로그램 근로자 건강관리 지원 항목), 자녀단체보험 가입 (공식 홈페이지 가족친화 운영 프로그램 근로자 자녀양육지원 항목) — 보장 내용 미기재', 31),
  (@comp_id, 'health_check', '건강검진 지원·가족 건강검진 (만40세이상 1인)', NULL, 'health',
   'est', NULL, TRUE, '건강검진 지원, 가족(1인)건강검진 지원 (만40세이상) (공식 홈페이지 가족친화 운영 프로그램 근로자 건강관리 지원 항목) — 검진 주기·비용 지원 범위 미기재', 32),
  (@comp_id, 'massage', '헬스키퍼실', NULL, 'health',
   'est', NULL, TRUE, '헬스키퍼실 운영 (공식 홈페이지 가족친화 운영 프로그램 근로자 건강관리 지원 항목) — 운영 사업장·이용 조건 미기재', 33),
  (@comp_id, 'mental', 'EAP 마음건강상담', NULL, 'health',
   'est', NULL, TRUE, 'E.A.P(마음건강상담) 프로그램 운영 (공식 홈페이지 가족친화 운영 프로그램 근로자 건강관리 지원 항목) — 상담 횟수·비용 부담 미기재', 34),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '건강관리실 등 8개소 (공식 홈페이지 ESG 정보 공개 주요 안전보건 활동 2025년 시설현황 항목) — 운영 인력·이용 조건 미기재', 35),
  (@comp_id, 'fitness', '체력단련실', NULL, 'health',
   'est', NULL, TRUE, '휴게실/체력단련실 52개소 (공식 홈페이지 ESG 정보 공개 주요 안전보건 활동 2025년 시설현황 항목) — 사업장별 설치 수·이용 조건 미기재', 36),
  -- ── 근무 유연성 (flexibility) — 공식 홈페이지 가족친화 운영 프로그램 · 공시 ──
  (@comp_id, 'flex_work', '시차출퇴근제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 (육아 및 원거리출퇴근) (공식 홈페이지 가족친화 운영 프로그램 유연근무제 항목), 탄력적 근무제도 (2026 반기보고서 기타 시행중인 가족친화제도 운영사항 항목), 시차출퇴근제 사용자 수 2026년 상반기 109명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 출퇴근 시간대·탄력적 근무 대상 미기재', 40),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 (공식 홈페이지 가족친화 운영 프로그램 유연근무제 항목), 원격근무제 사용자 수 2023년 546명 · 2024년 487명, 2025년 · 2026년 상반기 - (2025 사업보고서 · 2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 41),
  (@comp_id, 'family_day', '패밀리데이 (둘째·넷째 금요일 조기퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '패밀리데이운영 (둘째, 넷째 금요일 조기퇴근) (공식 홈페이지 가족친화 운영 프로그램 가족관계증진 및 여가지원 항목), 패밀리 데이 (2026 반기보고서 기타 시행중인 가족친화제도 운영사항 항목) — 퇴근 시각·적용 대상 미기재', 42),
  (@comp_id, 'workation', '워케이션 프로그램', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무 및 워케이션 프로그램 등 다양한 근로환경 조성 (공식 홈페이지 ESG 정보 공개 이해관계자 소통 임직원 주요 활동 항목) — 운영 장소·대상·기간 미기재', 43),
  -- ── 여가 (leisure) — 공식 홈페이지 가족친화 운영 프로그램 ──
  (@comp_id, 'company_event', '가족초청행사', NULL, 'leisure',
   'est', NULL, TRUE, '가족초청행사 (문화관광, 공장견학 등) (공식 홈페이지 가족친화 운영 프로그램 가족관계증진 및 여가지원 항목) — 시행 주기·대상 사업장 미기재', 50),
  (@comp_id, 'club', '동호회활동지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회활동지원 (공식 홈페이지 가족친화 운영 프로그램 가족관계증진 및 여가지원 항목) — 지원 금액·동호회 종류 미기재', 51),
  (@comp_id, 'resort', '임직원 휴양소 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 휴양소 이용 지원 (공식 홈페이지 가족친화 운영 프로그램 가족관계증진 및 여가지원 항목) — 휴양소 위치·이용 조건 미기재', 52),
  -- ── 휴가 (time_off) — 공식 홈페이지 가족친화 운영 프로그램 ──
  (@comp_id, 'leave_general', '징검다리 휴가·포상휴가 (해외여행)', NULL, 'time_off',
   'est', NULL, TRUE, '징검다리 휴가제도, 포상휴가제도 (해외여행) (공식 홈페이지 가족친화 운영 프로그램 가족관계증진 및 여가지원 항목) — 징검다리 휴가의 본인 휴가 사용일인지·일수·유급 여부, 포상휴가 선정 기준 미기재', 60),
  (@comp_id, 'refresh_leave', '리프레쉬 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '리프레쉬 휴가 (공식 홈페이지 가족친화 운영 프로그램 가족관계증진 및 여가지원 항목) — 휴가 일수·부여 조건 미기재', 61),
  -- ── 생활 · 금융 (perks) — 공식 홈페이지 가족친화 운영 프로그램 ──
  (@comp_id, 'welfare_point', '선택적 복리후생 제도', NULL, 'perks',
   'est', NULL, TRUE, '선택적 복리후생 제도 (공식 홈페이지 가족친화 운영 프로그램 복리 및 가족경조사 지원 항목) — 배정 포인트·사용처 미기재', 70),
  (@comp_id, 'welfare_fund_loan', '생활안정자금·재해재난 지원자금 대부', NULL, 'perks',
   'est', NULL, TRUE, '생활안정자금 대부, 재해재난 지원자금 대부 (공식 홈페이지 가족친화 운영 프로그램 사내 복지 대부 지원 항목) — 대부 한도·이율 미기재', 71),
  (@comp_id, 'housing_loan', '주택매매·전세자금 대부', NULL, 'perks',
   'est', NULL, TRUE, '주택매매/전세자금 대부 (공식 홈페이지 가족친화 운영 프로그램 사내 복지 대부 지원 항목) — 대부 한도·이율 미기재', 72),
  -- ── 보상 (compensation) — 공식 홈페이지 가족친화 운영 프로그램 · 공시 ──
  (@comp_id, 'holiday_gift', '가정의 달·연말연시 선물', NULL, 'compensation',
   'est', NULL, TRUE, '가정의 달 및 연말연시 선물 지원 (공식 홈페이지 가족친화 운영 프로그램 복리 및 가족경조사 지원 항목) — 선물 품목·금액 미기재', 80),
  (@comp_id, 'long_service_bonus', '장기근속포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속포상제도운영 (공식 홈페이지 가족친화 운영 프로그램 복리 및 가족경조사 지원 항목), 장기 근속 임직원에게 장기종업원급여 제공, 주로 10년 이상의 장기간 근무한 임직원 대상 (2025 사업보고서 재무제표 주석 장기종업원급여 항목) — 근속 기간별 기준·포상 형태·금액 미기재', 81),
  -- ── 성장 (growth) — 공식 홈페이지 ESG 정보 공개 ──
  (@comp_id, 'self_development', '직무 자격증 취득 지원 (기능직)', NULL, 'growth',
   'est', NULL, TRUE, '기능직 직무 자격증 취득 (기능장, 기술사 등)까지 연계 지원 (공식 홈페이지 ESG 정보 공개 임직원 교육훈련 프로그램 실적 항목) — 지원 방식·비용 부담 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
