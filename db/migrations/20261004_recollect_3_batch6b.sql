-- ══════════════════════════════════════════════════════════════════════
-- 근거 URL 없는 회사 재수집 R-3 묶음 6-B (DB손해보험) 반영 — 표적 삭제 4 · 코드 바꾸기 0
-- 사용자 결정: 2026-09-28 (근거 주소 없는 곳은 표시를 바꾸지 말고 다시 모은다)
--             2026-10-04 (자기 도메인 복리후생 페이지 본문 붙여넣기 · 「운영 반영도 너가 해」)
-- 선례: db/migrations/20261004_recollect_3_batch7.sql
--
-- 배경: 2026-04-15 초기 AI 파싱으로 등록돼 근거 URL 이 없던 DB손해보험(db_insurance)을 회사 자기 도메인
--   복리후생 페이지(https://www.idbins.com/pc/bizxpress/cmy/adp/FWCOMV1732.shtm — 사용자 붙여넣기) 원문과 OpenDART 로 다시 세웠다
--   (수집 Opus → 적대 검증 Opus 레인 5b). 구본 15행은 다른 회사(엔카닷컴) 데이터가 섞여 있었다.
--   정본 = /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-6/ (verify/_ACTIONS-5b.md 운영 반영 표가 이 파일의 입력).
--   새 시드 1파일은 같은 PR 에서 바뀐다(15 → 19행). 전체 3093 → 3097 · 회사 147 그대로(회사 등록 해제 · 법정 등록 변경 없음).
--
-- 무엇을 바꾸나:
--   · 표적 삭제 — 운영 행은 전부 BADGE_CD = official 이라 시드의 DELETE(est 한정)가 지우지 못한다.
--     원문에 근거가 없어 새 시드에서 빠진 4행(20 · 24 · 27 · 31)만 지운다.
--   · 코드 바꾸기 0. 같은 코드 11행(18 · 19 · 21 · 22 · 23 · 25 · 26 · 28 · 29 · 30 · 32)은 적재(load.py)의 upsert 가 덮고,
--     새 코드 8행(transport · welfare_fund_loan · leave_general · birthday_leave · parenting · dormitory · self_development · remote_work)은 적재가 넣는다.
--   DB손해보험에 재직자 행 · 편집 이력은 없다(15행 전부 official · ai_parse).
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--
-- web/assets 변경 없음(이 PR 은 find.js · legal.js 를 바꾸지 않는다) — git pull 만으로 라이브가 바뀌지 않는다.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   0) 머지 → git pull
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 참조 9테이블(TCOMPANY_TYPE · TCOMPANY · TCOMPANY_ALIAS · TCOMPANY_BENEFIT · TBENEFIT_PRESET · TBENEFIT_EDIT_LOG · TCOMPANY_EMAIL_DOMAIN · TCORP · TCOMPANY_CORP)을 뜬다
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: DELETE 4문 각각 1 row affected · 두 번째 실행은 0 · 적재 뒤 전체 3097행 · 회사 147.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 표적 삭제 (4) ──
-- db_insurance 20 summer_leave — 원문 없음 — 하계휴양소는 시설(resort)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 20 AND c.COMP_ENG_NM = 'db_insurance' AND b.BENEFIT_CD = 'summer_leave' AND b.BADGE_CD = 'official';
-- db_insurance 24 insurance — 원문 없음 — 제도 원문 없어 기준 11 C (추정 30)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 24 AND c.COMP_ENG_NM = 'db_insurance' AND b.BENEFIT_CD = 'insurance' AND b.BADGE_CD = 'official';
-- db_insurance 27 edu_support — 원문 없음 — 자격수당은 급여성 지급
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 27 AND c.COMP_ENG_NM = 'db_insurance' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- db_insurance 31 meal — 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 31 AND c.COMP_ENG_NM = 'db_insurance' AND b.BENEFIT_CD = 'meal' AND b.BADGE_CD = 'official';

COMMIT;
