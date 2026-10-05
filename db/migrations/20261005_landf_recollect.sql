-- ══════════════════════════════════════════════════════════════════════
-- 엘앤에프 재수집(출처 이전) 반영 — 표적 삭제 11 · 코드 바꾸기 0 (R-3 후속 6)
-- 사용자 결정: 2026-10-05 (옛 채용 사이트 전용 12건 모두 빼기 · 새 복리후생 제도 소개 붙여넣기)
-- 선례: db/migrations/20261004_recollect_3_batch6b.sql
--
-- 배경: 엘앤에프(landf)의 정본 출처가 옛 채용 사이트 recruit.landf.co.kr 에서 새 복리후생 제도 소개
--   https://landf.recruiter.co.kr/career/culture 로 옮겨졌다. 새 시드는 20 → 13행(-11 + 4)이다.
--   운영 20행(BENEFIT_ID 8336~8355)은 전부 BADGE_CD = official 이라 시드의 DELETE(est 한정)가 지우지 못한다.
--   새 소개에 없는 옛 사이트 전용 11행만 표적 삭제한다(재직자 행 · 편집 이력 · 게시글 참조 0).
--   정본 = /home/ubuntu/loupit-evidence/2026-10-05-hold-recollect/ (verify/REVIEW-LANDF.md §7 · §8).
-- 코드 바꾸기 0. 남는 9행(8337 · 8338 · 8344 · 8346 · 8347 · 8348 · 8351 · 8353 · 8355)은 적재(load.py)의 upsert 가 덮고,
--   새 4행(excellence_award · welfare_point · discount · edu_support)은 적재가 넣는다. 전체 3186 → 3179 · 회사 147 그대로.
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--
-- web/assets 변경 없음 — git pull 만으로 라이브가 바뀌지 않는다.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   0) 머지 → git pull
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 참조 9테이블을 뜬다
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: DELETE 11문 각각 1 row affected · 두 번째 실행은 0 · 적재 뒤 전체 3179행 · 회사 147.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 표적 삭제 (11) — 옛 채용 사이트 recruit.landf.co.kr 전용 · 새 복리후생 제도 소개에 없음 ──
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 8336 AND c.COMP_ENG_NM = 'landf' AND b.BENEFIT_CD = 'long_service_bonus' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 8339 AND c.COMP_ENG_NM = 'landf' AND b.BENEFIT_CD = 'remote_work' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 8340 AND c.COMP_ENG_NM = 'landf' AND b.BENEFIT_CD = 'foundation_day_leave' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 8341 AND c.COMP_ENG_NM = 'landf' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 8342 AND c.COMP_ENG_NM = 'landf' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 8343 AND c.COMP_ENG_NM = 'landf' AND b.BENEFIT_CD = 'long_service_leave' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 8345 AND c.COMP_ENG_NM = 'landf' AND b.BENEFIT_CD = 'medical' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 8349 AND c.COMP_ENG_NM = 'landf' AND b.BENEFIT_CD = 'lounge' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 8350 AND c.COMP_ENG_NM = 'landf' AND b.BENEFIT_CD = 'resort' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 8352 AND c.COMP_ENG_NM = 'landf' AND b.BENEFIT_CD = 'club' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 8354 AND c.COMP_ENG_NM = 'landf' AND b.BENEFIT_CD = 'commute_subsidy' AND b.BADGE_CD = 'official';

COMMIT;
