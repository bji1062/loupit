-- ══════════════════════════════════════════════════════════════════════
-- 근거 URL 없는 회사 재수집 R-3 묶음 6-A (이오테크닉스 · 주성엔지니어링 · 테크윙 · 덕산네오룩스 · 비에이치 · 지놈앤컴퍼니 · 클래시스 · 레인보우로보틱스) 반영 — 표적 삭제 17 · 코드 바꾸기 2
-- 사용자 결정: 2026-09-28 (근거 주소 없는 곳은 표시를 바꾸지 말고 다시 모은다)
--             2026-10-02 (「묶음 6 시작해줘」)
-- 선례: db/migrations/20261002_recollect_3_batch5.sql
--
-- 배경: 2026-04-15 초기 AI 파싱으로 등록돼 근거 URL 이 없던 8개사를 공식 출처에서 다시 세웠다
--   (수집 Opus → 적대 검증 Opus 레인 1~5).
--   정본 = /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-6/ (verify/_ACTIONS-1.md ~ _ACTIONS-5.md §3 이 이 파일의 입력).
--   새 시드 8파일은 같은 PR 에서 바뀐다(92 → 127행). HPSP 회사 등록 해제(14행)와 합쳐 전체 2968 → 2989.
--   이오테크닉스 12 · 주성엔지니어링 19 · 테크윙 21 · 덕산네오룩스 23 · 비에이치 7 · 지놈앤컴퍼니 11 · 클래시스 23 · 레인보우로보틱스 11.
--   DB손해보험은 이 묶음(6-A)에 없다(붙여넣기 대기 — 6-B).
--
-- 무엇을 바꾸나:
--   · 코드 바꾸기 — 같은 제도의 코드만 바꿔 행 번호를 잇는다. 명칭 · 금액 · 카테고리 · 설명은 이어지는
--     적재(load.py)가 새 시드 값으로 덮는다. 새 코드는 그 회사 운영 행에 없다(uq 충돌 0, 2026-10-02 스냅숏).
--   · 표적 삭제 — 운영 행은 전부 BADGE_CD = official 이라 시드의 DELETE(est 한정)가 지우지 못한다.
--     공식 원문에 근거가 없어 새 시드에서 빠진 행만 지운다.
--   8사에 재직자 행 · 편집 이력은 없다(92행 전부 official).
--   이 파일은 HPSP(20261002_unregister_hpsp.sql)와 서로 다른 회사만 건드린다.
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 20261002_unregister_hpsp.sql → 이 파일 → python3 db/seed/load.py → release.
--   적재를 먼저 돌리면 새 코드 행이 먼저 생겨 UPDATE 가 uq_comp_benefit 중복 키로 실패하고 옛 행이 남는다.
--
-- 🚨 이 PR 은 web/assets/js/legal.js(이오테크닉스 · 클래시스 · 레인보우로보틱스 법정 등록 해제)와 find.js(/find 대표 이름 고정 2)를 바꾼다.
--   web/assets 는 라이브 docroot 라 git pull 하는 순간 legal.js · find.js 가 둘 다 바로 라이브가 된다 — 아래 pull → 백업 → 마이그레이션 → load.py → release 를 끊지 않고 잇는다
--   (묶음 3 · 유한양행 · 4-A · 4-B · 5 마이그레이션 머리말 「0) 머지 → git pull」 줄과 같은 경고).
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   0) 머지 → git pull — pull 하는 순간 legal.js · find.js 가 라이브가 되므로 아래 1~5 를 release 까지 멈추지 않고 잇는다
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 참조 9테이블 + HPSP 등록 해제가 지우는 TCOMPARE_LOG · TSOURCE_CHECK · TAUTH_CODE 를 뜬다
--   2) 20261002_unregister_hpsp.sql 을 mysql -vv 로 적용
--   3) 이 파일을 mysql -vv 로 적용
--   4) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   5) 릴리스
-- 기대: UPDATE 2문 각각 Rows matched 1 Changed 1 · DELETE 17문 각각 1 row affected · 두 번째 실행은 0 ·
--   적재 뒤 전체 2989행 · 회사 147.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 코드 바꾸기 (2) ──
-- techwing 990: long_service_leave → long_service_bonus · 원문 세 곳 「포상」 · 휴가 낱말 0 — time_off → compensation 은 적재가 덮는다
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'long_service_bonus'
 WHERE b.BENEFIT_ID = 990 AND c.COMP_ENG_NM = 'techwing' AND b.BENEFIT_CD = 'long_service_leave' AND b.BADGE_CD = 'official';
