-- ══════════════════════════════════════════════════════════════════════
-- 코퍼스 정리 4가지 반영 — 표적 삭제 11 · 코드 바꾸기 2 (웨이브 5 감사 후속, 2026-10-10)
-- 사용자 지시: 2026-10-10 「기존 회사 고칠 거리 4가지 진행하자」
-- 선례: db/migrations/20261005_landf_recollect.sql
--
-- 배경: 경조휴가를 event 행 하나로 합치고(휴가를 쓰라고 권하는 행 삼성생명 PlusWeek 삭제 포함) S-Oil 성과급 코드를
--   profit_sharing 으로, 비에이치 경조휴가를 event(family) 로 바꾼다. 운영 행은 전부 BADGE_CD = official 이라 시드의
--   DELETE(est 한정)가 지우지 못하고 upsert(UNIQUE (COMP_ID, BENEFIT_CD))로는 코드 바꾸기가 반영되지 않는다.
--   정본 = /home/ubuntu/loupit-evidence/2026-10-11-corpus-fix4/_ACTIONS.md
-- 운영 DB SELECT 확인(2026-10-10): 아래 13행은 각각 정확히 1행 · 전부 BADGE_CD = official(재직자 행 없음) ·
--   TBENEFIT_EDIT_LOG 는 전체 2행이고 이 13행 · 이 13개 회사에 걸린 것이 0 · 게시글(TPOST)은 BENEFIT_ID 참조 열이 없다(참조 0).
--   S-Oil 에 profit_sharing 행, 비에이치에 event 행은 아직 없어 UNIQUE 충돌이 없다.
--
-- 표적 삭제 11 (모두 leave_general · BENEFIT_ID 회사)
--   27211 samsung_life · 83021 isc · 7679 ls_electric · 251 sk_innovation · 52337 lino · 490 voronoi
--   84021 sanil_electric · 6590 alteogen · 935 caregen · 85206 kolon_industries · 85728 hansol_chemical
-- 코드 바꾸기 2 (BENEFIT_ID 유지)
--   225 s_oil incentive to profit_sharing · 49328 bh leave_general to event (카테고리 time_off to family)
-- 나머지(문안 교체 · 새 행 2: 한미약품 nap_room · 현대제철 event)는 적재(load.py)가 한다.
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 to python3 db/seed/load.py to release.
--
-- web/assets 변경 없음 — git pull 만으로 라이브가 바뀌지 않는다.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   0) 머지 → git pull
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 참조 9테이블을 뜬다
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: 1회차 DELETE 11문 · UPDATE 2문 각각 1 row affected · 2회차 전부 0 · 적재 뒤 전체 3463행 · 회사 160.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 표적 삭제 (11) — 경조휴가는 event 행 서술로 · 삼성생명은 휴가를 쓰라고 권하는 행 ──
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 27211 AND c.COMP_ENG_NM = 'samsung_life' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 83021 AND c.COMP_ENG_NM = 'isc' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 7679 AND c.COMP_ENG_NM = 'ls_electric' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 251 AND c.COMP_ENG_NM = 'sk_innovation' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 52337 AND c.COMP_ENG_NM = 'lino' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 490 AND c.COMP_ENG_NM = 'voronoi' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 84021 AND c.COMP_ENG_NM = 'sanil_electric' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 6590 AND c.COMP_ENG_NM = 'alteogen' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 935 AND c.COMP_ENG_NM = 'caregen' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 85206 AND c.COMP_ENG_NM = 'kolon_industries' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 85728 AND c.COMP_ENG_NM = 'hansol_chemical' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';

-- ── 코드 바꾸기 (2) — BENEFIT_ID 유지 ──
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'profit_sharing'
 WHERE b.BENEFIT_ID = 225 AND c.COMP_ENG_NM = 's_oil' AND b.BENEFIT_CD = 'incentive' AND b.BADGE_CD = 'official';
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'event', b.BENEFIT_CTGR_CD = 'family'
 WHERE b.BENEFIT_ID = 49328 AND c.COMP_ENG_NM = 'bh' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';

COMMIT;
