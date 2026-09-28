-- ══════════════════════════════════════════════════════════════════════
-- 근거 URL 없는 72곳 재수집 R-3 묶음 1 (10사) 반영 — 표적 삭제 21 · 코드 바꾸기 13
-- 사용자 결정: 2026-09-28 (근거 주소 없는 72곳은 표시를 바꾸지 말고 다시 모은다)
-- 선례: db/migrations/20260926_recollect_9_official.sql · 20260928_recollect_2_lg_mobis.sql
--
-- 배경: 2026-04-15 초기 AI 파싱으로 등록돼 근거 URL 이 없던 10사를 공식 출처에서 다시 세웠다
--   (수집 Opus ×10 → 적대 검증 Fable 레인 5 · 레인 4 후반은 Opus 이어받기). 기아 구본은 다른 회사 데이터였다.
--   정본 = /home/ubuntu/loupit-evidence/2026-09-28-recollect-3/ (verify/_ACTIONS-1~5.md §3 이 이 파일의 입력).
--   새 시드 10파일은 같은 PR 에서 바뀐다(163 → 242행, 전체 2530 → 2609).
--
-- 무엇을 바꾸나:
--   · 표적 삭제 — 운영 행은 전부 BADGE_CD = official 이라 시드의 DELETE(est 한정)가 지우지 못한다.
--     공식 원문에 근거가 없어 새 시드에서 빠진 행만 지운다.
--   · 코드 바꾸기 — 같은 제도의 코드만 바꿔 행 번호를 잇는다. 명칭 · 금액 · 카테고리 · 설명은 이어지는
--     적재(load.py)가 새 시드 값으로 덮는다. 새 코드는 그 회사 운영 행에 없다(uq 충돌 0, 2026-09-28 스냅숏).
--   · 크래프톤 971(resort, 재직자 행 verified)은 건드리지 않는다(SP-SEED-12).
--   10사에서 편집 이력이 가리키는 행은 971 하나뿐이다(삭제 대상 아님).
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
-- 기대: DELETE 21문 각각 1 row affected · UPDATE 13문 각각 Rows matched 1 Changed 1 · 두 번째 실행은 0 ·
--   적재 뒤 전체 2609행.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 코드 바꾸기 (13) ──
-- pearl_abyss 1076: lounge → massage · 힐링룸 안마 서비스 → massage (lounge 는 적재가 새 행으로 넣는다)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'massage'
 WHERE b.BENEFIT_ID = 1076 AND c.COMP_ENG_NM = 'pearl_abyss' AND b.BENEFIT_CD = 'lounge' AND b.BADGE_CD = 'official';
-- pearl_abyss 1085: conference → edu_support · 외부 교육 지원
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'edu_support'
 WHERE b.BENEFIT_ID = 1085 AND c.COMP_ENG_NM = 'pearl_abyss' AND b.BENEFIT_CD = 'conference' AND b.BADGE_CD = 'official';
-- wgames 395: long_service_leave → long_service_bonus · 장기근속 포상
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'long_service_bonus'
 WHERE b.BENEFIT_ID = 395 AND c.COMP_ENG_NM = 'wgames' AND b.BENEFIT_CD = 'long_service_leave' AND b.BADGE_CD = 'official';
-- wgames 398: fitness → massage · 헬스키퍼(영문판 massage therapist)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'massage'
 WHERE b.BENEFIT_ID = 398 AND c.COMP_ENG_NM = 'wgames' AND b.BENEFIT_CD = 'fitness' AND b.BADGE_CD = 'official';
-- wgames 401: lang → self_development · 자기계발비 지원
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'self_development'
 WHERE b.BENEFIT_ID = 401 AND c.COMP_ENG_NM = 'wgames' AND b.BENEFIT_CD = 'lang' AND b.BADGE_CD = 'official';
-- wgames 408: housing_loan → welfare_fund_loan · 용도 미기재 사내 대출 — 주거 외 대출 규칙
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'welfare_fund_loan'
 WHERE b.BENEFIT_ID = 408 AND c.COMP_ENG_NM = 'wgames' AND b.BENEFIT_CD = 'housing_loan' AND b.BADGE_CD = 'official';
-- kakao_bank 886: self_development → welfare_point · 자기주도 마일리지 포인트 연 600만 원 — 20260918_recode_misclassified_rows.sql 의 kakao_bank 항목을 되돌린다
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'welfare_point'
 WHERE b.BENEFIT_ID = 886 AND c.COMP_ENG_NM = 'kakao_bank' AND b.BENEFIT_CD = 'self_development' AND b.BADGE_CD = 'official';
