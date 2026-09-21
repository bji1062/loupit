-- ══════════════════════════════════════════════════════════════════════
-- 복지 행 재코딩 51행 + 원문 정리 1행 — UPDATE 54문(맞바꿈·돌림의 임시 코드 경유 2문 포함)
-- 결정: 2026-09-21 세션 인계 §7-1 「1번 재코딩 43행 · 2번 유진테크 메모 노출」(사용자 지정)
-- 선례: 20260918_recode_misclassified_rows.sql (같은 가드·같은 형식)
--
-- 왜 필요한가: 복지 항목 페이지(SP-BEN)는 코드가 틀린 행을 설정 파일의 exclude 예외 43개로
--   빼 두고 있었다. 예외는 항목 페이지에서만 걷히고 회사 페이지·/find·9각형 비교는 코드 그대로
--   센다 — 같은 행이 화면마다 다른 복지로 세어진다. 원인 행의 코드를 고치면 예외가 필요 없다.
--
-- 무엇을 바꾸나: BENEFIT_CD 만(카테고리가 바뀌는 19행은 BENEFIT_CTGR_CD·SORT_ORDER_NO 도).
--   금액·이름·설명·배지는 건드리지 않는다(원문 정리 1행만 예외). BENEFIT_ID 가 그대로라
--   편집 이력(TBENEFIT_EDIT_LOG.BENEFIT_ID)이 끊기지 않는다. 카테고리는 _VOCAB.md 정본을 따른다.
--   ① commute_subsidy ↔ transport 13행 — 수집 계약 house rule 「운행 = commute_subsidy,
--      금전 = transport」. 버스 운행만 적은 transport 9행 → commute_subsidy, 교통비·택시비만
--      적은 commute_subsidy 4행 → transport. sk_innovation 은 두 행이 서로 뒤바뀌어 있어 맞바꾼다.
--   ② refresh_leave → long_service_leave 7행 — 근속 연수에 맞춰 주는 휴가(카카오뱅크·JYP·
--      삼성E&A·네오위즈 같은 모양 선례가 이미 long_service_leave 에 있다).
--   ③ long_service_leave → long_service_bonus 11행 — 어휘표 「long_service_leave = 휴가만
--      (포상금은 long_service_bonus)」. 원문에 휴가 없이 포상금·기념품·여행만 있는 행.
--      NAVER 「근속 기념 선물」이 먼저 비켜야 ② 의 NAVER 휴가 행이 그 자리에 들어간다(순서 중요).
--   ④ excellence_award → long_service_bonus 3행 — 우수 선발 포상이 아니라 근속 연동 포상.
--   ⑤ 그 밖의 1:1 재코딩 14행 — kt 통신비(discount→telecom) · 덕산네오룩스 주거 지원비
--      (dormitory→housing_support) · lg_cns 학자금 이자·원익IPS 본인 학자금(edu_support→
--      self_development) · 솔브레인 학위지원(edu_support→mba) · 주성 기념일 조기퇴근(event→
--      family_day) · 펄어비스 기념일 선물(event→birthday_gift)·패밀리데이(club→company_event) ·
--      크래프톤 명절 반차(holiday_gift→leave_general) · 레인보우로보틱스 생일 상품권(holiday_gift→
--      birthday_gift) · 한화에어로스페이스 아빠휴가(leave_general→parenting) · 삼성카드 사내카페
--      (lounge→snack_bar) · TCK 사내 영화관(lounge→library) · S-Oil 집중 휴가제(summer_leave→
--      leave_general).
--   ⑥ 삼성카드 성장 3행 돌림 — 자격 취득 지원(edu_support→self_development) · 지역전문가 제도
--      (self_development→career) · Job master 양성과정(career→edu_support). 세 코드가 한 회사에서
--      서로의 자리를 차지하고 있어 임시 코드 __recode_tmp 를 거친다.
--   ⑦ 원문 정리 1행 — 유진테크 birthday_gift 원문 끝에 수집 메모 「(기념일 선물 — 삼성카드
--      birthday_gift 선례)」가 섞여 회사 페이지와 /benefit/birthday-gift 에 코드명이 보였다.
--
-- 남기는 예외 4개(재코딩으로 못 푼다 — 목적 코드가 그 회사에 이미 있거나 맞는 코드가 없다):
--   cj_oliveyoung 트렌드 쿠폰(welfare_point·discount 둘 다 이미 있음) · sk_hynix 사내 편의시설
--   (맞는 코드 없음) · techwing 복지동(fitness·library 둘 다 이미 있음) · cj_freshway 렌터카·식음료
--   할인(discount 이미 있음). 합치기·새 코드는 사용자 결정이 필요하다.
--
-- 적용: /data/mysql/bin/mysql -vv -h <host> -u <user> -p <DB> < db/migrations/20260922_recode_benefit_rows.sql
--   -vv 를 붙여야 문마다 Rows matched 가 찍힌다. 붙이지 않으면 0행이어도 조용히 성공한다.
--   맨 앞 0단계 SELECT 는 읽기 전용이다 — 대상 52행이 옛 값 그대로인지 먼저 볼 수 있다.
-- 기대 영향 행 수: UPDATE 54문 각 1행 = 54. 적으면 멈추고 확인하라 — 회사명 오타면 @c 가
--   NULL 이라 오류 없이 0행이고, 값이 이미 다르면 가드가 건너뛴 것이다.
-- 멱등: 모든 WHERE 가 옛 값 전체(코드·이름·금액·카테고리·QUAL_YN·설명·NOTE·정렬·배지)를 본다 —
--   두 번째 실행은 전부 0행이다.
-- 가드: BADGE_CD = 'official' — 재직자가 고친 행은 조용히 덮지 않는다.
--   ⚠ 시드의 'est' 가 아니다. 시드 INSERT 는 'est' 로 적혀 있지만 적재 뒤 서빙 DB 는 전 행이
--   'official' 이다(배지가 재계산된다). 시드 값을 가드로 쓰면 전 문장이 조용히 0행이 된다.
-- 원자성: 한 트랜잭션이다. 새 코드가 그 회사에 이미 있으면(uq_comp_benefit) UPDATE 가
--   ERROR 1062 로 멈추고, mysql 클라이언트가 스크립트를 끊으며 COMMIT 전이라 전부 되돌아간다.
-- 시드: 같은 52행을 db/seed/benefit/sql/*.sql 에서도 같은 종착 상태로 고쳤다. 시드는 업서트라
--   코드를 바꾼 행은 새 키다 — 이 마이그레이션 없이 시드만 재적용하면 옛 코드 행이 남고 새 코드
--   행이 하나 더 생긴다. 그러니 서빙 DB 는 반드시 이 파일로 맞춘다. 행 수는 그대로(2451).
-- 순서: 이 마이그레이션을 정적 재생성(release)보다 먼저. 같은 PR 이 항목 페이지 exclude 예외
--   39개를 지웠다 — DB 가 옛 코드인 채로 재생성하면 뺐던 행이 항목 페이지에 다시 들어간다.
-- ══════════════════════════════════════════════════════════════════════

-- 0) 점검(읽기 전용) — 대상 행과 새 코드 자리를 함께 띄운다. 옛 코드 행 52개 + 새 코드 자리.
--    새 코드 자리에 이미 행이 있으면 그 행이 이 파일 안에서 먼저 비켜 가는 행인지 확인할 것
--    (NAVER long_service_leave · sk_innovation 두 행 · 삼성카드 세 행만 그렇다).
SELECT c.COMP_ENG_NM, b.BENEFIT_ID, b.BENEFIT_CD, b.BENEFIT_NM, b.BENEFIT_CTGR_CD, b.SORT_ORDER_NO,
       b.BENEFIT_AMT, b.QUAL_YN, b.BADGE_CD,
       (SELECT COUNT(*) FROM TBENEFIT_EDIT_LOG l WHERE l.BENEFIT_ID = b.BENEFIT_ID) AS EDIT_LOGS
  FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE (c.COMP_ENG_NM, b.BENEFIT_CD) IN (
        ('apr', 'long_service_leave'),
        ('apr', 'refresh_leave'),
        ('doosan', 'long_service_bonus'),
        ('doosan', 'long_service_leave'),
        ('doosan_enerbility', 'long_service_bonus'),
        ('doosan_enerbility', 'long_service_leave'),
        ('duksan_neolux', 'dormitory'),
        ('duksan_neolux', 'excellence_award'),
        ('duksan_neolux', 'housing_support'),
        ('duksan_neolux', 'long_service_bonus'),
        ('eo_technics', 'excellence_award'),
        ('eo_technics', 'long_service_bonus'),
        ('eugenetech', 'birthday_gift'),
        ('hanmi_pharm', 'long_service_bonus'),
        ('hanmi_pharm', 'long_service_leave'),
        ('hanmi_semi', 'long_service_bonus'),
        ('hanmi_semi', 'long_service_leave'),
        ('hanwha', 'long_service_bonus'),
        ('hanwha', 'long_service_leave'),
        ('hanwha_aerospace', 'leave_general'),
        ('hanwha_aerospace', 'parenting'),
        ('hugel', 'commute_subsidy'),
        ('hugel', 'transport'),
        ('hyundai_mobis', 'commute_subsidy'),
        ('hyundai_mobis', 'long_service_leave'),
        ('hyundai_mobis', 'refresh_leave'),
        ('hyundai_mobis', 'transport'),
        ('hyundai_motor', 'commute_subsidy'),
        ('hyundai_motor', 'transport'),
        ('hyundai_muvex', 'long_service_bonus'),
        ('hyundai_muvex', 'long_service_leave'),
        ('hyundai_rotem', 'commute_subsidy'),
        ('hyundai_rotem', 'transport'),
        ('hyundai_steel', 'commute_subsidy'),
        ('hyundai_steel', 'long_service_bonus'),
        ('hyundai_steel', 'long_service_leave'),
        ('hyundai_steel', 'transport'),
        ('jusung', 'event'),
        ('jusung', 'family_day'),
        ('kakao_pay', 'long_service_leave'),
        ('kakao_pay', 'refresh_leave'),
        ('kia', 'commute_subsidy'),
        ('kia', 'transport'),
        ('korean_air', 'long_service_bonus'),
        ('korean_air', 'long_service_leave'),
        ('krafton', 'holiday_gift'),
        ('krafton', 'leave_general'),
        ('kt', 'discount'),
        ('kt', 'long_service_leave'),
        ('kt', 'refresh_leave'),
        ('kt', 'telecom'),
        ('lg_cns', 'edu_support'),
        ('lg_cns', 'long_service_leave'),
        ('lg_cns', 'refresh_leave'),
        ('lg_cns', 'self_development'),
        ('lg_display', 'commute_subsidy'),
        ('lg_display', 'transport'),
        ('lg_elec', 'commute_subsidy'),
        ('lg_elec', 'long_service_leave'),
        ('lg_elec', 'refresh_leave'),
        ('lg_elec', 'transport'),
        ('lig_nex1', 'long_service_bonus'),
        ('lig_nex1', 'long_service_leave'),
        ('ls', 'long_service_bonus'),
        ('ls', 'long_service_leave'),
        ('naver', 'long_service_bonus'),
        ('naver', 'long_service_leave'),
        ('naver', 'refresh_leave'),
        ('ncsoft', 'commute_subsidy'),
        ('ncsoft', 'transport'),
        ('pearl_abyss', 'birthday_gift'),
        ('pearl_abyss', 'club'),
        ('pearl_abyss', 'company_event'),
        ('pearl_abyss', 'event'),
        ('rainbow_robotics', 'birthday_gift'),
        ('rainbow_robotics', 'holiday_gift'),
        ('s_oil', 'leave_general'),
        ('s_oil', 'summer_leave'),
        ('samsung_card', 'career'),
        ('samsung_card', 'edu_support'),
        ('samsung_card', 'lounge'),
        ('samsung_card', 'self_development'),
        ('samsung_card', 'snack_bar'),
        ('samsung_elec', 'commute_subsidy'),
        ('samsung_elec', 'transport'),
        ('sk_hynix', 'commute_subsidy'),
        ('sk_hynix', 'transport'),
        ('sk_innovation', 'commute_subsidy'),
        ('sk_innovation', 'transport'),
        ('soulbrain', 'edu_support'),
        ('soulbrain', 'mba'),
        ('tck', 'library'),
        ('tck', 'lounge'),
        ('wonik_ips', 'edu_support'),
        ('wonik_ips', 'self_development'),
        ('yuhan', 'excellence_award'),
        ('yuhan', 'long_service_bonus'))
 ORDER BY c.COMP_ENG_NM, b.BENEFIT_CD;

START TRANSACTION;

-- ── sk_innovation — commute_subsidy ↔ transport 맞바꿈(야간 교통비 ↔ 통근버스) ── 첫 행을 임시 코드로 비우고, 나머지를 차례로 옮긴 뒤, 임시 행을 제자리로

-- sk_innovation commute_subsidy 「야간 교통비」 → (임시) __recode_tmp
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_innovation');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = '__recode_tmp'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'commute_subsidy'
   AND BENEFIT_NM = '야간 교통비'
   AND BENEFIT_AMT = 30
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '야간 교통비 지급 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 83
   AND BADGE_CD = 'official';

-- sk_innovation transport 「통근버스」 → commute_subsidy — 교통비 지급이 아니라 통근버스 운행(야간 교통비 행과 맞바꿈)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_innovation');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'commute_subsidy'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'transport'
   AND BENEFIT_NM = '통근버스'
   AND BENEFIT_AMT = 120
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '통근버스 운행 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 82
   AND BADGE_CD = 'official';

-- sk_innovation (임시) __recode_tmp 「야간 교통비」 → transport — 버스 운행이 아니라 야간 교통비 지급(통근버스 행과 맞바꿈)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_innovation');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'transport'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = '__recode_tmp'
   AND BENEFIT_NM = '야간 교통비'
   AND BENEFIT_AMT = 30
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '야간 교통비 지급 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 83
   AND BADGE_CD = 'official';

-- ── 삼성카드 — 성장 3행 돌림(edu_support → self_development → career → edu_support) ── 첫 행을 임시 코드로 비우고, 나머지를 차례로 옮긴 뒤, 임시 행을 제자리로

-- samsung_card edu_support 「전문 자격 취득 지원」 → (임시) __recode_tmp
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_card');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = '__recode_tmp'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'edu_support'
   AND BENEFIT_NM = '전문 자격 취득 지원'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'growth'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '데이터분석·마케팅·CFA·CPA·세무사 등 금융/비금융 자격 취득 지원'
   AND SORT_ORDER_NO = 52
   AND BADGE_CD = 'official';

-- samsung_card career 「Job master 양성과정」 → edu_support — 직무·리더십 교육체계 — 교육 제도
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_card');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'edu_support'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'career'
   AND BENEFIT_NM = 'Job master 양성과정'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'growth'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '직무별 사내 전문가 선발·양성 과정, 기본·리더십·직무 교육체계 운영'
   AND SORT_ORDER_NO = 55
   AND BADGE_CD = 'official';

-- samsung_card self_development 「지역전문가 제도」 → career — 자기계발비가 아니라 해외 파견 지역전문가 제도
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_card');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'career'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'self_development'
   AND BENEFIT_NM = '지역전문가 제도'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'growth'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '글로벌 금융인재 양성을 위한 해외 파견 지역전문가 제도'
   AND SORT_ORDER_NO = 50
   AND BADGE_CD = 'official';

-- samsung_card (임시) __recode_tmp 「전문 자격 취득 지원」 → self_development — 교육 과정이 아니라 자격 취득 지원(lig_nex1·samsung_heavy 선례)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_card');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'self_development'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = '__recode_tmp'
   AND BENEFIT_NM = '전문 자격 취득 지원'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'growth'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '데이터분석·마케팅·CFA·CPA·세무사 등 금융/비금융 자격 취득 지원'
   AND SORT_ORDER_NO = 52
   AND BADGE_CD = 'official';

-- ── long_service_leave → long_service_bonus ──
-- naver 「근속 기념 선물」 — 휴가 없이 근속 선물만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'naver');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus',
       BENEFIT_CTGR_CD = 'compensation',
       SORT_ORDER_NO = 86
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '근속 기념 선물'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '근속 10주년/20주년 선물 지급'
   AND SORT_ORDER_NO = 32
   AND BADGE_CD = 'official';

-- ── commute_subsidy → transport ──
-- hugel 「야근 교통비」 — 버스 운행이 아니라 야근 교통비 지급
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hugel');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'transport'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'commute_subsidy'
   AND BENEFIT_NM = '야근 교통비'
   AND BENEFIT_AMT = 30
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '야근 교통비 지원 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 83
   AND BADGE_CD = 'official';

-- kia 「야근 교통비」 — 버스 운행이 아니라 심야 택시비 지급
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kia');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'transport'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'commute_subsidy'
   AND BENEFIT_NM = '야근 교통비'
   AND BENEFIT_AMT = 30
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '23시~07시 택시 교통비 지원 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 83
   AND BADGE_CD = 'official';

-- ncsoft 「야근 택시비 지원」 — 버스 운행이 아니라 야근 택시비 지급
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ncsoft');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'transport'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'commute_subsidy'
   AND BENEFIT_NM = '야근 택시비 지원'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '23시 이후 야근 시 택시비 지원'
   AND SORT_ORDER_NO = 83
   AND BADGE_CD = 'official';

-- ── transport → commute_subsidy ──
-- hyundai_mobis 「셔틀버스」 — 교통비 지급이 아니라 셔틀버스 운행
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_mobis');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'commute_subsidy'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'transport'
   AND BENEFIT_NM = '셔틀버스'
   AND BENEFIT_AMT = 120
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '서울/경기 약 60개 노선 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 84
   AND BADGE_CD = 'official';

-- hyundai_motor 「통근버스」 — 교통비 지급이 아니라 통근버스 운행
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_motor');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'commute_subsidy'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'transport'
   AND BENEFIT_NM = '통근버스'
   AND BENEFIT_AMT = 120
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '사업장별 통근버스 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 82
   AND BADGE_CD = 'official';

-- hyundai_rotem 「통근버스」 — 교통비 지급이 아니라 통근버스 운행
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_rotem');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'commute_subsidy'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'transport'
   AND BENEFIT_NM = '통근버스'
   AND BENEFIT_AMT = 120
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '(추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 82
   AND BADGE_CD = 'official';

-- hyundai_steel 「통근버스」 — 교통비 지급이 아니라 통근버스 운행
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_steel');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'commute_subsidy'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'transport'
   AND BENEFIT_NM = '통근버스'
   AND BENEFIT_AMT = 120
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '서울/당진/인천/포항/순천 전 지역 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 80
   AND BADGE_CD = 'official';

-- lg_display 「통근버스」 — 교통비 지급이 아니라 통근버스 운행
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_display');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'commute_subsidy'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'transport'
   AND BENEFIT_NM = '통근버스'
   AND BENEFIT_AMT = 120
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '통근버스 지원 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 81
   AND BADGE_CD = 'official';

-- lg_elec 「출퇴근 버스」 — 교통비 지급이 아니라 통근버스 운행
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_elec');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'commute_subsidy'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'transport'
   AND BENEFIT_NM = '출퇴근 버스'
   AND BENEFIT_AMT = 120
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '사업장별 통근버스 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 83
   AND BADGE_CD = 'official';

-- samsung_elec 「통근버스」 — 교통비 지급이 아니라 통근버스 운행
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_elec');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'commute_subsidy'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'transport'
   AND BENEFIT_NM = '통근버스'
   AND BENEFIT_AMT = 120
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '수도권 150여 노선, 일 약 800회 운행'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 83
   AND BADGE_CD = 'official';

-- sk_hynix 「통근버스」 — 교통비 지급이 아니라 리무진 통근버스 운행
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_hynix');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'commute_subsidy'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'transport'
   AND BENEFIT_NM = '통근버스'
   AND BENEFIT_AMT = 120
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '수도권 전 지역 무료, 리무진 통근버스, 다양한 시간대 운행 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 82
   AND BADGE_CD = 'official';

-- ── refresh_leave → long_service_leave ──
-- hyundai_mobis 「장기근속자 포상」 — 근속연수에 따라 주는 휴가·여행 포상
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_mobis');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_leave'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'refresh_leave'
   AND BENEFIT_NM = '장기근속자 포상'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '근속연수에 따라 휴가, 해외여행 등 포상 제공 및 퇴직 지원'
   AND SORT_ORDER_NO = 31
   AND BADGE_CD = 'official';

-- kt 「장기근속 포상」 — 장기근속 시 주는 포상과 휴가
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kt');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_leave'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'refresh_leave'
   AND BENEFIT_NM = '장기근속 포상'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '장기근속 시 포상과 휴가 지원'
   AND SORT_ORDER_NO = 30
   AND BADGE_CD = 'official';

-- lg_elec 「장기근속 포상」 — 근속 5년마다 주는 포상금과 휴가
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_elec');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_leave'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'refresh_leave'
   AND BENEFIT_NM = '장기근속 포상'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '10년 이상 장기근속자에게 5년마다 포상금과 휴가 지급, 20년/30년 근속 시 배우자 동반 해외여행 제공'
   AND SORT_ORDER_NO = 30
   AND BADGE_CD = 'official';

-- kakao_pay 「안식 휴가(3년마다)」 — 근속 3년마다 주는 휴가(카카오뱅크 같은 모양 선례)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_pay');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_leave'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'refresh_leave'
   AND BENEFIT_NM = '안식 휴가(3년마다)'
   AND BENEFIT_AMT = 200
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '근속 3년마다 30일 유급 휴가 + 휴가비 200만원'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 30
   AND BADGE_CD = 'official';

-- apr 「리프레시 휴가 (3/6/9년)」 — 근속 연수에 맞춰 주는 휴가(JYP 선례)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'apr');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_leave'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'refresh_leave'
   AND BENEFIT_NM = '리프레시 휴가 (3/6/9년)'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '3,6,9년 마다 3,6,9일 리프레시 휴가 제공'
   AND SORT_ORDER_NO = 31
   AND BADGE_CD = 'official';

-- lg_cns 「안식휴가」 — 근속 기준연한에 따라 주는 휴가(삼성E&A 선례)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_cns');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_leave'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'refresh_leave'
   AND BENEFIT_NM = '안식휴가'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '일정 근속 기준연한에 따라 유급휴가 및 휴가비 지급'
   AND SORT_ORDER_NO = 30
   AND BADGE_CD = 'official';

-- naver 「리프레시 플러스 휴가」 — 2년 근속 시 주는 추가 휴가(근속 기념 선물 행을 먼저 long_service_bonus 로 옮김)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'naver');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_leave'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'refresh_leave'
   AND BENEFIT_NM = '리프레시 플러스 휴가'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '2년 근속 시 15일 추가 유급휴가, 연차 2일 이상 사용시 1일x5만원 휴가비'
   AND SORT_ORDER_NO = 30
   AND BADGE_CD = 'official';

-- ── long_service_leave → long_service_bonus ──
-- doosan 「장기근속 포상」 — 휴가 없이 포상금·감사패만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'doosan');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus',
       BENEFIT_CTGR_CD = 'compensation',
       SORT_ORDER_NO = 9
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기근속 포상'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '10년 이후 5년마다 포상금+감사패'
   AND SORT_ORDER_NO = 31
   AND BADGE_CD = 'official';

-- hanmi_semi 「장기근속 순금 선물」 — 휴가 없이 순금 선물만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanmi_semi');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus',
       BENEFIT_CTGR_CD = 'compensation',
       SORT_ORDER_NO = 83
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기근속 순금 선물'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '장기근속자 감사 선물(순금) 지급'
   AND SORT_ORDER_NO = 31
   AND BADGE_CD = 'official';

-- hanwha 「장기근속 포상」 — 휴가 없이 포상·해외여행 상품권만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus',
       BENEFIT_CTGR_CD = 'compensation',
       SORT_ORDER_NO = 2
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기근속 포상'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '10년/20년/30년 근속자 포상 및 해외여행 상품권 지급'
   AND SORT_ORDER_NO = 31
   AND BADGE_CD = 'official';

-- hyundai_steel 「장기근속 포상」 — 휴가 없이 기념품·포상금·여행만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_steel');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus',
       BENEFIT_CTGR_CD = 'compensation',
       SORT_ORDER_NO = 29
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기근속 포상'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '10년 이후 5년마다 기념품, 15년 포상금+기념품, 20년 배우자 동반 해외여행'
   AND SORT_ORDER_NO = 31
   AND BADGE_CD = 'official';

-- ls 「장기근속 포상」 — 휴가 없이 포상금만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ls');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus',
       BENEFIT_CTGR_CD = 'compensation',
       SORT_ORDER_NO = 51
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기근속 포상'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '5년 단위 포상금 지급'
   AND SORT_ORDER_NO = 30
   AND BADGE_CD = 'official';

-- lig_nex1 「장기근속 포상」 — 휴가 없이 장기근속비·기념품만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus',
       BENEFIT_CTGR_CD = 'compensation',
       SORT_ORDER_NO = 9
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기근속 포상'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '10년 이상 5년 단위 장기근속비 지급, 정년 퇴임식 및 기념품'
   AND SORT_ORDER_NO = 32
   AND BADGE_CD = 'official';

-- korean_air 「장기근속 여행 지원」 — 휴가 없이 여행 지원만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'korean_air');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus',
       BENEFIT_CTGR_CD = 'compensation',
       SORT_ORDER_NO = 2
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기근속 여행 지원'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '장기근속 직원 여행 지원 및 정년퇴직 여행비 지원'
   AND SORT_ORDER_NO = 30
   AND BADGE_CD = 'official';

-- hanmi_pharm 「장기근속 포상 포인트」 — 휴가 없이 포상 포인트만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanmi_pharm');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus',
       BENEFIT_CTGR_CD = 'compensation',
       SORT_ORDER_NO = 2
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기근속 포상 포인트'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '장기근속 포상 포인트 지급'
   AND SORT_ORDER_NO = 31
   AND BADGE_CD = 'official';

-- hyundai_muvex 「장기근속 포상」 — 휴가 없이 포상금만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_muvex');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus',
       BENEFIT_CTGR_CD = 'compensation',
       SORT_ORDER_NO = 39
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기근속 포상'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '장기근속 포상금 지원'
   AND SORT_ORDER_NO = 30
   AND BADGE_CD = 'official';

-- doosan_enerbility 「장기근속 포상」 — 휴가 없이 포상·해외여행·기념패만
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'doosan_enerbility');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus',
       BENEFIT_CTGR_CD = 'compensation',
       SORT_ORDER_NO = 29
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기근속 포상'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '근속년수별 포상, 35년 부부동반 해외여행, 정년퇴직 기념패+금열쇠'
   AND SORT_ORDER_NO = 31
   AND BADGE_CD = 'official';

-- ── excellence_award → long_service_bonus ──
-- duksan_neolux 「장기근속 포상」 — 우수 선발이 아니라 근속 연동 포상
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'duksan_neolux');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'excellence_award'
   AND BENEFIT_NM = '장기근속 포상'
   AND BENEFIT_AMT = 50
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '근속메달, 기념패, 포상금, 해외여행, 리프레쉬 휴가 등 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 1
   AND BADGE_CD = 'official';

-- eo_technics 「장기근속 포상금」 — 우수 선발이 아니라 근속 연동 포상금
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'eo_technics');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'excellence_award'
   AND BENEFIT_NM = '장기근속 포상금'
   AND BENEFIT_AMT = 50
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '근속 10년차부터 장기근속 포상금 지급 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 1
   AND BADGE_CD = 'official';

-- yuhan 「장기근속 포상/퇴직금 누진제」 — 우수 선발이 아니라 장기근속 표창·포상
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'yuhan');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'long_service_bonus'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'excellence_award'
   AND BENEFIT_NM = '장기근속 포상/퇴직금 누진제'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '퇴직금 누진제, 장기근속 표창+기념품+상금+특별휴가+자사주식, 정년퇴직자 6개월 공로연수휴가'
   AND SORT_ORDER_NO = 2
   AND BADGE_CD = 'official';

-- ── discount → telecom ──
-- kt 「통신비/단말기 지원」 — 할인이 아니라 통신비·단말기 보조
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kt');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'telecom'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'discount'
   AND BENEFIT_NM = '통신비/단말기 지원'
   AND BENEFIT_AMT = 120
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '휴대폰 통신비 및 단말기 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 81
   AND BADGE_CD = 'official';

-- ── dormitory → housing_support ──
-- duksan_neolux 「원거리 주거 지원」 — 시설이 아니라 주거 지원비(현금)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'duksan_neolux');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'housing_support',
       BENEFIT_CTGR_CD = 'perks',
       SORT_ORDER_NO = 82
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'dormitory'
   AND BENEFIT_NM = '원거리 주거 지원'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'work_env'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT = '6년간 지원'
   AND QUAL_DESC_CTNT = '원거리 거주자 6년간 주거 지원비 지원'
   AND SORT_ORDER_NO = 20
   AND BADGE_CD = 'official';

-- ── edu_support → self_development ──
-- lg_cns 「학자금 이자 지원」 — 교육 제도가 아니라 본인 학자금 대출 이자 지원
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_cns');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'self_development'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'edu_support'
   AND BENEFIT_NM = '학자금 이자 지원'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'growth'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '학자금 대출 이자비용 지원'
   AND SORT_ORDER_NO = 60
   AND BADGE_CD = 'official';

-- ── edu_support → mba ──
-- soulbrain 「학위지원제도」 — 직무 교육이 아니라 학위 지원(kai·gc_biopharma 선례)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'soulbrain');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'mba'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'edu_support'
   AND BENEFIT_NM = '학위지원제도'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'growth'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '학위지원제도 운영'
   AND SORT_ORDER_NO = 61
   AND BADGE_CD = 'official';

-- ── edu_support → self_development ──
-- wonik_ips 「본인 학자금」 — 본인 학자금(hanmi_pharm·hyundai_muvex 선례)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'wonik_ips');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'self_development'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'edu_support'
   AND BENEFIT_NM = '본인 학자금'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'growth'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '학자금 지원 항목 중 본인학자금'
   AND SORT_ORDER_NO = 50
   AND BADGE_CD = 'official';

-- ── event → family_day ──
-- jusung 「기념일 조기퇴근」 — 경조사 지원이 아니라 가족 기념일 조기 퇴근
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'jusung');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'family_day',
       BENEFIT_CTGR_CD = 'flexibility',
       SORT_ORDER_NO = 19
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'event'
   AND BENEFIT_NM = '기념일 조기퇴근'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'family'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '부모님 생신, 배우자 생일, 결혼기념일 중 연 2회 17시 조기 퇴근'
   AND SORT_ORDER_NO = 51
   AND BADGE_CD = 'official';

-- ── event → birthday_gift ──
-- pearl_abyss 「기념일 선물」 — 경조사가 아니라 기념일 선물
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'pearl_abyss');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'birthday_gift',
       BENEFIT_CTGR_CD = 'perks',
       SORT_ORDER_NO = 84
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'event'
   AND BENEFIT_NM = '기념일 선물'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'family'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '원하는 날짜에 원하는 곳 배송, 자녀 입학 선물 약 30만원'
   AND SORT_ORDER_NO = 53
   AND BADGE_CD = 'official';

-- ── club → company_event ──
-- pearl_abyss 「패밀리데이/반려동물 보험」 — 동호회가 아니라 가족 참여 프로그램(패밀리데이)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'pearl_abyss');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'company_event'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'club'
   AND BENEFIT_NM = '패밀리데이/반려동물 보험'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'leisure'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '가족 참여 프로그램, 1인가구 가사 청소 월 1회, 반려동물 보험비 지원'
   AND SORT_ORDER_NO = 70
   AND BADGE_CD = 'official';

-- ── holiday_gift → leave_general ──
-- krafton 「명절 반차」 — 선물·돈이 아니라 명절 반차(휴가)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'krafton');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'leave_general',
       BENEFIT_CTGR_CD = 'time_off',
       SORT_ORDER_NO = 32
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절 반차'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '명절 기념 반차 제공'
   AND SORT_ORDER_NO = 1
   AND BADGE_CD = 'official';

-- ── holiday_gift → birthday_gift ──
-- rainbow_robotics 「생일 상품권」 — 명절이 아니라 생일 상품권
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'rainbow_robotics');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'birthday_gift',
       BENEFIT_CTGR_CD = 'perks',
       SORT_ORDER_NO = 82
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '생일 상품권'
   AND BENEFIT_AMT = 5
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_YN = FALSE
   AND NOTE_CTNT = '생일자 상품권 지급 (추정)'
   AND QUAL_DESC_CTNT IS NULL
   AND SORT_ORDER_NO = 2
   AND BADGE_CD = 'official';

-- ── leave_general → parenting ──
-- hanwha_aerospace 「아빠휴가」 — 자녀 출산 때 아버지에게 주는 휴가(한화시스템 선례)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha_aerospace');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'parenting',
       BENEFIT_CTGR_CD = 'family',
       SORT_ORDER_NO = 52
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '아빠휴가'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '아빠휴가 제도'
   AND SORT_ORDER_NO = 30
   AND BADGE_CD = 'official';

-- ── lounge → snack_bar ──
-- samsung_card 「사내카페」 — 휴게실이 아니라 사내 카페
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_card');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'snack_bar',
       BENEFIT_CTGR_CD = 'perks',
       SORT_ORDER_NO = 75
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'lounge'
   AND BENEFIT_NM = '사내카페'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'work_env'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '임직원 전용 사내 카페 운영'
   AND SORT_ORDER_NO = 30
   AND BADGE_CD = 'official';

-- ── lounge → library ──
-- tck 「사내 영화관」 — 휴게 공간이 아니라 문화시설(sk_hynix 사내 문화시설 선례)
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'tck');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'library',
       BENEFIT_CTGR_CD = 'leisure',
       SORT_ORDER_NO = 72
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'lounge'
   AND BENEFIT_NM = '사내 영화관'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'work_env'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '퇴근 후 영화 관람 가능한 사내 영화관 운영'
   AND SORT_ORDER_NO = 21
   AND BADGE_CD = 'official';

-- ── summer_leave → leave_general ──
-- s_oil 「집중 휴가제」 — 여름휴가가 아니라 휴가 집중 사용 제도
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 's_oil');
UPDATE TCOMPANY_BENEFIT
   SET BENEFIT_CD = 'leave_general'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'summer_leave'
   AND BENEFIT_NM = '집중 휴가제'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '연 1회 2주간 휴가사용 의무화 (사무직/기술직)'
   AND SORT_ORDER_NO = 30
   AND BADGE_CD = 'official';

-- ── 원문 정리 ──
-- eugenetech birthday_gift 「결혼기념일 선물」 — 수집 메모가 원문에 섞여 회사 페이지·/benefit/birthday-gift 에 코드명이 보였다
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'eugenetech');
UPDATE TCOMPANY_BENEFIT
   SET QUAL_DESC_CTNT = '결혼기념일 축하 꽃바구니 지급'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'birthday_gift'
   AND BENEFIT_NM = '결혼기념일 선물'
   AND BENEFIT_AMT IS NULL
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_YN = TRUE
   AND NOTE_CTNT IS NULL
   AND QUAL_DESC_CTNT = '결혼기념일 축하 꽃바구니 지급(기념일 선물 — 삼성카드 birthday_gift 선례)'
   AND SORT_ORDER_NO = 42
   AND BADGE_CD = 'official';

COMMIT;
