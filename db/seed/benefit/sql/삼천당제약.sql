-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼천당제약 복리후생 데이터
-- 출처: AI 파싱 (2026-08-31)
-- URL: http://www.scd.co.kr/recruit/welfare.jsp
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 근거는 전부 **삼천당제약 공식 도메인**(scd.co.kr) 「인사제도 복리후생」 페이지.
--       ⚠ 사이트는 https 미지원(443 Connection refused) — http 만 살아있다. robots.txt 는 404(제한 없음).
--       ⚠ 페이지 본문이 전부 **이미지**다. 복리후생 9개 항목은 GIF 한 장
--       (검증 판정 2026-08-31: 9항목 중 '각종 수당'은 정보량 0, '주 5일 근무'는 법정
--        기준이라 2행 미수록 — 수록 7행)
--       (/common/images/recruit/recruit_img_05.gif, 700x262)에 들어있고 HTML 텍스트는 0자다.
--       같은 페이지의 recruit_img_04.gif 는 「인사제도」= 승진체계(사원→주임→…→부장)라 복지가 아니다.
--       페이지는 금액을 일절 공개하지 않는다 — 금액이 있는 4행은 구본(2026-04)의 앵커 추정치를
--       유지한 것(금액정책 (a) → note 의 "추정" 표기로 DG-2 가 estimated 로 도출).
--       ⚠ 구본의 meal=432 는 승계하지 않았다: 432 는 시드 102개 중 44개 파일이 조식전용·중식전용·
--       삼시세끼를 가리지 않고 똑같이 쓴 코퍼스 기본값이고, 같은 코퍼스가 "중식 식대"에는 288·240 을
--       쓴다 → 회사 고유값이 아니라 오염으로 판단, 금액 제거 후 정성행으로 강등.
--       신규 코드 2개(allowance, five_day_week) — 정식 어휘에 대응 개념이 없다(사유는 evidence 참조).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samchundang', '삼천당제약',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '제약', 'S', 'http://www.scd.co.kr/recruit/welfare.jsp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samchundang');

-- 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본은 NULL — INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'http://www.scd.co.kr/recruit/welfare.jsp'
 WHERE COMP_ID = @comp_id;

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'excellence_award', '우수·모범사원 포상', 50, 'compensation',
   'est', '우수사원 해외연수 실시, 모범사원 포상 실시 (연 50만원 추정)', FALSE, NULL, 20),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 사원 포상 실시', 30),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조금 지급', 20, 'family',
   'est', '각종 경조사시 경조금 지급 (연 20만원 추정)', FALSE, NULL, 50),
  (@comp_id, 'child_edu', '자녀 학자금 지원', 100, 'family',
   'est', '자녀 학자금 지원 (연 100만원 추정)', FALSE, NULL, 60),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '공식 동호회 경비 지원', 10, 'leisure',
   'est', '각종 공식동호회 경비지원 (연 10만원 추정)', FALSE, NULL, 70),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'birthday_gift', '생일자 문화생활 지원', 5, 'perks',
   'est', '생일자 문화 생활 지원 (연 5만원 추정)', FALSE, NULL, 80),
  (@comp_id, 'meal', '중식비 제공', NULL, 'perks',
   'est', NULL, TRUE, '중식비 제공 (금액 미공개)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