-- duksan_neolux 415: edu_support → self_development · 본인 학자금 — 2026-09-22 선례 3사
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'self_development'
 WHERE b.BENEFIT_ID = 415 AND c.COMP_ENG_NM = 'duksan_neolux' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';

-- ── 표적 삭제 (17) ──
-- eo_technics 808 parenting — 법정 제도만(규칙 3) — 법정 등록 해제와 함께
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 808 AND c.COMP_ENG_NM = 'eo_technics' AND b.BENEFIT_CD = 'parenting' AND b.BADGE_CD = 'official';
-- jusung 822 refresh_leave — 현행 원문 없음(R5)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 822 AND c.COMP_ENG_NM = 'jusung' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';
-- jusung 826 family_day — 현행 원문 없음(R5)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 826 AND c.COMP_ENG_NM = 'jusung' AND b.BENEFIT_CD = 'family_day' AND b.BADGE_CD = 'official';
-- techwing 997 edu_support — 구본 묶음 4행 분리 — 새 시드에 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 997 AND c.COMP_ENG_NM = 'techwing' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- techwing 1005 housing_loan — 구본 묶음 4행 분리 — 새 시드에 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1005 AND c.COMP_ENG_NM = 'techwing' AND b.BENEFIT_CD = 'housing_loan' AND b.BADGE_CD = 'official';
-- bh 497 family_day — 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 497 AND c.COMP_ENG_NM = 'bh' AND b.BENEFIT_CD = 'family_day' AND b.BADGE_CD = 'official';
-- bh 499 event — 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 499 AND c.COMP_ENG_NM = 'bh' AND b.BENEFIT_CD = 'event' AND b.BADGE_CD = 'official';
-- bh 500 self_development — 원문 없음(항목 페이지 예외 bh 삭제 동반)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 500 AND c.COMP_ENG_NM = 'bh' AND b.BENEFIT_CD = 'self_development' AND b.BADGE_CD = 'official';
-- bh 501 welfare_point — 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 501 AND c.COMP_ENG_NM = 'bh' AND b.BENEFIT_CD = 'welfare_point' AND b.BADGE_CD = 'official';
-- bh 504 telecom — 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 504 AND c.COMP_ENG_NM = 'bh' AND b.BENEFIT_CD = 'telecom' AND b.BADGE_CD = 'official';
-- bh 505 holiday_gift — 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 505 AND c.COMP_ENG_NM = 'bh' AND b.BENEFIT_CD = 'holiday_gift' AND b.BADGE_CD = 'official';
-- genome_company 833 excellence_award — 직무발명 보상제도 = 발명진흥법 15조 법정 보상
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 833 AND c.COMP_ENG_NM = 'genome_company' AND b.BENEFIT_CD = 'excellence_award' AND b.BADGE_CD = 'official';
-- classys 979 work_tools — 현행 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 979 AND c.COMP_ENG_NM = 'classys' AND b.BENEFIT_CD = 'work_tools' AND b.BADGE_CD = 'official';
-- rainbow_robotics 450 stock_option — 현행 원문 없음 · DART 주주 표 「-」(R5)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 450 AND c.COMP_ENG_NM = 'rainbow_robotics' AND b.BENEFIT_CD = 'stock_option' AND b.BADGE_CD = 'official';
-- rainbow_robotics 451 birthday_gift — 현행 원문 없음(R5)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 451 AND c.COMP_ENG_NM = 'rainbow_robotics' AND b.BENEFIT_CD = 'birthday_gift' AND b.BADGE_CD = 'official';
-- rainbow_robotics 452 leave_general — 현행 원문 없음(R5)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 452 AND c.COMP_ENG_NM = 'rainbow_robotics' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
-- rainbow_robotics 454 parenting — 법정 제도만(규칙 3) — 법정 등록 해제와 함께
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 454 AND c.COMP_ENG_NM = 'rainbow_robotics' AND b.BENEFIT_CD = 'parenting' AND b.BADGE_CD = 'official';

COMMIT;
