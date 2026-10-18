-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 애경산업 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://ak.career.greetinghr.com/ko/benefit
-- badge: est
--
-- 참고:
--   정본은 애경산업(주) 회사 계정 그리팅 채용 사이트 복지제도 페이지다. 공식 홈 www.aekyung.co.kr 헤더 인재채용 링크가
--   이 호스트를 가리키고 꼬리말이 애경산업(주) 사업자등록번호 113-81-11573 이다. 그룹 통합 페이지가 아니라 법인 전용.
--   SSR 이라 원본 HTML 에 Work & Culture 블록과 Benefits 블록 텍스트가 다 있다. 헤드리스 렌더 · 이미지 판독 불필요.
--   같은 호스트 AK LIFE 동호회 소개 · AK WORK 웰컴키트 Akit 소개 페이지도 이 법인 페이지다.
--   보조 출처는 자기 도메인 지속가능경영보고서 목록의 가장 새 판 2025 애경산업 지속가능경영보고서
--   (발행 2026년 6월 · 보고 기간 2025-01-01 ~ 2025-12-31 · 보고 범위 애경산업 국내 전 사업장 · 법인 단독 발행)
--   47쪽 근로자 복지제도 · 48쪽 일과 삶의 균형 · 51쪽 어학교육 지원 E-러닝 · 56쪽 건강검진 · 힐링테라스 · AK 피지컬 · 83쪽 주식 구조.
--   공시 보조: OpenDART 2026 반기보고서 기재정정(접수 20260814004155) 유연근무제도 사용 현황 표와 담보 주석,
--   2025 사업보고서(접수 20260318001405) 같은 표. 직원 943명(2025).
--   귀속: 페이지 주어가 애경산업 단수이고 계열사 단서가 없다. 보고서는 자기 발행 단독 범위라 각주 없음.
--   같은 웨이브 제주항공(AK홀딩스 계열) 형제 — 이 법인 페이지의 제주항공 기업 우대 서비스 문장은 애경산업 원문으로 싣는다.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL (stated 0 · 추정 0).
--   제외: 법정(임신기 근로시간 단축 · 출산 전후 휴가 · 임신 중 정기검진 유급 시간 · 유급 수유 시간 · 육아기 근로시간 단축 ·
--     난임 치료 휴가 · 생리 휴가 · 배우자 출산휴가 확대 숫자 없음 · 온열 한랭 예방물품) · 업무 교육(직무교육 · 리더 특강 ·
--     AI 심화 교육 · 뉴커머 입문 교육 · 애경그룹 핵심인재교육 · 온보딩) · 님 호칭(조직문화) · 안전 포상(아차사고 · AK Safety Day) ·
--     L&R Day · 타운홀(경영 소통 행사) · 주니어쌀롱(경력 입사자 적응 교류 프로그램) · 임원 보수 칸(학자금 · 복지포인트).
--   공고 근거 0행 / 전체 28행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(perks 10 · leisure 20 · work_env 30 · flexibility 40 · growth 50 ·
--     compensation 60 · family 70 · health 80), 보고서에만 있는 time_off 90.
-- 검증 · 감사 판정 반영(2026-10-18): 힐링테라스 멘탈 건강 상담 mental 행 추가 · 사내 의무실 clinic 서술에서 그 몫 걷기 · AK LIFE 주니어쌀롱 company_event 추가 · 우리사주 stock_option 유지 · 제주항공 기업 우대 서비스 discount 유지 · 항목 페이지 예외 3(통합 밖 리드 집행) · 참고 블록 제외 줄의 주니어쌀롱은 이 판정으로 뒤집힘 — 최종 30행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('aekyung_industrial', '애경산업',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화장품', 'A', 'https://ak.career.greetinghr.com/ko/benefit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'aekyung_industrial');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://ak.career.greetinghr.com/ko/benefit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활 · 편의 (perks) — 공식 채용 페이지 + 2025 지속가능경영보고서 ──
  (@comp_id, 'snack_bar', '사내 카페 Café Fourteen · 어메니티존', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페 Café Fourteen 운영, 무제한 간식, 음료 이용이 가능한 어메니티존 운영 (공식 채용 페이지 Work & Culture 항목), 장애인 직원이 근무하는 사내 카페 CAFÉ FOURTEEN 운영 (2025 지속가능경영보고서 49쪽 사회적 약자 고용 활성화 항목) — 이용 가격·운영 시간 미기재', 10),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '연 2회 복지 포인트 지급 (공식 채용 페이지 Work & Culture 항목), 복지포인트 제공 (2025 지속가능경영보고서 47쪽 복리후생 지원 항목) — 지급 금액 미기재', 11),
  (@comp_id, 'discount', '제주항공 기업 우대 서비스', NULL, 'perks',
   'est', NULL, TRUE, '제주항공 기업 우대 서비스 제공 (공식 채용 페이지 복리후생 항목) — 우대 내용·이용 대상 미기재', 12),
  (@comp_id, 'housing_loan', '주택자금대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택자금대출 지원 (공식 채용 페이지 복리후생 항목, 2025 지속가능경영보고서 47쪽 복리후생 지원 항목) — 대출 한도·이율 미기재', 13),

  -- ── 여가 (leisure) — 공식 채용 페이지 ──
  (@comp_id, 'library', '사내 북카페 Open Library', NULL, 'leisure',
   'est', NULL, TRUE, '사내 북카페 Open Library 운영 (공식 채용 페이지 Work & Culture 항목) — 운영 시간·보유 도서 규모 미기재', 20),
  (@comp_id, 'welcome_kit', '웰컴키트 Akit · 입사 축하선물', NULL, 'leisure',
   'est', NULL, TRUE, '입사 당일 웰컴키트, 축하선물 지급 중 입사 (공식 채용 페이지 복리후생 항목), 웰컴키트 Akit 구성 칫솔 치약 셋트 · 핸드크림 · 미니 손소독제 · 테이블 미러 · 무선 충전 마우스패드 · 텀블러 · 다이어리 볼펜 캘린더 세트 · 에코백 (공식 채용 페이지 AK WORK 웰컴키트 Akit 소개 항목) — 입사 축하선물 품목 미기재', 21),
  (@comp_id, 'summer_vacation_subsidy', '하계 휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '하계 휴가비지급 (공식 채용 페이지 복리후생 항목) — 지급 금액·지급 시기 미기재', 22),
  (@comp_id, 'resort', '법인콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '법인콘도 지원 (공식 채용 페이지 복리후생 항목), 콘도 이용 지원 (2025 지속가능경영보고서 47쪽 복리후생 지원 항목) — 이용 가능 콘도·지원 범위 미기재', 23),
  (@comp_id, 'club', 'AK동호회', NULL, 'leisure',
   'est', NULL, TRUE, '애경산업의 모든 구성원은 직급, 직책, 나이, 성별과 상관없이 동호회 활동에 자유롭게 참여, 약 20개 동호회 운영 · 월 1회 이상 모임 · 소정의 활동비 지원 (공식 채용 페이지 AK LIFE 동호회 소개 항목) — 활동비 금액 미기재', 24),
  (@comp_id, 'company_event', '주니어쌀롱', NULL, 'leisure',
   'est', NULL, TRUE, '주니어 직급의 경력입사자가 교류할 수 있도록 마련한 주니어쌀롱 프로그램, 취미를 매개로 문화·예술·인문학 경험을 나누는 원데이클래스 모임, 다른 구성원과의 소통을 원하는 모두를 위한 프로그램 (공식 채용 페이지 AK LIFE 주니어쌀롱 소개 항목) — 운영 주기·비용 부담 미기재', 25),

  -- ── 근무 환경 (work_env) — 공식 채용 페이지 ──
  (@comp_id, 'free_seating', '자율좌석제', NULL, 'work_env',
   'est', NULL, TRUE, '당일 업무 필요에 따른 자율좌석제 시행 (공식 채용 페이지 Work & Culture 항목) — 적용 사업장 미기재', 30),
  (@comp_id, 'dormitory', '연구소 사택 · 공장 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '연구소 사택 및 공장 기숙사 지원 (공식 채용 페이지 Work & Culture 항목) — 입주 대상·비용 부담 미기재', 31),
  (@comp_id, 'work_tools', '개인노트북 지급', NULL, 'work_env',
   'est', NULL, TRUE, '입사 당일 개인노트북 지급 (공식 채용 페이지 복리후생 항목) — 기종·교체 주기 미기재', 32),

  -- ── 근무 유연성 (flexibility) — 공식 채용 페이지 + 보고서 + 반기보고서 ──
  (@comp_id, 'flex_work', '선택근무제 · 시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '스스로 근무시간 조절이 가능한 선택근무제 시행 (공식 채용 페이지 Work & Culture 항목), 업무의 시작 및 종료 시각을 자율적으로 선택/조정할 수 있는 근무 제도 (2025 지속가능경영보고서 47쪽 선택근무제 항목), 시차출퇴근제 · 선택근무제 사용자 2026년 상반기 719명 · 2025년 715명 · 2024년 695명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 의무 근무시간대 미기재', 40),
  (@comp_id, 'remote_work', '원격근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '일하는 방식 변화와 업무몰입을 위한 원격근무제 시행 (공식 채용 페이지 Work & Culture 항목), 근로시간의 일부 또는 전부를 회사 외 장소에서 수행할 수 있는 환경 (2025 지속가능경영보고서 47쪽 유연한 근무환경 조성 항목), 원격근무제(재택근무 포함) 사용자 2026년 상반기 115명 · 2025년 163명 · 2024년 152명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 41),
  (@comp_id, 'family_day', '가족의 날', NULL, 'flexibility',
   'est', NULL, TRUE, '월 1회 가족의날 시행 (공식 채용 페이지 복리후생 항목), 구성원이 1시간 조기 퇴근 후 가족들과 함께 시간을 보낼 수 있도록 지원하는 제도 (2025 지속가능경영보고서 47쪽 가족의 날 항목) — 시행 요일 미기재', 42),

  -- ── 성장 · 교육 (growth) — 공식 채용 페이지 + 보고서 ──
  (@comp_id, 'lang', '어학교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학교육 지원 (공식 채용 페이지 Work & Culture 항목), 구성원 누구나 활용할 수 있도록 전화·화상 외국어 과정, 온·오프라인 어학 교육 및 어학 시험 지원 제도, 글로벌 직무 담당자 대상 그룹 외국어 수업과 1:1 튜터링 (2025 지속가능경영보고서 51쪽 어학교육 지원 항목) — 지원 금액·한도 미기재', 50),
  (@comp_id, 'edu_support', 'E-러닝 플랫폼', NULL, 'growth',
   'est', NULL, TRUE, '약 2,000개 이상의 온라인 교육 콘텐츠를 제공하는 E-러닝 플랫폼 운영, 라이프 인사이트 · 자격 시험 대비 · 글로벌(어학) 콘텐츠 포함 (2025 지속가능경영보고서 51쪽 E-러닝 플랫폼 운영 항목) — 수강 비용 부담 미기재', 51),

  -- ── 보상 (compensation) — 공식 채용 페이지 + 보고서 + 반기보고서 ──
  (@comp_id, 'long_service_bonus', '1년 근속축하금 · 장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '1년 근속축하금 및 장기근속자 포상 (공식 채용 페이지 Work & Culture 항목) — 근속 기준·포상 내용·금액 미기재', 60),
  (@comp_id, 'holiday_gift', '창립기념일 축하선물', NULL, 'compensation',
   'est', NULL, TRUE, '축하선물 지급 중 창립기념일 (공식 채용 페이지 복리후생 항목) — 선물 내용 미기재', 61),
  (@comp_id, 'stock_option', '우리사주조합', NULL, 'compensation',
   'est', NULL, TRUE, '우리사주조합은 1.67%를 보유해 임직원의 기업 참여를 확대 (2025 지속가능경영보고서 83쪽 주식 및 자본구조 항목), 우리사주 취득자금 대출약정과 관련하여 회사가 예치금을 담보로 제공 (2026 반기보고서 재무제표 주석 담보 항목) — 회사 출연·지원 금액 미기재', 62),

  -- ── 가족 (family) — 공식 채용 페이지 + 보고서 ──
  (@comp_id, 'event', '경조사 지원 · 경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원(상조서비스, 경조금, 경조화환), 경조휴가 (공식 채용 페이지 복리후생 항목) — 경조금 금액·휴가 일수 미기재', 70),
  (@comp_id, 'parenting', '출산 축하선물', NULL, 'family',
   'est', NULL, TRUE, '축하선물 지급 중 출산 (공식 채용 페이지 복리후생 항목) — 선물 내용 미기재', 71),
  (@comp_id, 'child_edu', '자녀학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금 지원 (공식 채용 페이지 복리후생 항목), 자녀 교육비 지원 (2025 지속가능경영보고서 47쪽 복리후생 지원 항목) — 지원 학령·금액 미기재', 72),

  -- ── 건강 (health) — 공식 채용 페이지 + 보고서 ──
  (@comp_id, 'clinic', '사내 의무실 힐링테라스', NULL, 'health',
   'est', NULL, TRUE, '사내 의무실 힐링테라스 운영 (공식 채용 페이지 복리후생 항목), 간단한 상처 치료, 혈압·혈당 측정을 통한 생활 습관 관리 (2025 지속가능경영보고서 56쪽 힐링테라스 운영 항목) — 운영 시간·상주 인력 미기재', 80),
  (@comp_id, 'health_check', '건강검진 지원 · 선택검진제도 · 가족검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강검진 지원 (공식 채용 페이지 복리후생 항목), 2025년부터 내시경, CT, 초음파 검사 등 항목을 선택할 수 있는 선택검진제도 도입, 가족검진 지원 제도를 연계해 가족까지 건강검진 혜택 확대 (2025 지속가능경영보고서 56쪽 건강검진제도 확대 항목) — 검진 주기·가족 범위·비용 지원 범위 미기재', 81),
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체 상해보험 지원 (공식 채용 페이지 복리후생 항목) — 보장 범위·가족 포함 여부 미기재', 82),
  (@comp_id, 'fitness', 'AK 피지컬 프로그램 · 걷기 프로그램', NULL, 'health',
   'est', NULL, TRUE, 'AK 피지컬 2025 프로그램으로 임직원의 체력 수준과 신체 상태 측정, 본사 및 연구소 등 주요 사업장 대상 걷기 프로그램 · 길따라 걷기 챌린지 목표 달성 시 포상 (2025 지속가능경영보고서 56쪽 AK 피지컬 프로그램 운영 항목) — 포상 내용 미기재', 83),
  (@comp_id, 'mental', '힐링테라스 멘탈 건강 상담', NULL, 'health',
   'est', NULL, TRUE, '사내 건강관리 공간 힐링테라스에서 멘탈 건강 관리를 위한 상담과 휴식 제공 (2025 지속가능경영보고서 56쪽 힐링테라스 운영 항목) — 상담 인력·이용 조건 미기재', 84),

  -- ── 휴가 (time_off) — 2025 지속가능경영보고서 ──
  (@comp_id, 'leave_general', '샌드위치 데이 · 연말 리프레시 데이', NULL, 'time_off',
   'est', NULL, TRUE, '연휴 전후 및 연말 기간의 업무 부담 완화를 위한 샌드위치 데이와 연말 리프레시 데이 운영 (2025 지속가능경영보고서 48쪽 일과 삶의 균형 항목) — 연차 사용일인지·일수·유급 여부 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
