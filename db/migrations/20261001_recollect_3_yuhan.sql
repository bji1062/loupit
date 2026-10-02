-- ══════════════════════════════════════════════════════════════════════
-- 근거 URL 없는 회사 재수집 R-3 묶음 3 후속 — 유한양행 반영 — 표적 삭제 3 · 코드 바꾸기 3
-- 사용자 결정: 2026-10-01 (유한양행 = 사용자가 공식 채용 사이트 복리후생 · 교육 본문을 브라우저로 붙여 넣는다)
-- 선례: db/migrations/20261001_recollect_3_batch3.sql
--
-- 배경: 유한양행은 구본(17행)이 2026-04-15 초기 AI 파싱이었고 근거 URL 이 없었다. 사용자가 붙여 넣은 공식 채용 사이트
--   원문 2쪽(복리후생 · 교육)으로 수집 → 적대 검증(Opus)해 17 → 22행으로 다시 세웠다.
--   정본 = /home/ubuntu/loupit-evidence/2026-10-01-recollect-3-3/ (verify/_ACTIONS-4b.md 운영 반영 표가 이 파일의 입력).
--   새 시드(유한양행.sql 22행)는 같은 PR 에서 바뀐다(전체 2705 → 2710).
--
-- 무엇을 바꾸나:
--   · 표적 삭제 — 운영 행은 전부 BADGE_CD = official 이라 시드의 DELETE(est 한정)가 지우지 못한다.
--     공식 원문에 근거가 없어 새 시드에서 빠진 행만 지운다(793 edu_support · 795 lang · 799 housing_loan).
--   · 코드 바꾸기 — 같은 제도의 코드만 바꿔 행 번호를 잇는다(787 · 796 · 800). 명칭 · 금액 · 카테고리 · 설명은 이어지는
--     적재(load.py)가 새 시드 값으로 덮는다. 새 코드는 유한양행 운영 행에 없다(uq 충돌 0, 2026-10-01 스냅숏).
--     796 books → library 는 growth → leisure 라 BENEFIT_CTGR_CD 도 함께 바꾼다.
--   유한양행에 재직자 행 · 편집 이력은 없다(17행 전부 official).
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--   적재를 먼저 돌리면 새 코드 행이 먼저 생겨 UPDATE 가 uq_comp_benefit 중복 키로 실패하고 옛 행이 남는다.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   0) 머지 → git pull — pull 하는 순간 web/assets/js/find.js 가 라이브가 되므로 아래 1~4 를 release 까지 멈추지 않고 잇는다
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 9테이블을 뜬다
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: UPDATE 3문 각각 Rows matched 1 Changed 1 · DELETE 3문 각각 1 row affected · 두 번째 실행은 0 ·
--   적재 뒤 전체 2710행 · 회사 148.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 코드 바꾸기 (3) ──
-- yuhan 787: leave_general → refresh_leave · 연차휴가 22일(최대 32일) → 추가 휴가 7일 (최대 32일) — 검증 확정
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'refresh_leave'
 WHERE b.BENEFIT_ID = 787 AND c.COMP_ENG_NM = 'yuhan' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
-- yuhan 796: books → library · 버들전자도서관 — 같은 제도의 코드만 바꾼다(growth → leisure)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'library', b.BENEFIT_CTGR_CD = 'leisure'
 WHERE b.BENEFIT_ID = 796 AND c.COMP_ENG_NM = 'yuhan' AND b.BENEFIT_CD = 'books' AND b.BADGE_CD = 'official';
-- yuhan 800: transport → commute_subsidy · 통근버스 — 검증 확정
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'commute_subsidy'
 WHERE b.BENEFIT_ID = 800 AND c.COMP_ENG_NM = 'yuhan' AND b.BENEFIT_CD = 'transport' AND b.BADGE_CD = 'official';

-- ── 표적 삭제 (3) ──
-- 793 edu_support: 교육 과정은 행이 아니다(규칙 8) · 795 lang: 어학 비용 문장 없음 · 799 housing_loan: 용도 미기재 대출은 싣지 않는다(기준 13, 리드 판정)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 793 AND c.COMP_ENG_NM = 'yuhan' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 795 AND c.COMP_ENG_NM = 'yuhan' AND b.BENEFIT_CD = 'lang' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 799 AND c.COMP_ENG_NM = 'yuhan' AND b.BENEFIT_CD = 'housing_loan' AND b.BADGE_CD = 'official';

COMMIT;
