-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 종근당 복리후생 데이터 (신규 회사 — 웨이브 11)
-- 출처: AI 파싱 (2026-10-16)
-- URL: https://ckd.recruiter.co.kr/career/Welfare
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)종근당의 법인 전용 채용 사이트 ckd.recruiter.co.kr 복리후생 페이지다
--   (자기 도메인 www.ckdpharm.com 상단 인재채용 링크가 이 사이트로 연결 · 사이트 이름 종근당 채용).
--   본문은 벤더 API 호스트(robots 전면 금지)에서 클라이언트 렌더로 불러와 직접 받지 않았고,
--   사용자가 브라우저로 연 화면을 붙여 넣은 사본(2026-10-16 · 9개 블록 18줄)을 원문으로 썼다.
--   보조 출처: OpenDART 2025 사업보고서(접수 20260318001376)와 2026 반기보고서(접수 20260814003547)
--   직원 등 현황 유연근무제도 사용 현황 표(시차출퇴근제 · 원격근무제 사용자 수).
--   귀속: 페이지 문구가 종근당은 든든한 복지로 여러분을 응원합니다 로 법인 단수 주어이고
--   그룹 · 계열사 공통 단서가 없다 — 각주 없음. 코퍼스에 종근당홀딩스 형제 시드 0건.
--   금액: 원문에 숫자 0건 — 전 행 BENEFIT_AMT NULL(자녀학자금 전액 지원은 비율이라 금액 아님).
--   제외: 일반 건강검진(법정 일반건강진단 이름 — 정밀 건강검진만 행) · 공시 선택근무제(전 기간 사용자 없음) ·
--     공시 임원 보수 산정 칸(상여 · 성과급 · 복지규정) · 자기 도메인 2025 지속가능경영보고서(robots 로 받지 않음).
--   공고 근거 0행 / 전체 21행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(flexibility 10 · work_env 20 · time_off 30 · leisure 40 ·
--     family 50 · growth 60 · health 70 · perks 80 · compensation 90).
-- 검증 · 감사 판정 반영(2026-10-16): 행 조치 없음 · 사용자 붙여넣기 사본 21행 그대로 · 건강검진은 정밀 몫만(일반은 법정 검진 이름) · 건강기능식품 임직원몰 discount 유지 · 공시 선택근무제는 다섯 기간 사용자 없음이라 싣지 않음 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('chongkundang', '종근당',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '제약', 'C', 'https://ckd.recruiter.co.kr/career/Welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'chongkundang');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://ckd.recruiter.co.kr/career/Welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 채용 페이지 Work & Life Balance · 2025 사업보고서 · 2026 반기보고서 ──
  (@comp_id, 'pc_off', 'PC-Off', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-Off (공식 채용 페이지 복리후생 Work & Life Balance 항목) — 적용 시각·대상 미기재', 10),
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 (공식 채용 페이지 복리후생 Work & Life Balance 항목), 유연근무제 활용, 시차출퇴근제 사용자 수 2023년 70명·2024년 62명·2025년 100명·2026년 상반기 87명 (2025 사업보고서·2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 제도 유형별 적용 대상·출퇴근 시간대 미기재', 11),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 (공식 채용 페이지 복리후생 Work & Life Balance 항목), 원격근무제(재택근무 포함) 사용자 수 2023년 313명·2024년 226명·2025년 177명·2026년 상반기 147명 (2025 사업보고서·2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 12),
  -- ── 근무 환경 (work_env) — 채용 페이지 Work & Life Balance ──
  (@comp_id, 'smart_office', '스마트오피스', NULL, 'work_env',
   'est', NULL, TRUE, '스마트오피스 (공식 채용 페이지 복리후생 Work & Life Balance 항목) — 공간 구성·적용 사업장 미기재', 20),
  -- ── 휴가 (time_off) — 채용 페이지 Refresh ──
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '리프레시 휴가 (공식 채용 페이지 복리후생 Refresh 항목) — 휴가 일수·부여 조건 미기재', 30),
  (@comp_id, 'summer_leave', '하기휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하기휴가 (공식 채용 페이지 복리후생 Refresh 항목) — 연차 사용일인지·일수·유급 여부 미기재', 31),
  -- ── 여가 (leisure) — 채용 페이지 Refresh · 직원혜택 · 회사생활 ──
  (@comp_id, 'resort', '무료 휴양소 · 제휴사 콘도', NULL, 'leisure',
   'est', NULL, TRUE, '여름휴가시 무료 휴양소 운영 (공식 채용 페이지 복리후생 Refresh 항목), 제휴사 콘도 이용 (같은 페이지 복리후생 직원혜택 항목) — 휴양소 위치·이용 기간·콘도 이용 요금 지원 여부 미기재', 40),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 지원 (공식 채용 페이지 복리후생 회사생활 항목) — 지원 금액·지원 방식 미기재', 41),
  -- ── 가족 (family) — 채용 페이지 교육비 · 경조사 지원 · 회사생활 ──
  (@comp_id, 'child_edu', '자녀학자금 전액 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금 전액 지원 (공식 채용 페이지 복리후생 교육비 항목) — 지원 학교 단계·자녀 수 제한 미기재', 50),
  (@comp_id, 'event', '경조금 · 경조휴가', NULL, 'family',
   'est', NULL, TRUE, '회사 & 사우회 경조금 지원, 경조휴가 지원 (공식 채용 페이지 복리후생 경조사 지원 항목) — 경조 구분별 금액·휴가 일수 미기재', 51),
  (@comp_id, 'childcare', '사내어린이집 (공장)', NULL, 'family',
   'est', NULL, TRUE, '사내어린이집 운영 (공장) (공식 채용 페이지 복리후생 회사생활 항목) — 정원·이용 자녀 연령 미기재', 52),
  -- ── 성장 · 교육 (growth) — 채용 페이지 교육비 · 자기개발 ──
  (@comp_id, 'mba', '석/박사 학위과정 연수 지원', NULL, 'growth',
   'est', NULL, TRUE, '석/박사 학위과정 연수 지원 (공식 채용 페이지 복리후생 교육비 항목) — 선발 기준·지원 범위 미기재', 60),
  (@comp_id, 'edu_support', '사내외 교육 · E-learning', NULL, 'growth',
   'est', NULL, TRUE, '사내외 교육, E-learning (공식 채용 페이지 복리후생 자기개발 항목) — 과정 종류·교육비 지원 범위 미기재', 61),
  (@comp_id, 'books', '도서비', NULL, 'growth',
   'est', NULL, TRUE, '도서비 (공식 채용 페이지 복리후생 자기개발 항목) — 지원 금액·한도 미기재', 62),
  (@comp_id, 'self_development', '자기개발 프로그램 및 비용 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기개발 프로그램 및 비용 지원 (공식 채용 페이지 복리후생 자기개발 항목) — 지원 금액·대상 프로그램 미기재', 63),
  -- ── 건강 (health) — 채용 페이지 건강관리 ──
  (@comp_id, 'health_check', '정밀 건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '정밀 건강검진 지원 (공식 채용 페이지 복리후생 건강관리 항목) — 검진 주기·대상·비용 지원 범위 미기재', 70),
  -- ── 생활 · 금융 (perks) — 채용 페이지 건강관리 · 직원혜택 · 회사생활 ──
  (@comp_id, 'discount', '건강기능식품 임직원몰', NULL, 'perks',
   'est', NULL, TRUE, '건강기능식품 임직원몰 운영 (공식 채용 페이지 복리후생 건강관리 항목) — 판매 품목·가격 혜택·이용 조건 미기재', 80),
  (@comp_id, 'welfare_point', '복지포인트 · 복지몰', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 지급 / 복지몰 운영 (공식 채용 페이지 복리후생 직원혜택 항목) — 지급 포인트 금액·지급 시기 미기재', 81),
  (@comp_id, 'commute_subsidy', '통근버스 (연구소, 공장)', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운영 (연구소, 공장) (공식 채용 페이지 복리후생 회사생활 항목) — 운행 노선·운행 시간 미기재', 82),
  -- ── 보상 (compensation) — 채용 페이지 포상 ──
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (공식 채용 페이지 복리후생 포상 항목) — 근속 기준·포상 형태·금액 미기재', 90),
  (@comp_id, 'excellence_award', '우수사원 해외여행비 지원', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 해외여행비 지원 (공식 채용 페이지 복리후생 포상 항목) — 선발 기준·지원 금액·여행 기간 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
