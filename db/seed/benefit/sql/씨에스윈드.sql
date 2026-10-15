-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 씨에스윈드 복리후생 데이터 (신규 회사 — 웨이브 10)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.cswind.com/talent_recruitment/welfare
-- badge: est
--
-- 참고:
--   정본은 상장 법인 씨에스윈드(주)의 자기 도메인 www.cswind.com 인재채용 > 복리후생 페이지다.
--   SSR 이라 원본 HTML 에 복리후생 7블록(업무 환경 · 건강 · 생활 안정 지원 · 자기계발 지원 · 포상 · 사내 행사 · 기타)이 다 있다.
--   헤드리스 렌더 · 이미지 판독 불필요. 영문판(/en/talent_recruitment/welfare)은 같은 항목의 번역이다.
--   보조 출처: 공식 홈 링크의 회사 계정 채용 사이트 cswind.career.greetinghr.com 홈 복리후생 블록(__NEXT_DATA__ SSR) ·
--   OpenDART 2026 반기보고서(접수 20260814001500) 유연근무제 사용현황 · 2025 사업보고서(접수 20260318001110)
--   재무제표 주석 기타장기종업원급여. 지속가능경영보고서 목록은 국문 · 영문 모두 0건이다.
--   귀속: 페이지 주어가 CS WIND는 이고 그룹 · 계열사 단서가 없다. 채용 사이트 근무지는 서울 강남 본사.
--   해외 생산법인 제도 문장은 읽은 출처에 없다. 각주 없음. 국내 직원 98명(2025-12-31 사업보고서).
--   금액: 원문에 원 단위 숫자 0건 — 식대 1행만 기준 단가 추정(하루 3끼 × 12,000원 × 240일 = 864), 나머지 NULL.
--   제외: 임원 보수지급기준 칸의 복리후생비 문장(차량유지비 · 자기개발비 · 관리비 — 임원 산정 칸) ·
--     주주 현황 표의 우리사주조합 한 칸 · 사옥 사진 캡션(회의실 · 로비) · 자유로운 휴가 사용 분위기(제도 아님) ·
--     업무 자율성 · 조직장 협업(제도 아님).
--   공고 근거 0행 / 전체 25행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(flexibility 10 · perks 20 · health 30 · work_env 40 · family 50 ·
--     time_off 60 · growth 70 · compensation 80 · leisure 90).
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 관리비 지원 housing_support · 정직원 순금 배지 welcome_kit · 질병 진료 보장 medical · 교육비와 컨퍼런스비 conference 유지 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 25행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('cs_wind', '씨에스윈드',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '에너지/발전', 'C', 'https://www.cswind.com/talent_recruitment/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cs_wind');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.cswind.com/talent_recruitment/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 복리후생 업무 환경 · 채용 사이트 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '탄력근로시간제·유연출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '탄력근로시간제 운영 (공식 채용 페이지 복리후생 업무 환경 항목), 집중근무를 위한 유연출퇴근제 (회사 채용 사이트 복리후생 몰입을 위한 최고의 근무 환경 항목), 선택근무제 (2026 반기보고서 직원 등 현황 유연근무제 사용현황 항목) — 적용 대상·운영 방식 미기재', 10),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 활용 (2026 반기보고서 직원 등 현황 유연근무제 사용현황 항목) — 대상 직무·사용 조건 미기재', 11),
  -- ── 생활 · 편의 (perks) — 복리후생 업무 환경 · 생활 안정 지원 · 기타 · 채용 사이트 ──
  (@comp_id, 'meal', '조식·중식·석식 제공', 864, 'perks',
   'est', '아침, 점심, 저녁식사 제공 (공식 채용 페이지 복리후생 업무 환경 항목), 식비 지원 (회사 채용 사이트 복리후생 항목) — 식대 단가·본인 부담 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 20),
  (@comp_id, 'snack_bar', '간식 제공', NULL, 'perks',
   'est', NULL, TRUE, '간식 제공 (공식 채용 페이지 복리후생 업무 환경 항목), 간식비 지원 (회사 채용 사이트 복리후생 몰입을 위한 최고의 근무 환경 항목) — 간식 종류·지원 금액 미기재', 21),
  (@comp_id, 'housing_support', '관리비 지원', NULL, 'perks',
   'est', NULL, TRUE, '관리비 지원 (공식 채용 페이지 복리후생 생활 안정 지원 항목) — 관리비 종류·지원 대상·지원 금액 미기재', 22),
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일 선물 지급 (공식 채용 페이지 복리후생 기타 항목) — 선물 품목·금액 미기재', 23),
  -- ── 건강 (health) — 복리후생 업무 환경 · 건강 ──
  (@comp_id, 'fitness', '사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '사내 편의시설 헬스장·샤워시설 (공식 채용 페이지 복리후생 업무 환경 항목) — 이용 시간·운영 방식 미기재', 30),
  (@comp_id, 'health_check', '격년 상급종합병원 건강검진비 지원', NULL, 'health',
   'est', NULL, TRUE, '격년 상급종합병원 건강검진비 지원 (공식 채용 페이지 복리후생 건강 항목) — 검진 항목·지원 금액·가족 적용 미기재', 31),
  (@comp_id, 'insurance', '임직원 단체 보험·해외 출장 여행자 보험', NULL, 'health',
   'est', NULL, TRUE, '임직원 단체 보험 가입 지원, 해외 출장시 여행자 보험 가입 지원 (공식 채용 페이지 복리후생 건강 항목) — 보장 범위·가족 적용 미기재', 32),
  (@comp_id, 'medical', '질병·질환 진료 보장', NULL, 'health',
   'est', NULL, TRUE, '각종 질병/질환 진료에 대한 보장 (공식 채용 페이지 복리후생 건강 항목) — 보장 방식·지원 한도·가족 적용 미기재', 33),
  -- ── 근무 환경 (work_env) — 복리후생 업무 환경 ──
  (@comp_id, 'lounge', '사내 라운지·안마의자', NULL, 'work_env',
   'est', NULL, TRUE, '사내 편의시설 안마의자·라운지 (공식 채용 페이지 복리후생 업무 환경 항목) — 이용 시간·규모 미기재', 40),
  -- ── 가족 (family) — 복리후생 생활 안정 지원 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (공식 채용 페이지 복리후생 생활 안정 지원 항목) — 지원 학령·지원 금액 미기재', 50),
  (@comp_id, 'event', '경조휴가·경조금', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 경조금 지원 (공식 채용 페이지 복리후생 생활 안정 지원 항목), 경조 화환 Wreath (영문 채용 페이지 Welfare Stable living 항목) — 경조 범위·금액·휴가 일수 미기재', 51),
  -- ── 휴가 (time_off) — 복리후생 생활 안정 지원 · 채용 사이트 ──
  (@comp_id, 'refresh_leave', '격년 안식년 휴가 10일', NULL, 'time_off',
   'est', NULL, TRUE, '격년 안식년 휴가 제도 (공식 채용 페이지 복리후생 생활 안정 지원 항목), 2년 1회 안식년 휴가 10일 부여 (회사 채용 사이트 복리후생 재충전을 위한 지원 항목) — 부여 조건·유급 여부 미기재', 60),
  (@comp_id, 'leave_general', '휴가 선사용', NULL, 'time_off',
   'est', NULL, TRUE, '휴가 선사용 가능 (회사 채용 사이트 복리후생 재충전을 위한 지원 항목) — 선사용 한도·조건 미기재', 61),
  -- ── 성장 · 교육 (growth) — 복리후생 자기계발 지원 · 포상 · 채용 사이트 ──
  (@comp_id, 'self_development', '자기계발비 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기계발비 지원 (공식 채용 페이지 복리후생 자기계발 지원 항목), 도서 구입, 학습 등 성장에 필요한 자기계발비 지원 (회사 채용 사이트 복리후생 성장을 위한 지원 항목) — 지원 금액·지급 방식 미기재', 70),
  (@comp_id, 'conference', '교육비·컨퍼런스비 지원', NULL, 'growth',
   'est', NULL, TRUE, '직원 역량 교육 지원 (공식 채용 페이지 복리후생 자기계발 지원 항목), 업무에 필요한 교육비/컨퍼런스비 등 지원 (회사 채용 사이트 복리후생 성장을 위한 지원 항목) — 지원 한도·대상 과정 미기재', 71),
  (@comp_id, 'retirement_support', '정년퇴직 포상', NULL, 'growth',
   'est', NULL, TRUE, '정년퇴직 포상 (공식 채용 페이지 복리후생 포상 항목) — 포상 내용·금액 미기재', 72),
  -- ── 보상 (compensation) — 복리후생 포상 · 기타 · 2025 사업보고서 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 (공식 채용 페이지 복리후생 포상 항목), 장기 근속 임직원에게 장기종업원급여를 제공 (2025 사업보고서 재무제표 주석 기타장기종업원급여 항목) — 근속 기준·포상 내용·금액 미기재', 80),
  (@comp_id, 'excellence_award', '분기별 우수 직원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '분기별 우수 직원 포상 (공식 채용 페이지 복리후생 포상 항목) — 선정 기준·포상 내용 미기재', 81),
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물 지급 (공식 채용 페이지 복리후생 기타 항목) — 선물 품목·금액 미기재', 82),
  -- ── 여가 · 행사 (leisure) — 복리후생 포상 · 사내 행사 · 기타 · 채용 사이트 ──
  (@comp_id, 'welcome_kit', '정직원 순금 배지', NULL, 'leisure',
   'est', NULL, TRUE, '정직원 순금 배지 지급 (공식 채용 페이지 복리후생 포상 항목) — 지급 시점·중량 미기재', 90),
  (@comp_id, 'club', '사내 동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 사내 동호회 활동 지원 (공식 채용 페이지 복리후생 사내 행사 항목) — 지원 금액·동호회 종류 미기재', 91),
  (@comp_id, 'company_event', '생일파티', NULL, 'leisure',
   'est', NULL, TRUE, '생일파티 진행 (공식 채용 페이지 복리후생 사내 행사 항목) — 진행 주기·방식 미기재', 92),
  (@comp_id, 'resort', '콘도·리조트 이용권', NULL, 'leisure',
   'est', NULL, TRUE, '콘도/리조트 이용권 지급 (공식 채용 페이지 복리후생 기타 항목), 콘도 숙박 지원 (회사 채용 사이트 복리후생 재충전을 위한 지원 항목) — 이용 횟수·지원 범위 미기재', 93)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
