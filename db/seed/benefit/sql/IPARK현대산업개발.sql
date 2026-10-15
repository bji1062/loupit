-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- IPARK현대산업개발 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.ipark-dvp.com/ko/careers/hr-system
-- badge: est
--
-- 참고:
--   정본은 상장 법인 아이파크현대산업개발(주)(DART 01310269 · 홈 www.ipark-dvp.com)의 자기 도메인
--   인재 채용 > 인사 제도 페이지다. SSR 이라 원본 HTML 에 복리후생 3묶음(Work Life and Balance 8 ·
--   Healthcare and Wellness 4 · Life and Family 6) 라벨 18개가 다 있다. 라벨만 있고 설명 문장은 없다.
--   헤드리스 렌더 · 이미지 판독 불필요. 영문판 /en/careers/hr-system 은 같은 18개 라벨의 번역(휴테크 제도 = Hutech Systems).
--   보조 출처: OpenDART 2026 반기보고서 [기재정정](접수 20260818000088) 직원 등 현황 유연근무제도 사용 현황 표
--   (유연근무제 활용 여부 일부활용(본사) · 시차출퇴근제). 직원 합계 1,833명.
--   귀속: 페이지 주어가 IPARK현대산업개발은 으로 법인 단수 주어이고 그룹 · 계열사 단서가 없다. 각주 없음.
--   코퍼스 · 대기 폴더에 HDC 그룹 형제(HDC · HDC랩스 등) 없음.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL.
--   제외: 법정(육아휴직 · 육아기 단축근무 · 배우자 출산휴가 사용자 수 표) · 원격근무제(공시 당기 · 전기 사용자 0 ·
--     회사 복리후생 목록에 없음) · 우리사주조합(주주 표 한 칸뿐) · 임원 보수 칸 성과급 · 평가 및 보상체계 문단(제도 이름 없음) ·
--     직무별 역량 개발 프로그램(업무 교육). 지속가능경영보고서 PDF 는 POST 폼으로만 내려와 받지 않았다.
--   공고 근거 0행 / 전체 16행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(flexibility 10 · work_env 20 · perks 30 · growth 40 · time_off 50 ·
--     leisure 60 · compensation 70 · health 80 · family 90).
-- 검증 · 감사 판정 반영(2026-10-15): 유연근무제 이름을 조건부로(공시 일부활용 본사) · 공시 원격근무제 2024년 8명 remote_work 조건부 추가(리드 판정 137 잣대 — 참고 블록 제외 줄의 공시 원격근무는 이 판정으로 뒤집힘) · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 17행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ipark_hdc', 'IPARK현대산업개발',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '건설', 'I', 'https://www.ipark-dvp.com/ko/careers/hr-system');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ipark_hdc');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.ipark-dvp.com/ko/careers/hr-system'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 공식 채용 페이지 인사 제도 + 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제, 육아기 시차출퇴근제 (공식 채용 페이지 인사 제도 복리후생 항목), 유연근무제 활용 여부 일부활용(본사) · 시차출퇴근제 (2026 반기보고서 유연근무제도 사용 현황 표 항목) — 제도 유형별 대상·사용 조건 미기재', 10),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함) (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용 여부 일부활용(본사) · 원격근무제(재택근무 포함) 사용자 2024년 8명 · 2025년 0명 · 2026년 상반기 0명 (2026 반기보고서 유연근무제도 사용 현황 표 항목) — 대상 직무·사용 조건 미기재', 11),

  -- ── 근무 환경 (work_env) — 공식 채용 페이지 인사 제도 ──
  (@comp_id, 'dormitory', '숙소 (현장)', NULL, 'work_env',
   'est', NULL, TRUE, '현장 숙소 (공식 채용 페이지 인사 제도 복리후생 항목) — 숙소 형태·대상·비용 부담 미기재', 20),

  -- ── 생활 · 금융 (perks) — 공식 채용 페이지 인사 제도 ──
  (@comp_id, 'transport', '교통비 (현장)', NULL, 'perks',
   'est', NULL, TRUE, '현장 교통비 (공식 채용 페이지 인사 제도 복리후생 항목) — 지급 기준·금액 미기재', 30),
  (@comp_id, 'telecom', '통신비', NULL, 'perks',
   'est', NULL, TRUE, '통신비 (공식 채용 페이지 인사 제도 복리후생 항목) — 지원 금액·대상 미기재', 31),
  (@comp_id, 'housing_loan', '주택자금대여', NULL, 'perks',
   'est', NULL, TRUE, '주택자금대여 (공식 채용 페이지 인사 제도 복리후생 항목) — 대여 한도·이율·대상 미기재', 32),

  -- ── 성장 · 교육 (growth) — 공식 채용 페이지 인사 제도 ──
  (@comp_id, 'edu_support', 'HDC Academy (자기개발지원)', NULL, 'growth',
   'est', NULL, TRUE, 'HDC Academy 자기개발지원 (공식 채용 페이지 인사 제도 복리후생 항목) — 지원 방식·과정·대상 미기재', 40),

  -- ── 휴가 (time_off) — 공식 채용 페이지 인사 제도 ──
  (@comp_id, 'leave_general', '휴테크 제도', NULL, 'time_off',
   'est', NULL, TRUE, '휴테크 제도 (공식 채용 페이지 인사 제도 복리후생 항목, 영문 페이지 Hutech Systems 항목) — 제도 내용·휴가 일수·부여 조건 미기재', 50),

  -- ── 여가 (leisure) — 공식 채용 페이지 인사 제도 ──
  (@comp_id, 'resort', '휴양시설 바우처', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설 바우처 (공식 채용 페이지 인사 제도 복리후생 항목) — 이용 횟수·지원 범위 미기재', 60),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 지원 (공식 채용 페이지 인사 제도 복리후생 항목) — 지원 금액·방식 미기재', 61),

  -- ── 보상 (compensation) — 공식 채용 페이지 인사 제도 ──
  (@comp_id, 'holiday_gift', '명절포인트', NULL, 'compensation',
   'est', NULL, TRUE, '명절포인트 (공식 채용 페이지 인사 제도 복리후생 항목) — 포인트 규모·지급 시기 미기재', 70),

  -- ── 건강 (health) — 공식 채용 페이지 인사 제도 ──
  (@comp_id, 'health_check', '종합건강검진 (가족 1인 포함)', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진, 가족 1인 포함 (공식 채용 페이지 인사 제도 복리후생 항목) — 검진 주기·비용 지원 범위 미기재', 80),
  (@comp_id, 'medical', '중대질환 의료비 · 가족 입원 치료비', NULL, 'health',
   'est', NULL, TRUE, '중대질환 의료비, 가족 입원 치료비 (공식 채용 페이지 인사 제도 복리후생 항목) — 지원 한도·대상 질환·가족 범위 미기재', 81),
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '단체보험 (공식 채용 페이지 인사 제도 복리후생 항목) — 보장 범위·가입 대상 미기재', 82),

  -- ── 가족 (family) — 공식 채용 페이지 인사 제도 ──
  (@comp_id, 'child_edu', '자녀 대학 학자금 · 유치원 보육비', NULL, 'family',
   'est', NULL, TRUE, '자녀 대학 학자금, 유치원 보육비 (공식 채용 페이지 인사 제도 복리후생 항목) — 지원 한도·자녀 수 미기재', 90),
  (@comp_id, 'event', '경조금 및 경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금 및 경조휴가 (공식 채용 페이지 인사 제도 복리후생 항목) — 경조 사유별 금액·휴가 일수 미기재', 91),
  (@comp_id, 'parenting', '초등/중학교 입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '초등/중학교 입학 축하금 (공식 채용 페이지 인사 제도 복리후생 항목) — 지급 금액 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
