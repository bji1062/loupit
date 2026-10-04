-- ══════════════════════════════════════════════════════════════════════
-- 근거 URL 없는 회사 재수집 R-3 묶음 7 (보로노이 · 오스코텍 · 한미약품 · 케어젠 · 텔레칩스 · 리노공업 · 아모레퍼시픽 · 리메드 · 기업은행 · 효성중공업 · 대한항공 · 네오위즈) 반영 — 표적 삭제 19 · 코드 바꾸기 7
-- 사용자 결정: 2026-09-28 (근거 주소 없는 곳은 표시를 바꾸지 말고 다시 모은다)
--             2026-10-02 (「묶음 7 시작해줘」)
--             2026-10-04 (케어젠 · 리노공업 · 리메드 = 공식 출처가 없으면 사용자 제공 검색 AI 요약 기준 — 기준 39 · 「대한항공은 권고대로」)
-- 선례: db/migrations/20261002_recollect_3_batch6a.sql
--
-- 배경: 2026-04-15 초기 AI 파싱으로 등록돼 근거 URL 이 없던 12개사를 공식 출처(케어젠 · 리노공업 · 리메드 3사는 사용자 제공 검색 AI 요약)에서 다시 세웠다
--   (수집 Opus → 적대 검증 Opus 레인 1~6).
--   정본 = /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/ (verify/_ACTIONS-1.md ~ _ACTIONS-6.md 운영 반영 표가 이 파일의 입력).
--   새 시드 12파일은 같은 PR 에서 바뀐다(125 → 229행). 전체 2989 → 3093 · 회사 147 그대로(회사 등록 해제 · 법정 등록 변경 없음).
--   보로노이 13 · 오스코텍 5 · 한미약품 30 · 케어젠 17 · 텔레칩스 26 · 리노공업 8 · 아모레퍼시픽 24 · 리메드 8 · 기업은행 24 · 효성중공업 20 · 대한항공 31 · 네오위즈 23.
--
-- 무엇을 바꾸나:
--   · 코드 바꾸기 — 같은 제도의 코드만 바꿔 행 번호를 잇는다. 명칭 · 금액 · 카테고리 · 설명은 이어지는
--     적재(load.py)가 새 시드 값으로 덮는다. 새 코드는 그 회사 운영 행에 없다(uq 충돌 0, 2026-10-04 스냅숏).
--   · 표적 삭제 — 운영 행은 전부 BADGE_CD = official 이라 시드의 DELETE(est 한정)가 지우지 못한다.
--     원문에 근거가 없어 새 시드에서 빠진 행만 지운다.
--   · 같은 코드 덮어쓰기(리노공업 477~481 · 리메드 485~487 · 케어젠 7행 등)는 이 파일이 아니라 적재의 upsert 가 한다.
--   12사에 재직자 행 · 편집 이력은 없다(125행 전부 official · ai_parse).
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--   적재를 먼저 돌리면 새 코드 행이 먼저 생겨 UPDATE 가 uq_comp_benefit 중복 키로 실패하고 옛 행이 남는다.
--
-- 🚨 이 PR 은 web/assets/js/find.js(/find 대표 이름 고정 1 — LABEL_OVERRIDE uniform 1줄 · 무해)를 바꾼다. legal.js 는 안 바뀐다.
--   web/assets 는 라이브 docroot 라 git pull 하는 순간 find.js 가 바로 라이브가 된다 — 아래 pull → 백업 → 마이그레이션 → load.py → release 를 끊지 않고 잇는다
--   (묶음 3 · 4-A · 4-B · 5 · 6-A 마이그레이션 머리말 「0) 머지 → git pull」 줄과 같은 경고).
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   0) 머지 → git pull — pull 하는 순간 find.js 가 라이브가 되므로 아래 1~4 를 release 까지 멈추지 않고 잇는다
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 참조 9테이블(TCOMPANY_TYPE · TCOMPANY · TCOMPANY_ALIAS · TCOMPANY_BENEFIT · TBENEFIT_PRESET · TBENEFIT_EDIT_LOG · TCOMPANY_EMAIL_DOMAIN · TCORP · TCOMPANY_CORP)을 뜬다
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: UPDATE 7문 각각 Rows matched 1 Changed 1 · DELETE 19문 각각 1 row affected · 두 번째 실행은 0 ·
--   적재 뒤 전체 3093행 · 회사 147.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 코드 바꾸기 (7) ──
-- caregen 936: long_service_leave → long_service_bonus · 장기근속자 포상 — 급여제도 분류의 포상 · 휴가 낱말 없음 (time_off → compensation 은 적재가 덮는다)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'long_service_bonus'
 WHERE b.BENEFIT_ID = 936 AND c.COMP_ENG_NM = 'caregen' AND b.BENEFIT_CD = 'long_service_leave' AND b.BADGE_CD = 'official';
-- ibk 342: edu_support → self_development · 학자금/자격증 지원 → 자기개발 비용 (growth → growth)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'self_development'
 WHERE b.BENEFIT_ID = 342 AND c.COMP_ENG_NM = 'ibk' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- hyosung_heavy 1292: bonus → incentive · 성과급 → 사업부 평가 연계 인센티브 (compensation → compensation)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'incentive'
 WHERE b.BENEFIT_ID = 1292 AND c.COMP_ENG_NM = 'hyosung_heavy' AND b.BENEFIT_CD = 'bonus' AND b.BADGE_CD = 'official';
-- hyosung_heavy 1294: long_service → long_service_leave · 장기근속 포상 → 장기근속 휴가 · 이후 long_service 코드 사용 0 (time_off → time_off)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'long_service_leave'
 WHERE b.BENEFIT_ID = 1294 AND c.COMP_ENG_NM = 'hyosung_heavy' AND b.BENEFIT_CD = 'long_service' AND b.BADGE_CD = 'official';
