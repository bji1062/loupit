-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 아이센스 복리후생 데이터
-- 출처: AI 파싱 (2026-04-15)
-- URL: 수동 입력
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: txt 원본은 아이센스에프앤비(자회사) 데이터, 아이센스 본사 기준으로 보수적 반영
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('isens', '아이센스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '의료기기', 'I', NULL);

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'isens');

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '8시 또는 9시 선택 출퇴근제', 10),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'lounge', '오락/휴게시설', NULL, 'work_env',
   'est', NULL, TRUE, '사내 PC방, 전자오락기기, 닌텐도, 플레이스테이션, 다트머신, 보드게임', 20),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '점심 제공', 432, 'perks',
   'est', '점심시간 1시간 30분 (추정)', FALSE, NULL, 80),
  (@comp_id, 'snack_bar', '간식/커피/라면', 30, 'perks',
   'est', '라면, 아메리카노 무료머신, 과자/음료 제공 (추정)', FALSE, NULL, 81),
  (@comp_id, 'discount', '자사브랜드 할인', 30, 'perks',
   'est', '직영 PC방/만화카페 100% 무료 이용 (추정)', FALSE, NULL, 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
