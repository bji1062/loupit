-- ══════════════════════════════════════════════════════════════════════
-- 근거 URL 없는 회사 재수집 R-3 묶음 5 (한화 4 · 두산 2 · 에코프로 2 · 올릭스 · 솔브레인) 반영 — 표적 삭제 28 · 코드 바꾸기 5
-- 사용자 결정: 2026-09-28 (근거 주소 없는 곳은 표시를 바꾸지 말고 다시 모은다)
--             2026-10-02 (「묶음 5 시작해줘」)
-- 선례: db/migrations/20261002_recollect_3_batch4b.sql
--
-- 배경: 2026-04-15 초기 AI 파싱으로 등록돼 근거 URL 이 없던 10개사를 공식 출처에서 다시 세웠다
--   (수집 Opus × 10 → 적대 검증 Opus 레인 1~5).
--   정본 = /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-5/ (verify/_ACTIONS-1.md ~ _ACTIONS-5.md §3 이 이 파일의 입력).
--   새 시드 10파일은 같은 PR 에서 바뀐다(135 → 242행, 전체 2861 → 2968).
--   한화 39 · 한화에어로스페이스 20 · 한화시스템 30 · 한화오션 24 · ㈜두산 12 · 두산에너빌리티 34 · ㈜에코프로 19 · 에코프로비엠 21 · 올릭스 13 · 솔브레인 30.
--   ㈜두산 구본 12행은 두산매거진 데이터라 폐기 — 같은 코드 4행(422 · 423 · 427 · 429)은 적재가 덮어쓰고 나머지 8행은 아래 표적 삭제.
--
-- 무엇을 바꾸나:
--   · 코드 바꾸기 — 같은 제도의 코드만 바꿔 행 번호를 잇는다. 명칭 · 금액 · 카테고리 · 설명은 이어지는
--     적재(load.py)가 새 시드 값으로 덮는다. 새 코드는 그 회사 운영 행에 없다(uq 충돌 0, 2026-10-02 스냅숏).
--   · 표적 삭제 — 운영 행은 전부 BADGE_CD = official 이라 시드의 DELETE(est 한정)가 지우지 못한다.
--     공식 원문에 근거가 없어 새 시드에서 빠진 행만 지운다.
--   10사에 재직자 행 · 편집 이력은 없다(135행 전부 official).
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--   적재를 먼저 돌리면 새 코드 행이 먼저 생겨 UPDATE 가 uq_comp_benefit 중복 키로 실패하고 옛 행이 남는다.
--
-- 🚨 이 PR 은 web/assets/js/legal.js 를 바꾼다(한화시스템 · 한화에어로스페이스 parenting 법정 등록 해제). web/assets 는 라이브 docroot 라
--   git pull 하는 순간 바로 라이브가 된다 — 아래 pull → 백업 → 마이그레이션 → load.py → release 를 끊지 않고 잇는다
--   (묶음 3 · 유한양행 · 4-A · 4-B 마이그레이션 머리말 「0) 머지 → git pull」 줄과 같은 경고).
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   0) 머지 → git pull — pull 하는 순간 legal.js 가 라이브가 되므로 아래 1~4 를 release 까지 멈추지 않고 잇는다
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 9테이블을 뜬다
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: UPDATE 5문 각각 Rows matched 1 Changed 1 · DELETE 28문 각각 1 row affected · 두 번째 실행은 0 ·
--   적재 뒤 전체 2968행.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 코드 바꾸기 (5) ──
-- hanwha 1136: long_service_bonus → long_service_leave · 장기근속 포상+휴가 한 줄(건설부문 원문) — SPEC 20 경계: 휴가와 포상이 한 줄이면 long_service_leave
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'long_service_leave'
 WHERE b.BENEFIT_ID = 1136 AND c.COMP_ENG_NM = 'hanwha' AND b.BENEFIT_CD = 'long_service_bonus' AND b.BADGE_CD = 'official';
-- hanwha_systems 1159: edu_support → mba · 남는 제도 = 재직 중 석 · 박사 학위 과정(규칙 8-1)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'mba'
 WHERE b.BENEFIT_ID = 1159 AND c.COMP_ENG_NM = 'hanwha_systems' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- ecopro 696: long_service_leave → long_service_bonus · 장기근속 포상 — 휴가 낱말 없음(time_off → compensation 은 적재가 덮는다)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'long_service_bonus'
 WHERE b.BENEFIT_ID = 696 AND c.COMP_ENG_NM = 'ecopro' AND b.BENEFIT_CD = 'long_service_leave' AND b.BADGE_CD = 'official';
-- ecopro 705: relocation → housing_support · 주거지원금
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'housing_support'
 WHERE b.BENEFIT_ID = 705 AND c.COMP_ENG_NM = 'ecopro' AND b.BENEFIT_CD = 'relocation' AND b.BADGE_CD = 'official';
