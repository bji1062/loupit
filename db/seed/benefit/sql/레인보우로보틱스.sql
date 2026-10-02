-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 레인보우로보틱스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://rainbow-robotics.com/%ec%b1%84%ec%9a%a9/
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인(rainbow-robotics.com, WordPress 서버 렌더) 헤더 메뉴 인재채용 상시 페이지다.
--   그 페이지에는 Work Environments 항목(구내 식당 · 휴게실 등)만 있고 복리후생 목록은 없다.
--   복리후생 4줄은 같은 사이트 채용공고 게시판(KBoard, 작성자 인사관리)의 2026-09-04 ~ 09-08 작성 공고에
--     글자까지 같은 블록으로 있다(검증 때 연 19건 전부 — 대표 uid 119 · 145 · 146, 전부 채용 시까지 게시 중).
--     2026-09-14 이후 작성된 공고(uid 147 ~ 167)와 uid 110 에는 이 블록이 없다 — 같은 때 채용절차 문구도 바뀐 공고 양식 변경이다.
--     공고가 닫히면 근거가 사라질 수 있어 상시 페이지를 정본으로 골랐다(올릭스 선례).
--   보조: OpenDART 2025 사업보고서(접수 20260320000803) 직원 161명 · 우리사주조합 보유 없음.
--     2026 반기보고서(접수 20260814002901) 조건부 시차출퇴근제 도입 주석 · 정관 사업목적 추가(세종 신사옥 사내 로봇 카페) — flex_work · snack_bar 근거.
--     생산 및 조립 · 품질검사원 공고(uid 121 · 122) 급여수준 칸의 성과급 문장 — incentive 근거(대상 직무를 서술에 적음).
--   귀속: 법인 자기 도메인만. 삼성전자(최대주주 35%) · 삼성 채용 포털 문구는 쓰지 않았다. 그룹 각주 없음.
--   법정 제도: 공고의 4대보험 및 법정휴가 보장 줄은 법정이라 싣지 않았다. 직원 161명 — 재취업지원 의무 대상 아님.
--   법정 등록 행: parenting 육아휴직 → 원문에 법정을 넘는 내용이 없어 뺐다(등록표에서 지울 행).
--   금액: 원문 금액 0. 구본 추정 승계 1(health_check 100 — 틀 값, NOTE 끝에 (추정)).
--   구본에서 뺀 행: stock_option · leave_general · parenting · birthday_gift. 재코딩 0. 신규 코드 0.
--   SORT 섹션 순서 = 공고 복리후생 블록에서 카테고리가 처음 나온 순서, 상시 페이지만의 카테고리는 끝
--     (perks 10 · leisure 20 · family 30 · health 40 · growth 50 · work_env 60), 공고 급여수준 compensation 70 · 공시 flexibility 80.
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-6): 2026 반기보고서 근거 snack_bar · flex_work 행과 생산 · 품질 공고 급여수준 근거 incentive 행을 더함 — 최종 11행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('rainbow_robotics', '레인보우로보틱스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '로봇', 'R', 'https://rainbow-robotics.com/%ec%b1%84%ec%9a%a9/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'rainbow_robotics');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://rainbow-robotics.com/%ec%b1%84%ec%9a%a9/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 채용 공고 복리후생 · 인재채용 Work Environments ──
  (@comp_id, 'meal', '중식 제공', NULL, 'perks',
   'est', NULL, TRUE, '중식 제공 (공식 채용 공고 복리후생 항목), 구내 식당 (공식 홈페이지 인재채용 Work Environments 항목) — 조식·석식 제공 여부·본인 부담 미기재', 10),
  (@comp_id, 'welfare_point', '복지카드 (1년 이상 근속 시)', NULL, 'perks',
   'est', NULL, TRUE, '1년 이상 근속 시 복지카드 지급 (공식 채용 공고 복리후생 항목) — 배정 금액·사용처 미기재', 11),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '세종 신사옥 내 로봇 기반 자동화 카페 운영, 임직원 복지환경 개선 목적 (2026 반기보고서 정관 사업목적 추가 항목) — 이용 요금·운영 시간 미기재', 12),

  -- ── 여가·라이프 (leisure) — 채용 공고 복리후생 ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 (공식 채용 공고 복리후생 항목) — 활동비 지원 여부·동호회 종류 미기재', 20),
  (@comp_id, 'resort', '휴양 리조트 숙박비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '법인 가입 고급 휴양 리조트 이용 시 숙박비 지원 (공식 채용 공고 복리후생 항목) — 리조트 이름·지원 한도·이용 횟수 미기재', 21),

  -- ── 가족·돌봄 (family) — 채용 공고 복리후생 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (공식 채용 공고 복리후생 항목) — 경조금 금액·경조 범위 미기재', 30),

  -- ── 건강·의료 (health) — 채용 공고 복리후생 ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '종합건강검진 (공식 채용 공고 복리후생 항목) — 검진 주기·비용 한도·가족 포함 여부 미기재 (추정)', FALSE, NULL, 40),

  -- ── 성장·교육 (growth) — 채용 공고 복리후생 ──
  (@comp_id, 'self_development', '자기계발비 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기개발비 지원 (공식 채용 공고 복리후생 항목) — 지원 금액·대상 항목 미기재', 50),

  -- ── 근무환경 (work_env) — 인재채용 Work Environments ──
  (@comp_id, 'lounge', '휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '휴게실 (공식 홈페이지 인재채용 Work Environments 항목) — 위치·이용 방식 미기재', 60),

  -- ── 보상 (compensation) — 생산 · 품질검사 직무 채용 공고 급여수준 ──
  (@comp_id, 'incentive', '성과급 (생산·품질검사 직무)', NULL, 'compensation',
   'est', NULL, TRUE, '성과급 내부 규정에 따라 지급 (공식 채용 공고 생산 및 조립·품질검사원 급여수준 항목) — 지급 기준·지급률·다른 직무 적용 여부 미기재', 70),

  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '조건부 시차출퇴근제 도입 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 적용 조건·출퇴근 시간대 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
