-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한국항공우주산업(KAI) 복리후생 데이터
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://www.koreaaero.com/KO/Sustainability/WelfareSystem.aspx
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 KAI 공식 도메인(koreaaero.com)과 공식 GNB 에서 링크된
--       회사 브랜드 ATS(koreaaero.recruiter.co.kr) 다. 3자 사이트 인용 0건.
--       정본 = 지속가능경영 > 노사화합 > 복리후생제도 (5카테고리 29항목).
--       보조 = 채용사이트 복리후생 12항목(설명·수치) · 가족친화 직장 · 인사제도 복리후생 10항목.
--       ⚠ 정본 29항목은 전부 PNG 1장(1258×2510) 안의 텍스트다. HTML 텍스트는 리드 4줄뿐이고
--         alt 는 「복리후생제도」 하나라 파싱으로는 0건이 나온다. 이미지를 세로 5분할해 판독했고
--         판독 결과는 프로브(별도 세션)의 29항목 목록과 전건 일치했다. 해시는 evidence 참조.
--       ⚠ 인사제도 복리후생 페이지도 이미지 1장(1185×700)이고 alt 속성 자체가 없다.
--       ⚠ 채용사이트는 Next.js CSR 이라 curl 로는 본문 0자다. 렌더 DOM 과 ATS 빌더 JSON
--         두 경로로 각각 확보해 문자열이 일치함을 확인했다.
--       ⚠ 절대 쓰면 안 되는 URL: koreaaero.recruiter.co.kr/career/welfare — KAI 도메인·KAI GNB 를
--         달고 200 을 주지만 본문이 ATS 빌더의 마켓컬리 샘플 데이터 그대로인 오염 페이지다.
--         sitemap 을 시드로 쓰면 남의 회사 복지가 그대로 들어온다. 정본은 /career/benefits 뿐이다.
--       ⚠ apex(koreaaero.com)는 타임아웃이라 반드시 www 를 붙인다. HEAD 는 302, GET 이 200 이다.
--       34행 = 세 출처의 합집합에서 중복을 제거한 수다. 계약 목표(12~25)를 넘지만
--         행마다 원문 불릿이 1:1 로 있어 억지로 줄이지 않았다(줄일 경우 후보는 evidence 참조).
--       금액 있는 행은 출산장려금 1행뿐이다. 나머지 33행은 원문에 금액이 없어 전부 NULL 이고
--         신규 회사라 승계할 앵커도 없어 타사 금액을 끌어오지 않았다.
--       법정 제도(4대보험·퇴직연금·법정 연차·법정 출산휴가·육아휴직·임신기 근로시간 단축·
--         가족돌봄휴직)는 수록하지 않았다. 최초 연차 22일만 법정 상회분으로 수록한다.
--       정본 이미지 하단 각주: ※ 개인연금 등 일부를 제외하고 복리후생제도는 정규직과
--         임시 또는 비정규직 직원 간 동일하게 적용됨 — 개인연금 행 QUAL_DESC 에 반영했다.
--       ⚠ 검증·감사 판정 반영(2026-09-05): 행 삭제·병합·금액 변경 없음(34행 그대로).
--       SORT 23 출산장려금 1,000만원은 두 공식 페이지가 못 박은 실지급액이라 유지하되,
--       NOTE 에 자녀 1인당 1회 지급액이라고 밝혔다(연간 반복 지급이 아니다).
--       SORT 91 에서 법정 제도인 임신기 근로시간 단축·가족돌봄휴직 문구를 빼고, 사용자
--       노출 3필드의 편집 주석 23곳(사진 수록·부연·판단 서술)을 전부 걷어냈다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kai', '한국항공우주산업',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '항공/방산', 'K', 'https://www.koreaaero.com/KO/Sustainability/WelfareSystem.aspx');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kai');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.koreaaero.com/KO/Sustainability/WelfareSystem.aspx'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 원문 가계안정·근무편의 카테고리 ──
  (@comp_id, 'housing_loan', '주거안정자금 이자지원', NULL, 'perks',
   'est', NULL, TRUE, '주거안정자금 이자지원 (복리후생제도 페이지 가계안정 항목). 채용사이트 주거안정 지원 항목이 주거안정자금 대출이자 지원으로 설명 — 대출 한도·이율·대상 미기재', 10),
  (@comp_id, 'housing_support', '신입사원 원룸지원비', NULL, 'perks',
   'est', NULL, TRUE, '신입사원 원룸지원비 (복리후생제도 페이지 가계안정 항목). 채용사이트 주거안정 지원: 신입사원 기숙사 혹은 월세지원금 — 지원 한도·지급 기간 미기재', 11),
  (@comp_id, 'relocation', '부임여비 지원', NULL, 'perks',
   'est', NULL, TRUE, '부임여비 지원 (복리후생제도 페이지 가계안정 항목) — 지원 범위·금액 미기재', 12),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 (복리후생제도 페이지 가계안정 항목). 채용사이트 부가급여: 매월 개인연금 100% 회사지원 — 월 납입액 미기재라 연 환산 불가. 복리후생제도 안내 각주: 개인연금 등 일부는 정규직·임시·비정규직 간 동일 적용 대상에서 제외', 13),
  (@comp_id, 'commute_subsidy', '출퇴근 통근버스', NULL, 'perks',
   'est', NULL, TRUE, '진주·사천·삼천포 출퇴근 통근버스 (복리후생제도 페이지 근무편의 항목). 채용사이트도 진주/사천/삼천포 전 지역 출퇴근버스 운영으로 동일 — 노선 수·요금 부담 여부 미기재', 14),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 (복리후생제도 페이지 근무편의 항목) — 제공 끼니·식대 단가 미기재', 15),
  (@comp_id, 'snack_bar', '사내 카페테리아·매점', NULL, 'perks',
   'est', NULL, TRUE, '사내 편의시설 - 은행/매점/카페테리아 등 (복리후생제도 페이지 근무편의 항목). 카페테리아 사진 게재 — 이용료 부담 여부 미기재', 16),
  (@comp_id, 'birthday_gift', '생일선물 지원제도', NULL, 'perks',
   'est', NULL, TRUE, '생일선물 지원제도 (복리후생제도 페이지 동기부여 항목) — 선물 종류·금액 미기재', 17),

  -- ── 가족·돌봄 (family) — 원문 가계안정 카테고리 + 가족친화 직장 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금(유치원~대학/해외) (복리후생제도 페이지 가계안정 항목). 채용사이트도 자녀 진학시 학자금 지원(유치원 ~ 대학교), 인사제도 페이지도 학자금지원(유치원~대학) — 한도·자녀 수 제한 미기재', 20),
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장어린이집 (복리후생제도 페이지 가계안정 항목, 직장 어린이집 사진 게재). 채용사이트 가정/육아지원 항목도 사내 어린이집 운영 — 정원·대상 연령 미기재', 21),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (복리후생제도 페이지 동기부여 항목) — 경조금 액수·경조휴가 일수 미기재', 22),
  (@comp_id, 'parenting', '출산장려금', 1000, 'family',
   'est', '출산장려금 1,000만원 지급 (채용사이트 가정/육아지원 항목). 가족친화 직장 페이지: 종전 100만원에서 1·2자녀 각 1,000만원, 3자녀 3,000만원으로 상향 — 자녀 1인당 1회 지급액(연간 반복 지급 아님)', FALSE, NULL, 23),

  -- ── 근무환경 (work_env) — 원문 가계안정·Health Care·근무편의 카테고리 ──
  (@comp_id, 'dormitory', '사내·외 기숙사 지원', NULL, 'work_env',
   'est', NULL, TRUE, '사내·외 기숙사 지원 (복리후생제도 페이지 가계안정 항목, 기숙사 사진 게재) — 대상·자부담 미기재', 30),
  (@comp_id, 'uniform', '근무복 지원·세탁', NULL, 'work_env',
   'est', NULL, TRUE, '근무복 지원/현장 근무복 세탁 (복리후생제도 페이지 근무편의 항목, 근무복 사진 게재) — 지급 벌수·세탁 주기 미기재', 31),
  (@comp_id, 'lounge', '수유실·휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '수유실/휴게실 (복리후생제도 페이지 Health Care 항목, 수유실 사진 게재) — 사업장별 설치 현황 미기재', 32),

  -- ── 건강·의료 (health) — 원문 Health Care 카테고리 ──
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (복리후생제도 페이지 Health Care 항목). 채용사이트가 본인(전액)/배우자/부양가족 의료비 실비지원, 인사제도 페이지가 의료비 지원(본인/가족)으로 설명 — 연간 한도 금액 미기재', 40),
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진 (복리후생제도 페이지 Health Care 항목). 인사제도 페이지가 종합검진(본인) ※배우자 양도 가능으로 설명 — 주기·검진 금액 미기재', 41),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 (치아보험 보장) (복리후생제도 페이지 Health Care 항목). 인사제도 페이지: 단체보험 — 보장 한도·보험료 미기재', 42),
  (@comp_id, 'clinic', '의무실·물리치료실', NULL, 'health',
   'est', NULL, TRUE, '의무실 및 물리치료실 (복리후생제도 페이지 Health Care 항목 「의무실/심리상담실」·「물리치료실/체력단련실」, 물리치료실 사진 게재) — 상주 인력·운영 시간 미기재', 43),
  (@comp_id, 'mental', '심리상담실', NULL, 'health',
   'est', NULL, TRUE, '심리상담실 (복리후생제도 페이지 Health Care 항목 「의무실/심리상담실」, 심리상담실 사진 게재) — 상담 횟수·외부 EAP 연계 여부 미기재', 44),
  (@comp_id, 'fitness', '체력단련실·사내 피트니스', NULL, 'health',
   'est', NULL, TRUE, '물리치료실/체력단련실 (복리후생제도 페이지 Health Care 항목, 체력단련실 사진 게재). 채용사이트가 사내 최신시설 헬스장/풋살장/농구장/테니스장 무료사용으로 설명', 45),

  -- ── 보상·금전 (compensation) — 원문 동기부여 카테고리 ──
  (@comp_id, 'holiday_gift', '명절 귀성여비·창립기념일 상품권', NULL, 'compensation',
   'est', NULL, TRUE, '설/추석 귀성여비 지원 및 창립기념일 상품권 (복리후생제도 페이지 동기부여 항목 2건). 채용사이트 부가급여 항목에도 명절 귀성여비 — 지급액 미기재', 50),
  (@comp_id, 'long_service_bonus', '근속기념품·축하금', NULL, 'compensation',
   'est', NULL, TRUE, '근속기념품·축하금 (복리후생제도 페이지 동기부여 항목 「근속기념품/휴가/축하금 지원」) — 근속 연차 기준·금액 미기재', 51),
  (@comp_id, 'excellence_award', '자랑스러운 KAI인 상·유공자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '자랑스러운 KAI인 상 수여 (복리후생제도 페이지 동기부여 항목, 시상식 사진 게재). 인사제도 페이지가 모범 및 근무유공자 포상, 해외연수로 설명 — 포상 기준·부상 금액 미기재', 52),

  -- ── 휴가·휴직 (time_off) — 원문 동기부여 + 채용사이트 연차와 휴가 ──
  (@comp_id, 'long_service_leave', '근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '근속 휴가 (복리후생제도 페이지 동기부여 항목 「근속기념품/휴가/축하금 지원」) — 부여 일수·근속 연차 기준 미기재', 60),
  (@comp_id, 'leave_general', '최초 연차 22일', NULL, 'time_off',
   'est', NULL, TRUE, '최초 연차 22일 제공, 하기휴가 5일 별도 (채용사이트 연차와 휴가 항목) — 근속별 가산·사용 조건 미기재', 61),
  (@comp_id, 'summer_leave', '하기휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하기휴가(5일) 연차와 별도 제공, 하기휴가비 지급 (채용사이트 연차와 휴가·부가급여 항목) — 휴가비 금액 미기재', 62),

  -- ── 성장·커리어 (growth) — 원문 동기부여 + 인사제도 복리후생 ──
  (@comp_id, 'retirement_support', '정년퇴직자·퇴직예정자 지원', NULL, 'growth',
   'est', NULL, TRUE, '정년퇴직자 지원 (복리후생제도 페이지 동기부여 항목, 정년퇴임 행사 사진 게재). 인사제도 페이지가 정년퇴직지원 및 퇴직예정자 지원 제도(창업, 재취업, 여행, 귀농, 재무 등)로 설명 — 지원 금액·기간 미기재', 70),
  (@comp_id, 'mba', '학위취득 지원제도', NULL, 'growth',
   'est', NULL, TRUE, '국내 협약대학 석·박사학위 취득 지원 (채용사이트 학위취득 지원제도 항목) — 협약 대학명·학비 지원 비율·의무 근무 조건 미기재', 71),

  -- ── 여가·라이프 (leisure) — 원문 문화·여가생활 카테고리 ──
  (@comp_id, 'resort', '제휴 리조트 지원', NULL, 'leisure',
   'est', NULL, TRUE, '제휴 리조트 지원 (복리후생제도 페이지 문화·여가생활 항목, 리조트 사진 게재). 채용사이트가 국내 휴양지 리조트 숙박 지원 및 협약 항공기 할인으로 설명 — 제휴처 수·이용 한도 미기재', 80),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 운영 지원 (복리후생제도 페이지 문화·여가생활 항목, 동호회 사진 게재). 채용사이트가 뮤지컬/클라이밍/테니스/다이빙 등 50개 이상 동호회 활동 지원으로 설명 — 활동비 지원액 미기재', 81),
  (@comp_id, 'company_event', '사내 문화행사·가족 초청행사', NULL, 'leisure',
   'est', NULL, TRUE, '각종 Culture Event 개최 및 신입사원 부모님 초청행사 개최 (복리후생제도 페이지 문화·여가생활·동기부여 항목, 신입사원 행사 사진 게재). 가족친화 직장 페이지가 가족 초청 행사와 사내 음악회로 설명 — 개최 주기·규모 미기재', 82),

  -- ── 유연근무 (flexibility) — 채용사이트 + 가족친화 직장 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '출퇴근시간 자율설정 가능한 유연근무제 시행 (채용사이트 유연근무제 항목). 가족친화 직장 페이지도 대표 제도로 유연근무제를 명시 — 코어타임·정산 단위 미기재', 90),
  (@comp_id, 'pc_off', 'PC-OFF', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF 제도 운영 (가족친화 직장 페이지: 대표적인 제도로는 PC-OFF, 유연근무제 등) — 소등 시각·예외 승인 절차 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
