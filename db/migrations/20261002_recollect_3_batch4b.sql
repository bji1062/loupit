-- ══════════════════════════════════════════════════════════════════════
-- 근거 URL 없는 회사 재수집 R-3 묶음 4-B (현대 3사) 반영 — 표적 삭제 6 · 코드 바꾸기 2
-- 사용자 결정: 2026-09-28 (근거 주소 없는 곳은 표시를 바꾸지 말고 다시 모은다)
--             2026-10-02 (현대 3사 공식 채용 사이트 본문을 사용자가 직접 붙여 넣음 · 「합산 = 공식 수치」)
-- 선례: db/migrations/20261002_recollect_3_batch4a.sql
--
-- 배경: 2026-04-15 초기 AI 파싱으로 등록돼 근거 URL 이 없던 현대로템 · 현대제철 · 현대글로비스를
--   사용자가 붙여 넣은 공식 채용 사이트 원문(recruiter.co.kr, 로봇 차단 사이트)에서 다시 세웠다
--   (수집 Opus → 적대 검증 Opus 레인 1 · 2b).
--   정본 = /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-4/ (verify/_ACTIONS-1.md · _ACTIONS-2b.md §3 이 이 파일의 입력).
--   새 시드 3파일은 같은 PR 에서 바뀐다(40 → 69행, 전체 2832 → 2861). 로템 29 · 제철 28 · 글로비스 12.
--
-- 무엇을 바꾸나:
--   · 표적 삭제 — 운영 행은 전부 BADGE_CD = official 이라 시드의 DELETE(est 한정)가 지우지 못한다.
--     공식 원문에 근거가 없어 새 시드에서 빠진 행만 지운다.
--   · 코드 바꾸기 — 같은 제도의 코드만 바꿔 행 번호를 잇는다. 명칭 · 금액 · 카테고리 · 설명은 이어지는
--     적재(load.py)가 새 시드 값으로 덮는다. 새 코드는 그 회사 운영 행에 없다(uq 충돌 0, 2026-10-02 스냅숏).
--   3사에 재직자 행 · 편집 이력은 없다(40행 전부 official).
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--   적재를 먼저 돌리면 새 코드 행이 먼저 생겨 UPDATE 가 uq_comp_benefit 중복 키로 실패하고 옛 행이 남는다.
--
-- 🚨 이 PR 은 web/assets/js/legal.js 를 바꾼다(현대제철 「출산/육아」 법정 등록 해제). web/assets 는 라이브 docroot 라
--   git pull 하는 순간 바로 라이브가 된다 — 아래 pull → 백업 → 마이그레이션 → load.py → release 를 끊지 않고 잇는다
--   (묶음 2 20261001_recollect_3_batch2.sql 의 같은 경고).
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   0) 머지 → git pull — pull 하는 순간 legal.js 가 라이브가 되므로 아래 1~4 를 release 까지 멈추지 않고 잇는다
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 9테이블을 뜬다
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: UPDATE 2문 각각 Rows matched 1 Changed 1 · DELETE 6문 각각 1 row affected · 두 번째 실행은 0 ·
--   적재 뒤 전체 2861행.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 코드 바꾸기 (2) ──
-- hyundai_rotem 1196: long_service_leave → long_service_bonus · 「장기 근속자 포상」 — 휴가 낱말 없음
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'long_service_bonus'
 WHERE b.BENEFIT_ID = 1196 AND c.COMP_ENG_NM = 'hyundai_rotem' AND b.BENEFIT_CD = 'long_service_leave' AND b.BADGE_CD = 'official';
-- hyundai_steel 1278: refresh_leave → summer_leave · 남는 제도 = 「유급 하기휴가(5일)」 (Refresh 는 법정 휴가 사용)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'summer_leave'
 WHERE b.BENEFIT_ID = 1278 AND c.COMP_ENG_NM = 'hyundai_steel' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';

-- ── 표적 삭제 (6) ──
-- hyundai_rotem 1201 edu_support · 1202 lang — 회사 교육 · 어학 과정(규칙 8)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1201 AND c.COMP_ENG_NM = 'hyundai_rotem' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1202 AND c.COMP_ENG_NM = 'hyundai_rotem' AND b.BENEFIT_CD = 'lang' AND b.BADGE_CD = 'official';
-- hyundai_steel 1279 long_service_bonus — 붙여넣기 원문 · 2026 · 2025 보고서에 장기근속 포상 문장 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1279 AND c.COMP_ENG_NM = 'hyundai_steel' AND b.BENEFIT_CD = 'long_service_bonus' AND b.BADGE_CD = 'official';
-- hyundai_glovis 1184 incentive(공시 문장은 사내이사 전용) · 1185 refresh_leave(추가 부여 · 일수 없음) · 1191 edu_support(원문 없음)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1184 AND c.COMP_ENG_NM = 'hyundai_glovis' AND b.BENEFIT_CD = 'incentive' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1185 AND c.COMP_ENG_NM = 'hyundai_glovis' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1191 AND c.COMP_ENG_NM = 'hyundai_glovis' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';

COMMIT;
