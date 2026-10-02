-- ══════════════════════════════════════════════════════════════════════
-- 근거 URL 없는 회사 재수집 R-3 묶음 4-A (그룹 계열 7사) 반영 — 표적 삭제 6 · 코드 바꾸기 3 (현대로템 · 현대제철 · 현대글로비스는 묶음 4-B)
-- 사용자 결정: 2026-09-28 (근거 주소 없는 곳은 표시를 바꾸지 말고 다시 모은다)
--             2026-10-02 (「묶음 4 시작해줘」 · 현대 3사는 사용자 원문 붙여넣기 대기 → 4-B 로 따로 한다)
-- 선례: db/migrations/20261001_recollect_3_batch3.sql
--
-- 배경: 2026-04-15 초기 AI 파싱으로 등록돼 근거 URL 이 없던 회사 중 그룹 계열 7사를 공식 출처에서 다시 세웠다
--   (수집 Opus ×10 → 적대 검증 Opus 레인 5 중 이 7사). 현대오토에버 · 현대무벡스 · LG디스플레이 · 삼성전기 · 삼성SDI · 삼성물산 · 삼성바이오로직스.
--   정본 = /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-4/ (verify/_ACTIONS-2~5.md 가 이 파일의 입력).
--   새 시드 7파일은 같은 PR 에서 바뀐다(88 → 210행, 전체 2710 → 2832). 현대로템 · 현대제철 · 현대글로비스 시드는 그대로다.
--
-- 무엇을 바꾸나:
--   · 표적 삭제 — 운영 행은 전부 BADGE_CD = official 이라 시드의 DELETE(est 한정)가 지우지 못한다.
--     공식 원문에 근거가 없어 새 시드에서 빠진 행만 지운다.
--   · 코드 바꾸기 — 같은 제도의 코드만 바꿔 행 번호를 잇는다. 명칭 · 금액 · 카테고리 · 설명은 이어지는
--     적재(load.py)가 새 시드 값으로 덮는다. 새 코드는 그 회사 운영 행에 없다(uq 충돌 0, 2026-10-02 스냅숏).
--   7사에 재직자 행 · 편집 이력은 없다(88행 전부 official).
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--   적재를 먼저 돌리면 새 코드 행이 먼저 생겨 UPDATE 가 uq_comp_benefit 중복 키로 실패하고 옛 행이 남는다.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   0) 머지 → git pull — pull 하는 순간 web/assets 가 라이브가 되므로(find.js 가 바뀌면 특히) 아래 1~4 를 release 까지 멈추지 않고 잇는다
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 9테이블을 뜬다
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: UPDATE 3문 각각 Rows matched 1 Changed 1 · DELETE 6문 각각 1 row affected · 두 번째 실행은 0 ·
--   적재 뒤 전체 2832행.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 코드 바꾸기 (3) ──
-- hyundai_autoever 1243: refresh_leave → summer_leave · 「하계 휴가」 추가 5일 — 검증 수용(기준 18 은 이름 없는 가산 휴가만)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'summer_leave'
 WHERE b.BENEFIT_ID = 1243 AND c.COMP_ENG_NM = 'hyundai_autoever' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';
-- hyundai_muvex 1228: long_service_bonus → long_service_leave · 원문 「포상금 및 휴가」 — 9월 22일 재코딩의 반대 방향
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'long_service_leave'
 WHERE b.BENEFIT_ID = 1228 AND c.COMP_ENG_NM = 'hyundai_muvex' AND b.BENEFIT_CD = 'long_service_bonus' AND b.BADGE_CD = 'official';
-- lg_display 89: summer_leave → refresh_leave · 「Refresh 휴가 4일」
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'refresh_leave'
 WHERE b.BENEFIT_ID = 89 AND c.COMP_ENG_NM = 'lg_display' AND b.BENEFIT_CD = 'summer_leave' AND b.BADGE_CD = 'official';

-- ── 표적 삭제 (6) ──
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 96 AND c.COMP_ENG_NM = 'lg_display' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 562 AND c.COMP_ENG_NM = 'samsung_electro' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 513 AND c.COMP_ENG_NM = 'samsung_sdi' AND b.BENEFIT_CD = 'lang' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 514 AND c.COMP_ENG_NM = 'samsung_sdi' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 535 AND c.COMP_ENG_NM = 'samsung_bio' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 538 AND c.COMP_ENG_NM = 'samsung_bio' AND b.BENEFIT_CD = 'library' AND b.BADGE_CD = 'official';

COMMIT;
