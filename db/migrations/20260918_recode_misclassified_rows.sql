-- ══════════════════════════════════════════════════════════════════════
-- 잘못 분류된 복지 행 재코딩·정정 — 18행 UPDATE + 2행 DELETE(합치기) = 20행
-- 결정: 2026-09-18 세션 인계 3-1 「데이터 정리」 · 선례: 20260918_meal_anchor_to_qual.sql
--
-- 왜 필요한가: 코드가 틀린 행은 두 화면에서 서로 다른 숫자를 만든다. 복지 항목 페이지(SP-BEN)는
--   설정 파일의 exclude 예외로 이 행들을 빼 두었고(주택자금 대출 73곳), 복지검색 /find 는 코드
--   그대로 센다(76곳). 원인 행의 코드를 고치면 예외가 필요 없어지고 두 숫자가 같아진다.
--
-- 무엇을 바꾸나 (회사 COMP_ENG_NM · 옛 코드 → 새 코드):
--   재코딩 15행 — BENEFIT_CD 만 바꾼다(UPDATE). BENEFIT_ID 가 그대로라 편집 이력
--     (TBENEFIT_EDIT_LOG.BENEFIT_ID 외래키, ON DELETE SET NULL)이 끊기지 않는다.
--     ecopro        housing_loan  → relocation        「사택 또는 정착지원금 지급」 — 대출이 아니다
--     ecopro_bm     housing_loan  → relocation        「정착 지원금 지원」 — 대출이 아니다
--     olix          housing_loan  → housing_support   「주거 지원」 — 원문에 대출이 없다
--     kakao_bank    welfare_point → self_development  「연 600만원 자기계발비」 — 카테고리 perks → growth, 정렬 80 → 61
--     naver         welfare_point → self_development  「개인 업무 지원비」 360 — 카테고리 perks → growth, 정렬 81 → 62.
--                                                     근거 = NAVER 공식 채용 복지 페이지(recruit.navercorp.com/cnts/benefits)
--                                                     Growth 칸 「개인업무지원비: 업무 몰입을 위해 사용할 수 있도록 연간
--                                                     360만 원의 지원금 지급」. 같은 회사 work_tools 「업무 장비 예산」과의
--                                                     이중 계상은 아니다 — 공식 페이지가 Work Tools 칸 「업무기기 예산: 업무에
--                                                     꼭 맞는 기기를 선택할 수 있도록 입사와 함께 권장모델 구입이 가능한 예산
--                                                     및 매월 추가 예산 지급」으로 따로 적는다
--     samyang_foods child_edu     → parenting         자녀 입학 축하금 — 학자금이 아니다
--     korean_air    childcare     → parenting         「보육비 지원」 — 어린이집이 아니다
--     pearl_abyss   parenting     → parent_care       부모 요양 치료비 — **새 코드**(family). medical 에는
--                                                     이미 치과 진료비 255 가 있어 합치면 금액이 섞인다
--     ls            health_check  → medical           헬스케어비 — 검진 제도가 아니라 건강 비용 수당
--     hyundai_mobis remote_office → satellite_office  같은 뜻 중복 코드. 코퍼스의 유일한 remote_office 라
--                                                     이 행으로 코드 자체가 사라진다
--     birthday_leave(생일 휴가 코드)에 휴가 없이 선물만 있는 행 5개 — /find 라벨이 「생일 선물 · 생일 축하」로
--     휴가 코드의 이름을 선물로 만들고 있었다. 선물 4행은 birthday_gift(perks, 정렬은 perks 구역 끝),
--     창립기념일 1행은 foundation_day_leave(time_off, 자리 그대로).
--     ecopro        birthday_leave → birthday_gift        「근로자 생일 상품권 지급」 · 정렬 31 → 83
--     ncsoft        birthday_leave → birthday_gift        「생일자 페이코 10만원 지급」 10 stated · 정렬 30 → 84.
--                                                         (birthday_gift, 10) 은 이 회사뿐이라 앵커 강등 없음 — stated 유지
--     com2us        birthday_leave → birthday_gift        「생일 선물 지급」 · 정렬 33 → 85
--     hanmi_pharm   birthday_leave → birthday_gift        「입사 1주년 축하 선물 · 기념일 연 4회 포인트 지급」 · 정렬 32 → 83
--     hugel         birthday_leave → foundation_day_leave 「창립기념일 대체 휴무」 — 생일이 아니다
--   합치기 1곳 — isens 의 childcare 「보육수당」 · child_edu 「자녀 입학축하금」 두 행은 어린이집도
--     학자금도 아니고, 같은 회사에 parenting 「모성보호」 행이 이미 있다. 두 사실을 parenting 설명
--     끝에 덧붙이고(UPDATE 1) 두 행을 지운다(DELETE 2).
--   정성 전환 2행 — 비율이 금액 칸에 들어가 「회사 공식 수치 N만원」으로 나가고 있었다. 금액을 걷고
--     정성으로 — 비율 사실은 QUAL_DESC_CTNT 로 옮긴다(선례 meal 432 와 같은 꼴).
--     hyundai_steel medical 100 · stated · NOTE 「본인 100%, 가족 50%」 — 본인 100퍼센트이지 100만원이 아니다
--     s_oil bonus 800 · stated · NOTE 「연 800% 상여금」 — 800퍼센트이지 800만원이 아니다
--
-- 건드리지 않는 것: naver work_tools 「업무 장비 예산」 360(estimated). 현 공식 문구에 「2년 720만원」
--   근거가 없다 — 후속 점검. 금액정책 (a) 새 출처가 무금액이면 기존 앵커를 보존한다.
--
-- 적용: mysql -vv -h <host> -u <user> -p <DB> < db/migrations/20260918_recode_misclassified_rows.sql
--   -vv 를 붙여야 문마다 Rows matched 가 찍힌다. 붙이지 않으면 0행이어도 조용히 성공한다.
--   맨 앞 0단계 SELECT 는 읽기 전용 점검이다 — 이것만 먼저 따로 돌려 20행이 기대값과 같은지,
--   EDIT_LOGS 가 0 인지 보고 적용해도 된다.
-- 기대 영향 행 수: 20 (UPDATE 문 18개 각 1 · DELETE 문 2개 각 1). 적으면 멈추고 확인하라 —
--   회사명 오타면 @c 가 NULL 이라 오류 없이 0행이고, BADGE_CD 가 official 이 아니면(재직자 수정)
--   가드가 일부러 건너뛴 것이다. 합치기는 parenting 설명이 새 문안일 때만(@merged = 1) 지운다 —
--   parenting 이 가드에 걸려 안 바뀌었는데 두 행만 지워지는 일은 없다.
-- 멱등: 모든 WHERE 가 옛 값 전체(코드·이름·금액·QUAL_YN·설명)를 본다 — 두 번째 실행은 전부 0행.
-- 가드: BADGE_CD = official — 재직자가 고친 행은 조용히 덮지 않는다. DELETE 는 추가로
--   편집 이력에 걸린 행이면 지우지 않는다(NOT EXISTS TBENEFIT_EDIT_LOG).
-- 원자성: 한 트랜잭션이다. 새 코드가 그 회사에 이미 있으면(uq_comp_benefit) UPDATE 가
--   ERROR 1062 로 멈추고, mysql 클라이언트가 스크립트를 끊으며 COMMIT 전이라 전부 되돌아간다.
-- 시드: 같은 20행을 db/seed/benefit/sql/*.sql 에서도 같은 종착 상태로 고쳤다. 시드는 업서트라
--   코드를 바꾼 행은 **새 키**다 — 이 마이그레이션 없이 시드만 재적용하면 옛 코드 행이 남고
--   새 코드 행이 하나 더 생긴다. 그러니 서빙 DB 는 반드시 이 파일로 맞춘다.
-- 순서: 이 마이그레이션을 **정적 재생성(release)보다 먼저**. 같은 PR 이 항목 페이지 exclude 예외
--   11개 전부를 지웠다 — DB 가 옛 코드인 채로 재생성하면 뺐던 행이 항목 페이지에 다시 들어간다.
-- ══════════════════════════════════════════════════════════════════════

-- 0) 점검(읽기 전용) — 대상 20행 + 새 코드 자리 15곳이 비었는지 + 편집 이력 참조 수
SELECT c.COMP_ENG_NM, b.BENEFIT_ID, b.BENEFIT_CD, b.BENEFIT_NM, b.BENEFIT_AMT, b.AMT_SOURCE_CD,
       b.QUAL_YN, b.BADGE_CD,
       (SELECT COUNT(*) FROM TBENEFIT_EDIT_LOG l WHERE l.BENEFIT_ID = b.BENEFIT_ID) AS EDIT_LOGS
  FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE (c.COMP_ENG_NM, b.BENEFIT_CD) IN (
        ('ecopro', 'housing_loan'), ('ecopro_bm', 'housing_loan'), ('olix', 'housing_loan'),
        ('kakao_bank', 'welfare_point'), ('samyang_foods', 'child_edu'), ('korean_air', 'childcare'),
        ('pearl_abyss', 'parenting'), ('ls', 'health_check'), ('hyundai_mobis', 'remote_office'),
        ('naver', 'welfare_point'), ('hyundai_steel', 'medical'), ('s_oil', 'bonus'),
        ('isens', 'parenting'), ('isens', 'child_edu'), ('isens', 'childcare'),
        ('ecopro', 'birthday_leave'), ('ncsoft', 'birthday_leave'), ('com2us', 'birthday_leave'),
        ('hanmi_pharm', 'birthday_leave'), ('hugel', 'birthday_leave'),
        -- 새 코드 자리 — 아래 줄은 0행이어야 한다(있으면 UPDATE 가 1062 로 멈춘다)
        ('ecopro', 'relocation'), ('ecopro_bm', 'relocation'), ('olix', 'housing_support'),
        ('kakao_bank', 'self_development'), ('samyang_foods', 'parenting'), ('korean_air', 'parenting'),
        ('pearl_abyss', 'parent_care'), ('ls', 'medical'), ('hyundai_mobis', 'satellite_office'),
        ('naver', 'self_development'),
        ('ecopro', 'birthday_gift'), ('ncsoft', 'birthday_gift'), ('com2us', 'birthday_gift'),
        ('hanmi_pharm', 'birthday_gift'), ('hugel', 'foundation_day_leave'))
 ORDER BY c.COMP_ENG_NM, b.BENEFIT_CD;

START TRANSACTION;

-- ── 재코딩 15행 ──────────────────────────────────────────────────────────

-- 에코프로 — 「사택/정착지원금」 housing_loan → relocation
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ecopro');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'relocation'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'housing_loan' AND BENEFIT_NM = '사택/정착지원금'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '사택 또는 정착지원금 지급' AND BADGE_CD = 'official';

-- 에코프로비엠 — 「정착 지원금」 housing_loan → relocation
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ecopro_bm');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'relocation'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'housing_loan' AND BENEFIT_NM = '정착 지원금'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '정착 지원금 지원' AND BADGE_CD = 'official';

-- 올릭스 — 「주거 지원」 housing_loan → housing_support
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'olix');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'housing_support'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'housing_loan' AND BENEFIT_NM = '주거 지원'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '주거 지원' AND BADGE_CD = 'official';

-- 카카오뱅크 — 「자기계발비」 welfare_point(perks) → self_development(growth). 금액 600 stated 는 그대로
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_bank');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD      = 'self_development',
       BENEFIT_CTGR_CD = 'growth',
       SORT_ORDER_NO   = 61
 WHERE COMP_ID = @c AND BENEFIT_CD = 'welfare_point' AND BENEFIT_NM = '자기계발비'
   AND BENEFIT_AMT = 600 AND QUAL_YN = FALSE AND AMT_SOURCE_CD = 'stated'
   AND NOTE_CTNT = '연 600만원 자기계발비' AND BADGE_CD = 'official';

-- NAVER — 「개인 업무 지원비」 welfare_point(perks) → self_development(growth). 금액 360 stated 는 그대로
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'naver');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD      = 'self_development',
       BENEFIT_CTGR_CD = 'growth',
       SORT_ORDER_NO   = 62
 WHERE COMP_ID = @c AND BENEFIT_CD = 'welfare_point' AND BENEFIT_NM = '개인 업무 지원비'
   AND BENEFIT_AMT = 360 AND QUAL_YN = FALSE AND AMT_SOURCE_CD = 'stated'
   AND NOTE_CTNT = '업무 몰입 위한 연간 360만원 지원금' AND BADGE_CD = 'official';

-- 삼양식품 — 「자녀입학 축하금 지원」 child_edu → parenting
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samyang_foods');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'parenting'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'child_edu' AND BENEFIT_NM = '자녀입학 축하금 지원'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '임직원들 자녀 입학 축하금 지원 (공식 채용 페이지 복리 후생 항목 그대로 — 축하금 금액·대상 학교급·자녀 수 제한 미기재. 학자금 지원 여부 미기재)'
   AND BADGE_CD = 'official';

-- 대한항공 — 「보육비 지원」 childcare → parenting
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'korean_air');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'parenting'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'childcare' AND BENEFIT_NM = '보육비 지원'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '보육비 지원' AND BADGE_CD = 'official';

-- 펄어비스 — 「부모 요양 치료비」 parenting → parent_care(새 코드). 금액 480 stated 는 그대로
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'pearl_abyss');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'parent_care'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting' AND BENEFIT_NM = '부모 요양 치료비'
   AND BENEFIT_AMT = 480 AND QUAL_YN = FALSE AND AMT_SOURCE_CD = 'stated'
   AND NOTE_CTNT = '매월 최대 40만원 x 12개월' AND BADGE_CD = 'official';

-- LS — 「헬스케어비」 health_check → medical. 금액 30 stated 는 그대로
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ls');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'medical'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'health_check' AND BENEFIT_NM = '헬스케어비'
   AND BENEFIT_AMT = 30 AND QUAL_YN = FALSE AND AMT_SOURCE_CD = 'stated'
   AND NOTE_CTNT = '연 1회 건강관련 비용(검진/약/주사 등) 지원' AND BADGE_CD = 'official';

-- 현대모비스 — 「거점오피스」 remote_office → satellite_office
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_mobis');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'satellite_office'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'remote_office' AND BENEFIT_NM = '거점오피스'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '집 근처 거점오피스에서 근무 가능' AND BADGE_CD = 'official';

-- 에코프로 — 「생일 상품권」 birthday_leave(time_off) → birthday_gift(perks)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ecopro');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD      = 'birthday_gift',
       BENEFIT_CTGR_CD = 'perks',
       SORT_ORDER_NO   = 83
 WHERE COMP_ID = @c AND BENEFIT_CD = 'birthday_leave' AND BENEFIT_NM = '생일 상품권'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '근로자 생일 상품권 지급' AND BADGE_CD = 'official';

-- 엔씨소프트 — 「생일 페이코 지급」 birthday_leave(time_off) → birthday_gift(perks). 금액 10 stated 는 그대로
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ncsoft');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD      = 'birthday_gift',
       BENEFIT_CTGR_CD = 'perks',
       SORT_ORDER_NO   = 84
 WHERE COMP_ID = @c AND BENEFIT_CD = 'birthday_leave' AND BENEFIT_NM = '생일 페이코 지급'
   AND BENEFIT_AMT = 10 AND QUAL_YN = FALSE AND AMT_SOURCE_CD = 'stated'
   AND NOTE_CTNT = '생일자 페이코 10만원 지급' AND BADGE_CD = 'official';

-- 컴투스 — 「생일 선물」 birthday_leave(time_off) → birthday_gift(perks)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'com2us');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD      = 'birthday_gift',
       BENEFIT_CTGR_CD = 'perks',
       SORT_ORDER_NO   = 85
 WHERE COMP_ID = @c AND BENEFIT_CD = 'birthday_leave' AND BENEFIT_NM = '생일 선물'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '생일 선물 지급' AND BADGE_CD = 'official';

-- 한미약품 — 「기념일 축하 (연 4회 포인트)」 birthday_leave(time_off) → birthday_gift(perks)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanmi_pharm');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD      = 'birthday_gift',
       BENEFIT_CTGR_CD = 'perks',
       SORT_ORDER_NO   = 83
 WHERE COMP_ID = @c AND BENEFIT_CD = 'birthday_leave' AND BENEFIT_NM = '기념일 축하 (연 4회 포인트)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '입사 1주년 축하 선물(Retention Program), 기념일 연 4회 포인트 지급'
   AND BADGE_CD = 'official';

-- 휴젤 — 「창립기념일 휴무」 birthday_leave → foundation_day_leave(같은 time_off, 정렬 그대로)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hugel');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'foundation_day_leave'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'birthday_leave' AND BENEFIT_NM = '창립기념일 휴무'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '창립기념일 대체 휴무' AND BADGE_CD = 'official';

-- ── 정성 전환 2행 ────────────────────────────────────────────────────────

-- 현대제철 — 의료비 100 은 비율(본인 100%)이다. 금액을 걷고 비율 사실은 설명으로
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_steel');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '본인 100%, 가족 50%',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'medical' AND BENEFIT_NM = '의료비 지원'
   AND BENEFIT_AMT = 100 AND QUAL_YN = FALSE AND AMT_SOURCE_CD = 'stated'
   AND NOTE_CTNT = '본인 100%, 가족 50%' AND BADGE_CD = 'official';

-- S-Oil — 상여금 800 은 비율(연 800%)이다. 금액을 걷고 비율 사실은 설명으로
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 's_oil');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_AMT    = NULL,
       QUAL_YN        = TRUE,
       AMT_SOURCE_CD  = 'none',
       QUAL_DESC_CTNT = '연 800% 상여금',
       NOTE_CTNT      = NULL
 WHERE COMP_ID = @c AND BENEFIT_CD = 'bonus' AND BENEFIT_NM = '상여금'
   AND BENEFIT_AMT = 800 AND QUAL_YN = FALSE AND AMT_SOURCE_CD = 'stated'
   AND NOTE_CTNT = '연 800% 상여금' AND BADGE_CD = 'official';

-- ── 합치기 1곳(아이센스) — UPDATE 1 + DELETE 2 ──────────────────────────

SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'isens');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '임신 축하 복지포인트·출산 축하금, 육아용품·당뇨관리 용품 지원, 아동 심리상담 지원, 미취학 자녀 보육수당, 초/중/고/대학교 입학축하금 지급'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting' AND BENEFIT_NM = '모성보호'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '임신 축하 복지포인트·출산 축하금, 육아용품·당뇨관리 용품 지원, 아동 심리상담 지원 등'
   AND BADGE_CD = 'official';
-- 합친 문안이 실제로 들어갔을 때만 1 — 아래 두 DELETE 의 전제
SET @merged = (SELECT COUNT(*) FROM TCOMPANY_BENEFIT
                WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
                  AND QUAL_DESC_CTNT = '임신 축하 복지포인트·출산 축하금, 육아용품·당뇨관리 용품 지원, 아동 심리상담 지원, 미취학 자녀 보육수당, 초/중/고/대학교 입학축하금 지급');
DELETE FROM TCOMPANY_BENEFIT
 WHERE COMP_ID = @c AND BENEFIT_CD = 'child_edu' AND BENEFIT_NM = '자녀 입학축하금'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '초/중/고/대학교 입학축하금 지급' AND BADGE_CD = 'official'
   AND @merged = 1
   AND NOT EXISTS (SELECT 1 FROM TBENEFIT_EDIT_LOG l WHERE l.BENEFIT_ID = TCOMPANY_BENEFIT.BENEFIT_ID);
DELETE FROM TCOMPANY_BENEFIT
 WHERE COMP_ID = @c AND BENEFIT_CD = 'childcare' AND BENEFIT_NM = '보육수당'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '미취학 자녀 보육수당 지급' AND BADGE_CD = 'official'
   AND @merged = 1
   AND NOT EXISTS (SELECT 1 FROM TBENEFIT_EDIT_LOG l WHERE l.BENEFIT_ID = TCOMPANY_BENEFIT.BENEFIT_ID);

COMMIT;

-- 사후 확인(읽기 전용) — 재코딩 15행 + 현대제철 medical + S-Oil bonus + 아이센스 parenting = 18행.
--   옛 자리(아이센스 child_edu·childcare · 현대모비스 remote_office · NAVER welfare_point ·
--   5개사 birthday_leave)는 나오지 않아야 한다.
SELECT c.COMP_ENG_NM, b.BENEFIT_ID, b.BENEFIT_CD, b.BENEFIT_CTGR_CD, b.BENEFIT_NM, b.BENEFIT_AMT,
       b.AMT_SOURCE_CD, b.QUAL_YN
  FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE (c.COMP_ENG_NM, b.BENEFIT_CD) IN (
        ('ecopro', 'relocation'), ('ecopro_bm', 'relocation'), ('olix', 'housing_support'),
        ('kakao_bank', 'self_development'), ('samyang_foods', 'parenting'), ('korean_air', 'parenting'),
        ('pearl_abyss', 'parent_care'), ('ls', 'medical'), ('hyundai_mobis', 'satellite_office'),
        ('naver', 'self_development'), ('hyundai_steel', 'medical'), ('s_oil', 'bonus'), ('isens', 'parenting'),
        ('ecopro', 'birthday_gift'), ('ncsoft', 'birthday_gift'), ('com2us', 'birthday_gift'),
        ('hanmi_pharm', 'birthday_gift'), ('hugel', 'foundation_day_leave'),
        ('isens', 'child_edu'), ('isens', 'childcare'), ('hyundai_mobis', 'remote_office'),
        ('naver', 'welfare_point'),
        ('ecopro', 'birthday_leave'), ('ncsoft', 'birthday_leave'), ('com2us', 'birthday_leave'),
        ('hanmi_pharm', 'birthday_leave'), ('hugel', 'birthday_leave'))
 ORDER BY c.COMP_ENG_NM, b.BENEFIT_CD;
