-- ══════════════════════════════════════════════════════════════════════
-- LG 지주(주식회사 LG, COMP_ENG_NM = lg) 회사 등록 해제 — 복지 14 · 별칭 3 · 메일 도메인 1 · DART 연결 1 · 회사 1
-- 사용자 결정: 2026-10-01 (공식 복지 원문이 없어 회사 등록을 해제한다)
--
-- 배경: R-3 묶음 2(PR #86)에서 LG 지주 자신의 복지 원문을 찾지 못했다 — 수집 · 검증이 따로 찾았고
--   (lg.co.kr · lgcorp.com 사이트맵, LG 채용 포털 채널 · 공고 회사 코드, ESG 보고서 5판, 보도자료)
--   DART 2025 사업보고서 원문에도 복리후생 제도 서술이 없다(복리후생비 합계 · 퇴직연금 회계 설명뿐).
--   구본 14행은 LG유플러스 옛 자료의 사본이었다. 복지 0행으로 남기면 회사 페이지가 150개사 중 꼴찌로
--   보이고 회사마다 복지 1행 이상 계약(DC-3 · SD-5)이 깨져, 회사째 내린다.
--   시드 쪽은 같은 PR 에서 LG.sql 삭제 · company_email_domain.sql 의 lg.com 줄 · corp_code_map.csv 의 LG 줄 ·
--   generator/data/company_registrations.json 의 lg 를 지운다. /company/lg 는 release 뒤 404 다.
--   TCORP 의 LG 법인 행(00120021)과 재무 · 직원 행은 남는다 — 회사 연결이 없어 생성기가 읽지 않는다.
--
-- 안전장치: TCOMPANY 를 가리키는 외래키 대부분이 ON DELETE CASCADE 다(재직 인증 · 게시글은 SET NULL).
--   회원 데이터(재직 인증 · 인증 요청 · 게시글 · 편집 이력 · 재직자 행)가 하나라도 LG 를 가리키면 @lg 가 NULL 이
--   되어 아래 문장이 전부 0행으로 끝난다(아무것도 지우지 않는다). 2026-10-01 운영 기준 그런 행은 0건이다.
-- 멱등: 두 번째 실행은 @lg 가 NULL 이라 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   1) 백업 — 참조 9테이블 + 이 파일이 지우는 TCOMPARE_LOG · TSOURCE_CHECK · TAUTH_CODE
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: lg_comp_id 6 · DELETE 8문 = 14 · 3 · 1 · 1 · 0 · 0 · 0 · 1 rows affected ·
--   두 번째 실행은 lg_comp_id NULL · 전부 0 · 적재 뒤 회사 149 · 복지 2691행.
--   TCOMPARE_LOG 는 적용 전에 누가 LG 를 비교하면 0 이 아닐 수 있다(익명 비교 기록이라 지워도 된다).
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

SET @lg = (
  SELECT c.COMP_ID FROM TCOMPANY c
   WHERE c.COMP_ENG_NM = 'lg'
     AND NOT EXISTS (SELECT 1 FROM TEMPLOY_VERIFICATION v WHERE v.COMP_ID = c.COMP_ID)
     AND NOT EXISTS (SELECT 1 FROM TEMPLOY_VRF_REQUEST r WHERE r.COMP_ID = c.COMP_ID)
     AND NOT EXISTS (SELECT 1 FROM TPOST p WHERE p.COMP_ID = c.COMP_ID)
     AND NOT EXISTS (SELECT 1 FROM TBENEFIT_EDIT_LOG l WHERE l.COMP_ID = c.COMP_ID)
     AND NOT EXISTS (SELECT 1 FROM TCOMPANY_BENEFIT b WHERE b.COMP_ID = c.COMP_ID AND b.BADGE_CD <> 'official')
);
SELECT @lg AS lg_comp_id;

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @lg AND BADGE_CD = 'official';
DELETE FROM TCOMPANY_ALIAS WHERE COMP_ID = @lg;
DELETE FROM TCOMPANY_EMAIL_DOMAIN WHERE COMP_ID = @lg;
DELETE FROM TCOMPANY_CORP WHERE COMP_ID = @lg;
DELETE FROM TSOURCE_CHECK WHERE COMP_ID = @lg;
DELETE FROM TCOMPARE_LOG WHERE A_COMP_ID = @lg OR B_COMP_ID = @lg;
DELETE FROM TAUTH_CODE WHERE COMP_ID = @lg;
DELETE FROM TCOMPANY WHERE COMP_ID = @lg AND COMP_ENG_NM = 'lg';

COMMIT;