-- kakao_bank 891: work_tools → office_furniture · 스탠딩 데스크 · 의자
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'office_furniture'
 WHERE b.BENEFIT_ID = 891 AND c.COMP_ENG_NM = 'kakao_bank' AND b.BENEFIT_CD = 'work_tools' AND b.BADGE_CD = 'official';
-- ncsoft 728: leisure_ticket → sports_ticket · NC 다이노스 경기 관람
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'sports_ticket'
 WHERE b.BENEFIT_ID = 728 AND c.COMP_ENG_NM = 'ncsoft' AND b.BENEFIT_CD = 'leisure_ticket' AND b.BADGE_CD = 'official';
-- krafton 956: leave_general → holiday_gift · 명절 선물 — 20260922_recode_benefit_rows.sql 의 역방향(반차는 생일 몫)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'holiday_gift'
 WHERE b.BENEFIT_ID = 956 AND c.COMP_ENG_NM = 'krafton' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
-- hanmi_semi 1109: fertility_support → parenting · 출산 · 육아 지원
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'parenting'
 WHERE b.BENEFIT_ID = 1109 AND c.COMP_ENG_NM = 'hanmi_semi' AND b.BENEFIT_CD = 'fertility_support' AND b.BADGE_CD = 'official';
-- hanmi_semi 1115: holiday_gift → birthday_gift · 생일 선물
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'birthday_gift'
 WHERE b.BENEFIT_ID = 1115 AND c.COMP_ENG_NM = 'hanmi_semi' AND b.BENEFIT_CD = 'holiday_gift' AND b.BADGE_CD = 'official';
-- hanmi_semi 1105: long_service_bonus → long_service_leave · 상품권과 포상휴가 한 줄 — 원문이 휴가 중심
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'long_service_leave'
 WHERE b.BENEFIT_ID = 1105 AND c.COMP_ENG_NM = 'hanmi_semi' AND b.BENEFIT_CD = 'long_service_bonus' AND b.BADGE_CD = 'official';

-- ── 표적 삭제 (21) — 공식 원문에 근거 없음 ──
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 677 AND c.COMP_ENG_NM = 'apr' AND b.BENEFIT_CD = 'pc_off' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 686 AND c.COMP_ENG_NM = 'apr' AND b.BENEFIT_CD = 'wedding' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 393 AND c.COMP_ENG_NM = 'wgames' AND b.BENEFIT_CD = 'remote_work' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 394 AND c.COMP_ENG_NM = 'wgames' AND b.BENEFIT_CD = 'nap_room' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 399 AND c.COMP_ENG_NM = 'wgames' AND b.BENEFIT_CD = 'parenting' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 402 AND c.COMP_ENG_NM = 'wgames' AND b.BENEFIT_CD = 'books' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 874 AND c.COMP_ENG_NM = 'kakao_bank' AND b.BENEFIT_CD = 'stock_option' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 876 AND c.COMP_ENG_NM = 'kakao_bank' AND b.BENEFIT_CD = 'remote_work' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 722 AND c.COMP_ENG_NM = 'ncsoft' AND b.BENEFIT_CD = 'remote_work' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 732 AND c.COMP_ENG_NM = 'ncsoft' AND b.BENEFIT_CD = 'transport' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 330 AND c.COMP_ENG_NM = 'kia' AND b.BENEFIT_CD = 'welfare_point' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 331 AND c.COMP_ENG_NM = 'kia' AND b.BENEFIT_CD = 'meal' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 332 AND c.COMP_ENG_NM = 'kia' AND b.BENEFIT_CD = 'snack_bar' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 333 AND c.COMP_ENG_NM = 'kia' AND b.BENEFIT_CD = 'transport' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 958 AND c.COMP_ENG_NM = 'krafton' AND b.BENEFIT_CD = 'satellite_office' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 970 AND c.COMP_ENG_NM = 'krafton' AND b.BENEFIT_CD = 'books' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 841 AND c.COMP_ENG_NM = 'kakao' AND b.BENEFIT_CD = 'flex_work' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 844 AND c.COMP_ENG_NM = 'kakao' AND b.BENEFIT_CD = 'parenting' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 847 AND c.COMP_ENG_NM = 'kakao' AND b.BENEFIT_CD = 'self_development' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 853 AND c.COMP_ENG_NM = 'kakao' AND b.BENEFIT_CD = 'work_tools' AND b.BADGE_CD = 'official';
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 216 AND c.COMP_ENG_NM = 'nh_invest' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';

COMMIT;
