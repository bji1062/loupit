-- ══════════════════════════════════════════════════════════════════════
-- LS 지주(주식회사 LS, COMP_ENG_NM = ls) 회사 등록 해제 — 복지 8 · 별칭 2 · 메일 도메인 1 · DART 연결 1 · 회사 1
-- 사용자 결정: 2026-10-01 (공식 복지 원문이 없어 회사 등록을 해제한다)
--
-- 배경: R-3 묶음 3 에서 ㈜LS(지주) 자신에게 적용된다고 밝힌 복지 원문을 찾지 못했다 — 수집 · 검증이 따로 찾았고
--   (lsholdings.com 보도자료 · 그룹 보도자료 · OpenDART 사업보고서: 직원 94명 · 복지 서술 없음) 유일한 복지 절인
--   lsholdings.com 「인사제도」는 그룹 공통이며 소절마다 「각 계열사 별 차이」 · ㈜LS 에 없는 공장 사택을 포함한다.
--   구본 LS.sql 8행은 머리말대로 KLT(Pulsarlube) 데이터였다(다른 회사). 복지 0행으로 남기면 회사 페이지가
--   꼴찌로 보이고 회사마다 복지 1행 이상 계약(DC-3 · SD-5)이 깨져, 회사째 내린다.
--   시드 쪽은 같은 PR 에서 LS.sql 삭제 · company_email_domain.sql 의 lsholdings.com 줄 · corp_code_map.csv 의 LS 줄 ·
--   generator/data/company_registrations.json 의 ls 를 지운다. /company/ls 는 release 뒤 404 다.
--   TCORP 의 LS 법인 행(00105952)과 재무 · 직원 행은 남는다 — 회사 연결이 없어 생성기가 읽지 않는다.
--   🚨 ls_electric(LS ELECTRIC)은 다른 회사다 — 건드리지 않는다(COMP_ENG_NM = 'ls' 정확 일치만).
--
-- 안전장치: TCOMPANY 를 가리키는 외래키 대부분이 ON DELETE CASCADE 다(재직 인증 · 게시글은 SET NULL).
--   회원 데이터(재직 인증 · 인증 요청 · 게시글 · 편집 이력 · 재직자 행)가 하나라도 LS 를 가리키면 @ls 가 NULL 이
--   되어 아래 문장이 전부 0행으로 끝난다(아무것도 지우지 않는다). 2026-10-01 운영 기준 그런 행은 0건이다.
-- 멱등: 두 번째 실행은 @ls 가 NULL 이라 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   1) 백업 — 참조 9테이블 + 이 파일이 지우는 TCOMPARE_LOG · TSOURCE_CHECK · TAUTH_CODE
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: ls_comp_id 13 · DELETE 8문 = 8 · 2 · 1 · 1 · 0 · 0 · 0 · 1 rows affected ·
--   두 번째 실행은 ls_comp_id NULL · 전부 0 · 적재 뒤 회사 148 · 복지 2705행.
--   TCOMPARE_LOG 는 적용 전에 누가 LS 를 비교하면 0 이 아닐 수 있다(익명 비교 기록이라 지워도 된다).
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

SET @ls = (
  SELECT c.COMP_ID FROM TCOMPANY c
   WHERE c.COMP_ENG_NM = 'ls'
     AND NOT EXISTS (SELECT 1 FROM TEMPLOY_VERIFICATION v WHERE v.COMP_ID = c.COMP_ID)
     AND NOT EXISTS (SELECT 1 FROM TEMPLOY_VRF_REQUEST r WHERE r.COMP_ID = c.COMP_ID)
     AND NOT EXISTS (SELECT 1 FROM TPOST p WHERE p.COMP_ID = c.COMP_ID)
     AND NOT EXISTS (SELECT 1 FROM TBENEFIT_EDIT_LOG l WHERE l.COMP_ID = c.COMP_ID)
     AND NOT EXISTS (SELECT 1 FROM TCOMPANY_BENEFIT b WHERE b.COMP_ID = c.COMP_ID AND b.BADGE_CD <> 'official')
);
SELECT @ls AS ls_comp_id;

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @ls AND BADGE_CD = 'official';
DELETE FROM TCOMPANY_ALIAS WHERE COMP_ID = @ls;
DELETE FROM TCOMPANY_EMAIL_DOMAIN WHERE COMP_ID = @ls;
DELETE FROM TCOMPANY_CORP WHERE COMP_ID = @ls;
DELETE FROM TSOURCE_CHECK WHERE COMP_ID = @ls;
DELETE FROM TCOMPARE_LOG WHERE A_COMP_ID = @ls OR B_COMP_ID = @ls;
DELETE FROM TAUTH_CODE WHERE COMP_ID = @ls;
DELETE FROM TCOMPANY WHERE COMP_ID = @ls AND COMP_ENG_NM = 'ls';

COMMIT;
