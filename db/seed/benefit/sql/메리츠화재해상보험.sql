-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 메리츠화재 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://recruit.meritzfire.com/new/company/company02.do
-- badge: est
--
-- 참고:
--   정본은 비상장 법인 메리츠화재해상보험(주)의 자기 도메인 채용 사이트 recruit.meritzfire.com Company > 복리후생 페이지다.
--   SSR 이라 원본 HTML 에 6블록(Work-Life Balance · Family Welfare · Healthcare Benefits · Life after Work ·
--   Financial Benefits · Personal Development) 항목 이름과 설명이 다 있다. 헤드리스 렌더 · 이미지 판독 불필요.
--   보조 출처는 같은 채용 사이트 Culture > 기업문화 페이지(탄력근무제 · PC-OFF · 승인 없는 휴가 사용 · 안식월)와
--   OpenDART 2026 반기보고서(접수 20260814002253) · 2025 사업보고서(접수 20260331003916) 직원 등 현황 유연근무제도 사용 현황 표.
--   귀속: 페이지 주어가 메리츠화재 단수이고 계열사 · 그룹 공통 단서가 없다. 꼬리말 사업자 등록번호 116-81-03752 는 이 법인.
--   기등록 메리츠 계열 형제 없음. 지주(메리츠금융지주) 발행 지속가능경영보고서는 이 법인 출처로 쓰지 않았다. 각주 없음.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL.
--   제외: 자격수당(급여성 수당) · 편한 옷(자율복장 — 대응 코드 없음) · 공시 육아휴직 · 배우자 출산휴가 사용자 수(법정) ·
--     원격근무제 사용자 수(세 기간 모두 - · 활용 여부 주석에 시차출퇴근제 · 선택근무제만 활용) · 임원 보수 칸 ·
--     이사회 장기근속보상 부여의 건(대상 미기재) · 인터뷰 페이지.
--   공고 근거 0행 / 전체 19행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(flexibility 10 · time_off 20 · family 30 · health 40 · perks 50 · leisure 60 · growth 70).
-- 검증 · 감사 판정 반영(2026-10-23): 안식월 휴가와 장기근속 포상을 원문 항목대로 분리(휴가 몫 long_service_leave · 기념품 여행경비 long_service_bonus 보상 섹션 신설) · 성장 섹션 SORT 를 80 · 81 로 재번호 · 귀성여비와 현장 교통비 이름에 대상 · 항목 페이지 예외 2(통합 밖 리드 집행) · 참고 블록의 SORT 섹션 순서와 전체 19행은 이 판정으로 뒤집힘(compensation 70 · growth 80 · 20행) — 최종 20행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('meritz_fire', '메리츠화재',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '보험', 'M', 'https://recruit.meritzfire.com/new/company/company02.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'meritz_fire');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.meritzfire.com/new/company/company02.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 채용 사이트 복리후생 Work-Life Balance · 기업문화 · 2026 반기보고서 ──
  (@comp_id, 'pc_off', 'PC-OFF', NULL, 'flexibility',
   'est', NULL, TRUE, '업무시간의 집중도는 높이고 개인시간을 충분히 활용할 수 있도록 출근시간 전, 퇴근시간 후에는 업무용 PC 사용 불가 (공식 채용 사이트 복리후생 PC-OFF 항목), 특별한 일이 없으면 정시 퇴근(PC-OFF) (공식 채용 사이트 기업문화 페이지 항목)', 10),
  (@comp_id, 'flex_work', '시차출퇴근제 · 선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '1일 8시간 근무는 준수하되 개인업무 일정에 따라 평일 오전 7시부터 오후 8시 사이에 출근과 퇴근, 초과근무를 하게 되면 그 시간만큼 다른 날의 근무시간에서 차감하여 1개월 범위 내에서 근로시간 조정 (공식 채용 사이트 복리후생 시차출퇴근제, 선택적 근로시간제 항목), 탄력근무제 시행으로 유연하게 출퇴근 (공식 채용 사이트 기업문화 페이지 항목), 시차출퇴근제 사용자 611명 · 선택근무제 사용자 1,745명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목)', 11),

  -- ── 휴가 (time_off) — 채용 사이트 복리후생 Work-Life Balance · Financial Benefits · 기업문화 ──
  (@comp_id, 'long_service_leave', '안식월 휴가 · 장기근속 포상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '근속 5년마다 보유 휴가를 사용하여 3주 이상 휴식할 수 있는 여건을 보장하고 보유 휴가가 부족할 경우 별도의 휴가 추가 지원 (공식 채용 사이트 복리후생 안식월 휴가 항목), 5년마다 Refresh 할 수 있는 안식월 제도 운영 (공식 채용 사이트 기업문화 페이지 항목), 장기근속 포상으로 포상휴가 지원 (공식 채용 사이트 복리후생 장기근속 포상 항목) — 추가 휴가 일수·포상휴가 근속 기준 미기재', 20),
  (@comp_id, 'leave_general', '승인 없는 자율 휴가 사용', NULL, 'time_off',
   'est', NULL, TRUE, '누구나 승인 없이 자유롭게 휴가 사용 (공식 채용 사이트 기업문화 페이지 항목) — 휴가 종류·사용 절차 미기재', 21),

  -- ── 가족 (family) — 채용 사이트 복리후생 Family Welfare ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼, 출산, 회갑, 칠순, 장례 등 경조사 발생 시 경조금, 경조휴가, 장례용품, 경조화환 지원 (공식 채용 사이트 복리후생 경조사 지원 항목) — 경조금 금액·경조휴가 일수 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '고등학교, 대학교 등록금 전액 지원, 자녀수 제한없이 유치원 비용 지원 (공식 채용 사이트 복리후생 자녀 학자금 지원 항목) — 유치원 비용 지원 범위 미기재', 31),
  (@comp_id, 'childcare', '직장어린이집 운영', NULL, 'family',
   'est', NULL, TRUE, '직원들이 자녀를 안심하고 맡길 수 있는 안전한 시설과 전문 선생님이 있는 직장어린이집 운영 (공식 채용 사이트 복리후생 직장어린이집 운영 항목) — 어린이집 위치·정원 미기재', 32),

  -- ── 건강 (health) — 채용 사이트 복리후생 Healthcare Benefits ──
  (@comp_id, 'health_check', '건강검진 · 검진휴가', NULL, 'health',
   'est', NULL, TRUE, '직원과 가족들이 건강을 관리하고 질병을 예방할 수 있도록 매년 건강검진과 검진휴가(유급) 지원, 본인 및 배우자 무료 · 그 외 가족 직원 할인가 적용 (공식 채용 사이트 복리후생 건강검진 항목) — 검진 항목·검진휴가 일수 미기재', 40),
  (@comp_id, 'medical', '치과 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '직원 본인과 배우자가 사용한 치과 진료비 매년 지원 (공식 채용 사이트 복리후생 치과 의료비 지원 항목) — 지원 한도·지원 비율 미기재', 41),
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '직원과 가족(부모, 자녀)에게 실손의료비, 입·통원 의료비, 진단비, 치료비, 후유장해, 질병·상해 사망 등을 보장하고 유병력자도 가입이 가능한 상품 제공 (공식 채용 사이트 복리후생 단체 상해보험 항목) — 보장 금액·회사 부담 범위 미기재', 42),

  -- ── 생활 · 금융 (perks) — 채용 사이트 복리후생 Life after Work · Financial Benefits ──
  (@comp_id, 'welfare_point', '선택적 복지포인트 제도', NULL, 'perks',
   'est', NULL, TRUE, '자기 계발, 문화 생활 등 여가를 즐길 수 있도록 현금처럼 사용할 수 있는 복지포인트 지원 (공식 채용 사이트 복리후생 선택적 복지포인트 제도 항목) — 포인트 금액·배정 기준 미기재', 50),
  (@comp_id, 'pension_support', '개인연금 · 저축장려금 지원', NULL, 'perks',
   'est', NULL, TRUE, '노후 자금 확보를 돕기 위해 연금저축보험에 가입하고 매월 보험료 지원, 자산 증식을 돕기 위해 매월 주식(메리츠금융지주) 또는 펀드 매수 비용 지원 (공식 채용 사이트 복리후생 개인연금, 저축장려금 지원 항목) — 월 지원 금액·회사 부담 비율 미기재', 51),
  (@comp_id, 'welfare_fund_loan', '사내근로복지기금 생활안정자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '직원들의 안정적인 생활을 위해 생활안정자금 대출 지원 (공식 채용 사이트 복리후생 사내근로복지기금 운영 항목) — 대출 한도·이율 미기재', 52),
  (@comp_id, 'relocation', '사택임차보증금 및 월세 지원 (비연고지 발령)', NULL, 'perks',
   'est', NULL, TRUE, '비연고지 발령으로 거주지 출퇴근이 어려운 경우 해당 지역에 정착할 수 있도록 이사비용 지원, 매월 주거비용(월세) 지원 (공식 채용 사이트 복리후생 사택임차보증금 및 월세 지원 항목) — 임차보증금 지원 방식·월세 지원 금액 미기재', 53),
  (@comp_id, 'transport', '귀성여비 (비연고지 발령) · 현장 직원 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '비연고지 발령으로 가족과 떨어져 근무 중인 직원에게 주말 왕복 교통비 매월 실비 지원 (공식 채용 사이트 복리후생 귀성여비 지원 항목), 영업, 보상 등 현장에서 활동하는 직원에게 유류대, 주차비, 통행료 등 실비 지원 (공식 채용 사이트 복리후생 교통비 지원 항목) — 지원 한도 미기재', 54),

  -- ── 여가 (leisure) — 채용 사이트 복리후생 Life after Work ──
  (@comp_id, 'resort', '콘도 · 리조트 운영', NULL, 'leisure',
   'est', NULL, TRUE, '전국 유명 관광지에 있는 콘도·리조트를 연중 상시 사용할 수 있도록 지원 (공식 채용 사이트 복리후생 콘도/리조트 운영 항목) — 이용 횟수·비용 부담 미기재', 60),
  (@comp_id, 'club', '사내동호회 운영', NULL, 'leisure',
   'est', NULL, TRUE, '스포츠나 취미 활동을 함께 할 수 있는 다양한 동호회 운영 지원 (공식 채용 사이트 복리후생 사내동호회 운영 항목) — 지원 금액 미기재', 61),
  -- ── 보상 (compensation) — 채용 사이트 복리후생 Financial Benefits ──
  (@comp_id, 'long_service_bonus', '장기근속 포상 (기념품 · 여행경비)', NULL, 'compensation',
   'est', NULL, TRUE, '메리츠화재의 발전과 성장에 기여한 직원들의 노고에 감사함을 전하고자 기념품, 여행경비 지원 (공식 채용 사이트 복리후생 장기근속 포상 항목) — 포상 근속 기준·여행경비 금액 미기재', 70),

  -- ── 성장 · 교육 (growth) — 채용 사이트 복리후생 Personal Development ──
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격증 취득 시 축하수당 지급, 자격증 취득을 돕고자 교육비, 응시료, 교재비 등 취득 관련 비용 지원 (공식 채용 사이트 복리후생 자격증 취득 지원 항목) — 대상 자격증·축하수당 금액 미기재', 80),
  (@comp_id, 'edu_support', '교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무와 연관된 온·오프라인 교육 수강 비용 지원 (공식 채용 사이트 복리후생 교육비 지원 항목) — 지원 한도 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
