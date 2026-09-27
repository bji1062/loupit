-- ══════════════════════════════════════════════════════════════════════
-- LIG D&A(lig_nex1) 재직 인증 메일 도메인 2개 추가 — ligdefenseaerospace.com · lignex1.com
-- 사용자 결정: 2026-09-27 (ligdna.com 은 그대로 두고 두 도메인을 추가) — 2026-07-29 의 lignex1.com 보류를 뒤집는다.
--
-- 왜: 등록된 도메인은 ligdna.com 하나다. 사명 변경(2026-03) 뒤에도 구 주소 lignex1.com 이나
--   ligdefenseaerospace.com 메일을 쓰는 임직원은 도메인 인증이 안 돼 422 → 수동 승인으로 빠진다.
--   두 도메인 모두 회사 소유가 확실하다 — MX 가 ligdna.com 과 같은 sniper01/02.ligdefenseaerospace.com 이고,
--   ligdefenseaerospace.com 은 공식 홈페이지 · 채용 복지 페이지의 도메인이다.
-- 시드: db/seed/company_email_domain.sql 에 같은 두 줄을 넣고 @rejected 표식을 지웠다(SED-7).
-- 멱등: INSERT IGNORE + uq (COMP_ID, EMAIL_DOMAIN_NM) — 두 번째 실행은 0행이다.
--   회사 영문명이 틀리면 SELECT 가 0행이라 조용히 0행이다 — 기대 행 수로 확인한다.
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다): mysql -vv 로 적용한다.
-- 기대: INSERT 2문 각각 1 row affected. 재직 인증 API 가 요청마다 이 표를 읽으므로 적용 즉시 반영된다
--   (release · 재시작 불필요).
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'ligdefenseaerospace.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lignex1.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1';
