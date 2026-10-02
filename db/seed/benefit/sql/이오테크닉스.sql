-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 이오테크닉스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.eotechnics.com/page/company/welfare.php
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인 홈페이지 헤더 메뉴 COMPANY → 인재채용 → 복리후생 페이지 /page/company/welfare.php 다.
--   본문은 이미지 4장(welfare_001~004.jpg)이다 — 복리후생제도 표 8항목 · 복지시설 표 5항목 · 사진 · 주변환경 표 2항목.
--   이미지를 내려받아 읽었고 URL · 크기 · sha256 은 근거표에 적었다. 헤드리스 렌더 없음.
--   보조 출처: 같은 메뉴 인재채용 → 인사제도 페이지 /page/company/personnel_management.php 이미지(보상제도 성과급).
--   구본 12행은 복리후생 페이지 두 표를 그대로 옮긴 것이었다(구본 귀속 A — 12행 전부).
--   귀속: 단독 법인 자기 도메인(꼬리말 EO Technics Co., Ltd.) — 그룹 각주 없음. 직원 636명(DART 2025) — 1,000인 미만.
--   법정 제도: 출산/육아 항목(산전 후 휴가 · 육아휴직 · 남성출산휴가 · 보건휴가)은 법정 제도만이라 싣지 않았다.
--     인사제도 퇴직연금은 법정이라 싣지 않았다.
--   금액: 원문 금액 0 · 구본 추정 승계 5(health_check 100 · medical 100 · child_edu 200 · resort 50 ·
--     meal 432 조식/중식/석식 표기 — 전부 틀 값, NOTE 끝에 (추정)). long_service_bonus 50 · lang 50 은 회사 고유값이고
--     원문에 금액 전제가 없어 NULL. event 50 은 경조금이라 승계하지 않았다.
--   구본에서 뺀 행: parenting(법정 제도만). 새 행: incentive(인사제도 보상제도 성과급). 재코딩 0 · 신규 코드 0.
--   제외: 주변환경(카페거리 · 산책로 — 회사 밖 조경 소개) · 고정급 · 퇴직연금 · 호칭 · 평가 · 교육제도(회사 주도 과정).
--   SORT 섹션 순서 = 복리후생 페이지에서 카테고리가 처음 나온 순서, 인사제도 성과급은 compensation 섹션 안
--     (health 10 · family 20 · growth 30 · compensation 40 · leisure 50 · perks 60 · work_env 70).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-6): 12행 원문 이미지 독립 판독과 일치 · 법정 제도만 적힌 출산/육아 항목은 싣지 않음(등록 해제 동반) · 최종 12행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('eo_technics', '이오테크닉스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '레이저장비', 'E', 'https://www.eotechnics.com/page/company/welfare.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'eo_technics');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.eotechnics.com/page/company/welfare.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) — 복리후생 페이지 복리후생제도 ──
  (@comp_id, 'health_check', '종합 건강검진 (간부 정밀)', 100, 'health',
   'est', '매년 종합건강검진 지원, 간부급 정밀 검진 지원(삼성병원 검진센터 등) (공식 홈페이지 인재채용 복리후생 임직원 건강검진 항목) — 검진 비용 한도·가족 포함 여부 미기재 (추정)', FALSE, NULL, 10),
  (@comp_id, 'medical', '수술/입원비 지원', 100, 'health',
   'est', '본인, 배우자 및 직계비속 수술 및 입원비 지원 (공식 홈페이지 인재채용 복리후생 의료비 지원 항목) — 지원 비율·한도 미기재 (추정)', FALSE, NULL, 11),

  -- ── 가족·돌봄 (family) — 복리후생 페이지 복리후생제도 · 복지시설 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 및 가족 경조사 지원 — 경조금, 조화, 장례비품 (공식 홈페이지 인재채용 복리후생 경조금 지원 항목) — 경조금 기준 미기재', 20),
  (@comp_id, 'child_edu', '대학교 등록금 지원', 200, 'family',
   'est', '자녀 대학교 등록금 지원 (공식 홈페이지 인재채용 복리후생 자녀 학자금 지원 항목) — 지원 한도·자녀 수 미기재 (추정)', FALSE, NULL, 21),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '임직원 전용 직장 어린이집 운영 (공식 홈페이지 인재채용 복리후생 복지시설 어린이집 운영 항목) — 정원·이용 조건 미기재', 22),

  -- ── 성장·커리어 (growth) — 복리후생 페이지 복리후생제도 ──
  (@comp_id, 'lang', '어학비 지원', NULL, 'growth',
   'est', NULL, TRUE, '영어/중국어/일본어 등 어학비 지원 (공식 홈페이지 인재채용 복리후생 어학비 지원 항목) — 지원 한도·방식 미기재', 30),

  -- ── 보상·금전 (compensation) — 복리후생 페이지 복리후생제도 · 인사제도 보상제도 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상금', NULL, 'compensation',
   'est', NULL, TRUE, '근속 10년차부터 포상금 지급 (공식 홈페이지 인재채용 복리후생 장기근속자 포상 항목) — 포상금 금액·지급 주기 미기재', 40),
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '개인 혹은 팀이 탁월한 성과를 낼 경우 성과급 지급 (공식 홈페이지 인재채용 인사제도 보상제도 항목) — 지급 기준·지급률 미기재', 41),

  -- ── 여가·라이프 (leisure) — 복리후생 페이지 복리후생제도 ──
  (@comp_id, 'resort', '자가 콘도/리조트 제휴', 50, 'leisure',
   'est', '자가 콘도 무료 이용(부산, 강릉, 속초), 대명·한화·롯데 리조트 제휴, 숙박요금 지원 (공식 홈페이지 인재채용 복리후생 자가/제휴 콘도 이용 항목) — 지원 금액·이용 횟수 미기재 (추정)', FALSE, NULL, 50),

  -- ── 경제적 부가혜택 (perks) — 복리후생 페이지 복지시설 ──
  (@comp_id, 'meal', '조식/중식/석식 제공', 432, 'perks',
   'est', '사내식당 조식/중식/석식 제공 (공식 홈페이지 인재채용 복리후생 복지시설 사내식당 항목) — 단가·본인 부담 미기재 (추정)', FALSE, NULL, 60),

  -- ── 근무환경 (work_env) — 복리후생 페이지 복지시설 ──
  (@comp_id, 'parking', '무료 주차장 (300대)', NULL, 'work_env',
   'est', NULL, TRUE, '임직원에게 무료 주차 개방, 300대 주차 가능 (공식 홈페이지 인재채용 복리후생 복지시설 사내 주차장 항목)', 70),
  (@comp_id, 'nap_room', '남/여 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '남/여 휴게실에 1인용 리클라이너 설치 (공식 홈페이지 인재채용 복리후생 복지시설 사내 휴게실 항목), 남/여 샤워실 설치 및 필요 물품 제공 (같은 표 사내 샤워실 항목)', 71)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
