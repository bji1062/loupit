-- ══════════════════════════════════════════════════════════════════════
-- 근거 URL 없는 회사 재수집 R-3 묶음 2 (10사) 반영 — 표적 삭제 17 · 코드 바꾸기 5 (LG 지주는 후속 PR)
-- 사용자 결정: 2026-09-28 (근거 주소 없는 곳은 표시를 바꾸지 말고 다시 모은다)
--             2026-10-01 (LG 지주는 공식 원문이 없다 — 복지 0행 화면 처리와 함께 후속 PR 에서 지운다. 이 파일은 LG 를 건드리지 않는다)
-- 선례: db/migrations/20260928_recollect_3_batch1.sql
--
-- 배경: 2026-04-15 초기 AI 파싱으로 등록돼 근거 URL 이 없던 10사를 공식 출처에서 다시 세웠다
--   (수집 Opus ×10 → 적대 검증 Opus 레인 5). 하이브 구본은 다른 회사(하이브로) 데이터였다.
--   정본 = /home/ubuntu/loupit-evidence/2026-10-01-recollect-3-2/ (verify/_ACTIONS-1~5.md §3 이 이 파일의 입력).
--   새 시드 9파일은 같은 PR 에서 바뀐다(134 → 230행, 전체 2609 → 2705). LG.sql 은 그대로다.
--
-- 무엇을 바꾸나:
--   · 표적 삭제 — 운영 행은 전부 BADGE_CD = official 이라 시드의 DELETE(est 한정)가 지우지 못한다.
--     공식 원문에 근거가 없어 새 시드에서 빠진 행만 지운다.
--   · 코드 바꾸기 — 같은 제도의 코드만 바꿔 행 번호를 잇는다. 명칭 · 금액 · 카테고리 · 설명은 이어지는
--     적재(load.py)가 새 시드 값으로 덮는다. 새 코드는 그 회사 운영 행에 없다(uq 충돌 0, 2026-10-01 스냅숏).
--   9사에 재직자 행 · 편집 이력은 없다(134행 전부 official).
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--   적재를 먼저 돌리면 새 코드 행이 먼저 생겨 UPDATE 가 uq_comp_benefit 중복 키로 실패하고 옛 행이 남는다.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 9테이블을 뜬다
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: UPDATE 5문 각각 Rows matched 1 Changed 1 · DELETE 17문 각각 1 row affected · 두 번째 실행은 0 ·
--   적재 뒤 전체 2705행.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 코드 바꾸기 (5) ──
-- lg_energy 104: summer_leave → refresh_leave · 5일 리프레쉬휴가 — 같은 제도
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'refresh_leave'
 WHERE b.BENEFIT_ID = 104 AND c.COMP_ENG_NM = 'lg_energy' AND b.BENEFIT_CD = 'summer_leave' AND b.BADGE_CD = 'official';
-- kakao_games 865: self_development → welfare_point · 복지 포인트 연 360만원 카드 — 배정형
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'welfare_point'
 WHERE b.BENEFIT_ID = 865 AND c.COMP_ENG_NM = 'kakao_games' AND b.BENEFIT_CD = 'self_development' AND b.BADGE_CD = 'official';
-- samsung_life 551: edu_support → self_development · 전문자격 취득 지원을 잇는다
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'self_development'
 WHERE b.BENEFIT_ID = 551 AND c.COMP_ENG_NM = 'samsung_life' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- pharma_research 1048: massage → lounge · 원문 주어가 휴식 공간
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'lounge'
 WHERE b.BENEFIT_ID = 1048 AND c.COMP_ENG_NM = 'pharma_research' AND b.BENEFIT_CD = 'massage' AND b.BADGE_CD = 'official';
-- pharma_research 1039: refresh_leave → leave_general · 하계 · 연말 단체 휴가 — 부여 조건 불명 집중휴가, 법정 등록 해제
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'leave_general'
 WHERE b.BENEFIT_ID = 1039 AND c.COMP_ENG_NM = 'pharma_research' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';

-- ── 표적 삭제 (17) ──
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 116 AND c.COMP_ENG_NM = 'lg_uplus' AND b.BENEFIT_CD = 'holiday_gift' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 124 AND c.COMP_ENG_NM = 'lg_uplus' AND b.BENEFIT_CD = 'lang' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 110 AND c.COMP_ENG_NM = 'lg_energy' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 151 AND c.COMP_ENG_NM = 'lg_chem' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 153 AND c.COMP_ENG_NM = 'lg_chem' AND b.BENEFIT_CD = 'lang' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1092 AND c.COMP_ENG_NM = 'hybe' AND b.BENEFIT_CD = 'stock_option' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1095 AND c.COMP_ENG_NM = 'hybe' AND b.BENEFIT_CD = 'family_day' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1098 AND c.COMP_ENG_NM = 'hybe' AND b.BENEFIT_CD = 'welcome_kit' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 861 AND c.COMP_ENG_NM = 'kakao_games' AND b.BENEFIT_CD = 'fitness' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 542 AND c.COMP_ENG_NM = 'samsung_life' AND b.BENEFIT_CD = 'excellence_award' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 544 AND c.COMP_ENG_NM = 'samsung_life' AND b.BENEFIT_CD = 'long_service_leave' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 556 AND c.COMP_ENG_NM = 'samsung_life' AND b.BENEFIT_CD = 'housing_loan' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1045 AND c.COMP_ENG_NM = 'pharma_research' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1311 AND c.COMP_ENG_NM = 'hugel' AND b.BENEFIT_CD = 'lang' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 357 AND c.COMP_ENG_NM = 'nepes' AND b.BENEFIT_CD = 'nap_room' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 361 AND c.COMP_ENG_NM = 'nepes' AND b.BENEFIT_CD = 'fitness' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 365 AND c.COMP_ENG_NM = 'nepes' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';

COMMIT;
