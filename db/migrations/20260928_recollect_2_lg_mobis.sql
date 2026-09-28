-- ══════════════════════════════════════════════════════════════════════
-- 출처가 끊긴 2개사 재수집 반영 — LG전자 코드 바꾸기 2 (삭제 0)
-- 사용자 결정: 2026-09-27 (LG전자랑 현대모비스 새 출처 찾아서 진행해)
-- 선례: db/migrations/20260926_recollect_9_official.sql
--
-- 배경: 두 회사의 근거 URL 이 끊겼다(2026-09-27 출처 주간 점검 첫 실행 — LG전자 404 · 현대모비스 NXDOMAIN).
--   공식 출처에서 다시 수집했다(수집 Opus ×2 → 적대 검증 Fable, 반박 1 · 누락 2 반영).
--   새 정본: LG전자 www.lge.co.kr/company/recruit/hr · 현대모비스 careers.mobis.com/life (도메인 mobis.com 이전).
--   정본 = /home/ubuntu/loupit-evidence/2026-09-27-recollect-2/ (검증 verify/_ACTIONS.md §3 이 이 파일의 입력).
--   새 시드 2파일은 같은 PR 에서 바뀐다(15 → 26 · 18 → 34행, 전체 2503 → 2530).
--
-- 무엇을 바꾸나: LG전자 두 행의 코드만 바꿔 행 번호를 잇는다. 명칭 · 금액 · 카테고리 · 설명은 이어지는
--   적재(load.py)가 새 시드 값으로 덮는다. 표적 삭제는 없다 — 두 회사의 구본 코드가 새 시드에 모두 이어진다.
--   · 129 bonus → incentive (원문 임금체계의 인센티브 · 성과급은 profit_sharing 새 행)
--   · 132 leave_general → summer_leave (원문 여름휴가)
--   새 코드는 LG전자 운영 행에 없다(uq 충돌 0). 두 회사 재직자 편집 이력 0건.
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--   적재를 먼저 돌리면 새 코드 행이 먼저 생겨 이 UPDATE 가 uq_comp_benefit 중복 키로 실패하고 옛 행이 남는다.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 9테이블을 뜬다
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: UPDATE 2문 각각 Rows matched 1 Changed 1 · 두 번째 실행은 0 · 적재 뒤 전체 2530행.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- LG전자
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'incentive'
 WHERE b.BENEFIT_ID = 129 AND c.COMP_ENG_NM = 'lg_elec' AND b.BENEFIT_CD = 'bonus' AND b.BADGE_CD = 'official';
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'summer_leave'
 WHERE b.BENEFIT_ID = 132 AND c.COMP_ENG_NM = 'lg_elec' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';

COMMIT;
