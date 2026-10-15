-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HJ중공업 복리후생 데이터 (신규 회사 — 웨이브 6)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://career.hjsc.co.kr/
-- badge: est
--
-- 참고:
--   정본은 HJ중공업 자기 채용 서브도메인 career.hjsc.co.kr 홈(자체 제작 단일 페이지, 벤더 ATS 아님)의
--   복리후생 섹션(GNB 인사 정보 > 복리후생 = #welfare 앵커)이다. 주어 HJ중공업, 4구분 18항목
--   (Family Support 6 · Health and Safety 4 · Leave and Time Off 4 · Work and Life Balance 4).
--   SSR HTML 텍스트(wf-item-title / wf-item-desc 18쌍, 기본 표시되는 homePage 안) — 렌더 · 이미지 판독 없음.
--   같은 페이지 인사제도 > 보상제도 표의 성과격려금 1행도 이 페이지가 근거다.
--   보조 출처는 같은 법인이 자기 도메인(www.hjsc.co.kr/images/sustainable/ — robots 허용 경로)에 올린
--   2025 HJSC 지속가능경영보고서 국문 PDF(116쪽, 2025년 11월 발행, 보고 기간 2024-01-01~12-31,
--   목록 esg/01.asp 의 최신 판) 57쪽 근로자 및 근로자 가족 지원제도(4구분 26불릿).
--   GRI 인덱스 106쪽이 401-2 정규직 복리후생을 57쪽으로 가리킨다.
--   보고서에만 있는 항목(개인연금 · 사내대출 · 의료비 · 가족 의료비 · 의무실 · 금연클리닉 · 사내식당 ·
--   통근버스 · 근무복 · 간식)은 최신 판 보고서라 싣는다(수집 계약 0-1 9 · 리드 판정 98).
--   같은 57쪽 가족친화 인증기업 선정 문단의 유연근무제 운영은 flex_work 1행으로 세웠다(리드 판정 101).
--   원문은 프로브 사본(2026-10-14 04:56~04:57 UTC)을 그대로 썼다.
--   귀속: 채용 페이지 제목 · 푸터 · 복리후생 부제 · 보고서 57쪽 주어가 모두 HJ중공업 단독이고
--   그룹 · 계열사 문구가 없다 — 각주 없음. 코퍼스에 형제 법인 0.
--   금액: 두 출처 모두 임직원 복지 원 단위 금액 0건 — 25행 전부 BENEFIT_AMT NULL(stated 0 · 추정 0).
--   사내식당은 끼니가 적혀 있지 않아 식대 금액을 세우지 않았다.
--   제외: 법정(출산 전후 휴가 · 배우자 출산휴가 · 육아휴직 · 육아기 근로시간 단축 · 가족돌봄 근로시간 단축 —
--   상회분 기재 없음) · 업무 교육(55쪽 직무교육 · 신입 · 경력 입문 · 기술자 위탁 교육) · 급여성 수당
--   (보상제도 표 임의제수당) · 법정제수당 · 57쪽 가족친화기업 인증 문구(유연근무제 운영 구절은 행) · 72쪽 퇴직자 재취업 알선
--   (지역 상생 사업) · 78쪽 우리사주 지분율 한 칸.
--   분리: 자녀 학자금 · 입학축하금 → child_edu + parenting · 건강검진 · 결혼기념일 휴가 → health_check
--   (검진 휴가) + leave_general(결혼기념일 휴가) · 사내식당 / 통근버스 → meal + commute_subsidy ·
--   개인연금 / 단체상해보험 → pension_support + insurance.
--   공고 근거 0행 / 전체 25행.
--   SORT 섹션 순서 = 정본 #welfare 섹션에서 카테고리가 처음 나온 순서
--   (family 10 · compensation 20 · perks 30 · health 40 · growth 50 · time_off 60 · leisure 70),
--   보고서에만 있는 카테고리는 끝(work_env 80 · flexibility 90). 보상제도 성과격려금은 compensation 섹션 끝.
-- 검증 · 감사 판정 반영(2026-10-14): 유연근무제 서술의 출처 메모 걷기 — 최종 25행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hj_heavy', 'HJ중공업',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '조선', 'H', 'https://career.hjsc.co.kr/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hj_heavy');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://career.hjsc.co.kr/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — 공식 채용 페이지 복리후생 · 2025 지속가능경영보고서 57쪽 ──
  (@comp_id, 'child_edu', '자녀 학자금 (유치원~대학교)', NULL, 'family',
   'est', NULL, TRUE, '유치원~대학교 학자금 지원 (공식 채용 페이지 복리후생 자녀 학자금·입학축하금 항목), 자녀 학자금 지원 · 자녀 고교학자금 · 자녀 대학학자금 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 가족복지제도·생활 안정 지원 항목) — 지원 금액·한도·대상 자녀 수 미기재', 10),
  (@comp_id, 'parenting', '자녀 입학축하금', NULL, 'family',
   'est', NULL, TRUE, '유치원·초·중·고 입학 시 축하금 지급 (공식 채용 페이지 복리후생 자녀 학자금·입학축하금 항목) — 축하금 금액 미기재', 11),
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사에 경조금 및 경조휴가 지원 (공식 채용 페이지 복리후생 경조사 지원 항목), 경조금 및 경조 휴가 · 경조사 지원 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 가족복지제도·기타 복지 지원 항목) — 경조 유형별 금액·휴가 일수 미기재', 12),
  -- ── 보상 (compensation) — 공식 채용 페이지 복리후생 · 보상제도 · 2025 지속가능경영보고서 57쪽 ──
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '설날·추석 명절 선물 현물 지급 (공식 채용 페이지 복리후생 명절 선물 항목) — 선물 품목·금액 미기재', 20),
  (@comp_id, 'long_service_bonus', '장기근속 포상 (금메달·여행권)', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 금메달 및 여행권 지급 (공식 채용 페이지 복리후생 장기근속 포상 항목), 장기근속 포상 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 기타 복지 지원 항목) — 근속 기준 연수·여행권 금액 미기재', 21),
  (@comp_id, 'profit_sharing', '성과격려금', NULL, 'compensation',
   'est', NULL, TRUE, '전사 목표 달성 시 등 임직원의 동기부여를 위한 특별 상여 지급 (공식 채용 페이지 인사제도 보상제도 성과격려금 항목) — 지급 기준·지급률·지급 시기 미기재', 22),
  -- ── 경제적 부가혜택 (perks) — 공식 채용 페이지 복리후생 · 2025 지속가능경영보고서 57쪽 ──
  (@comp_id, 'relocation', '전입여비·이사/이동비용 지원', NULL, 'perks',
   'est', NULL, TRUE, '인사발령 등으로 인한 거주지 이동 시 전입여비 지원 (공식 채용 페이지 복리후생 전입여비 지원 항목), 현장 근무 시 이동·가족이사 비용 지원 (이사/이동비용 지원 항목), 이사비 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 생활 안정 지원 항목) — 지원 금액·한도 미기재', 30),
  (@comp_id, 'birthday_gift', '생일 축하금', NULL, 'perks',
   'est', NULL, TRUE, '임직원 생일을 축하하는 소정의 축하금 지급 (공식 채용 페이지 복리후생 생일 축하금 항목) — 축하금 금액 미기재', 31),
  (@comp_id, 'snack_bar', '생수·간식 지원', NULL, 'perks',
   'est', NULL, TRUE, '생수 지원 제주퓨어워터 자택 배송 (공식 채용 페이지 복리후생 생수 지원 항목), 간식 지원 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 기타 복지 지원 항목) — 배송 주기·수량, 간식 제공 방식 미기재', 32),
  (@comp_id, 'transport', '출퇴근 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 교통비 지원 (공식 채용 페이지 복리후생 출퇴근 교통비 지원 항목) — 지원 금액·지급 방식 미기재', 33),
  (@comp_id, 'pension_support', '개인연금', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 생활 안정 지원 항목) — 회사 부담 여부·지원 금액 미기재', 34),
  (@comp_id, 'welfare_fund_loan', '사내대출', NULL, 'perks',
   'est', NULL, TRUE, '사내대출 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 생활 안정 지원 항목) — 대출 용도·한도·이율 미기재', 35),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 운영 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 기타 복지 지원 항목) — 운영 사업장·제공 끼니·식대 부담 미기재', 36),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운영 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 기타 복지 지원 항목) — 운행 사업장·노선 미기재', 37),
  -- ── 건강 (health) — 공식 채용 페이지 복리후생 · 2025 지속가능경영보고서 57쪽 ──
  (@comp_id, 'health_check', '종합 건강검진 (배우자 포함)·검진 휴가', NULL, 'health',
   'est', NULL, TRUE, '건강검진 지원 전 임직원 대상 (배우자 포함) 연 1회 (공식 채용 페이지 복리후생 건강검진 지원 항목), 건강검진 시 별도 휴가 제공 (건강검진·결혼기념일 휴가 항목), 종합 건강검진 · 배우자 건강검진 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 건강관리 지원 항목) — 검진 항목·지원 금액·휴가 일수 미기재', 40),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '임직원 단체상해보험 가입 (공식 채용 페이지 복리후생 단체상해보험 항목), 단체상해보험 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 생활 안정 지원 항목) — 보장 범위·회사 부담 비율 미기재', 41),
  (@comp_id, 'medical', '의료비·가족 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 · 가족 의료비 지원 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 건강관리 지원 항목) — 지원 한도·대상 가족 범위 미기재', 42),
  (@comp_id, 'clinic', '사내 의무실', NULL, 'health',
   'est', NULL, TRUE, '사내 의무실 운영 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 건강관리 지원 항목) — 설치 사업장·진료 범위 미기재', 43),
  (@comp_id, 'smoking_cessation', '금연클리닉', NULL, 'health',
   'est', NULL, TRUE, '금연클리닉 운영 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 건강관리 지원 항목) — 프로그램 내용·운영 사업장 미기재', 44),
  -- ── 성장 (growth) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'self_development', '기술사 자격증 취득비 지원', NULL, 'growth',
   'est', NULL, TRUE, '기술사 자격증 취득비 지원 (공식 채용 페이지 복리후생 자격증 취득 지원 항목) — 지원 금액·한도·대상 종목 미기재', 50),
  -- ── 휴가 (time_off) — 공식 채용 페이지 복리후생 · 2025 지속가능경영보고서 57쪽 ──
  (@comp_id, 'leave_general', '결혼기념일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '결혼기념일 별도 휴가 제공 (공식 채용 페이지 복리후생 건강검진·결혼기념일 휴가 항목), 결혼기념일 휴가 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 가족복지제도 항목) — 휴가 일수·유급 여부 미기재', 60),
  -- ── 여가 (leisure) — 공식 채용 페이지 복리후생 · 2025 지속가능경영보고서 57쪽 ──
  (@comp_id, 'resort', '휴양소 지원 (콘도·호텔)', NULL, 'leisure',
   'est', NULL, TRUE, '제휴 휴양소 무료 이용 (공식 채용 페이지 복리후생 휴양소 지원 항목), 휴양소(콘도, 호텔) 지원 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 가족복지제도 항목) — 이용 횟수·제휴 시설 목록 미기재', 70),
  (@comp_id, 'club', '사내 동호회 활동비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '스포츠·취미 등 사내 동호회 활동비 지원 (공식 채용 페이지 복리후생 사내 동호회 지원 항목), 사내동호회 지원 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 기타 복지 지원 항목) — 활동비 금액·지원 한도 미기재', 71),
  -- ── 근무 환경 (work_env) — 2025 지속가능경영보고서 57쪽 ──
  (@comp_id, 'uniform', '근무복 지원', NULL, 'work_env',
   'est', NULL, TRUE, '근무복 지원 (2025 지속가능경영보고서 57쪽 근로자 및 근로자 가족 지원제도 기타 복지 지원 항목) — 지급 대상·지급 주기 미기재', 80),
  -- ── 근무 유연성 (flexibility) — 2025 지속가능경영보고서 57쪽 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 운영 (2025 지속가능경영보고서 57쪽 가족친화 인증기업 선정 본문) — 제도 유형·대상 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
