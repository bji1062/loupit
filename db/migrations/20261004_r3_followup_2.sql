-- ══════════════════════════════════════════════════════════════════════
-- R-3 후속 정리 2 반영 — 코드 바꾸기 7 · 표적 삭제 0
-- 사용자 결정: 2026-10-04 (회사가 여는 어학 강좌도 복지 · 사내 대출은 용도 몰라도 복지 · 리프레시 휴가는 이름만 있어도 연차 외 휴가 ·
--             「퇴직금 누진제」 새 코드 승인)
-- 선례: db/migrations/20261004_recollect_3_batch7.sql
--
-- 배경: 위 사용자 결정으로 규칙 8 · 기준 13 · 기준 23 이 개정됐다. 개정 규칙으로 예전에 뺀 121줄을 저장된 원문 사본으로 되살리고
--   (새 행 71 · 서술 합침 50), 한미약품 연차 총량 분리 1 · 생활안정 대출 분리 2 · 퇴직금 누진제 새 코드 3 행을 더한다.
--   새 시드는 같은 PR 에서 80파일이 바뀐다(3,097 → 3,174행). 회사 147 그대로(회사 등록 해제 · 법정 등록 변경 없음).
--   정본 = /home/ubuntu/loupit-evidence/2026-10-04-r3-followup/ (PR2-SURVEY-v2.md · PR2-v2-lanes/ · _INTEGRATE-PR2.md).
--
-- 무엇을 바꾸나:
--   · 코드 바꾸기 7 — 같은 제도의 코드만 바꿔 행 번호를 잇는다. 명칭 · 금액 · 카테고리 · 설명은 이어지는 적재(load.py)가 새 시드 값으로 덮는다.
--       연차 일수 · 총량 2   750 올릭스 · 787 유한양행 refresh_leave → leave_general (기준 18 개정 — 연차 일수를 밝힌 문장은 leave_general)
--       용도 미기재 대출 2   10054 삼양식품 · 12391 에스티팜 housing_loan → welfare_fund_loan (기준 13 개정)
--       경영성과급 단독 제도 3  45162 현대제철 · 1036 파마리서치 · 780 유진테크 incentive → profit_sharing
--     새 코드는 그 회사 운영 행에 없다(uq_comp_benefit 충돌 0 — 시드 대조 · 리허설로 확인).
--   · 표적 삭제 0. 새 행은 적재(load.py)의 upsert 가 넣는다.
--   7곳 모두 재직자 행 · 편집 이력이 없는 official 행이다(가드가 BADGE_CD = official 을 건다).
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--   적재를 먼저 돌리면 새 코드 행이 먼저 생겨 UPDATE 가 uq_comp_benefit 중복 키로 실패하고 옛 행이 남는다.
--
-- 🚨 web/assets/js/find.js 가 바뀐다(LABEL_OVERRIDE welfare_fund_loan 1줄 · 무해). web/assets 는 라이브 docroot 라 git pull 하는 순간 바로 라이브가 된다 —
--   아래 pull → 백업 → 마이그레이션 → load.py → release 를 끊지 않고 잇는다.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   0) 머지 → git pull
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 참조 9테이블(TCOMPANY_TYPE · TCOMPANY · TCOMPANY_ALIAS · TCOMPANY_BENEFIT · TBENEFIT_PRESET · TBENEFIT_EDIT_LOG · TCOMPANY_EMAIL_DOMAIN · TCORP · TCOMPANY_CORP)을 뜬다
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: UPDATE 7문 각각 Rows matched 1 Changed 1 · 두 번째 실행은 0 · 적재 뒤 전체 3174행 · 회사 147.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 코드 바꾸기 (7) ──
-- olix 750: refresh_leave → leave_general · 연간 휴가 총 20일 = 연차 일수를 밝힌 총량 (기준 18 개정)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'leave_general'
 WHERE b.BENEFIT_ID = 750 AND c.COMP_ENG_NM = 'olix' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';
-- yuhan 787: refresh_leave → leave_general · 법정 기준보다 7일 추가 휴가 = 연차 일수 가산 (기준 18 개정)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'leave_general'
 WHERE b.BENEFIT_ID = 787 AND c.COMP_ENG_NM = 'yuhan' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';
-- samyang_foods 10054: housing_loan → welfare_fund_loan · 신협 대출 지원 = 용도 미기재 사내 대출 (기준 13 개정)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'welfare_fund_loan'
 WHERE b.BENEFIT_ID = 10054 AND c.COMP_ENG_NM = 'samyang_foods' AND b.BENEFIT_CD = 'housing_loan' AND b.BADGE_CD = 'official';
-- stpharm 12391: housing_loan → welfare_fund_loan · 임직원 대출 = 용도 미기재 사내 대출 (기준 13 개정)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'welfare_fund_loan'
 WHERE b.BENEFIT_ID = 12391 AND c.COMP_ENG_NM = 'stpharm' AND b.BENEFIT_CD = 'housing_loan' AND b.BADGE_CD = 'official';
-- hyundai_steel 45162: incentive → profit_sharing · 경영 성과급을 단독 제도로 밝힘 (기준 20)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'profit_sharing'
 WHERE b.BENEFIT_ID = 45162 AND c.COMP_ENG_NM = 'hyundai_steel' AND b.BENEFIT_CD = 'incentive' AND b.BADGE_CD = 'official';
-- pharma_research 1036: incentive → profit_sharing · 연간 경영실적 목표 달성 시 경영성과급 (기준 20)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'profit_sharing'
 WHERE b.BENEFIT_ID = 1036 AND c.COMP_ENG_NM = 'pharma_research' AND b.BENEFIT_CD = 'incentive' AND b.BADGE_CD = 'official';
-- eugenetech 780: incentive → profit_sharing · 매년 경영 성과에 따른 Profit Sharing (기준 20)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'profit_sharing'
 WHERE b.BENEFIT_ID = 780 AND c.COMP_ENG_NM = 'eugenetech' AND b.BENEFIT_CD = 'incentive' AND b.BADGE_CD = 'official';

COMMIT;
