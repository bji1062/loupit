-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 케어젠 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚠ 재수집 시도 실패(2026-09-21): 공식 사이트 caregen.co.kr 이 **전면 403** 이다.
--    robots.txt·루트·www/비www·http/https 전부 403(본문은 「접근 제한」 안내 페이지, 2775B).
--    robots 를 받지 못하면 본문을 요청하지 않는다는 수집 계약에 따라 중단했다.
--    그래서 SORT 30 leave_general 과 SORT 50 event 가 둘 다 「경조휴가」를 말하는 상태가 남는다 —
--    이 회사 원문에 경조「금」 근거가 0이라 event 행에 쓸 말이 없다. 겹침을 푸는 길은 원문뿐이다.
--    다시 시도하기 전에 403 이 풀렸는지부터 확인할 것(우리 IP 차단일 수 있다).
-- ⚠ 법정 제도 문구 정리(2026-09-20): SORT 30 문안 교체 — 법정 제도 서술을 걷고 회사 상회분만 남겼다. 행 수 변동 없음.

-- ⚠ 데이터 정리 2차(2026-09-21): SORT 50·83 카테고리 통일 + 문안 교체. db/migrations/20260921_data_cleanup_2.sql 동봉.
-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('caregen', '케어젠',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오', 'K', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'caregen');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절 선물', 20, 'compensation',
   'est', '명절 선물 지급 (추정)', FALSE, NULL, 1),
  (@comp_id, 'excellence_award', '우수사원 포상', 30, 'compensation',
   'est', '(추정)', FALSE, NULL, 2),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '경조휴가·휴가비 지원', NULL, 'time_off',
   'est', '휴가비 지원', TRUE, '경조휴가 및 휴가비 지원', 30),
  (@comp_id, 'long_service_leave', '장기근속자 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상', 31),

  -- ── 가족·돌봄 (family) ──
  -- 문안(2026-09-21): 이름을 코퍼스 표준 「경조사 지원」으로 맞추고 서술은 원문 근거(경조휴가)만 남겼다.
  --   ⚠ 이 회사는 원문이 「경조휴가」 하나뿐이라 SORT 30 leave_general 과 서술이 여전히 겹친다.
  --   금전 근거가 0이라 금액·「경조금」을 쓸 수 없다 — 겹침을 푸는 길은 원문 재수집뿐이다(구본: AI 파싱·URL 수동 입력).
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 부여', 50),

  -- ── 경제적 부가혜택 (perks) ──
  -- meal 432 앵커 규칙(3식 이상 명시) 미충족 → 정성 강등 (2026-09-18, db/migrations/20260918_meal_anchor_to_qual.sql)
  (@comp_id, 'meal', '점심/저녁식사 제공', NULL, 'perks',  'est', NULL, TRUE, '점심식사 및 저녁식사 제공', 80),
  (@comp_id, 'snack_bar', '음료 제공', 20, 'perks',
   'est', '(추정)', FALSE, NULL, 81),
  (@comp_id, 'discount', '자회사 제품 할인', 30, 'perks',
   'est', '자회사 제품 할인 지원 (추정)', FALSE, NULL, 82),
  -- 카테고리 통일(2026-09-21): perks → work_env
  (@comp_id, 'parking', '주차장 제공', NULL, 'work_env',
   'est', NULL, TRUE, '주차장 제공', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
