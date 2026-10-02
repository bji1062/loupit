-- ══════════════════════════════════════════════════════════════════════
-- HPSP(주식회사 HPSP, COMP_ENG_NM = hpsp) 회사 등록 해제 — 복지 14 · 별칭 2 · 메일 도메인 0 · DART 연결 1 · 회사 1
-- 사용자 결정: 2026-10-02 (공식 복지 원문이 없어 회사 등록을 해제한다 — 「등록 해제」)
-- 선례: db/migrations/20261001_unregister_ls_holding.sql (LS #89) · LG #87
--
-- 배경: R-3 묶음 6 에서 HPSP 자신의 공식 복리후생 원문을 찾지 못했다 — 수집 · 검증이 따로 찾았다
--   (자기 도메인 www.thehpsp.com 헤더 메뉴 · 국영문 · 공고 8건 복리후생 절 없음 · 보도자료 · 그리팅 · OpenDART 사업보고서 직원 127명;
--   공시 문장 「시차출퇴근제와 선택근무제」 1줄뿐). 구본 14행은 전부 근거 없는 AI 파싱이다.
--   복지 0행으로 남기면 꼴찌 노출 + DC-3 · SD-5 계약 위반이라 회사째 내린다(사용자 결정).
--   시드 쪽은 같은 PR 에서 HPSP.sql 삭제 · corp_code_map.csv 의 HPSP 줄 · generator/data/company_registrations.json 의 hpsp 를 지운다
--   (company_email_domain.sql 의 HPSP 줄은 이미 @rejected 주석뿐이라 등록 줄이 없다). /company/hpsp 는 release 뒤 404 다.
--   TCORP 의 HPSP 법인 행(01288827)과 재무 · 직원 행은 남는다 — 회사 연결이 없어 생성기가 읽지 않는다.
--
-- 안전장치: TCOMPANY 를 가리키는 외래키 대부분이 ON DELETE CASCADE 다(재직 인증 · 게시글은 SET NULL).
--   회원 데이터(재직 인증 · 인증 요청 · 게시글 · 편집 이력 · 재직자 행)가 하나라도 HPSP 를 가리키면 @hpsp 가 NULL 이
--   되어 아래 문장이 전부 0행으로 끝난다(아무것도 지우지 않는다). 2026-10-02 운영 기준 그런 행은 0건이다.
-- 멱등: 두 번째 실행은 @hpsp 가 NULL 이라 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → 20261002_recollect_3_batch6a.sql → python3 db/seed/load.py → release.
-- 🚨 같은 PR 이 web/assets/js/legal.js · find.js 를 바꾼다 — web/assets 는 라이브 docroot 라 git pull 하는 순간 바로 라이브가 되므로
--   pull → 백업 → 이 파일 → 20261002_recollect_3_batch6a.sql → load.py → release 를 끊지 않고 잇는다.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   1) 백업 — 참조 9테이블 + 이 파일이 지우는 TCOMPARE_LOG · TSOURCE_CHECK · TAUTH_CODE
--   2) 이 파일을 mysql -vv 로 적용
--   3) 20261002_recollect_3_batch6a.sql 적용 → cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: hpsp_comp_id 4 · DELETE 8문 = 14 · 2 · 0 · 1 · 0 · 2 · 0 · 1 rows affected ·
--   두 번째 실행은 hpsp_comp_id NULL · 전부 0 · 적재 뒤 회사 147 · 복지 2989행.
--   TCOMPARE_LOG 는 적용 전에 누가 HPSP 를 비교하면 2 가 아닐 수 있다(익명 비교 기록이라 지워도 된다).
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

SET @hpsp = (
  SELECT c.COMP_ID FROM TCOMPANY c
   WHERE c.COMP_ENG_NM = 'hpsp'
     AND NOT EXISTS (SELECT 1 FROM TEMPLOY_VERIFICATION v WHERE v.COMP_ID = c.COMP_ID)
     AND NOT EXISTS (SELECT 1 FROM TEMPLOY_VRF_REQUEST r WHERE r.COMP_ID = c.COMP_ID)
     AND NOT EXISTS (SELECT 1 FROM TPOST p WHERE p.COMP_ID = c.COMP_ID)
     AND NOT EXISTS (SELECT 1 FROM TBENEFIT_EDIT_LOG l WHERE l.COMP_ID = c.COMP_ID)
     AND NOT EXISTS (SELECT 1 FROM TCOMPANY_BENEFIT b WHERE b.COMP_ID = c.COMP_ID AND b.BADGE_CD <> 'official')
);
SELECT @hpsp AS hpsp_comp_id;

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @hpsp AND BADGE_CD = 'official';
DELETE FROM TCOMPANY_ALIAS WHERE COMP_ID = @hpsp;
DELETE FROM TCOMPANY_EMAIL_DOMAIN WHERE COMP_ID = @hpsp;
DELETE FROM TCOMPANY_CORP WHERE COMP_ID = @hpsp;
DELETE FROM TSOURCE_CHECK WHERE COMP_ID = @hpsp;
DELETE FROM TCOMPARE_LOG WHERE A_COMP_ID = @hpsp OR B_COMP_ID = @hpsp;
DELETE FROM TAUTH_CODE WHERE COMP_ID = @hpsp;
DELETE FROM TCOMPANY WHERE COMP_ID = @hpsp AND COMP_ENG_NM = 'hpsp';

COMMIT;
