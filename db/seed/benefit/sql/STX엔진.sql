-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- STX엔진 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://recruit.stxengine.co.kr/stxengine/page/user/people03
-- badge: est
--
-- 참고:
--   정본은 상장 법인 STX엔진(주)의 자기 도메인 채용 사이트 recruit.stxengine.co.kr 인사제도 > 복리후생 페이지다.
--   SSR 이라 원본 HTML 에 3블록(현금성 복리후생 7 · 회사생활 지원 7 · 건강증진 및 기타지원 2) 16개 라벨이 텍스트로 있다.
--   아이콘은 SVG 장식이고 라벨은 HTML 텍스트라 헤드리스 렌더 · 이미지 판독 불필요. 라벨만 있고 설명 문장은 없다.
--   대표 홈 www.stxengine.co.kr 은 robots 전면 금지(User-agent * Disallow /)라 본문을 받지 않았다 — 지속가능경영보고서 미확인.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814001988) 직원 등 현황 유연근무제도 사용 현황 표(시차출퇴근제).
--   직원 943명(2026-06-30 · 임원 포함) — 1,000명 미만.
--   귀속: 페이지 주어가 STX엔진은 이고 그룹 · 계열사 단서가 없다. 옛 STX 그룹 계열사(STX · STX중공업)와 무관한
--   법인 단독 페이지라 각주 없음. 코퍼스 · 대기 폴더에 STX 형제 없음.
--   금액: 원문에 숫자 0건 — 전 행 BENEFIT_AMT NULL(구내식당 운영은 끼니가 안 적혀 NULL).
--   제외: 인사제도 페이지의 연봉제 · 승진 · 평가 · 부서배치(보상 · 인사 문장) · 공시 육아휴직 · 배우자 출산휴가 · 육아기 단축 사용자 수(법정) ·
--     공시 원격근무제 사용자 수 - (회사 자기 출처에 재택 문장 없음) · 주주 표 우리사주조합 - 칸 · 회계정책 기타장기종업원급여 일반 문장.
--   공고 근거 0행 / 전체 16행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(compensation 10 · leisure 20 · perks 30 · family 40 ·
--     flexibility 50 · work_env 60 · time_off 70 · health 80).
-- 검증 · 감사 판정 반영(2026-10-15): 인사제도 평가제도의 성과배분 incentive 추가(참고 블록 제외 줄의 평가 문장은 이 판정으로 뒤집힘) · 경조금 행 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 17행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('stx_engine', 'STX엔진',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '방산', 'S', 'https://recruit.stxengine.co.kr/stxengine/page/user/people03');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'stx_engine');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.stxengine.co.kr/stxengine/page/user/people03'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 채용 사이트 복리후생 현금성 복리후생 ──
  (@comp_id, 'holiday_gift', '명절 귀향여비', NULL, 'compensation',
   'est', NULL, TRUE, '명절 귀향여비 (공식 채용 사이트 복리후생 현금성 복리후생 항목) — 지급 금액·지급 기준 미기재', 10),
  (@comp_id, 'incentive', '성과배분', NULL, 'compensation',
   'est', NULL, TRUE, '개인 공통·리더십·직무역량 평가와 조직 성과 달성도 평가를 보상과 성과배분에 활용 (공식 채용 사이트 인사제도 평가제도 항목) — 지급 기준·지급률·지급 시기 미기재', 11),

  -- ── 여가 (leisure) — 채용 사이트 복리후생 현금성 복리후생 · 회사생활 지원 ──
  (@comp_id, 'summer_vacation_subsidy', '하계 휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '하계 휴가비 (공식 채용 사이트 복리후생 현금성 복리후생 항목) — 지급 금액·지급 기준 미기재', 20),
  (@comp_id, 'welcome_kit', 'STX엔진 웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, 'STX엔진 웰컴키트 (공식 채용 사이트 복리후생 회사생활 지원 항목) — 구성품 미기재', 21),

  -- ── 생활 지원 (perks) — 채용 사이트 복리후생 현금성 복리후생 · 회사생활 지원 ──
  (@comp_id, 'birthday_gift', '기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '기념일 선물 (공식 채용 사이트 복리후생 현금성 복리후생 항목) — 대상 기념일·선물 내용 미기재', 30),
  (@comp_id, 'welfare_point', '복지카드', NULL, 'perks',
   'est', NULL, TRUE, '복지카드 (공식 채용 사이트 복리후생 현금성 복리후생 항목) — 지급 금액·사용처 미기재', 31),
  (@comp_id, 'commute_subsidy', '출퇴근 통근버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '출/퇴근 통근버스 운영 (공식 채용 사이트 복리후생 회사생활 지원 항목) — 노선·운행 사업장 미기재', 32),
  (@comp_id, 'meal', '구내식당 운영', NULL, 'perks',
   'est', NULL, TRUE, '구내식당 운영 (공식 채용 사이트 복리후생 회사생활 지원 항목) — 제공 끼니·식대 부담 방식 미기재', 33),

  -- ── 가족 (family) — 채용 사이트 복리후생 현금성 복리후생 ──
  (@comp_id, 'child_edu', '자녀학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금 지원 (공식 채용 사이트 복리후생 현금성 복리후생 항목) — 지원 학교급·한도·자녀 수 미기재', 40),
  (@comp_id, 'parenting', '유아보조금 지원', NULL, 'family',
   'est', NULL, TRUE, '유아보조금 지원 (공식 채용 사이트 복리후생 현금성 복리후생 항목) — 대상 자녀 연령·지원 금액 미기재', 41),
  (@comp_id, 'event', '경/상조금', NULL, 'family',
   'est', NULL, TRUE, '경/상조금 (공식 채용 사이트 복리후생 현금성 복리후생 항목) — 지급 사유·금액 미기재', 42),

  -- ── 근무 유연성 (flexibility) — 채용 사이트 복리후생 회사생활 지원 + 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 (공식 채용 사이트 복리후생 회사생활 지원 항목), 유연근무제 활용 · 시차출퇴근제 사용자 수 298명 2026년 반기 (2026 반기보고서 유연근무제도 사용 현황 항목) — 출퇴근 시간대·대상 미기재', 50),

  -- ── 근무 환경 (work_env) — 채용 사이트 복리후생 회사생활 지원 ──
  (@comp_id, 'uniform', '근무복 지급', NULL, 'work_env',
   'est', NULL, TRUE, '근무복 지급 (공식 채용 사이트 복리후생 회사생활 지원 항목) — 지급 주기·대상 직군 미기재', 60),
  (@comp_id, 'dormitory', '1인1실 기숙사 운영', NULL, 'work_env',
   'est', NULL, TRUE, '1인1실 기숙사 운영 (공식 채용 사이트 복리후생 회사생활 지원 항목) — 입주 대상·사업장·비용 부담 미기재', 61),

  -- ── 휴가 (time_off) — 채용 사이트 복리후생 회사생활 지원 ──
  (@comp_id, 'summer_leave', '하계유급휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계유급휴가 (공식 채용 사이트 복리후생 회사생활 지원 항목) — 본인 휴가 사용일인지·휴가 일수 미기재', 70),

  -- ── 건강 (health) — 채용 사이트 복리후생 건강증진 및 기타지원 ──
  (@comp_id, 'medical', '의료지원', NULL, 'health',
   'est', NULL, TRUE, '의료지원 (공식 채용 사이트 복리후생 건강증진 및 기타지원 항목) — 지원 대상·범위·한도 미기재', 80),
  (@comp_id, 'fitness', '휘트니스 센터 운영', NULL, 'health',
   'est', NULL, TRUE, '휘트니스 센터운영 (공식 채용 사이트 복리후생 건강증진 및 기타지원 항목) — 위치·이용 대상 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
