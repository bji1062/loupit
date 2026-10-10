-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 산일전기 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://www.sanil.co.kr/kr/sub/career/welfare.php
-- badge: est
--
-- 참고:
--   정본은 상장 법인 산일전기(KOSPI 062040)의 자기 도메인 www.sanil.co.kr GNB 인재경영 > 복리후생 페이지다.
--   리드 문장 주어가 산일전기는 이라 법인 귀속이 확정된다. 그룹 · 계열사 메뉴가 없는 단독 법인이라 그룹 각주 없음.
--   Apache + PHP 서버렌더 — 원본 HTML 의 section.line01~05 h5(카테고리 5) > li p(항목 18)에 항목 전문이 있다.
--   항목은 라벨뿐이다(설명문 없음 · 괄호 부연 4건). 헤드리스 렌더 없음 — 렌더하면 robots 금지 경로 /site/ 를 밟는다.
--   보조 확인: 같은 사이트 헤더 메뉴 EN 의 /en/sub/career/welfare.php 가 같은 5카테고리 18항목(한영 1:1)이라
--     영문판에서만 나온 행은 없다. 보도자료(PR 홍보자료 2쪽) · 채용안내 페이지에 복지 문장 없음.
--     OpenDART 사업 · 반기보고서 본문은 받는 시각에 DART 문서 API 가 점검 중(status 800)이라 보지 못했다.
--   금액: 원문에 원 · 만원 · 일수 숫자 0건 — 15행 전부 BENEFIT_AMT NULL(정성). 사내식당 운영은 끼니가 안 적혀 NULL.
--   행 분할: 경조휴가 및 경조금 → event(경조금) · leave_general(경조휴가). 장기 근속 포상(포상 제도)과
--     장기근속 휴가(여가활동지원)는 원문이 다른 항목으로 나눠 long_service_bonus · long_service_leave 두 행.
--   제외: 회사가 법정복리후생 카테고리로 묶은 3항목(4대보험 · 정기 건강검진 · 퇴직금 퇴직연금)과
--     여가활동지원의 연차 휴가 — 법정 제도. 정기 건강검진은 회사가 스스로 법정 항목으로 분류해 싣지 않았고
--     근거표 판단 요청 1번에 올렸다. 채용안내 페이지 인사관리 체계 불릿(상시포상 실시 · 성과보상 실시 등)은 인사 원칙이라 제외.
--   공고 근거 0행 / 전체 15행(채용공고 본문은 사람인에만 있어 쓰지 않았다). 신규 코드 0.
--   SORT 섹션 순서 = 정본 첫 등장 순: family 10 · time_off 20 · perks 30 · growth 40 · compensation 50 ·
--     work_env 60 · leisure 70.
-- 검증 · 감사 판정 반영(2026-10-10): 조치 없음 — 최종 15행
-- 코퍼스 정리(2026-10-10 · 웨이브 5 감사 후속): 경조휴가 행 삭제, event 행에 합침 — 최종 14행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sanil_electric', '산일전기',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '전력기기', 'S', 'https://www.sanil.co.kr/kr/sub/career/welfare.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sanil_electric');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.sanil.co.kr/kr/sub/career/welfare.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — 정본 생활복지지원 ──
  (@comp_id, 'parenting', '자녀 입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '자녀 입학 축하금 지원 (공식 홈페이지 인재경영 복리후생 생활복지지원 항목) — 대상 학교 단계·지급액 미기재', 10),
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 경조금 (공식 홈페이지 인재경영 복리후생 생활복지지원 항목) — 경조 사유별 지급액·휴가 일수·유급 여부 미기재', 11),

  -- ── 휴가 (time_off) — 정본 생활복지지원 · 여가활동지원 ──
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 휴가 (공식 홈페이지 인재경영 복리후생 여가활동지원 항목) — 근속 연수 기준·휴가 일수 미기재', 21),
  (@comp_id, 'summer_leave', '정기 휴가 (하계)', NULL, 'time_off',
   'est', NULL, TRUE, '정기 휴가 (하계) (공식 홈페이지 인재경영 복리후생 여가활동지원 항목) — 부여 일수·별도 부여 여부·유급 여부 미기재', 22),

  -- ── 경제적 부가혜택 (perks) — 정본 생활복지지원 · 직원복지 지원 ──
  (@comp_id, 'birthday_gift', '생일선물', NULL, 'perks',
   'est', NULL, TRUE, '생일선물 지급 (공식 홈페이지 인재경영 복리후생 생활복지지원 항목) — 선물 품목·금액 미기재', 30),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 운영 (공식 홈페이지 인재경영 복리후생 직원복지 지원 항목) — 제공 끼니·식대 부담 방식 미기재', 31),

  -- ── 성장 (growth) — 정본 생활복지지원 ──
  (@comp_id, 'self_development', '자기계발비 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기계발비 지원 (공식 홈페이지 인재경영 복리후생 생활복지지원 항목) — 지원 한도·사용 범위 미기재', 40),

  -- ── 보상 (compensation) — 정본 포상 제도 ──
  (@comp_id, 'long_service_bonus', '장기 근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 포상 (공식 홈페이지 인재경영 복리후생 포상 제도 항목) — 근속 연수 기준·포상 내용 미기재', 50),
  (@comp_id, 'excellence_award', '우수 사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수 사원 포상 (공식 홈페이지 인재경영 복리후생 포상 제도 항목) — 선발 기준·포상 내용 미기재', 51),
  (@comp_id, 'holiday_gift', '명절·기념일 선물 (창립기념일 등)', NULL, 'compensation',
   'est', NULL, TRUE, '명절/기념일 선물 (창립기념일 등) (공식 홈페이지 인재경영 복리후생 포상 제도 항목) — 선물 품목·금액 미기재', 52),

  -- ── 근무 환경 (work_env) — 정본 직원복지 지원 ──
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 운영 (공식 홈페이지 인재경영 복리후생 직원복지 지원 항목) — 입주 대상·사업장·이용료 미기재', 60),

  -- ── 여가 (leisure) — 정본 직원복지 지원 · 여가활동지원 ──
  (@comp_id, 'company_event', '정기 행사 (야유회·송년회·체육대회)', NULL, 'leisure',
   'est', NULL, TRUE, '정기 행사진행 (야유회, 송년회, 체육대회) (공식 홈페이지 인재경영 복리후생 직원복지 지원 항목) — 개최 주기·비용 부담 미기재', 70),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동지원 (공식 홈페이지 인재경영 복리후생 여가활동지원 항목) — 지원 금액·지원 방식 미기재', 71),
  (@comp_id, 'resort', '콘도 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 이용 지원 (공식 홈페이지 인재경영 복리후생 여가활동지원 항목) — 이용 가능 콘도·지원 방식 미기재', 72)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
