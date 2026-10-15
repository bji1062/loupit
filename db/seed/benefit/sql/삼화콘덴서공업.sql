-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼화콘덴서공업 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://samwhacapacitor.applyin.co.kr/content/welfare
-- badge: est
--
-- 참고:
--   정본은 상장 법인 삼화콘덴서공업(주)의 회사 계정 채용 사이트(applyin · 법인명 삼화콘덴서공업㈜) 복리후생 메뉴다.
--   공식 홈 www.samwha.com/capacitor 상단 채용정보 메뉴와 본문 RECRUIT 자세히보기가 이 사이트로 링크한다.
--   자기 도메인 www.samwha.com 에는 복리후생 목록 페이지가 없다(그룹 소개 · 계열사 소개 · ESG 페이지뿐).
--   렌더: 원본 HTML 안 JSON 데이터(복리후생 8블록 · 메뉴 사용 중 · 편집일 2026-02) — 헤드리스 렌더 없음.
--   같은 JSON 의 인재육성 섹션은 메뉴에 없고 벤더 샘플 문구라 쓰지 않았다.
--   보조: 공식 홈 ESG 페이지 안전·보건 임직원 건강증진 활동 문단(건강검진) ·
--     OpenDART 2026 반기보고서(접수 20260814002905) 직원 등 현황 유연근무제도 사용 현황(시차출퇴근제).
--   귀속: 복리후생 소개 문구 주어가 삼화콘덴서는 으로 법인 단수 · 계열사 단서 없음 · 각주 없음.
--     같은 그룹 삼화전기 자기 페이지 복리후생 문구와 대조해 문장이 달라 그룹 템플릿이 아니다. 코퍼스에 삼화 형제 없음.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL(식당은 끼니 미기재라 NULL).
--   제외: 법정휴가 준수 · 반차(법정) · 가족수당(급여성 수당) · 자유 복장 및 캐주얼데이(대응 코드 없음) ·
--     출장 시 법인 차량 제공(업무 수단) · 우리사주조합(공시 지분 표뿐) · 재무제표 주석 기타장기종업원급여(회계 정책 문장).
--   공고 근거 0행 / 전체 18행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(health 10 · family 20 · leisure 30 · time_off 40 · compensation 50 ·
--     perks 60 · growth 70 · work_env 80 · flexibility 90).
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 18행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samwha_capacitor', '삼화콘덴서공업',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '전자부품', 'S', 'https://samwhacapacitor.applyin.co.kr/content/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samwha_capacitor');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://samwhacapacitor.applyin.co.kr/content/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 공식 채용 페이지 복리후생 · 공식 홈 ESG ──
  (@comp_id, 'health_check', '건강검진비 지원 (본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '건강검진비 지원(본인/배우자) (공식 채용 페이지 복리후생 항목), 지역 기관과의 종합검진 협약 및 임직원 검진 지원 (공식 홈페이지 ESG 안전·보건 임직원 건강증진 활동 항목) — 검진 주기·지원 금액 미기재', 10),
  (@comp_id, 'fitness', '운동시설', NULL, 'health',
   'est', NULL, TRUE, '복리후생시설 운동시설 (공식 채용 페이지 복리후생 항목) — 시설 종류·이용 조건 미기재', 11),

  -- ── 가족 (family) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'event', '경조휴가·경조금', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 경조금/용품 지급 (공식 채용 페이지 복리후생 항목) — 경조 종류별 휴가 일수·금액 미기재', 20),
  (@comp_id, 'parenting', '출산축하금·입학축하금 (초·중·고)', NULL, 'family',
   'est', NULL, TRUE, '출산축하금 지급, 입학축하금 지원(초, 중, 고) (공식 채용 페이지 복리후생 항목) — 지급 금액 미기재', 21),
  (@comp_id, 'child_edu', '자녀학비 보조금 (어린이집·대학)', NULL, 'family',
   'est', NULL, TRUE, '자녀학비 보조금 지원(어린이집, 대학) (공식 채용 페이지 복리후생 항목) — 지원 금액·지원 한도 미기재', 22),

  -- ── 여가 (leisure) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'resort', '콘도·리조트 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '콘도/리조트 이용 지원 (공식 채용 페이지 복리후생 항목) — 이용 시설·지원 방식 미기재', 30),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영 (공식 채용 페이지 복리후생 항목) — 지원 금액·동호회 종류 미기재', 31),

  -- ── 휴가 (time_off) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'long_service_leave', '장기근속 포상 및 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속포상 및 휴가 지급(근속 5, 7, 10, 15, 20, 25, 30년) (공식 채용 페이지 복리후생 항목) — 근속 연수별 포상 내용·휴가 일수 미기재', 40),
  (@comp_id, 'summer_leave', '하계자율휴가 (1년 이상자)', NULL, 'time_off',
   'est', NULL, TRUE, '하계자율휴가(1년 이상자) 지급 (공식 채용 페이지 복리후생 휴가 항목) — 휴가 일수·유급 여부·사용 시기 미기재', 41),
  (@comp_id, 'leave_general', '명절 휴가 1일 추가 · 2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '명절(설/추석) 휴가 1일 추가 지급, 2시간 단위 휴가 제도 운영 (공식 채용 페이지 복리후생 항목) — 명절 추가 휴가의 유급 여부·2시간 단위 휴가 사용 한도 미기재', 42),

  -- ── 보상 (compensation) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'holiday_gift', '명절·창립일 선물 및 격려금', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물 및 격려금 지급, 창립일 선물 및 장려금 지급 (공식 채용 페이지 복리후생 항목) — 선물 품목·격려금과 장려금 금액 미기재', 50),
  (@comp_id, 'excellence_award', '우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상 및 휴가 지급 (공식 채용 페이지 복리후생 항목) — 선정 기준·포상 내용·휴가 일수 미기재', 51),

  -- ── 생활 (perks) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'snack_bar', '하계기간 간식·매점', NULL, 'perks',
   'est', NULL, TRUE, '하계기간 간식 제공, 복리후생시설 매점 (공식 채용 페이지 복리후생 항목) — 간식 종류·매점 운영 방식 미기재', 60),
  (@comp_id, 'meal', '사내 식당', NULL, 'perks',
   'est', NULL, TRUE, '복리후생시설 식당 (공식 채용 페이지 복리후생 항목) — 제공 끼니·식대 부담 미기재', 61),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운행 (공식 채용 페이지 복리후생 출퇴근 항목) — 운행 노선·이용 조건 미기재', 62),

  -- ── 성장 (growth) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'lang', '외국어 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '외국어 교육 지원 (공식 채용 페이지 복리후생 항목) — 지원 방식·대상 언어 미기재', 70),

  -- ── 근무환경 (work_env) — 공식 채용 페이지 복리후생 ──
  (@comp_id, 'lounge', '휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '복리후생시설 휴게실 (공식 채용 페이지 복리후생 항목) — 시설 규모·위치 미기재', 80),

  -- ── 유연근무 (flexibility) — 공식 채용 페이지 복리후생 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 운영 (공식 채용 페이지 복리후생 출퇴근 항목), 유연근무제 활용 여부 시차출퇴근제 사용 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 출퇴근 시간대·대상 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
