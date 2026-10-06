-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 에코프로 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.ecopro.co.kr/sub0502
-- badge: est
--
-- 참고:
--   정본은 주식회사 에코프로(지주) 자기 도메인 ecopro.co.kr 의 회사소개 → 기업개요 → 복리후생 페이지다
--   (금전적 지원 3 · 생활안정 지원 4 · 기타 지원 4 · 여가활동 지원 4 · 건강증진 지원 4 항목).
--   서버 렌더 HTML 에 항목 본문이 그대로 있다 — 헤드리스 렌더 없음. 꼬리말 주식회사 에코프로(우편번호 28116).
--   귀속: 지주 자신의 페이지만 썼다. 자회사 에코프로비엠 자기 도메인(ecoprobm.com/sub0107)에 같은 틀의 복리후생 목록이 있으나
--     그 페이지 문장은 옮기지 않았다 — 두 페이지가 갈리는 한 줄(지주 사택 또는 주거지원금 · 비엠 사택 또는 정착지원금)은 지주 문장을 따랐다.
--   그룹 공통 채용 사이트(ecoprorecruit.co.kr 복지제도)의 항목(어린이집 · 기념일 축하 · 건강증진 프로그램 · 상담 서비스)은
--     지주 적용을 밝히지 않아 싣지 않았다. 공동복지기금사업단 항목은 지주 도메인 뉴스 2022-08-04(전 가족사 직원 대상 출범 기사)와 함께 복지포인트 행(SORT 23 · 그룹 공통)으로 세웠다.
--   직원 수 185명(OpenDART 2025) — 1,000인 미만. 원문에 재취업지원 문구 없음.
--   법정 제외: 연차 휴가 항목. 퇴직금 누진제도는 2026-10-04 새 코드 severance_plus 로 실었다. 사우회 운영은 내용 미기재라 싣지 않았다.
--   금액: 원문 금액 없음(평가급 최대 월 20만원은 한도라 금액 칸에 넣지 않음). 구본 추정 승계 3(health_check 100 · resort 50 · meal 288 —
--     전부 틀 값, NOTE 끝에 추정 표기).
--   재코딩: long_service_leave → long_service_bonus (원문은 휴가가 아니라 포상) · relocation → housing_support (원문 사택 또는 주거지원금).
--   구본 생일 상품권 행은 지주 원문에 없어 뺐다.
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서
--     (compensation 10 · perks 20 · family 30 · health 40 · leisure 50).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-5): 공식 홈페이지 뉴스(2026-03-06 여성 존중 경영 · 2022-08-04 공동복지기금사업단 출범)로 출산 축하금·자녀 입학 선물·도서 구입비(parenting)와 복지포인트(welfare_point · 그룹 공통) 2행 추가 · child_edu · disability_family_support · fertility_support 서술 보강 · 머리말 주석 정정 — 최종 19행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(severance_plus) — 최종 20행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2026-10-06 식대 기준 금액 1끼 12,000원(리드 판정 (82)) — meal 행 금액 = 1끼 단가 × 끼니 × 연 240일, 꼬리에 식 공개

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ecopro', '에코프로',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '배터리소재', 'E', 'https://www.ecopro.co.kr/sub0502');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ecopro');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.ecopro.co.kr/sub0502'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) — 복리후생 금전적 지원 · 기타 지원 ──
  (@comp_id, 'bonus', '특별상여 (연간 3회)', NULL, 'compensation',
   'est', NULL, TRUE, '특별상여 연간 3회 지급 (공식 홈페이지 회사소개 복리후생 금전적 지원 항목) — 지급률·지급액 미기재', 10),
  (@comp_id, 'incentive', '평가급 (운영직)', NULL, 'compensation',
   'est', NULL, TRUE, '운영직 대상 평가급 지급, 최대 월 20만원 (공식 홈페이지 회사소개 복리후생 금전적 지원 항목) — 평가 기준·실지급액 미기재', 11),
  (@comp_id, 'profit_sharing', '성과급 (Profit Sharing)', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 지급, Profit Sharing 방식 (공식 홈페이지 회사소개 복리후생 금전적 지원 항목) — 지급 기준·지급률 미기재', 12),
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 근속 구간·포상 내용 미기재', 13),
  (@comp_id, 'excellence_award', '우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 선정 기준·포상 내용 미기재', 14),
  (@comp_id, 'severance_plus', '퇴직금 누진제도', NULL, 'compensation',
   'est', NULL, TRUE, '퇴직금 누진제도 (공식 홈페이지 회사소개 복리후생 생활안정 지원 항목 — 누진 방식·적용 조건 미기재)', 15),

  -- ── 경제적 부가혜택 (perks) — 복리후생 생활안정 지원 · 기타 지원 · 여가활동 지원 ──
  (@comp_id, 'housing_support', '사택 또는 주거지원금', NULL, 'perks',
   'est', NULL, TRUE, '사택 또는 주거지원금 지급 (공식 홈페이지 회사소개 복리후생 생활안정 지원 항목) — 지급 대상·지원금액 미기재', 20),
  (@comp_id, 'meal', '구내식당 (중식·석식)', 576, 'perks',
   'est', '구내식당 운영, 중식·석식 제공 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 1식 단가·본인 부담 여부 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 21),
  (@comp_id, 'discount', '제휴업체 직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '제휴업체 직원 할인 (공식 홈페이지 회사소개 복리후생 여가활동 지원 항목) — 제휴처·할인율 미기재', 22),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '전 가족사 직원 대상 공동복지기금사업단이 자녀학자금·의료비·건강검진과 함께 복지 포인트를 지원 (공식 홈페이지 뉴스 2022-08-04 공동복지기금사업단 출범 기사 · 그룹 채용 사이트 복지제도 공동복지기금사업단 운영 항목) — 지급액 미기재 (그룹 공통)', 23),

  -- ── 가족·돌봄 (family) — 복리후생 생활안정 지원 · 건강증진 지원 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 지원, 장례용품 포함 (공식 홈페이지 회사소개 복리후생 생활안정 지원 항목) — 경조 종류별 금액 미기재', 30),
  (@comp_id, 'child_edu', '학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원 (공식 홈페이지 회사소개 복리후생 생활안정 지원 항목), 미취학 자녀와 대학생 자녀에게 학자금 실비 지원 (공식 홈페이지 뉴스 2026-03-06 여성 존중 경영 기사) — 학교급별 한도 미기재', 31),
  (@comp_id, 'disability_family_support', '발달장애 자녀 특수교육비 지원', NULL, 'family',
   'est', NULL, TRUE, '발달장애 자녀 특수교육비 지원 (공식 홈페이지 회사소개 복리후생 건강증진 지원 항목), 발달장애 또는 발달지연 판정을 받은 만 18세 이하 자녀의 특수교육비 실비를 연 240만원 한도로 지원 (공식 홈페이지 뉴스 2026-03-06 여성 존중 경영 기사)', 32),
  (@comp_id, 'fertility_support', '난임 시술 지원·난임 치료 휴가', NULL, 'family',
   'est', NULL, TRUE, '난임 시술 지원 (공식 홈페이지 회사소개 복리후생 건강증진 지원 항목), 본인 또는 배우자 체외수정 시술 1회당 50만원 정액 지원·횟수 제한 없음, 난임 치료 휴가 유급 5일(법정 유급 2일에 3일 추가) (공식 홈페이지 뉴스 2026-03-06 여성 존중 경영 기사)', 33),
  (@comp_id, 'parenting', '출산 축하금·자녀 입학 선물·자녀 도서 구입비', NULL, 'family',
   'est', NULL, TRUE, '출산 시 축하금 첫째 100만원·둘째 200만원·셋째 이상 300만원과 기저귀 선물, 자녀 초등학교 입학 시 학용품·중고등학교 입학 시 축하 선물, 만 4세부터 12세 자녀를 둔 직원에게 도서 구입비 지원 (공식 홈페이지 뉴스 2026-03-06 여성 존중 경영 기사) — 도서 구입비 한도 미기재', 34),

  -- ── 건강·의료 (health) — 복리후생 기타 지원 · 건강증진 지원 ──
  (@comp_id, 'fitness', '헬스장·당구장·탁구장', NULL, 'health',
   'est', NULL, TRUE, '부대시설 운영, 헬스장·당구장·탁구장 등 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 위치·이용 조건 미기재', 40),
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '종합건강 검진 (공식 홈페이지 회사소개 복리후생 건강증진 지원 항목) — 검진 주기·대상·비용 미기재 (추정)', FALSE, NULL, 41),
  (@comp_id, 'medical', '임직원·가족 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 가족 의료비 지원 (공식 홈페이지 회사소개 복리후생 건강증진 지원 항목) — 가족 범위·지원 한도 미기재', 42),

  -- ── 여가·라이프 (leisure) — 복리후생 여가활동 지원 ──
  (@comp_id, 'resort', '휴양시설', 50, 'leisure',
   'est', '휴양시설 운영 (공식 홈페이지 회사소개 복리후생 여가활동 지원 항목) — 이용 횟수·지원 금액 미기재 (추정)', FALSE, NULL, 50),
  (@comp_id, 'club', '사내동호회 운영·지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 운영 및 지원 (공식 홈페이지 회사소개 복리후생 여가활동 지원 항목) — 지원 금액 미기재', 51)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
