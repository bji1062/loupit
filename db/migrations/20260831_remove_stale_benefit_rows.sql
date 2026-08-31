-- ══════════════════════════════════════════════════════════════════════
-- 복지 재수집(에이전트 파일럿)에서 제외 확정된 잔존 행 삭제 — 셀트리온 8 · 아이센스 1
-- 근거: docs/handoff/2026-08-31-복지-에이전트수집-파일럿.md,
--       docs/handoff/2026-08-31-evidence/ (행별 원문 인용 + 적대 검증 보고)
--
-- 왜 마이그레이션인가: 시드 파일의 `DELETE ... WHERE BADGE_CD='est'` 는 백필로
--   official 이 된 서빙 행을 지우지 못한다. 멱등 재적용(load.py, --fresh 아님)은
--   INSERT..ON DUPLICATE 로 갱신만 하므로 **시드에서 빠진 행이 서빙에 잔존**한다.
--   --fresh 재시드에는 이 마이그레이션이 불필요하다(시드 파일이 정본).
--
-- ⚠ 실행 순서: **load.py 재적용보다 먼저** 실행할 것. 재적용의 백필이 회사 단위로
--   BADGE_SRC_CD 를 'scrape_official' 로 덮으면 아래 ai_parse 가드가 no-op 이 된다.
--   (가드를 두는 이유: 재직자 편집 계보 행이나 미래의 재수집 행을 오폭하지 않기 위함.)
--
-- 셀트리온 8행: 2026-08-31 공식 복지 페이지(celltrion.com/ko-kr/careers/recruit/welfare)
--   전수 대조에서 근거 문장 부재 확인(적대 검증 통과). incentive·stock_option·
--   excellence_award·long_service_leave·parenting·edu_support·parking·snack_bar.
-- 아이센스 1행: flex_work — 공식 채용사이트 FAQ 가 "월~금 09:00~18:00" 고정 근무를
--   명시하여 반증됨(구본 5행 자체가 아이센스에프앤비 자회사 오염 데이터).
-- ══════════════════════════════════════════════════════════════════════

SET @celltrion = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'celltrion');
DELETE FROM TCOMPANY_BENEFIT
 WHERE COMP_ID = @celltrion
   AND BADGE_SRC_CD = 'ai_parse'
   AND BENEFIT_CD IN ('incentive', 'stock_option', 'excellence_award', 'long_service_leave',
                      'parenting', 'edu_support', 'parking', 'snack_bar');

SET @isens = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'isens');
DELETE FROM TCOMPANY_BENEFIT
 WHERE COMP_ID = @isens
   AND BADGE_SRC_CD = 'ai_parse'
   AND BENEFIT_CD = 'flex_work';
