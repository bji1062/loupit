-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한화생명 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://company.hanwhalife.com/ko/recruitment/welfare
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 한화생명 회사소개 서브도메인(company.hanwhalife.com) 채용 > 복리후생 페이지.
--       푸터가 「한화생명보험 주식회사 / 사업자등록번호 116-81-11757」 — 상장 법인 자신의 페이지다.
--       ⚠ 고객 포털 www.hanwhalife.com 에는 채용·복지 메뉴가 아예 없다. 그쪽 /main/benefit/ 경로는
--          보험 「고객」 혜택이라 경로 키워드로 긁으면 임직원 복지가 아닌 것이 섞인다.
--          시작 URL 을 company. 서브도메인으로 고정할 것(www 는 OpenSSL 3 기본값에서 TLS 실패도 난다).
--       Next.js SSR — 복지 5블록이 최초 HTML 에 완성 마크업으로 들어 있다.
--          셀렉터 p.welfare-num + strong + span, curl 로 충분하고 헤드리스 불필요.
--       페이지 구조: 카테고리 5개(카페테리아 플랜·건강문화지원·생활안정지원·주거안정지원·모성보호지원)
--          아래 쉼표로 나열된 세부 항목 18개. 항목별 설명 문장이 없고 라벨뿐이다(심텍과 같은 유형).
--       18항목 → 15행. 법정 제도 2건 제외: 4대보험(생활안정지원) · 출산 & 육아휴가 제도(모성보호지원).
--          후자는 「본인 및 배우자」라고만 적고 법정 상회 조건(기간 연장·급여 보전)을 밝히지 않는다.
--          유치원교육비 지원 + 학자금 지원은 둘 다 child_edu 로 귀결돼 1행 병합(코드는 회사당 UNIQUE).
--       ⚠ 05 블록 원문의 「맘s 패키지」는 실제로 맘 뒤에 아포스트로피가 붙은 표기다.
--          시드 분할기(db/seed/load.py)가 ASCII 따옴표를 문자열 경계로 보므로 부호를 뺐다.
--       금액: 페이지 전체에 숫자가 0개다(01 이 「매년 일정금액」이라고만 적는다) →
--          15행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE. 신규 회사라 앵커도 없어 추정 금액을 넣지 않았다.
--       ⚠ 한화생명금융서비스(hanwhalifefs.com)는 2021년 분리된 별개 법인이다. 그 사이트의 FP 위촉직
--          처우를 여기 섞으면 안 된다. 그룹 통합 채용 hanwhain.com 의 한화생명 계열사 상세는 복지 0건.
--       ⚠ 검증·감사 판정 반영(2026-09-05): 사택지원을 housing_support(perks)에서
--       dormitory(work_env)로 재코딩하고 카테고리 10단위 섹션 규칙대로 SORT 15 →
--       50 으로 옮겼다(행 수 15 그대로). 사택·기숙사는 회사가 제공하는 주거 시설이고
--       housing_support 는 코퍼스에서 임차비·주거비 현금 축이다 — 대한항공 「사택 지원」
--       이 같은 선례다. SORT 33 은 원문 표기 「맘’s」를 U+2019 로 살렸다(분할기 안전).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanwha_life', '한화생명',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '보험', 'H', 'https://company.hanwhalife.com/ko/recruitment/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha_life');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://company.hanwhalife.com/ko/recruitment/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 원문 01 카페테리아 플랜 / 03 생활안정지원 / 04 주거안정지원 ──
  (@comp_id, 'welfare_point', '카페테리아 플랜', NULL, 'perks',
   'est', NULL, TRUE, '매년 일정금액 지급된 포인트를 체력단련·건강관리·자기계발·문화생활 등 임직원 니즈에 따라 자율 사용 (공식 복리후생 페이지 01 블록 — 연간 포인트 금액 미기재, 원문은 매년 일정금액 이라고만 적는다)', 10),
  (@comp_id, 'pension_support', '개인연금보험', NULL, 'perks',
   'est', NULL, TRUE, '개인연금보험 (공식 복리후생 페이지 생활안정지원 항목명 그대로 — 회사 부담률·납입 한도·가입 조건 미기재)', 11),
  (@comp_id, 'meal', '중식비', NULL, 'perks',
   'est', NULL, TRUE, '중식비 (공식 복리후생 페이지 생활안정지원 항목명 그대로 — 점심 한 끼 대상임은 명시, 지원 단가·구내식당 운영 여부 미기재)', 12),
  (@comp_id, 'transport', '교통보조비', NULL, 'perks',
   'est', NULL, TRUE, '교통보조비 지급 (공식 복리후생 페이지 생활안정지원 항목명 그대로 — 지급액·지급 주기·대상 미기재)', 13),
  (@comp_id, 'housing_loan', '주거안정 대출지원', NULL, 'perks',
   'est', NULL, TRUE, '대출지원 (공식 복리후생 페이지 주거안정지원 블록 항목명 그대로 — 주택자금 용도라고 못박지는 않았고 한도·이율·상환 조건 미기재)', 14),

  -- ── 건강·의료 (health) — 원문 02 건강문화지원 / 03 생활안정지원 ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '건강검진 (공식 복리후생 페이지 건강문화지원 항목명 그대로 — 주기·대상·검진 범위·가족 포함 여부 미기재)', 20),
  (@comp_id, 'fitness', '체력증진', NULL, 'health',
   'est', NULL, TRUE, '체력증진 (공식 복리후생 페이지 건강문화지원 항목명 그대로 — 사내 시설 운영인지 비용 지원인지 미기재)', 21),
  (@comp_id, 'insurance', '단체생명보험', NULL, 'health',
   'est', NULL, TRUE, '단체생명보험 (공식 복리후생 페이지 생활안정지원 항목명 그대로 — 보장 범위·보험료 부담 주체·가족 포함 여부 미기재)', 22),

  -- ── 가족·돌봄 (family) — 원문 02 건강문화지원 / 03 생활안정지원 / 05 모성보호지원 ──
  (@comp_id, 'child_edu', '유치원교육비·학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '유치원교육비 지원, 학자금 지원 (공식 복리후생 페이지 건강문화지원 항목 — 학자금의 본인·자녀 대상 구분과 학교급·한도 미기재)', 30),
  (@comp_id, 'event', '경조 지원', NULL, 'family',
   'est', NULL, TRUE, '경조 (공식 복리후생 페이지 생활안정지원 항목명 그대로 — 경조금·경조휴가 구분과 금액·대상 범위 미기재)', 31),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 (공식 복리후생 페이지 모성보호지원 항목명 그대로 — 설치 사업장·정원·대상 연령 미기재)', 32),
  (@comp_id, 'parenting', '모성보호 Cafe·임신직원 패키지', NULL, 'family',
   'est', NULL, TRUE, '모성보호 Cafe 운영 및 임신직원 맘’s 패키지 제공 (공식 복리후생 페이지 모성보호지원 항목명 그대로 — 시설 위치·패키지 구성·지급 시점 미기재)', 33),

  -- ── 여가·라이프 (leisure) — 원문 02 건강문화지원 ──
  (@comp_id, 'resort', '휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '휴양소 운영 (공식 복리후생 페이지 건강문화지원 항목명 그대로 — 시설 위치·이용 조건·성수기 배정 방식 미기재)', 40),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 지원 (공식 복리후생 페이지 건강문화지원 항목명 그대로 — 지원 금액·운영 동호회 수 미기재)', 41),

  -- ── 근무환경 (work_env) — 원문 03 생활안정지원 ──
  (@comp_id, 'dormitory', '사택지원', NULL, 'work_env',
   'est', NULL, TRUE, '사택지원 — 회사 사정에 따라 비 연고 근무시 (공식 복리후생 페이지 주거안정지원 항목명·괄호 조건 그대로. 사택 규모·본인 부담금·지원 기간 미기재)', 50)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
