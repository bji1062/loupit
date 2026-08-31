-- ══════════════════════════════════════════════════════════════════════
-- 복지 재수집 배치 1(에이전트 수집·검증)에서 제외·재코딩 확정된 잔존 행 삭제 — 10행/5개사
-- 근거: docs/handoff/2026-08-31-복지-배치1.md, docs/handoff/2026-08-31-evidence/batch1/
--
-- 왜 필요한가(파일럿 20260831 마이그레이션과 동일 함정): 백필이 서빙 행을 official 로
--   승격하므로 시드의 `DELETE ... BADGE_CD='est'` 는 잔존 행을 못 지우고, 멱등 재적용은
--   시드에서 빠진 행을 남긴다. **재코딩 행을 안 지우면 구·신 코드가 이중 계상된다**
--   (예: 삼천당제약 birthday_leave 5 + birthday_gift 5 = 총액 2배).
-- ⚠ 실행 순서: **load.py 재적용보다 먼저** (백필이 BADGE_SRC_CD 를 회사 단위로 덮으면
--   ai_parse 가드가 no-op 이 된다). --fresh 재시드에는 불필요.
--
-- 알테오젠 1: long_service_leave — 원문 「장기근속 포상」이라 long_service_bonus 로 재코딩
--   (구본이 refreshLeave 파생에 걸려 리프레시 휴가로 오표시되던 버그도 함께 해소).
-- 유진테크 1: holiday_gift(명절선물 20) — 공식 3페이지 전문에 근거 없음.
-- 엔켐 3: incentive·stock_option·parking — 공식 페이지에 언급 전무.
-- 삼성카드 3: insurance·fitness·discount — 구본이 타사("에코비트") 오염 데이터,
--   공식 두 페이지에서 근거 0건.
-- 삼천당제약 2: birthday_leave(→birthday_gift 재코딩, 원문 '문화 생활 지원'은 휴가 아님) ·
--   long_service_leave(→long_service_bonus 재코딩, 원문 '포상'은 휴가 아님).
-- ══════════════════════════════════════════════════════════════════════

SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'alteogen');
DELETE FROM TCOMPANY_BENEFIT
 WHERE COMP_ID = @c AND BADGE_SRC_CD = 'ai_parse'
   AND BENEFIT_CD = 'long_service_leave';

SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'eugenetech');
DELETE FROM TCOMPANY_BENEFIT
 WHERE COMP_ID = @c AND BADGE_SRC_CD = 'ai_parse'
   AND BENEFIT_CD = 'holiday_gift';

SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'enchem');
DELETE FROM TCOMPANY_BENEFIT
 WHERE COMP_ID = @c AND BADGE_SRC_CD = 'ai_parse'
   AND BENEFIT_CD IN ('incentive', 'stock_option', 'parking');

SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_card');
DELETE FROM TCOMPANY_BENEFIT
 WHERE COMP_ID = @c AND BADGE_SRC_CD = 'ai_parse'
   AND BENEFIT_CD IN ('insurance', 'fitness', 'discount');

SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samchundang');
DELETE FROM TCOMPANY_BENEFIT
 WHERE COMP_ID = @c AND BADGE_SRC_CD = 'ai_parse'
   AND BENEFIT_CD IN ('birthday_leave', 'long_service_leave');
