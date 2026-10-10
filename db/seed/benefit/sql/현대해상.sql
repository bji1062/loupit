-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대해상 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://hi.recruiter.co.kr/career/welfare
-- badge: est
--
-- 참고:
--   정본 = 현대해상 회사 계정 채용 사이트 복리후생 페이지(hi.recruiter.co.kr/career/welfare, 제목 복리후생 · 현대해상 채용).
--   본문은 벤더 데이터 호스트(api-recruiter.recruiter.co.kr, robots Disallow 전체)에서만 내려와 직접 받지 않았다.
--   사용자가 2026-10-10 브라우저로 열어 붙여 넣은 본문 사본이 근거다
--   (W5/hi_insurance/user_paste_2026-10-10.txt, sha256 273afc08…0217c). 이 파일의 원문 요청 0회.
--   렌더 방식: Next.js CSR(웨이브 4 프로브 실측) — 원본 HTML 에 본문 없음.
--   귀속: 법인 전용 서브도메인 hi, 메타 author 현대해상, 본문에 손해보험업계 · 보험계리사 · 손해사정사 등
--   이 법인 고유 문구가 있어 ATS 샘플 템플릿이 아니다. 범현대 별도 그룹이라 그룹 각주 없음.
--   제휴할인 항목의 현대 · 기아자동차 · 현대백화점은 원문이 적은 할인 제휴처 이름이다(귀속 주어 아님).
--   원문 8개 블록 22개 점 → 17행. 보조 출처 없음.
--   금액: 원문에 원 단위 숫자 0건 — 17행 전부 금액 NULL(stated 0 · 추정 0).
--   제외: 급여 블록의 업계 상위권 급여 수준(임금 수준) · 전문인수당과 자격수당(급여성 수당) ·
--         모성보호 블록 2점(출산전후휴가 · 육아휴직 · 임신기와 육아기 근로시간 단축 = 법정).
--   공고 근거 0행 / 전체 17행.
--   SORT 섹션 순서(원문에 처음 나온 순서): perks 10 · leisure 20 · flexibility 30 · time_off 40 ·
--   health 50 · family 60 · growth 70 · compensation 80.
-- 검증 · 감사 판정 반영(2026-10-10): 休-9 연속 휴가사용 장려 leave_general 삭제(회사가 더 주는 날 없음) — 최종 16행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_marine', '현대해상',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '보험', 'H', 'https://hi.recruiter.co.kr/career/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_marine');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://hi.recruiter.co.kr/career/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 원문 급여 연금지원 · 문화생활 복지카드 · 기타지원 제휴할인 ──
  (@comp_id, 'pension_support', '개인연금 보험료 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 가입 직원 대상 월 보험료 지원 (공식 채용 페이지 복리후생 급여 연금지원 항목) — 월 지원액·지원 기간 미기재', 10),
  (@comp_id, 'welfare_point', '직원 복지카드', NULL, 'perks',
   'est', NULL, TRUE, '직원 복지카드 지급, 여행·공연·레저·도서 등에 사용 (공식 채용 페이지 복리후생 문화생활 항목) — 연간 지급액·사용 기한 미기재', 11),
  (@comp_id, 'discount', '임직원 제휴할인 (자동차·백화점)', NULL, 'perks',
   'est', NULL, TRUE, '임직원 제휴할인, 현대/기아자동차·현대백화점 할인 (공식 채용 페이지 복리후생 기타지원 항목) — 할인율·이용 한도 미기재', 12),

  -- ── 여가·라이프 (leisure) — 원문 문화생활 ──
  (@comp_id, 'resort', '호텔·콘도 제휴할인', NULL, 'leisure',
   'est', NULL, TRUE, '호텔&콘도 제휴할인 (공식 채용 페이지 복리후생 문화생활 항목) — 제휴처·할인율·이용 한도 미기재', 20),
  (@comp_id, 'club', '사내동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 지원 (공식 채용 페이지 복리후생 문화생활 항목) — 지원 금액·동호회 수 미기재', 21),

  -- ── 근무 유연성 (flexibility) — 원문 일과 삶의 균형 ──
  (@comp_id, 'pc_off', 'PC On/Off 제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC On/Off 제도, 출근시간 전 PC 사용 불가·퇴근시간 후 PC 자동종료 (공식 채용 페이지 복리후생 일과 삶의 균형 항목) — 적용 대상·예외 승인 절차 미기재', 30),

  -- ── 시간·휴가 (time_off) — 원문 일과 삶의 균형 · 기타지원 장기근속자 ──
  (@comp_id, 'refresh_leave', '체력단련휴가 (법정휴가 외 5일)', NULL, 'time_off',
   'est', NULL, TRUE, '법정휴가 外 체력단련휴가 5일 부여 (공식 채용 페이지 복리후생 일과 삶의 균형 항목) — 유급 여부·사용 시기 미기재', 40),
  (@comp_id, 'birthday_leave', '생일 근로면제', NULL, 'time_off',
   'est', NULL, TRUE, '생일자 생일 근로면제 (공식 채용 페이지 복리후생 일과 삶의 균형 항목) — 면제 범위(하루·반일)·유급 여부 미기재', 41),
  (@comp_id, 'long_service_leave', '장기근속자 휴가·포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 휴가 및 포상 지급 (공식 채용 페이지 복리후생 기타지원 항목) — 근속 연수 기준·휴가 일수·포상 내용 미기재', 43),

  -- ── 건강·의료 (health) — 원문 건강관리 ──
  (@comp_id, 'health_check', '정기 건강검진·검진일 휴가', NULL, 'health',
   'est', NULL, TRUE, '연 1회 임직원 정기검진 실시, 검진일 휴가 부여 (공식 채용 페이지 복리후생 건강관리 항목) — 검진 항목·비용 지원 범위·가족 포함 여부 미기재', 50),
  (@comp_id, 'insurance', '의료비 지원 (단체상해보험)', NULL, 'health',
   'est', NULL, TRUE, '질병/부상으로 인한 진료 시 의료비 지원을 위한 단체상해보험 가입 (공식 채용 페이지 복리후생 건강관리 의료비지원 항목) — 보장 한도·가족 포함 여부 미기재', 51),

  -- ── 가족·돌봄 (family) — 원문 가정행복 ──
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 운영 (공식 채용 페이지 복리후생 가정행복 항목) — 운영 사업장·정원·이용 대상 미기재', 60),
  (@comp_id, 'child_edu', '자녀 학자금 지원 (고교·대학)', NULL, 'family',
   'est', NULL, TRUE, '고교/대학 자녀 학자금 지원 (공식 채용 페이지 복리후생 가정행복 항목) — 지원 한도·자녀 수 제한 미기재', 61),
  (@comp_id, 'event', '경조휴가·경조금', NULL, 'family',
   'est', NULL, TRUE, '본인/가족 경조일 경조휴가 및 경조금 지급 (공식 채용 페이지 복리후생 가정행복 항목) — 경조 사유별 휴가 일수·경조금 금액 미기재', 62),

  -- ── 성장·교육 (growth) — 원문 자기개발 ──
  (@comp_id, 'self_development', '자격증 취득비용·합격축하금', NULL, 'growth',
   'est', NULL, TRUE, '직무유관 주요 자격증 취득비용 지원, 주요 전문자격 취득 시 합격축하금 지급 (공식 채용 페이지 복리후생 자기개발 항목) — 대상 자격증·지원 한도·축하금 금액 미기재', 70),

  -- ── 보상·금전 (compensation) — 원문 기타지원 ──
  (@comp_id, 'holiday_gift', '근로자의 날 선물', NULL, 'compensation',
   'est', NULL, TRUE, '근로자의날 선물 지급 (공식 채용 페이지 복리후생 기타지원 항목) — 선물 품목·금액 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