-- hyosung_heavy 1296: career → excellence_award · 자랑스러운 효성인상 = 포상 (growth → compensation 은 적재가 덮는다)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'excellence_award'
 WHERE b.BENEFIT_ID = 1296 AND c.COMP_ENG_NM = 'hyosung_heavy' AND b.BENEFIT_CD = 'career' AND b.BADGE_CD = 'official';
-- korean_air 382: edu_support → mba · 대학원 장학금 · 정석대학 학위 (growth → growth)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'mba'
 WHERE b.BENEFIT_ID = 382 AND c.COMP_ENG_NM = 'korean_air' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- neowiz 348: birthday_leave → birthday_gift · 본인/가족 기념일 선물 (time_off → perks 는 적재가 덮는다)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'birthday_gift'
 WHERE b.BENEFIT_ID = 348 AND c.COMP_ENG_NM = 'neowiz' AND b.BENEFIT_CD = 'birthday_leave' AND b.BADGE_CD = 'official';

-- ── 표적 삭제 (19) ──
-- voronoi 496 parking — 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 496 AND c.COMP_ENG_NM = 'voronoi' AND b.BENEFIT_CD = 'parking' AND b.BADGE_CD = 'official';
-- oscotec 744 excellence_award — 원문 없음 (추정 30)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 744 AND c.COMP_ENG_NM = 'oscotec' AND b.BENEFIT_CD = 'excellence_award' AND b.BADGE_CD = 'official';
-- oscotec 745 health_check — 법정 일반 · 특수 검진뿐 (추정 100)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 745 AND c.COMP_ENG_NM = 'oscotec' AND b.BENEFIT_CD = 'health_check' AND b.BADGE_CD = 'official';
-- oscotec 746 medical — 원문 없음 (추정 50)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 746 AND c.COMP_ENG_NM = 'oscotec' AND b.BENEFIT_CD = 'medical' AND b.BADGE_CD = 'official';
-- oscotec 748 meal — 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 748 AND c.COMP_ENG_NM = 'oscotec' AND b.BENEFIT_CD = 'meal' AND b.BADGE_CD = 'official';
-- hanmi_pharm 1127 edu_support — 원문 교육은 회사 주도 과정뿐 — 규칙 8
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1127 AND c.COMP_ENG_NM = 'hanmi_pharm' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- caregen 934 excellence_award — 요약본 · 공식 출처 어디에도 없음 — 39-f (추정 30)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 934 AND c.COMP_ENG_NM = 'caregen' AND b.BENEFIT_CD = 'excellence_award' AND b.BADGE_CD = 'official';
-- telechips 1007 profit_sharing — 옛 /view/about/culture 라우트 = 메뉴 · 사이트맵 밖
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1007 AND c.COMP_ENG_NM = 'telechips' AND b.BENEFIT_CD = 'profit_sharing' AND b.BADGE_CD = 'official';
-- amorepacific 642 birthday_leave — 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 642 AND c.COMP_ENG_NM = 'amorepacific' AND b.BENEFIT_CD = 'birthday_leave' AND b.BADGE_CD = 'official';
-- amorepacific 649 edu_support — 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 649 AND c.COMP_ENG_NM = 'amorepacific' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- remed 482 stock_option — 요약본 · 공식 모두 없음 · 임프리메드 데이터 — 39-f
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 482 AND c.COMP_ENG_NM = 'remed' AND b.BENEFIT_CD = 'stock_option' AND b.BADGE_CD = 'official';
-- remed 483 flex_work — 공시 「유연근무제 활용 여부 부」와 어긋남 — 39-f
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 483 AND c.COMP_ENG_NM = 'remed' AND b.BENEFIT_CD = 'flex_work' AND b.BADGE_CD = 'official';
-- remed 484 leave_general — 요약본 · 공식 모두 없음 (요약본 「연차」는 법정)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 484 AND c.COMP_ENG_NM = 'remed' AND b.BENEFIT_CD = 'leave_general' AND b.BADGE_CD = 'official';
-- ibk 336 medical — 공시 의료비 지급기준에 규정 없음 · 5개년 지급 0 (추정 50)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 336 AND c.COMP_ENG_NM = 'ibk' AND b.BENEFIT_CD = 'medical' AND b.BADGE_CD = 'official';
-- ibk 337 clinic — 현행 원문 없음
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 337 AND c.COMP_ENG_NM = 'ibk' AND b.BENEFIT_CD = 'clinic' AND b.BADGE_CD = 'official';
-- ibk 341 lang — 현행 원문 없음 · 규칙 8
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 341 AND c.COMP_ENG_NM = 'ibk' AND b.BENEFIT_CD = 'lang' AND b.BADGE_CD = 'official';
-- hyosung_heavy 1297 retirement_support — 진로설계교육 = 퇴직 예정자 대상 — 고령자고용법 재취업지원 법정 (리드 판정 48)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 1297 AND c.COMP_ENG_NM = 'hyosung_heavy' AND b.BENEFIT_CD = 'retirement_support' AND b.BADGE_CD = 'official';
-- korean_air 375 long_service_bonus — 현행 원문에 여행 지원 0 — 장기근속은 항공권 괄호(discount 서술)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 375 AND c.COMP_ENG_NM = 'korean_air' AND b.BENEFIT_CD = 'long_service_bonus' AND b.BADGE_CD = 'official';
-- neowiz 354 discount — 현행 원문 0 (자사 게임쿠폰)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 354 AND c.COMP_ENG_NM = 'neowiz' AND b.BENEFIT_CD = 'discount' AND b.BADGE_CD = 'official';

COMMIT;
