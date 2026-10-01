-- ══════════════════════════════════════════════════════════════════════
-- 근거 URL 없는 회사 재수집 R-3 묶음 3 (8사) 반영 — 표적 삭제 32 · 코드 바꾸기 6 (LS 는 후속 PR 에서 등록 해제 · 유한양행은 사용자 원문 대기)
-- 사용자 결정: 2026-09-28 (근거 주소 없는 곳은 표시를 바꾸지 말고 다시 모은다)
--             2026-10-01 (LS = 등록 해제 후속 PR · 유한양행 = 사용자가 ATS 복리후생 본문을 붙여 넣는다 · 이 파일은 둘을 건드리지 않는다)
-- 선례: db/migrations/20261001_recollect_3_batch2.sql
--
-- 배경: 2026-04-15 초기 AI 파싱으로 등록돼 근거 URL 이 없던 회사 중 8사를 공식 출처에서 다시 세웠다
--   (수집 Opus ×10 → 적대 검증 Opus 레인 5). 위메이드 구본은 위메이드플레이, LS 구본은 다른 법인 데이터였다.
--   정본 = /home/ubuntu/loupit-evidence/2026-10-01-recollect-3-3/ (verify/_ACTIONS-1~5.md · 1b §2 이 이 파일의 입력).
--   새 시드 8파일은 같은 PR 에서 바뀐다(128 → 150행, 전체 2691 → 2713). LS.sql · 유한양행.sql 은 그대로다.
--
-- 무엇을 바꾸나:
--   · 표적 삭제 — 운영 행은 전부 BADGE_CD = official 이라 시드의 DELETE(est 한정)가 지우지 못한다.
--     공식 원문에 근거가 없어 새 시드에서 빠진 행만 지운다.
--   · 코드 바꾸기 — 같은 제도의 코드만 바꿔 행 번호를 잇는다. 명칭 · 금액 · 카테고리 · 설명은 이어지는
--     적재(load.py)가 새 시드 값으로 덮는다. 새 코드는 그 회사 운영 행에 없다(uq 충돌 0, 2026-10-01 스냅숏).
--   8사에 재직자 행 · 편집 이력은 없다(128행 전부 official).
--   위메이드 773 club 은 지우지 않고 적재가 덮어쓴다(1b 최종본에 club 이 다시 선다).
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
-- 기대: UPDATE 6문 각각 Rows matched 1 Changed 1 · DELETE 32문 각각 1 row affected · 두 번째 실행은 0 ·
--   적재 뒤 전체 2713행.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 코드 바꾸기 (6) ──
-- park_systems 1063: fertility_support → parenting · 출산 축하금 → 출산 축하금·산후조리비용 지원 — 검증 확정
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'parenting'
 WHERE b.BENEFIT_ID = 1063 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'fertility_support' AND b.BADGE_CD = 'official';
-- tck 1018: incentive → profit_sharing · 영업이익 초과 인센티브 — 검증 확정
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'profit_sharing'
 WHERE b.BENEFIT_ID = 1018 AND c.COMP_ENG_NM = 'tck' AND b.BENEFIT_CD = 'incentive' AND b.BADGE_CD = 'official';
-- tck 1020: library → leisure_room · 사내 영화관 — 검증 T-1 · 리드 판정 ②
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'leisure_room'
 WHERE b.BENEFIT_ID = 1020 AND c.COMP_ENG_NM = 'tck' AND b.BENEFIT_CD = 'library' AND b.BADGE_CD = 'official';
-- hmm 38: edu_support → self_development · 직무/리더십 교육 → 전문자격 취득 지원 — 검증 레인 4 확정
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'self_development'
 WHERE b.BENEFIT_ID = 38 AND c.COMP_ENG_NM = 'hmm' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- com2us 917: leave_general → foundation_day_leave · 창립기념일 대체 휴무
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'foundation_day_leave'
 WHERE b.BENEFIT_ID = 917 AND c.COMP_ENG_NM = 'com2us' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
-- cj 11: books → library · 같은 제도의 코드만 바꾼다(growth → leisure) — 검증 레인 3 확정
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'library'
 WHERE b.BENEFIT_ID = 11 AND c.COMP_ENG_NM = 'cj' AND b.BENEFIT_CD = 'books' AND b.BADGE_CD = 'official';

-- ── 표적 삭제 (32) ──
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1053 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'incentive' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1054 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'stock_option' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1056 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'remote_work' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1057 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'work_tools' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1058 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'parking' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1060 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'health_check' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1064 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'event' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1065 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1067 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'mba' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1068 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'library' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1069 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'club' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1070 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'welfare_point' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1072 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'snack_bar' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1073 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'telecom' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1074 AND c.COMP_ENG_NM = 'park_systems' AND b.BENEFIT_CD = 'holiday_gift' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1027 AND c.COMP_ENG_NM = 'tck' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 39 AND c.COMP_ENG_NM = 'hmm' AND b.BENEFIT_CD = 'lang' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 814 AND c.COMP_ENG_NM = 'jlk' AND b.BENEFIT_CD = 'flex_work' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 818 AND c.COMP_ENG_NM = 'jlk' AND b.BENEFIT_CD = 'club' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 819 AND c.COMP_ENG_NM = 'jlk' AND b.BENEFIT_CD = 'meal' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 915 AND c.COMP_ENG_NM = 'com2us' AND b.BENEFIT_CD = 'holiday_gift' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 918 AND c.COMP_ENG_NM = 'com2us' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 920 AND c.COMP_ENG_NM = 'com2us' AND b.BENEFIT_CD = 'birthday_gift' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 925 AND c.COMP_ENG_NM = 'com2us' AND b.BENEFIT_CD = 'event' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 763 AND c.COMP_ENG_NM = 'wemade' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 764 AND c.COMP_ENG_NM = 'wemade' AND b.BENEFIT_CD = 'birthday_leave' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 771 AND c.COMP_ENG_NM = 'wemade' AND b.BENEFIT_CD = 'books' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 774 AND c.COMP_ENG_NM = 'wemade' AND b.BENEFIT_CD = 'welcome_kit' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 777 AND c.COMP_ENG_NM = 'wemade' AND b.BENEFIT_CD = 'housing_loan' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 779 AND c.COMP_ENG_NM = 'wemade' AND b.BENEFIT_CD = 'discount' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1 AND c.COMP_ENG_NM = 'cj' AND b.BENEFIT_CD = 'remote_work' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 8 AND c.COMP_ENG_NM = 'cj' AND b.BENEFIT_CD = 'childcare' AND b.BADGE_CD = 'official';

COMMIT;
