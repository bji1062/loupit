-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 케이뱅크 복리후생 데이터 (신규 회사 — 웨이브 11)
-- 출처: AI 파싱 (2026-10-16)
-- URL: https://kbank.recruiter.co.kr/career/benefits
-- badge: est
--
-- 참고:
--   정본 = 케이뱅크 채용 사이트 복지와 혜택 페이지(kbank.recruiter.co.kr/career/benefits) — www.kbanknow.com 헤더
--     메뉴 인재영입 링크로 이어지는 법인 채용 사이트. 본문은 벤더 API 호스트(robots Disallow 전체)에서만 그려져
--     사람이 브라우저로 연 화면을 사용자가 붙여 넣은 사본으로 수집했다(5섹션 15항목 · 페이지 재요청 0회).
--   보조 = OpenDART 2026 반기보고서(20260814003251) 직원 등 현황 · 2025 사업보고서(20260323001560)
--     환경 및 종업원에 관한 사항 — 유연근무제도 사용 현황 표 · 육아휴직 내규 최대 2년 · 복지제도 확대 문장.
--   귀속: 페이지 주어는 케이뱅크(섹션 머리 케이뱅크에서의 소프트 랜딩). 대주주 KT 시드(recruit.kt.com) 문장과
--     글자 대조 겹침 0 · KT 그룹 주어 · 계열사별 상이 단서 없음 → 각주 없음.
--   금액: stated 1(welfare_point 연간 520만원) · 추정 0. 나머지 숫자는 일수 · 주기(근속 3년마다 · 연간 3일 ·
--     매년 1회)라 금액 아님.
--   제외: 추천 채용 리워드(인재추천 포상금) · 커넥트데이(CEO 경영 방향 공유 소통 행사) · 우리사주조합(주주 표 ·
--     보호예수 표 칸뿐) · 주식선택권 · 퇴직급여(법정) · 배우자 출산휴가 · 육아기 단축근무(법정 표 항목).
--   공고 근거 0행 / 전체 15행.
--   SORT 섹션 순서 = 정본 페이지에 카테고리가 처음 나온 순서(flexibility · leisure · time_off · health · family ·
--     compensation · perks · growth), 공시 행은 같은 카테고리 섹션 끝.
-- 검증 · 감사 판정 반영(2026-10-16): 행 조치 없음 · 원격근무제 조건부(공시 코로나 사유 주석) · 육아휴직 최대 2년(내규) · 복지포인트 연간 520만원 공식 수치 · 커넥트데이와 추천 채용 리워드는 싣지 않음 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 15행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kbank', '케이뱅크',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '핀테크/은행', 'K', 'https://kbank.recruiter.co.kr/career/benefits');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kbank');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://kbank.recruiter.co.kr/career/benefits'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 채용 사이트 복지와 혜택 + 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '개인의 라이프스타일에 맞춰 근로시간을 자율적으로 결정하는 유연근무제 (공식 채용 사이트 복지와 혜택 유연근무제 항목), 2026년 6월 30일 기준 시차출퇴근제 사용자 22명 · 선택근무제 사용자 631명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 근무시간대·적용 대상 미기재', 10),
  (@comp_id, 'remote_work', '원격근무제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 2024년 말 42명, 코로나 확산 방지를 위해 재택근무 운영 (2026 반기보고서 유연근무제도 사용 현황 항목) — 2025년 이후 사용자 수·대상 직무·사용 조건 미기재', 11),

  -- ── 여가 (leisure) — 채용 사이트 복지와 혜택 ──
  (@comp_id, 'resort', '임직원 휴양시설', NULL, 'leisure',
   'est', NULL, TRUE, '열심히 일한 후 리프레시할 수 있도록 휴양시설 이용 지원 (공식 채용 사이트 복지와 혜택 임직원 휴양시설 항목), 휴양소 등 복지제도 확대 (2025 사업보고서 환경 및 종업원에 관한 사항 항목) — 시설 위치·이용 횟수·비용 지원 범위 미기재', 20),
  (@comp_id, 'welcome_kit', '웰컴 키트', NULL, 'leisure',
   'est', NULL, TRUE, '새로운 동료를 환영하는 마음을 담아 웰컴 키트 전달 (공식 채용 사이트 복지와 혜택 웰컴 키트 항목) — 구성품 미기재', 21),
  (@comp_id, 'club', '사내동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회를 통해 취미도, 자기개발도 동료들과 함께하는 사내동호회 지원 (공식 채용 사이트 복지와 혜택 사내동호회 지원 항목) — 지원 금액·동호회 종류 미기재', 22),
  (@comp_id, 'company_event', '케미데이', NULL, 'leisure',
   'est', NULL, TRUE, '반기별로 동료들과 실컷 웃고, 맘껏 이야기하고, 함께 어울리는 시간 (공식 채용 사이트 복지와 혜택 케미데이 항목) — 행사 내용·비용 지원 미기재', 23),

  -- ── 휴가 (time_off) — 채용 사이트 복지와 혜택 + 2025 사업보고서 ──
  (@comp_id, 'long_service_leave', '장기근속휴가', NULL, 'time_off',
   'est', NULL, TRUE, '재충전을 위해 근속 3년마다 휴가와 보상금 지원 (공식 채용 사이트 복지와 혜택 장기근속휴가 항목) — 휴가 일수·보상금 금액 미기재', 30),
  (@comp_id, 'leave_general', '자기계발휴가', NULL, 'time_off',
   'est', NULL, TRUE, '역량 개발에 몰입할 수 있도록 연간 3일의 휴가 제공 (공식 채용 사이트 복지와 혜택 자기계발휴가 항목), 자기계발휴가 등 복지제도 확대 (2025 사업보고서 환경 및 종업원에 관한 사항 항목) — 유급 여부·사용 조건 미기재', 31),

  -- ── 건강 (health) — 채용 사이트 복지와 혜택 ──
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '본인과 배우자, 자녀까지 든든한 단체보험 지원 (공식 채용 사이트 복지와 혜택 단체보험 항목) — 보장 내용·보험료 미기재', 40),
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '매년 1회 본인과 가족 1명의 종합건강검진과 검진휴가 지원 (공식 채용 사이트 복지와 혜택 건강검진 지원 항목) — 검진 비용 지원 범위·검진휴가 일수 미기재', 41),

  -- ── 가족 (family) — 채용 사이트 복지와 혜택 + 2026 반기보고서 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '기쁜 일은 축하하고, 슬픈 일은 위로가 될 수 있도록 경조금과 경조휴가 제공 (공식 채용 사이트 복지와 혜택 경조사 지원 항목) — 경조 종류별 금액·휴가 일수 미기재', 50),
  (@comp_id, 'parenting', '육아휴직 최대 2년', NULL, 'family',
   'est', NULL, TRUE, '육아휴직 사용기간 내규상 최대 2년까지 사용 가능 (2026 반기보고서 육아지원제도 사용 현황 항목) — 휴직 중 급여 지원 미기재', 51),

  -- ── 보상 (compensation) — 채용 사이트 복지와 혜택 ──
  (@comp_id, 'excellence_award', '피어 보너스', NULL, 'compensation',
   'est', NULL, TRUE, '도움을 준 동료를 공개적으로 칭찬하고, 감사한 마음을 나누는 피어 보너스 (공식 채용 사이트 복지와 혜택 피어 보너스 항목) — 보상 형태·금액 미기재', 60),

  -- ── 생활 (perks) — 채용 사이트 복지와 혜택 ──
  (@comp_id, 'welfare_point', '복지포인트', 520, 'perks',
   'est', '자유롭게 사용할 수 있는 복지포인트 연간 520만원 지원 (공식 채용 사이트 복지와 혜택 복지포인트 항목) — 지급 시기 미기재', FALSE, NULL, 70),

  -- ── 성장 (growth) — 채용 사이트 복지와 혜택 ──
  (@comp_id, 'self_development', '성장지원제도', NULL, 'growth',
   'est', NULL, TRUE, '새것을 익히고 성장할 수 있도록 교육 및 자격증 지원 시스템 (공식 채용 사이트 복지와 혜택 성장지원제도 항목) — 지원 대상 교육·지원 금액 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
