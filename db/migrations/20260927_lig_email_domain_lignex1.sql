-- ══════════════════════════════════════════════════════════════════════
-- LIG D&A(lig_nex1) 재직 인증 메일 도메인 1개 추가 — lignex1.com (ligdna.com 은 그대로)
-- 사용자 결정: 2026-09-27 — 2026-07-29 의 lignex1.com 보류를 뒤집는다.
--
-- 왜: 등록된 도메인은 ligdna.com 하나다. 사명 변경(2026-03) 전 주소 lignex1.com 을 아직 쓰는 임직원은
--   도메인 인증이 안 돼 422 → 수동 승인으로 빠진다. lignex1.com 의 MX 는 ligdna.com 과 완전히 같다
--   (sniper01/02.ligdefenseaerospace.com) — 회사 소유이고 메일을 받는다.
-- 넣지 않은 것: ligdefenseaerospace.com. 회사 소유(NS · SPF · 공식 홈페이지)지만 MX 가 도메인 없는
--   sniper01. · sniper02. 로 잘못 설정돼 지금 메일을 받지 못한다(2026-09-27 dig 실측) — 등록하면 인증 코드가
--   반송되고 주소가 발송 차단된다. 시드에 @rejected 로 적었다(사용자 결정 2026-09-27).
-- 시드: db/seed/company_email_domain.sql 에 같은 줄을 넣고 lignex1.com 의 @rejected 표식을 지웠다(SED-7).
-- 멱등: INSERT IGNORE + uq (COMP_ID, EMAIL_DOMAIN_NM) — 두 번째 실행은 0행이다.
--   회사 영문명이 틀리면 SELECT 가 0행이라 조용히 0행이다 — 기대 행 수로 확인한다.
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다): mysql -vv 로 적용한다.
-- 기대: INSERT 1문 1 row affected. 재직 인증 API 가 요청마다 이 표를 읽으므로 적용 즉시 반영된다
--   (release · 재시작 불필요).
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lignex1.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1';
