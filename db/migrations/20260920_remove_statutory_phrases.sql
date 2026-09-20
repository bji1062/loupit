-- ══════════════════════════════════════════════════════════════════════
-- 법정 제도 문구 정리 — 사용자 노출 문안 52행 UPDATE (삭제 0 · 행 수 불변)
-- 결정: 2026-09-20 리드 지시 · 판정 정본: 레인 A 육아·출산 29행 · 레인 B 휴가·근속 23행
-- 선례: 20260918_recode_misclassified_rows.sql (같은 형식 · 같은 가드 방식)
--
-- 왜 필요한가: 복지는 「법이 시킨 것 위에 더 얹은 것」이다(SP-LEGAL). 그런데 52개 행의
--   설명·항목명에 근로기준법·남녀고용평등법이 모든 회사에 강제하는 제도(출산휴가 90일,
--   배우자 출산휴가, 육아휴직 제도명, 임신기·육아기 근로시간 단축, 가족돌봄휴가 10일·
--   휴직 90일, 연차·반차, 보건휴가, 잔여연차 수당 정산, 법정의무교육)가 회사 급부처럼
--   섞여 있었다. 그대로 두면 법을 지키는 것만으로 복지가 두꺼워 보인다.
--   법정 수치를 복제한 문구(「법정 1년 외 추가 1년」)는 법이 개정되면 그 자리에서 거짓이
--   된다 — NAVER 문안의 「법정 1년」은 2025-02-23 개정(18개월)으로 이미 틀려 있었다.
--
-- 무엇을 바꾸나: BENEFIT_NM · QUAL_DESC_CTNT 두 사용자 노출 필드뿐이다.
--   코드·카테고리·금액·SORT·배지는 한 칸도 건드리지 않는다. 행도 지우지 않는다.
--   · 레인 A 29행 — 육아·출산·난임. 법정분을 걷고 회사 상회분(육아휴직 2년, 플러스제
--     2년 6개월, 선물·축하금·시술비·시설)만 남긴다.
--   · 레인 B 23행 — 휴가·근속. CJ 계열 5사 창의휴가에서 「연차 결합 시 최대 4주」를 걷고
--     (직원 본인 연차가 회사 급부로 세어지고 있었다), 법정 나열에서 복지만 남긴다.
--
-- 행을 지우지 않는 이유: 법정만 있는 행은 삭제가 아니라 `generator/data/legal_rows.json`
--   등록으로 처리한다 — 행은 남기고 화면에 「법정」 배지를 달아 복지 항목 수 집계에서만
--   뺀다(사용자 결정 2026-09-16). 같은 PR 이 그 파일에 2행(CJ올리브영 시간 연차 ·
--   제주반도체 반차·반반차 휴가)을 새로 등록했다. 그 2행의 BENEFIT_NM 은 판정 키라서
--   여기서 바꾸지 않는다. 이미 등록된 16행도 같은 이유로 이 마이그레이션에 없다.
--
-- 적용: mysql -vv -h <host> -u <user> -p <DB> < db/migrations/20260920_remove_statutory_phrases.sql
--   -vv 를 붙여야 문마다 Rows matched 가 찍힌다. 붙이지 않으면 0행이어도 조용히 성공한다.
--   맨 앞 0단계 SELECT 는 읽기 전용이다 — 이것만 먼저 돌려 52행이 옛 문안 그대로인지,
--   EDIT_LOGS 가 0 인지 보고 적용해도 된다.
-- 기대 영향 행 수: 52 (UPDATE 문 52개 각 1). 적으면 멈추고 확인하라 — 회사명 오타면
--   @c 가 NULL 이라 오류 없이 0행이고, BADGE_CD 가 official 이 아니거나 문안이 이미
--   다르면 가드가 일부러 건너뛴 것이다.
-- 멱등: 모든 WHERE 가 **옛 문안 전체**(코드·항목명·설명·금액·QUAL_YN·NOTE·배지)를 본다 —
--   두 번째 실행은 전부 0행이고, 이미 고쳐진 행에는 닿지 않는다.
-- 가드: BADGE_CD = official — 재직자가 고친 행은 조용히 덮지 않는다.
-- 시드: 같은 52행을 db/seed/benefit/sql/*.sql 에서도 같은 종착 상태로 고쳤다. 코드가
--   그대로라 시드 업서트는 같은 키를 덮어쓴다 — 이 마이그레이션 없이 시드만 재적용해도
--   결과는 같지만, 서빙 DB 를 직접 맞추는 경로는 이 파일이다.
-- 순서: 정적 재생성(release)보다 **먼저**. DB 가 옛 문안인 채로 재생성하면 법정 문구가
--   그대로 페이지에 다시 구워진다.
-- 행 수: 삭제·추가가 없으므로 SD-4 핀 2452 는 그대로다.
-- ══════════════════════════════════════════════════════════════════════

-- 0) 점검(읽기 전용) — 대상 52행이 옛 문안 그대로인지 + 편집 이력 참조 수
SELECT c.COMP_ENG_NM, b.BENEFIT_ID, b.BENEFIT_CD, b.BENEFIT_NM, b.SORT_ORDER_NO, b.BADGE_CD,
       (SELECT COUNT(*) FROM TBENEFIT_EDIT_LOG l WHERE l.BENEFIT_ID = b.BENEFIT_ID) AS EDIT_LOGS
  FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE (c.COMP_ENG_NM, b.BENEFIT_CD) IN (
        ('alteogen', 'leave_general'), ('amorepacific', 'parenting'), ('apr', 'leave_general'),
        ('caregen', 'leave_general'), ('cj', 'parenting'), ('cj_cgv', 'long_service_leave'),
        ('cj_cgv', 'parenting'), ('cj_enm_com', 'long_service_leave'), ('cj_enm_com', 'parenting'),
        ('cj_enm_ent', 'long_service_leave'), ('cj_enm_ent', 'parenting'),
        ('cj_freshway', 'long_service_leave'), ('cj_freshway', 'parenting'),
        ('cj_logistics', 'parenting'), ('cj_oliveyoung', 'long_service_leave'),
        ('cj_oliveyoung', 'parenting'), ('classys', 'leave_general'), ('com2us', 'leave_general'),
        ('coway', 'parenting'), ('daeduck', 'leave_general'), ('dongjin_semichem', 'summer_leave'),
        ('doosan_enerbility', 'parenting'), ('hanwha_life', 'childcare'), ('hanwha_life', 'parenting'),
        ('hyundai_autoever', 'refresh_leave'), ('hyundai_mobis', 'leave_general'),
        ('hyundai_mobis', 'parenting'), ('hyundai_motor', 'parenting'), ('isens', 'fertility_support'),
        ('isens', 'parenting'), ('kakao', 'edu_support'), ('kakao', 'parenting'),
        ('kakao_games', 'parenting'), ('lig_nex1', 'childcare'), ('lotte_chem', 'parenting'),
        ('naver', 'leave_general'), ('naver', 'parenting'), ('netmarble', 'parenting'),
        ('olix', 'leave_general'), ('posco_futurem', 'leave_general'), ('posco_intl', 'parenting'),
        ('remed', 'leave_general'), ('samsung_fire', 'fertility_support'),
        ('samsung_fire', 'parenting'), ('samsung_heavy', 'parenting'), ('sk_hynix', 'parenting'),
        ('sk_innovation', 'leave_general'), ('skt', 'parenting'), ('voronoi', 'leave_general'),
        ('wgames', 'leave_general'), ('wgames', 'parenting'), ('yuhan', 'leave_general'))
 ORDER BY c.COMP_ENG_NM, b.SORT_ORDER_NO;

START TRANSACTION;

-- ── 레인 A — 육아·출산·난임 29행 ──────────────────────────────

-- CJ SORT 50 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '임신 축하 선물과 택시 쿠폰, 출산 선물, 초등 입학 자녀 돌봄휴가 최대 4주, 난임 시술비, 장애 자녀 양육비 지원'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '임신/출산/육아'
   AND QUAL_DESC_CTNT = '임신축하선물/택시쿠폰, 태아검진휴가, 출산선물, 초등입학 돌봄휴가 최대4주, 난임시술비, 장애자녀 양육비'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- CJCGV SORT 40 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_cgv');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '육아휴직 플러스제 — 만 8세 또는 초등학교 2학년 이하 자녀 대상 최대 2년 6개월, 입학 자녀 돌봄휴가 최대 4주, 난임휴직 최대 6개월, 임신 축하 선물'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '임신·출산·육아'
   AND QUAL_DESC_CTNT = '육아휴직 플러스제(만8세/초2 이하 자녀 시 최대 2.5년), 입학자녀 돌봄휴가 최대 4주, 난임휴직 최대 6개월, 배우자 출산휴가, 임신 축하 선물'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- CJENM엔터테인먼트부문 SORT 40 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_enm_ent');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '육아휴직 자녀당 최대 2년 6개월 중 회사 지원 추가 1년, 임신 12~36주 중 8주간 1일 2시간 단축근무, 출산 후 3개월간 1일 2시간 단축근무, 배우자 출산휴가 회사 지원 추가 최대 14일, 난임휴직, 임신 축하 선물 약 12만원 상당, 자녀 수능 선물 약 3만원 상당과 대표이사 응원 카드'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '임신·출산·육아'
   AND QUAL_DESC_CTNT = '육아휴직 최대 2년 6개월(법정 1년 6개월 + 추가 1년), 임신 12~36주 중 8주간 1일 2시간 단축, 출산 후 3개월 1일 2시간 단축, 배우자 출산휴가 법정 외 최대 14일 추가, 난임휴직, 임신 축하 선물(약 12만원 상당), 자녀 수능 선물(약 3만원 상당 + 대표이사 응원 카드)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- CJENM커머스부문 SORT 40 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_enm_com');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '육아휴직 자녀당 최대 2년 6개월 중 회사 지원 추가 1년, 자녀 초등 입학 선물, 산모 교실 연 2회(상·하반기), 배우자 출산휴가 회사 지원 추가 최대 14일, 난임휴직'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '임신·출산·육아'
   AND QUAL_DESC_CTNT = '육아휴직 최대 2년 6개월(법정 1년 6개월 + 추가 1년), 자녀 초등 입학 선물, 산모 교실 연 2회(상·하반기), 배우자 출산휴가 법정 외 최대 14일 추가, 난임휴직'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- CJ대한통운 SORT 40 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_logistics');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '육아휴직 플러스제 — 만 8세 또는 초등학교 2학년 이하 자녀 대상 최대 2년 6개월, 입학 자녀 돌봄휴가 최대 4주, 난임휴직 최대 6개월, 임신 축하 선물'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '임신·출산·육아'
   AND QUAL_DESC_CTNT = '육아휴직 플러스제(만8세/초2 이하 자녀 시 최대 2.5년), 입학자녀 돌봄휴가 최대 4주, 난임휴직 최대 6개월, 배우자 출산휴가, 임신 축하 선물'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- CJ올리브영 SORT 40 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_oliveyoung');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '육아휴직 최대 2년, 수험생 자녀 선물'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '임신·출산·육아'
   AND QUAL_DESC_CTNT = '육아휴직 최대 2년, 가족돌봄 연 최대 10일 + 최대 90일, 수험생 자녀 선물'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- CJ프레시웨이 SORT 40 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_freshway');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '육아휴직 총 2년'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '임신·출산·육아'
   AND QUAL_DESC_CTNT = '육아휴직 총 2년, 가족돌봄 연 10일 무급휴가 + 최대 90일 무급휴직'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- LIG넥스원 SORT 50 `childcare` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '직장 어린이집 운영'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'childcare'
   AND BENEFIT_NM = '직장 어린이집'
   AND QUAL_DESC_CTNT = '직장 어린이집 운영, 육아기 근로단축'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- NAVER SORT 50 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'naver');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '회사 지원 추가 1년 포함 총 2년 육아휴직'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '육아휴직 2년'
   AND QUAL_DESC_CTNT = '법정 1년 외 추가 1년, 총 2년 육아휴직'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- SK텔레콤 SORT 50 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'skt');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '육아휴직 남녀 2년, 초등학교 입학 시 3개월 휴직'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '출산/육아 지원'
   AND QUAL_DESC_CTNT = '출산휴가 90일(배우자10일), 육아휴직 남녀2년(2회 분할), 초등입학시 3개월 휴직'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- SK하이닉스 SORT 50 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_hynix');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '임신 전 기간 단축근무, 난임 의료비, 다자녀 출산축하금, 입학 자녀 돌봄휴직 3개월, 도담이방 임산부 휴게공간 운영'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '임신/출산/육아 지원'
   AND QUAL_DESC_CTNT = '임신 전기간 단축근무, 난임휴가/의료비, 다자녀 출산축하금, 입학자녀 돌봄휴직 3개월, 도담이방(임산부 휴게공간)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 넷마블 SORT 51 `parenting` — 항목명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'netmarble');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '임신·출산 지원'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '모성보호 지원'
   AND QUAL_DESC_CTNT = '임신 전 기간 단축 근로와 임신·출산 선물, 기준에 따른 출산 병원비 지원. 공식 인사제도 페이지에는 없고 넷마블컴퍼니 채용 웰니스 페이지에만 기재 (넷마블컴퍼니 공통 채용 기준)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 더블유게임즈 SORT 50 `parenting` — 항목명·설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'wgames');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '출산 경조금',
       QUAL_DESC_CTNT = '출산 경조금 50만원, 다태아 75만원 지급'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '출산/육아 지원'
   AND QUAL_DESC_CTNT = '경조금 50만원(다태아 75만원), 출산휴가 90일(다태아 120일), 임산부 2시간 단축, 육아휴직 1년'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 두산에너빌리티 SORT 50 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'doosan_enerbility');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '출산 축하 신생아용품과 난임 시술비 지원'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '임신/출산/육아'
   AND QUAL_DESC_CTNT = '출산축하 신생아용품, 출산휴가/육아휴직/근로시간단축/가족돌봄 휴직, 난임시술비 지원'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 롯데케미칼 SORT 53 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_chem');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '여성 자동 육아휴직 2년, 남성 육아휴직 의무 사용'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '출산/육아 정책'
   AND QUAL_DESC_CTNT = '여성 자동육아휴직(2년), 남성 육아휴직 의무화'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 삼성중공업 SORT 21 `parenting` — 항목명·설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_heavy');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '임산부 휴식공간',
       QUAL_DESC_CTNT = '임산부 휴식공간 제공 (위치·이용 대상 미기재)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '모성보호제도'
   AND QUAL_DESC_CTNT = '임산부 휴식공간 제공 등 모성보호제도 운영 (적용 기간·대상 범위 미기재)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 삼성화재 SORT 30 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_fire');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '생활안정 지원 항목의 출산 축하금과 임산부 물품 지원 (공식 페이지 — 축하금 액수·지원 품목 미기재)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '출산 축하금·임산부 지원'
   AND QUAL_DESC_CTNT = '생활안정 지원의 출산 축하금과 모성보호제도의 임산부 물품지원 (공식 페이지 — 축하금 액수·지원 품목 미기재)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 삼성화재 SORT 34 `fertility_support` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_fire');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '난임 치료비 지원 (공식 페이지 — 지원 한도·횟수 미기재)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'fertility_support'
   AND BENEFIT_NM = '난임 치료비 지원'
   AND QUAL_DESC_CTNT = '모성보호제도의 난임 치료비 지원 (공식 페이지 — 지원 한도·횟수 미기재)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 아모레퍼시픽 SORT 52 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'amorepacific');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '임산부 전용 의자와 발받침대, 담요 제공'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '예비맘 배려'
   AND QUAL_DESC_CTNT = '예비맘 단축근무, 임산부 전용 의자/발받침대/담요, 태아검진 외출/조퇴 허용'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 아이센스 SORT 53 `parenting` — 항목명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'isens');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '임신·출산·육아 지원'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '모성보호'
   AND QUAL_DESC_CTNT = '임신 축하 복지포인트·출산 축하금, 육아용품·당뇨관리 용품 지원, 아동 심리상담 지원, 미취학 자녀 보육수당, 초/중/고/대학교 입학축하금 지급'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 아이센스 SORT 54 `fertility_support` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'isens');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '난임 지원 복지포인트 지급'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'fertility_support'
   AND BENEFIT_NM = '난임 지원'
   AND QUAL_DESC_CTNT = '난임 지원 복지포인트 및 난임 휴가 유급 지원'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 카카오 SORT 50 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '출산 선물 지급'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '출산/육아 지원'
   AND QUAL_DESC_CTNT = '출산 선물, 배우자 유사산 휴가, 임신기간/육아기 단축근무'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 카카오게임즈 SORT 50 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_games');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '임신·출산 선물과 근무시간 변경'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '슈퍼맘 서포트'
   AND QUAL_DESC_CTNT = '임신/출산 선물, 근무시간 변경, 임산부 정기검진 유급휴가, 난임휴가, 육아휴직'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 코웨이 SORT 51 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'coway');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '자녀 입학 휴가와 난임 휴직 운영 (여성가족부 가족친화인증 2012년부터 유지)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '출산/육아 지원'
   AND QUAL_DESC_CTNT = '자녀 입학 휴가, 난임 휴직, 배우자 출산 휴가, 남녀 구분 없는 육아휴직 제도 (여성가족부 가족친화인증 2012년~현재)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 포스코인터내셔널 SORT 73 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'posco_intl');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '출산장려금 첫째 300만원, 둘째 이상 500만원 및 선물 지급, 육아 목적 일반휴직 1년 추가 사용 가능 (공식 홈페이지 복리후생 Family Care 항목 — 선물 내용·일반휴직 기간 급여 미기재)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '출산장려금·육아 일반휴직'
   AND QUAL_DESC_CTNT = '출산장려금 첫째 300만원, 둘째 이상 500만원 및 선물 지급, 육아 목적 일반휴직 1년 추가 사용 가능 (공식 홈페이지 복리후생 Family Care 출산장려금 지급·육아휴직 항목 — 선물 내용·일반휴직 기간 급여 미기재)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 한화생명 SORT 32 `childcare` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha_life');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '사내 어린이집 (공식 복리후생 페이지 항목명 그대로 — 설치 사업장·정원·대상 연령 미기재)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'childcare'
   AND BENEFIT_NM = '사내 어린이집'
   AND QUAL_DESC_CTNT = '사내 어린이집 (공식 복리후생 페이지 모성보호지원 항목명 그대로 — 설치 사업장·정원·대상 연령 미기재)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 한화생명 SORT 33 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha_life');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '모성보호 Cafe 운영 및 임신직원 맘’s 패키지 제공 (공식 복리후생 페이지 항목명 그대로 — 시설 위치·패키지 구성·지급 시점 미기재)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '모성보호 Cafe·임신직원 패키지'
   AND QUAL_DESC_CTNT = '모성보호 Cafe 운영 및 임신직원 맘’s 패키지 제공 (공식 복리후생 페이지 모성보호지원 항목명 그대로 — 시설 위치·패키지 구성·지급 시점 미기재)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 현대모비스 SORT 51 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_mobis');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '육아휴직 자녀당 최대 2년, 상병휴직 지원'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '임신/출산/육아 지원'
   AND QUAL_DESC_CTNT = '임신기/육아기 근로시간 단축, 출산 전후 휴가, 육아휴직 자녀당 최대 2년, 가족돌봄휴직 최대 90일, 상병휴직 지원'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 현대자동차 SORT 50 `parenting` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_motor');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '육아휴직 최대 2년, 가족여행 2박 3일 숙식 지원'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '출산/육아 지원'
   AND QUAL_DESC_CTNT = '출산휴가(여90일/남10일), 육아휴직 최대2년, 가족여행(2박3일 숙식), 난임치료 연3일 휴가'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- ── 레인 B — 휴가·근속 23행 ────────────────────────────────────

-- CJCGV SORT 20 `long_service_leave` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_cgv');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '근속 3·5·7·10년(이후 5년마다) 2주 유급휴가'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = 'CREATIVE WEEK(창의휴가)'
   AND QUAL_DESC_CTNT = '근속 3·5·7·10년(이후 5년마다) 2주 유급휴가, 연차 결합 시 최대 4주'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- CJENM엔터테인먼트부문 SORT 20 `long_service_leave` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_enm_ent');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '근속 3·5·7·10년(이후 5년마다) 2주 유급휴가'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = 'CREATIVE WEEK(창의휴가)'
   AND QUAL_DESC_CTNT = '근속 3·5·7·10년(이후 5년마다) 2주 유급휴가, 연차 결합 시 최대 4주'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- CJENM커머스부문 SORT 20 `long_service_leave` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_enm_com');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '근속 3·5·7·10년(이후 5년마다) 2주 유급휴가'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = 'CREATIVE WEEK(창의휴가)'
   AND QUAL_DESC_CTNT = '근속 3·5·7·10년(이후 5년마다) 2주 유급휴가, 연차 결합 시 최대 4주'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- CJ올리브영 SORT 20 `long_service_leave` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_oliveyoung');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '근속 3·5·7·10년(이후 5년마다) 2주 유급휴가'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = 'CREATIVE WEEK(창의휴가)'
   AND QUAL_DESC_CTNT = '근속 3·5·7·10년(이후 5년마다) 2주 유급휴가, 연차 결합 시 최대 4주'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- CJ프레시웨이 SORT 20 `long_service_leave` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj_freshway');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '근속 3·5·7·10년(이후 5년마다) 2주 유급휴가'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = 'CREATIVE WEEK(창의휴가)'
   AND QUAL_DESC_CTNT = '근속 3·5·7·10년(이후 5년마다) 2주 유급휴가, 연차 결합 시 최대 4주'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- SK이노베이션 SORT 30 `leave_general` — 항목명·설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_innovation');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '창립기념일 휴무·경조휴가',
       QUAL_DESC_CTNT = '창립기념일 휴무 및 경조휴가 운영'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '휴가제도'
   AND QUAL_DESC_CTNT = '연차, 반차, 경조휴가, 창립일휴무, 근로자의날 휴무'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 케어젠 SORT 30 `leave_general` — 항목명·설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'caregen');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '경조휴가·휴가비 지원',
       QUAL_DESC_CTNT = '경조휴가 및 휴가비 지원'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '연차/반차/경조휴가'
   AND QUAL_DESC_CTNT = '연차, 반차, 경조휴가, 근로자의 날 휴무'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT = '휴가비 지원' AND BADGE_CD = 'official';

-- 클래시스 SORT 30 `leave_general` — 항목명·설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'classys');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '경조휴가',
       QUAL_DESC_CTNT = '경조휴가 제공'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '연차/보건휴가/경조휴가'
   AND QUAL_DESC_CTNT = '연차, 보건휴가, 경조휴가, 근로자의 날 휴무'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 보로노이 SORT 30 `leave_general` — 항목명·설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'voronoi');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '경조휴가·창립일 휴무',
       QUAL_DESC_CTNT = '경조휴가 및 창립일 휴무'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '연차/반차/시간제연차'
   AND QUAL_DESC_CTNT = '연차, 반차, 시간제연차, 경조휴가, 창립일 휴무'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 컴투스 SORT 30 `leave_general` — 항목명·설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'com2us');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '창립기념일·크리스마스 다음날 휴무',
       QUAL_DESC_CTNT = '창립기념일 휴무, 크리스마스 다음날 유급휴일'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '1시간 단위 연차 + 창립기념일'
   AND QUAL_DESC_CTNT = '1시간 단위 연차 사용, 창립기념일 휴무, 크리스마스 다음날 유급휴일'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 알테오젠 SORT 20 `leave_general` — 항목명·설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'alteogen');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '경조휴가',
       QUAL_DESC_CTNT = '경조휴가 제공'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '연차·경조휴가'
   AND QUAL_DESC_CTNT = '연차 및 경조휴가 제공'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 리메드 SORT 30 `leave_general` — 항목명·설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'remed');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '정기휴가·연말휴가',
       QUAL_DESC_CTNT = '정기휴가와 연말휴가 운영'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '연차/정기휴가/연말휴가'
   AND QUAL_DESC_CTNT = '연차, 정기휴가, 연말휴가'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 더블유게임즈 SORT 32 `leave_general` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'wgames');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '연말 1일 유급휴가, 이사 유급휴가, 백신 유급휴가'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '연말/이사 유급휴가'
   AND QUAL_DESC_CTNT = '연말 1일 유급휴가, 이사 유급휴가, 백신 유급휴가, 잔여연차 수당 정산'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 현대오토에버 SORT 30 `refresh_leave` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_autoever');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '연차 외 별도 5일 휴가, 백신 접종 휴가, 휴가비 지원'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'refresh_leave'
   AND BENEFIT_NM = '별도 휴가'
   AND QUAL_DESC_CTNT = '연차 외 별도 5일 휴가, 백신/보건휴가, 휴가비 지원'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- NAVER SORT 31 `leave_general` — 항목명·설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'naver');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '자기돌봄 휴직',
       QUAL_DESC_CTNT = '3년 이상 근속자 대상 최대 6개월 무급 자기돌봄 휴직'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '자기돌봄/가족돌봄 휴직'
   AND QUAL_DESC_CTNT = '자기돌봄 휴직(3년 이상 근속, 최대 6개월 무급), 가족돌봄 휴가(최대 90일)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 대덕전자 SORT 70 `leave_general` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'daeduck');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '연중휴가 및 휴가비 지원 (공식 복지제도 페이지 워라밸 항목명 그대로 — 연중 사용 휴가 운영과 휴가비 지원을 한 항목으로 표기. 부여 일수·휴가비 지급액 미기재)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '연중휴가·휴가비 지원'
   AND QUAL_DESC_CTNT = '연중휴가 및 휴가비 지원 (공식 복지제도 페이지 워라밸 항목명 그대로 — 연중 사용 휴가 운영과 휴가비 지원을 한 항목으로 표기. 법정 연차 상회 일수·휴가비 지급액 미기재)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 동진쎄미켐 SORT 20 `summer_leave` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'dongjin_semichem');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '연차와 별도로 운영하는 하계휴가 — 부여 일수·사용 시기 미기재'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'summer_leave'
   AND BENEFIT_NM = '하계휴가'
   AND QUAL_DESC_CTNT = '하계휴가 별도 운영 — 법정 연차와 별도로 운영한다는 서술만 있고 부여 일수·시기 미기재'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 에이피알 SORT 30 `leave_general` — 항목명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'apr');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '셀프 승인 휴가'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '셀프 승인 연차'
   AND QUAL_DESC_CTNT = '휴가 셀프 승인제도 운영'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 올릭스 SORT 30 `leave_general` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'olix');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '연차 20일 제공'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '연차 20일'
   AND QUAL_DESC_CTNT = '연차 20일 제공, 가족돌봄휴가 제공'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 유한양행 SORT 30 `leave_general` — 항목명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'yuhan');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '연차휴가 22일(최대 32일)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '연차휴가 (법정 상회)'
   AND QUAL_DESC_CTNT = '연간 22일(최대 32일) 연차휴가 부여, 자유로운 휴가사용 문화'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 카카오 SORT 60 `edu_support` — 설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '입문교육, 직책자 리더십, 직무역량, 공통역량 과정 운영'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'edu_support'
   AND BENEFIT_NM = '교육 지원'
   AND QUAL_DESC_CTNT = '입문교육, 직책자 리더십, 직무역량, 공통역량, 법정의무교육'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 포스코퓨처엠 SORT 70 `leave_general` — 항목명·설명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'posco_futurem');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '권장휴가·저축휴가·연차 조기사용',
       QUAL_DESC_CTNT = '권장휴가와 저축휴가 제도, 연차 조기사용 제도 운영 (공식 인사제도 페이지 복리후생 휴가제도 항목 — 권장휴가 일수·저축 한도 미기재)'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '권장휴가·저축휴가·시간단위 휴가'
   AND QUAL_DESC_CTNT = '권장휴가, 저축휴가제도 운영과 반차제도, 4시간 이내 시간단위 휴가사용 제도, 연차휴가 조기사용 제도 (공식 인사제도 페이지 복리후생 휴가제도 항목 — 권장휴가 일수·저축 한도 미기재)'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';

-- 현대모비스 SORT 30 `leave_general` — 항목명
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_mobis');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_NM     = '월차·장기근속·하계·경조 휴가'
 WHERE COMP_ID = @c AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '연월차 및 기타 휴가'
   AND QUAL_DESC_CTNT = '법정 연차 외 월차, 장기근속휴가, 하계휴가, 경조휴가 제공'
   AND BENEFIT_AMT IS NULL AND QUAL_YN = TRUE AND NOTE_CTNT IS NULL AND BADGE_CD = 'official';


COMMIT;

-- 사후 확인(읽기 전용) — 52행이 새 문안인지. 옛 문안이 하나라도 남으면 가드에 걸린 것이다.
SELECT c.COMP_ENG_NM, b.BENEFIT_ID, b.BENEFIT_CD, b.BENEFIT_NM, b.SORT_ORDER_NO, b.QUAL_DESC_CTNT
  FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE (c.COMP_ENG_NM, b.BENEFIT_CD) IN (
        ('alteogen', 'leave_general'), ('amorepacific', 'parenting'), ('apr', 'leave_general'),
        ('caregen', 'leave_general'), ('cj', 'parenting'), ('cj_cgv', 'long_service_leave'),
        ('cj_cgv', 'parenting'), ('cj_enm_com', 'long_service_leave'), ('cj_enm_com', 'parenting'),
        ('cj_enm_ent', 'long_service_leave'), ('cj_enm_ent', 'parenting'),
        ('cj_freshway', 'long_service_leave'), ('cj_freshway', 'parenting'),
        ('cj_logistics', 'parenting'), ('cj_oliveyoung', 'long_service_leave'),
        ('cj_oliveyoung', 'parenting'), ('classys', 'leave_general'), ('com2us', 'leave_general'),
        ('coway', 'parenting'), ('daeduck', 'leave_general'), ('dongjin_semichem', 'summer_leave'),
        ('doosan_enerbility', 'parenting'), ('hanwha_life', 'childcare'), ('hanwha_life', 'parenting'),
        ('hyundai_autoever', 'refresh_leave'), ('hyundai_mobis', 'leave_general'),
        ('hyundai_mobis', 'parenting'), ('hyundai_motor', 'parenting'), ('isens', 'fertility_support'),
        ('isens', 'parenting'), ('kakao', 'edu_support'), ('kakao', 'parenting'),
        ('kakao_games', 'parenting'), ('lig_nex1', 'childcare'), ('lotte_chem', 'parenting'),
        ('naver', 'leave_general'), ('naver', 'parenting'), ('netmarble', 'parenting'),
        ('olix', 'leave_general'), ('posco_futurem', 'leave_general'), ('posco_intl', 'parenting'),
        ('remed', 'leave_general'), ('samsung_fire', 'fertility_support'),
        ('samsung_fire', 'parenting'), ('samsung_heavy', 'parenting'), ('sk_hynix', 'parenting'),
        ('sk_innovation', 'leave_general'), ('skt', 'parenting'), ('voronoi', 'leave_general'),
        ('wgames', 'leave_general'), ('wgames', 'parenting'), ('yuhan', 'leave_general'))
 ORDER BY c.COMP_ENG_NM, b.SORT_ORDER_NO;