-- olix 750: leave_general → refresh_leave · 연간 휴가 총 20일(총량 표기)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'refresh_leave'
 WHERE b.BENEFIT_ID = 750 AND c.COMP_ENG_NM = 'olix' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';

-- ── 표적 삭제 (28) ──
-- hanwha 1137 medical — 현행 원문 0 — 의료비는 단체상해보험(insurance) 한 줄
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1137 AND c.COMP_ENG_NM = 'hanwha' AND b.BENEFIT_CD = 'medical' AND b.BADGE_CD = 'official';
-- hanwha 1138 mental — 현행 원문 0
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1138 AND c.COMP_ENG_NM = 'hanwha' AND b.BENEFIT_CD = 'mental' AND b.BADGE_CD = 'official';
-- hanwha 1147 housing_loan — 현행 원문 0
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1147 AND c.COMP_ENG_NM = 'hanwha' AND b.BENEFIT_CD = 'housing_loan' AND b.BADGE_CD = 'official';
-- hanwha_aerospace 1170 event — 현행 원문 0
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1170 AND c.COMP_ENG_NM = 'hanwha_aerospace' AND b.BENEFIT_CD = 'event' AND b.BADGE_CD = 'official';
-- hanwha_aerospace 1172 books — 현행 원문 0
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1172 AND c.COMP_ENG_NM = 'hanwha_aerospace' AND b.BENEFIT_CD = 'books' AND b.BADGE_CD = 'official';
-- hanwha_aerospace 1174 club — 현행 원문 0(보고서 동호회 = 장애인 체육 봉사)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1174 AND c.COMP_ENG_NM = 'hanwha_aerospace' AND b.BENEFIT_CD = 'club' AND b.BADGE_CD = 'official';
-- hanwha_aerospace 1175 discount — 현행 원문 0 · 그룹 계열사 할인 문구
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1175 AND c.COMP_ENG_NM = 'hanwha_aerospace' AND b.BENEFIT_CD = 'discount' AND b.BADGE_CD = 'official';
-- hanwha_ocean 1182 meal — 현행 원문에 식사 제공 문장 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1182 AND c.COMP_ENG_NM = 'hanwha_ocean' AND b.BENEFIT_CD = 'meal' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 424 AND c.COMP_ENG_NM = 'doosan' AND b.BENEFIT_CD = 'summer_leave' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 425 AND c.COMP_ENG_NM = 'doosan' AND b.BENEFIT_CD = 'long_service_bonus' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 426 AND c.COMP_ENG_NM = 'doosan' AND b.BENEFIT_CD = 'health_check' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 428 AND c.COMP_ENG_NM = 'doosan' AND b.BENEFIT_CD = 'insurance' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 430 AND c.COMP_ENG_NM = 'doosan' AND b.BENEFIT_CD = 'child_edu' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 431 AND c.COMP_ENG_NM = 'doosan' AND b.BENEFIT_CD = 'event' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 432 AND c.COMP_ENG_NM = 'doosan' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 433 AND c.COMP_ENG_NM = 'doosan' AND b.BENEFIT_CD = 'club' AND b.BADGE_CD = 'official';
-- doosan_enerbility 434 refresh_leave — 리프레시 휴가 권장 문장 제외(법정 연차 사용 권장)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 434 AND c.COMP_ENG_NM = 'doosan_enerbility' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';
-- doosan_enerbility 446 edu_support — 현행 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 446 AND c.COMP_ENG_NM = 'doosan_enerbility' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- ecopro 697 birthday_gift — 현행 원문 0
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 697 AND c.COMP_ENG_NM = 'ecopro' AND b.BENEFIT_CD = 'birthday_gift' AND b.BADGE_CD = 'official';
-- ecopro_bm 713 edu_support — 현행 원문 0
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 713 AND c.COMP_ENG_NM = 'ecopro_bm' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 754 AND c.COMP_ENG_NM = 'olix' AND b.BENEFIT_CD = 'fitness' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 755 AND c.COMP_ENG_NM = 'olix' AND b.BENEFIT_CD = 'event' AND b.BADGE_CD = 'official';
-- olix 756 lang — 사내 어학강좌 = 회사 주도 교육 과정
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 756 AND c.COMP_ENG_NM = 'olix' AND b.BENEFIT_CD = 'lang' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 757 AND c.COMP_ENG_NM = 'olix' AND b.BENEFIT_CD = 'books' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 759 AND c.COMP_ENG_NM = 'olix' AND b.BENEFIT_CD = 'club' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 760 AND c.COMP_ENG_NM = 'olix' AND b.BENEFIT_CD = 'housing_support' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 762 AND c.COMP_ENG_NM = 'olix' AND b.BENEFIT_CD = 'parking' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 623 AND c.COMP_ENG_NM = 'soulbrain' AND b.BENEFIT_CD = 'lang' AND b.BADGE_CD = 'official';

COMMIT;
