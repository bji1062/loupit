-- ══════════════════════════════════════════════════════════════════════
-- 데이터 정리 2차 — 카테고리 통일 30행 · 문안 60행 · 삭제 1행
-- 결정: 2026-09-21 사용자 · 선례: 20260920_remove_statutory_phrases.sql (같은 형식·같은 가드)
--
-- 왜 필요한가 — 네 가지다.
--  ① 카테고리 분열(30행) — 수집 계약은 「카테고리 ∈ 9종」만 정하고 코드↔카테고리 1:1 을
--     못 박은 적이 없다. 그래서 같은 코드가 회사마다 다른 축에 들어갔다. 「명절 선물」이
--     7곳은 compensation, 4곳은 perks 로 세어져 9각형 비교에서 같은 복지가 다른 축이 된다.
--     정본: holiday_gift=compensation · work_tools/parking=work_env · family_day=flexibility ·
--     massage=health(사용자 결정 — 다수인 leisure 가 아니라 건강관리 성격을 따랐다).
--  ② 경조 중복(4사) — event(경조금) 행 서술에 「및 경조휴가」가 들어가 leave_general
--     (경조휴가) 행과 화면에 같은 말을 두 줄로 냈다. 클래시스·SK이노베이션·보로노이는
--     역할을 금전/휴가로 갈랐다(세 곳 다 event 에 금액이 있다).
--     ⚠ 케어젠만 갈리지 않는다 — 원문 근거가 「경조휴가」 하나뿐이라 event 행에 쓸 금전
--     근거가 0이다. 이름만 코퍼스 표준으로 맞추고 서술은 근거대로 두었으므로 **두 행의
--     서술 중복은 남는다**. 푸는 길은 원문 재수집뿐이다(구본: AI 파싱·URL 수동 입력).
--  ③ 문체(35행) — 서술의 주어가 제도가 아니라 「공식 채용 공고 …항목의」라는 출처였다.
--     제도를 주어로 돌리고 출처는 괄호로 옮겼다. **사실은 더하지도 빼지도 않았다** —
--     숫자·영문·기호를 before/after 로 전수 대조해 보존을 확인했다.
--  ④ 「근속 연차」 → 「근속 연수」(20건) — 「연차」는 법정 검출어라 스윕 오탐을 만든다.
--     여기서 말하는 것은 연차휴가가 아니라 근속 햇수다. 실측으로 검출 38 → 18 이 되고
--     걷힌 20건은 전부 오탐이었다(남은 18건은 진짜 연차휴가 문맥).
--  ⑤ 파두 `lounge` 항목명(1건) — 단독 「카페테리아」는 구내식당(`meal`)으로 읽힌다.
--     「카페테리아 (휴식 공간)」으로 명확히 한다. ①~⑤ + 삭제 1 = 91문.
--
-- 무엇을 바꾸나: BENEFIT_NM · BENEFIT_CTGR_CD · QUAL_DESC_CTNT · NOTE_CTNT 네 필드.
--   금액·SORT·배지·코드는 한 칸도 건드리지 않는다.
--
-- 삭제 1행(hugel/welcome_kit): 「신규 입사자 온보딩 프로그램 운영」 — 혜택 내용 없이
--   운영 사실만 있는 서술은 행이 아니다(상담실 선례). 게다가 welcome_kit 은 코퍼스
--   나머지 10사가 전부 입사 선물 물품에 쓰는 코드라 뜻도 어긋났다. 사용자 결정 2026-09-21.
--
-- 적용: /data/mysql/bin/mysql -vv -h <host> -u <user> -p <DB> < db/migrations/20260921_data_cleanup_2.sql
--   -vv 를 붙여야 문마다 Rows matched 가 찍힌다. 붙이지 않으면 0행이어도 조용히 성공한다.
--   맨 앞 0단계 SELECT 는 읽기 전용이다 — 이것만 먼저 돌려 대상이 옛 값 그대로인지 봐도 된다.
-- 기대 영향 행 수: 91 (UPDATE 90 각 1행 + DELETE 1). 적으면 멈추고 확인하라 —
--   회사명 오타면 @c 가 NULL 이라 오류 없이 0행이고, 값이 이미 다르면 가드가 건너뛴 것이다.
-- 멱등: 모든 WHERE 가 **옛 값 전체**(항목명·카테고리·설명·NOTE·배지·SORT)를 본다 —
--   두 번째 실행은 전부 0행이고 이미 고쳐진 행에는 닿지 않는다.
-- 가드: BADGE_CD 를 옛 값으로 고정 — 재직자가 고친 행은 조용히 덮지 않는다.
-- 블록 순서: 한 행에 한 문장이고 문장끼리 겹치는 대상이 없다 — 순서를 바꿔도 결과가 같다
--   (포스코퓨처엠 실사고의 반대 조건). 그래도 적용 뒤 시드↔DB 전수 대조를 권한다.
-- 시드: 같은 91행을 db/seed/benefit/sql/*.sql 에서도 같은 종착 상태로 고쳤다.
-- 순서: 정적 재생성(release)보다 **먼저**. DB 가 옛 값인 채로 재생성하면 그대로 다시 구워진다.
-- 행 수: DELETE 1행 때문에 **SD-4 핀 2452 → 2451** 로 함께 내린다(server/tests/test_seed_counts.py).
-- ══════════════════════════════════════════════════════════════════════

-- 0) 점검(읽기 전용) — 대상 91행이 옛 값 그대로인지 + 편집 이력 참조 수
--    가드로 쓰는 두 필드(QUAL_DESC_CTNT·NOTE_CTNT)를 같이 띄운다. 이게 옛 값과 다르면
--    그 UPDATE 는 0행이 된다 — 눈으로 먼저 보라는 뜻이다.
SELECT c.COMP_ENG_NM, b.BENEFIT_CD, b.BENEFIT_NM, b.BENEFIT_CTGR_CD, b.SORT_ORDER_NO, b.BADGE_CD,
       b.QUAL_DESC_CTNT, b.NOTE_CTNT,
       (SELECT COUNT(*) FROM TBENEFIT_EDIT_LOG l WHERE l.BENEFIT_ID = b.BENEFIT_ID) AS EDIT_LOGS
  FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_CD IN (
        'bonus', 'child_edu', 'childcare', 'club', 'company_event', 'edu_support', 'event',
        'excellence_award', 'family_day', 'flex_work', 'health_check', 'holiday_gift',
        'housing_support', 'incentive', 'insurance', 'leave_general', 'leisure_ticket',
        'long_service_bonus', 'long_service_leave', 'lounge', 'massage', 'parenting',
        'parking', 'pension_support', 'profit_sharing', 'remote_work', 'resort',
        'retirement_support', 'snack_bar', 'summer_leave', 'telecom', 'welcome_kit',
        'welfare_fund', 'welfare_fund_loan', 'welfare_point', 'work_tools')
   AND c.COMP_ENG_NM IN (
        'amorepacific', 'bh', 'caregen', 'celltrion_pharm', 'classys', 'coway', 'daeduck',
        'dongkook_pharm', 'douzone', 'duksan_neolux', 'emart', 'fadu', 'gc_biopharma',
        'hanmi_semi', 'hugel', 'hybe', 'isu_petasys', 'jeju_semi', 'jusung', 'kai',
        'kakao', 'kakao_bank', 'kakao_games', 'kakao_pay', 'ls', 'lunit', 'naver', 'nepes',
        'nongshim', 'olix', 'park_systems', 'pharma_research', 'poongsan', 'posco_futurem',
        'samsung_ena', 'samsung_heavy', 'samsung_sds', 'seegene', 'silicon2', 'simmtech',
        'sk_innovation', 'soulbrain', 'taihan', 'tck', 'voronoi', 'wemade', 'wonik_ips')
 ORDER BY c.COMP_ENG_NM, b.SORT_ORDER_NO;

START TRANSACTION;

-- ── amorepacific ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'amorepacific');
-- massage (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'health'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'massage'
   AND BENEFIT_NM = '마사지 테라피 라온(RA-ON)'
   AND BENEFIT_CTGR_CD = 'leisure'
   AND QUAL_DESC_CTNT = '시각장애인 안마사의 전문 수기치료 서비스 제공'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 71;

-- ── bh ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'bh');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절 선물'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '(추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 84;

-- ── caregen ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'caregen');
-- event (nm·desc)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_NM = '경조사 지원', QUAL_DESC_CTNT = '경조휴가 부여'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'event'
   AND BENEFIT_NM = '경조휴가'
   AND BENEFIT_CTGR_CD = 'family'
   AND QUAL_DESC_CTNT = '경조휴가'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 50;
-- parking (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'work_env'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'parking'
   AND BENEFIT_NM = '주차장 제공'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '주차장 제공'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 83;

-- ── celltrion_pharm ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'celltrion_pharm');
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속자 포상 (공식 복지제도 페이지 회사생활 항목명 그대로 — 영문판이 reward 로 표기해 포상이며 휴가 부여는 언급 없음, 근속 연수·포상 내용·금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '장기근속자 포상'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '장기근속자 포상 (공식 복지제도 페이지 회사생활 항목명 그대로 — 영문판이 reward 로 표기해 포상이며 휴가 부여는 언급 없음, 근속 연차·포상 내용·금액 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 40;

-- ── classys ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'classys');
-- event (note)
UPDATE TCOMPANY_BENEFIT SET NOTE_CTNT = '각종 경조사 지원 (추정)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'event'
   AND BENEFIT_NM = '경조사 지원'
   AND BENEFIT_CTGR_CD = 'family'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '각종 경조사 지원 및 경조휴가 (추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 51;

-- ── coway ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'coway');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '기념일 선물'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '창립기념일/설날/추석 (추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 81;

-- ── daeduck ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'daeduck');
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속자 포상 (공식 복지제도 페이지 기타 항목명 그대로 — 근속 연수 기준·포상금·부상 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '장기근속자 포상'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '장기근속자 포상 (공식 복지제도 페이지 기타 항목명 그대로 — 근속 연차 기준·포상금·부상 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 90;

-- ── dongkook_pharm ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'dongkook_pharm');
-- bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '연 보너스 600퍼센트와 성과급 (공식 채용 페이지 급여 항목 — 지급 시기·산정 기준 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'bonus'
   AND BENEFIT_NM = '보너스(600%)'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '공식 채용 페이지 급여 항목의 연 보너스 600퍼센트와 성과급 (지급 시기·산정 기준 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 51;
-- child_edu (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '자녀 학자금 지원 (공식 채용 페이지 복리후생 항목 — 대상 학교급·자녀 수·지원 한도 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'child_edu'
   AND BENEFIT_NM = '자녀 학자금 지원'
   AND BENEFIT_CTGR_CD = 'family'
   AND QUAL_DESC_CTNT = '공식 채용 페이지 복리후생 항목의 자녀 학자금 지원 (대상 학교급·자녀 수·지원 한도 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 21;
-- club (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '사내 동아리활동 지원 (공식 채용 페이지 복리후생 항목 — 활동비·동아리 수 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'club'
   AND BENEFIT_NM = '사내 동아리활동 지원'
   AND BENEFIT_CTGR_CD = 'leisure'
   AND QUAL_DESC_CTNT = '공식 채용 페이지 복리후생 항목의 사내 동아리활동 지원 (활동비·동아리 수 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 40;
-- event (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '경조휴가와 경조금 지원 (공식 채용 페이지 복리후생 항목 — 경조사 범위·휴가 일수·지급액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'event'
   AND BENEFIT_NM = '경조휴가 및 경조금 지원'
   AND BENEFIT_CTGR_CD = 'family'
   AND QUAL_DESC_CTNT = '공식 채용 페이지 복리후생 항목의 경조휴가와 경조금 지원 (경조사 범위·휴가 일수·지급액 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 20;
-- excellence_award (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '우수사원 표창과 해외연수 (공식 채용 페이지 복리후생 항목 — 선발 기준·포상 금액·연수 지역 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'excellence_award'
   AND BENEFIT_NM = '우수사원 표창 및 해외연수'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '공식 채용 페이지 복리후생 항목의 우수사원 표창과 해외연수 (선발 기준·포상 금액·연수 지역 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 50;
-- insurance (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '단체 상해보험 가입 (공식 채용 페이지 복리후생 항목 — 보장 범위·보험료 부담 주체 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'insurance'
   AND BENEFIT_NM = '단체 상해보험 가입'
   AND BENEFIT_CTGR_CD = 'health'
   AND QUAL_DESC_CTNT = '공식 채용 페이지 복리후생 항목의 단체 상해보험 가입 (보장 범위·보험료 부담 주체 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 30;
-- pension_support (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '개인연금보험 가입 지원 (공식 채용 페이지 복리후생 항목 — 회사 부담 비율·지원 금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'pension_support'
   AND BENEFIT_NM = '개인연금보험 가입지원'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '공식 채용 페이지 복리후생 항목의 개인연금보험 가입 지원 (회사 부담 비율·지원 금액 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 11;
-- resort (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '휴양시설 콘도 지원 (공식 채용 페이지 복리후생 항목 — 제휴처·이용 조건·이용료 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'resort'
   AND BENEFIT_NM = '휴양시설(콘도) 지원'
   AND BENEFIT_CTGR_CD = 'leisure'
   AND QUAL_DESC_CTNT = '공식 채용 페이지 복리후생 항목의 휴양시설 콘도 지원 (제휴처·이용 조건·이용료 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 41;
-- welfare_fund (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '사내 근로복지기금 운영 (공식 채용 페이지 복리후생 항목 — 기금 지원 내용·대상·한도 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'welfare_fund'
   AND BENEFIT_NM = '사내 근로복지기금 운영'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '공식 채용 페이지 복리후생 항목의 사내 근로복지기금 운영 (기금 지원 내용·대상·한도 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 10;

-- ── douzone ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'douzone');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절선물'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '명절선물 제공 (더존ICT그룹 채용공고 경조지원 항목 — 선물 품목·금액·지급 횟수 미기재) (그룹 통합 채용 기준)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 63;

-- ── duksan_neolux ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'duksan_neolux');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절/창립기념일 선물'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '설/추석 연 1회 + 창립기념일 기념품 (추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 82;

-- ── emart ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'emart');
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속 축하금 지급 (공식 채용 공고 이마트 복리후생 07 특별한 날 지원 항목) — 대상 근속 연수·축하금 액수 미기재'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '장기근속 축하금'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '장기근속 축하금 지급 (공식 채용 공고 이마트 복리후생 07 특별한 날 지원 항목) — 대상 근속 연차·축하금 액수 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 12;
-- long_service_leave (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '근속 포상 휴가 (공식 채용 공고 이마트 복리후생 05 다양한 휴가 제도 항목) — 대상 근속 연수·부여 일수 미기재'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '근속 포상 휴가'
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_DESC_CTNT = '근속 포상 휴가 (공식 채용 공고 이마트 복리후생 05 다양한 휴가 제도 항목) — 대상 근속 연차·부여 일수 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 62;

-- ── fadu ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'fadu');
-- lounge (nm)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_NM = '카페테리아 (휴식 공간)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'lounge'
   AND BENEFIT_NM = '카페테리아'
   AND BENEFIT_CTGR_CD = 'work_env'
   AND QUAL_DESC_CTNT = '안마의자 등을 구비한 휴식 공간 카페테리아 운영 (공식 채용 사이트 복지 혜택 행복한 회사 생활 항목 — 운영 시간·사업장 범위 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 31;

-- ── gc_biopharma ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'gc_biopharma');
-- long_service_leave (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기 근속자에 대한 Amazing Holiday 부여 (공식 채용사이트 GC녹십자 복리후생 페이지 휴식 항목 — 기준 근속 연수·휴가 일수 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = 'Amazing Holiday(장기근속 휴가)'
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_DESC_CTNT = '장기 근속자에 대한 Amazing Holiday 부여 (공식 채용사이트 GC녹십자 복리후생 페이지 휴식 항목 — 기준 근속 연차·휴가 일수 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 51;

-- ── hanmi_semi ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanmi_semi');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '생일/명절 선물'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '생일 케이크 상품권 + 명절 복지포인트 (추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 82;

-- ── hugel ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hugel');
-- 삭제: 혜택 내용 없이 「운영」만 있는 서술 (계약 규칙)
DELETE FROM TCOMPANY_BENEFIT
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'welcome_kit'
   AND BENEFIT_NM = '온보딩 프로그램'
   AND BENEFIT_CTGR_CD = 'work_env'
   AND QUAL_DESC_CTNT = '신규 입사자 온보딩 프로그램 운영'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 20;

-- ── hybe ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hybe');
-- family_day (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'flexibility'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'family_day'
   AND BENEFIT_NM = '금요일 조기퇴근'
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_DESC_CTNT = '금요일 오후 5시 퇴근 (1시간 30분 조기퇴근)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 31;

-- ── isu_petasys ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'isu_petasys');
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속자 포상 및 휴가 (공식 페이지 Motivation 항목명 그대로 — 근속 연수 구간·포상 금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '장기근속자 포상'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '장기근속자 포상 및 휴가 (공식 페이지 Motivation 항목명 그대로 — 근속 연차 구간·포상 금액 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 80;
-- long_service_leave (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속자 포상 및 휴가 (공식 페이지 Motivation 항목명 그대로 — 근속 연수 구간·휴가 일수 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기근속자 휴가'
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_DESC_CTNT = '장기근속자 포상 및 휴가 (공식 페이지 Motivation 항목명 그대로 — 근속 연차 구간·휴가 일수 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 71;

-- ── jeju_semi ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'jeju_semi');
-- company_event (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '전 직원 연 1~2회 제주도 워크샵과 액티비티 활동 지원 (공식 채용 공고 복리후생 제도 항목 — 참가 대상 조건·지원 금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'company_event'
   AND BENEFIT_NM = '전 직원 워크샵'
   AND BENEFIT_CTGR_CD = 'leisure'
   AND QUAL_DESC_CTNT = '공식 채용 공고 복리후생 제도 항목의 전 직원 연 1~2회 제주도 워크샵과 액티비티 활동 지원 — 참가 대상 조건·지원 금액 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 62;
-- edu_support (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '연간 직무·교양 교육비 지원 (공식 채용 공고 복리후생 제도 항목 — 지원 한도·대상 과정 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'edu_support'
   AND BENEFIT_NM = '직무·교양 교육비 지원'
   AND BENEFIT_CTGR_CD = 'growth'
   AND QUAL_DESC_CTNT = '공식 채용 공고 복리후생 제도 항목의 연간 직무·교양 교육비 지원 — 지원 한도·대상 과정 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 80;
-- event (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '결혼·회갑·사망 등 경조사비와 경조휴가 지원 (공식 채용 공고 복리후생 제도 항목 · 공식 인사/복지제도 페이지 경조금지원 항목 — 경조금액·경조휴가 일수 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'event'
   AND BENEFIT_NM = '경조사 지원'
   AND BENEFIT_CTGR_CD = 'family'
   AND QUAL_DESC_CTNT = '공식 채용 공고 복리후생 제도 항목의 결혼·회갑 등 경조사비 및 휴가 지원, 공식 인사/복지제도 페이지의 경조금지원(결혼, 회갑, 사망 등) — 경조금액·경조휴가 일수 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 50;
-- flex_work (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '부서별 유연근무제 도입 (공식 채용 공고 조직 문화 항목 — 적용 부서 범위·근무시간 운영 방식 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'flex_work'
   AND BENEFIT_NM = '부서별 유연근무제'
   AND BENEFIT_CTGR_CD = 'flexibility'
   AND QUAL_DESC_CTNT = '공식 채용 공고 조직 문화 항목의 부서별 유연근무제 도입 — 적용 부서 범위·근무시간 운영 방식 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 10;
-- health_check (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '전 직원 종합검진비용 지원 (공식 채용 공고 복리후생 제도 항목 — 검진 주기·검진 항목·금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'health_check'
   AND BENEFIT_NM = '종합건강검진 지원'
   AND BENEFIT_CTGR_CD = 'health'
   AND QUAL_DESC_CTNT = '공식 채용 공고 복리후생 제도 항목의 전 직원 종합검진비용 지원 — 검진 주기·검진 항목·금액 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 70;
-- holiday_gift (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '설·추석 각 250만원 명절 상여금과 10만원 상당 명절 선물 지급 (공식 채용 공고 복리후생 제도 항목 — 선물 지급 횟수 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절 상여금 및 선물'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '공식 채용 공고 복리후생 제도 항목의 명절 상여금 및 선물 지원 — 설·추석 각 250만원 지급과 10만원 상당 명절 선물, 선물 지급 횟수 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 40;
-- housing_support (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '신입사원 주거비 지원 — 대상자에 한하여 2년간 월 50만원 지급 (공식 채용 공고 복리후생 제도 항목 — 대상자 선정 기준 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'housing_support'
   AND BENEFIT_NM = '신입사원 주거비 지원'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '공식 채용 공고 복리후생 제도 항목의 신입사원 주거비 지원 — 대상자에 한하여 2년간 월 50만원 지급, 대상자 선정 기준 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 32;
-- incentive (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = 'R&D 프로젝트 수행에 따른 인센티브 지급 (공식 인사/복지제도 페이지 인사제도 항목 — 지급 기준·금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'incentive'
   AND BENEFIT_NM = 'R&D 프로젝트 인센티브'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '공식 인사/복지제도 페이지 인사제도 항목의 R&D 프로젝트 수행에 따른 인센티브 지급 — 지급 기준·금액 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 43;
-- leisure_ticket (note)
UPDATE TCOMPANY_BENEFIT SET NOTE_CTNT = '월 2만원 문화생활체육비 지원 (공식 채용 공고 복리후생 제도 항목) — 표기값은 월 2만원 × 12개월'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'leisure_ticket'
   AND BENEFIT_NM = '문화생활비 지원'
   AND BENEFIT_CTGR_CD = 'leisure'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '공식 채용 공고 복리후생 제도 항목의 월 2만원 문화생활체육비 지원, 표기값은 월 2만원 × 12개월'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 60;
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '5년·10년 장기 근속자 순금 지원 (공식 채용 공고 복리후생 제도 항목 — 순금 중량·금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '장기 근속자 순금 포상'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '공식 채용 공고 복리후생 제도 항목의 5년·10년 장기 근속자 순금 지원 — 순금 중량·금액 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 41;
-- long_service_leave (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '5년·10년 장기 근속자 리프레시 휴가 (공식 채용 공고 복리후생 제도 항목 — 휴가 일수 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기 근속자 리프레시 휴가'
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_DESC_CTNT = '공식 채용 공고 복리후생 제도 항목의 5년·10년 장기 근속자 리프레시 휴가 — 휴가 일수 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 21;
-- parenting (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '출산 축하금과 보육 수당 지급 (공식 채용 공고 복리후생 제도 항목 육아 지원 — 지급액·지급 대상 조건 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'parenting'
   AND BENEFIT_NM = '출산 축하금·보육 수당'
   AND BENEFIT_CTGR_CD = 'family'
   AND QUAL_DESC_CTNT = '공식 채용 공고 복리후생 제도 항목 육아 지원의 출산 축하금과 보육 수당 — 지급액·지급 대상 조건 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 51;
-- profit_sharing (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '부가급여(Profit Sharing System) (공식 인사/복지제도 페이지 인사제도 항목 — 지급 기준·시기·금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'profit_sharing'
   AND BENEFIT_NM = '부가급여(Profit Sharing System)'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '공식 인사/복지제도 페이지 인사제도 항목의 부가급여(Profit Sharing System) — 지급 기준·시기·금액 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 42;
-- resort (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '전국 소노 호텔&리조트 회원가 예약 지원 (공식 채용 공고 복리후생 제도 항목 — 이용 한도·예약 조건 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'resort'
   AND BENEFIT_NM = '소노 호텔&리조트 회원권'
   AND BENEFIT_CTGR_CD = 'leisure'
   AND QUAL_DESC_CTNT = '공식 채용 공고 복리후생 제도 항목의 전국 소노 호텔&리조트 회원가 예약 지원 — 이용 한도·예약 조건 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 61;
-- snack_bar (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '사내 카페테리아 음료 무한 제공 (공식 채용 공고 조직 문화 항목)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'snack_bar'
   AND BENEFIT_NM = '사내 카페테리아 음료'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '공식 채용 공고 조직 문화 항목의 사내 카페테리아 음료 무한 제공'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 30;
-- welfare_point (note)
UPDATE TCOMPANY_BENEFIT SET NOTE_CTNT = '직급별 연간 통합복리후생비 130~220만원 지원 (공식 채용 공고 복리후생 제도 항목) — 표기값은 직급별 구간의 중간값이고 실지급액은 직급에 따라 다르다. 포인트 형태·사용처 미기재'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'welfare_point'
   AND BENEFIT_NM = '복리후생비용 지원'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '공식 채용 공고 복리후생 제도 항목의 직급별 연간 통합복리후생비 130~220만원 지원 — 표기값은 직급별 구간의 중간값이고 실지급액은 직급에 따라 다르다. 포인트 형태·사용처 미기재'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 31;

-- ── jusung ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'jusung');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절 선물 포인트'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '설/추석 선물 포인트, 선물 신청몰에서 선택 (추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 82;

-- ── kai ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kai');
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '근속기념품·축하금 (복리후생제도 페이지 동기부여 항목 「근속기념품/휴가/축하금 지원」) — 근속 연수 기준·금액 미기재'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '근속기념품·축하금'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '근속기념품·축하금 (복리후생제도 페이지 동기부여 항목 「근속기념품/휴가/축하금 지원」) — 근속 연차 기준·금액 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 51;
-- long_service_leave (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '근속 휴가 (복리후생제도 페이지 동기부여 항목 「근속기념품/휴가/축하금 지원」) — 부여 일수·근속 연수 기준 미기재'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '근속 휴가'
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_DESC_CTNT = '근속 휴가 (복리후생제도 페이지 동기부여 항목 「근속기념품/휴가/축하금 지원」) — 부여 일수·근속 연차 기준 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 60;

-- ── kakao ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절 귀향비/생일선물'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '명절 귀향비 10만원, 생일선물 5만원(카카오톡 선물하기)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 86;
-- work_tools (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'work_env'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'work_tools'
   AND BENEFIT_NM = '최신 업무장비'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '최신/최고급 맥북, 전동 스탠딩 데스크, 허먼밀러 의자'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 83;

-- ── kakao_bank ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_bank');
-- work_tools (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'work_env'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'work_tools'
   AND BENEFIT_NM = '스탠딩 책상'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '스탠딩 책상 지원'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 85;

-- ── kakao_games ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_games');
-- massage (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'health'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'massage'
   AND BENEFIT_NM = '마사지(사이다룸)'
   AND BENEFIT_CTGR_CD = 'leisure'
   AND QUAL_DESC_CTNT = '전문 헬스키퍼 마사지, 안마의자/수면실'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 71;

-- ── kakao_pay ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_pay');
-- massage (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'health'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'massage'
   AND BENEFIT_NM = '전속 안마사/안마의자'
   AND BENEFIT_CTGR_CD = 'leisure'
   AND QUAL_DESC_CTNT = '전속 안마사 30분 안마, 격층 안마의자, 남녀 수면실'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 71;
-- parking (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'work_env'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'parking'
   AND BENEFIT_NM = '주차비 지원'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '주차비 지원'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 87;
-- work_tools (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'work_env'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'work_tools'
   AND BENEFIT_NM = '최신 맥북/스탠딩데스크'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '최신/최고급 맥북 또는 아이맥, 개인 스탠딩 데스크, 주말 업무용 차량 대여'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 86;

-- ── ls ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ls');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절 지원'
   AND BENEFIT_CTGR_CD = 'family'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '명절 상품권 지급 (추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 50;

-- ── lunit ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lunit');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절 선물'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '설과 추석 명절 선물 지급 (2025 지속가능경영보고서 복리후생 표 — 선물 종류·금액 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 43;

-- ── naver ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'naver');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절 네이버페이'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '설/추석 총 40만원 네이버페이 포인트(또는 상품권)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 85;
-- work_tools (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'work_env'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'work_tools'
   AND BENEFIT_NM = '업무 장비 예산'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '2년에 최대 720만원(연 360만원 환산) 노트북/모니터/태블릿 자유 선택, 허먼밀러 에어론/스탠딩데스크'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 80;

-- ── nepes ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'nepes');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절 선물'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '추석, 설날 명절 선물 지급 (추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 84;

-- ── nongshim ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'nongshim');
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속기념품 지급 (공식 채용 페이지 복리후생 「안정적인 삶」 항목 — 근속 연수 기준·기념품 내용 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '장기근속 기념품'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '장기근속기념품 지급 (공식 채용 페이지 복리후생 「안정적인 삶」 항목 — 근속 연차 기준·기념품 내용 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 60;

-- ── olix ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'olix');
-- parking (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'work_env'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'parking'
   AND BENEFIT_NM = '주차공간/주차비 지원'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '주차공간 및 주차비 지원'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 82;

-- ── park_systems ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'park_systems');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절 선물'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '(추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 84;

-- ── pharma_research ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'pharma_research');
-- massage (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'health'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'massage'
   AND BENEFIT_NM = '휴식공간 (포켓볼/안마의자)'
   AND BENEFIT_CTGR_CD = 'leisure'
   AND QUAL_DESC_CTNT = '포켓볼, 안마의자 등 휴식 공간 제공'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 72;

-- ── poongsan ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'poongsan');
-- flex_work (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '시차출퇴근제와 선택적근로시간제 운영 (2025 지속가능경영보고서 66쪽 복리후생 제도 표 유연근무제 운영 항목, 2025년 기준 — 신청 대상·운영 단위 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'flex_work'
   AND BENEFIT_NM = '유연근무제'
   AND BENEFIT_CTGR_CD = 'flexibility'
   AND QUAL_DESC_CTNT = '2025 지속가능경영보고서 66쪽 복리후생 제도 표 유연근무제 운영 항목의 시차출퇴근제와 선택적근로시간제 (2025년 기준) — 신청 대상·운영 단위 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 70;
-- health_check (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '본인·배우자 종합건강검진 지원 (2025 지속가능경영보고서 66쪽 건강관리 지원 항목, 2025년 기준 — 검진 주기·검진 비용 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'health_check'
   AND BENEFIT_NM = '종합건강검진 (본인·배우자)'
   AND BENEFIT_CTGR_CD = 'health'
   AND QUAL_DESC_CTNT = '2025 지속가능경영보고서 66쪽 건강관리 지원 항목의 본인·배우자 종합건강검진 지원 (2025년 기준) — 검진 주기·검진 비용 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 80;
-- insurance (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '전 임직원 대상 상해장애·상해사망·산재사망·질병사망 보험금 지급 (2025 지속가능경영보고서 66쪽 건강관리 지원 항목, 2025년 기준 — 보장 한도·보험료 부담 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'insurance'
   AND BENEFIT_NM = '단체보험'
   AND BENEFIT_CTGR_CD = 'health'
   AND QUAL_DESC_CTNT = '2025 지속가능경영보고서 66쪽 건강관리 지원 항목 기준 전 임직원 대상 상해장애·상해사망·산재사망·질병사망 보험금 지급 (2025년 기준) — 보장 한도·보험료 부담 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 81;
-- leave_general (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '자기계발휴가 (공식 채용정보 복지제도 페이지 여가 항목 휴가제도 · 2025 지속가능경영보고서 66쪽 휴가 제도 항목에도 자기계발 휴가 기재 — 부여 일수·사용 조건 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'leave_general'
   AND BENEFIT_NM = '자기계발휴가'
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_DESC_CTNT = '공식 채용정보 복지제도 페이지 여가 항목 휴가제도의 자기계발휴가. 2025 지속가능경영보고서 66쪽 휴가 제도 항목에도 자기계발 휴가 기재 — 부여 일수·사용 조건 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 61;
-- remote_work (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '재택근무 운영 (2025 지속가능경영보고서 66쪽 유연근무제 운영 항목, 2025년 기준 — 가능 일수·대상 직무 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'remote_work'
   AND BENEFIT_NM = '재택근무'
   AND BENEFIT_CTGR_CD = 'flexibility'
   AND QUAL_DESC_CTNT = '2025 지속가능경영보고서 66쪽 유연근무제 운영 항목의 재택근무 (2025년 기준) — 가능 일수·대상 직무 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 71;
-- retirement_support (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '퇴직 예정인 만 50세 이상 근로자 재취업 지원 서비스와 정년 앞둔 장기근속자 공로여행(유급휴가·여행 경비 지원) (2025 지속가능경영보고서 66쪽 복리후생 제도 표, 2025년 기준 · 공식 채용정보 복지제도 페이지 회사생활 항목 — 서비스 내용·기간·휴가 일수·여행 경비 한도 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'retirement_support'
   AND BENEFIT_NM = '퇴직자 재취업 지원'
   AND BENEFIT_CTGR_CD = 'growth'
   AND QUAL_DESC_CTNT = '2025 지속가능경영보고서 66쪽 복리후생 제도 표 기준 퇴직 예정인 만 50세 이상 근로자를 위한 재취업 지원 서비스 (2025년 기준), 공식 채용정보 복지제도 페이지 회사생활 항목 기준 정년 앞둔 장기근속자 공로여행(유급휴가·여행 경비 지원) — 서비스 내용·기간·휴가 일수·여행 경비 한도 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 91;
-- summer_leave (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '하기휴가 (공식 채용정보 복지제도 페이지 여가 항목 휴가제도 · 2025 지속가능경영보고서 66쪽 휴가 제도 항목에도 하계휴가 기재 — 휴가 일수·사용 시기 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'summer_leave'
   AND BENEFIT_NM = '하기휴가'
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_DESC_CTNT = '공식 채용정보 복지제도 페이지 여가 항목 휴가제도의 하기휴가. 2025 지속가능경영보고서 66쪽 휴가 제도 항목에도 하계휴가 기재 — 휴가 일수·사용 시기 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 60;
-- telecom (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '통신비 지원 (2025 지속가능경영보고서 66쪽 복리후생 제도 표 기타 지원 항목, 2025년 기준 — 지원 금액·대상 직군 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'telecom'
   AND BENEFIT_NM = '통신비 지원'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '2025 지속가능경영보고서 66쪽 복리후생 제도 표 기타 지원 항목의 통신비 지원 (2025년 기준) — 지원 금액·대상 직군 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 14;
-- welfare_fund_loan (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '사내 근로복지기금 대출 (공식 채용정보 복지제도 페이지 회사생활 항목은 「자금 지원」으로, 2025 지속가능경영보고서 66쪽 기타 지원 항목은 「복지기금 대출」로 기재 — 대출 한도·이율·대상 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'welfare_fund_loan'
   AND BENEFIT_NM = '사내 근로복지기금 대출'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '공식 채용정보 복지제도 페이지 회사생활 항목명은 자금 지원이고 내용은 사내 근로복지기금 운영. 2025 지속가능경영보고서 66쪽 기타 지원 항목이 복지기금 대출로 기재 — 대출 한도·이율·대상 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 13;

-- ── posco_futurem ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'posco_futurem');
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속자를 위한 포상금 지급 (공식 인사제도 페이지 복리후생 휴가제도 항목 — 근속 연수 기준·포상금 액수 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '장기근속 포상금'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '장기근속자를 위한 포상금 지급 (공식 인사제도 페이지 복리후생 휴가제도 항목 — 근속 연차 기준·포상금 액수 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 80;
-- long_service_leave (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속자를 위한 근속휴가 (공식 인사제도 페이지 복리후생 휴가제도 항목 — 근속 연수 기준·휴가 일수 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '근속휴가'
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_DESC_CTNT = '장기근속자를 위한 근속휴가 (공식 인사제도 페이지 복리후생 휴가제도 항목 — 근속 연차 기준·휴가 일수 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 71;

-- ── samsung_ena ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_ena');
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속 기간에 따른 기념품·상품권·휴가비 지급 (금액·근속 연수 구간 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '장기 근속 포상 및 휴가비'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '장기근속 기간에 따른 기념품·상품권·휴가비 지급 (금액·근속 연차 구간 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 60;
-- long_service_leave (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속 기간에 따른 유급휴가 부여 (근속 연수 구간·휴가 일수 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기 근속 휴가'
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_DESC_CTNT = '장기근속 기간에 따른 유급휴가 부여 (근속 연차 구간·휴가 일수 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 50;

-- ── samsung_heavy ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_heavy');
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기 근속 시 리텐션을 위한 선물 지급 (근속 연수 기준·선물 종류·금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '장기근속 선물'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '장기 근속 시 리텐션을 위한 선물 지급 (근속 연차 기준·선물 종류·금액 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 50;
-- long_service_leave (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기 근속 시 리텐션을 위한 휴가 지급 (근속 연수 기준·휴가 일수 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '근속휴가'
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_DESC_CTNT = '장기 근속 시 리텐션을 위한 휴가 지급 (근속 연차 기준·휴가 일수 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 40;

-- ── samsung_sds ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_sds');
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '오랜 시간 노력해 온 장기근속 임직원 시상 — 원문 항목 장기근속휴가/장기근속시상 중 시상 부분 (근속 연수 기준·포상 내용·금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '장기근속시상'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '오랜 시간 노력해 온 장기근속 임직원 시상 — 원문 항목 장기근속휴가/장기근속시상 중 시상 부분 (근속 연차 기준·포상 내용·금액 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 50;
-- long_service_leave (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속 임직원이 재충전할 수 있도록 휴가와 휴가비 지원 — 원문 항목 장기근속휴가/장기근속시상 중 휴가 부분 (근속 연수 기준·휴가 일수·휴가비 금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_leave'
   AND BENEFIT_NM = '장기근속휴가'
   AND BENEFIT_CTGR_CD = 'time_off'
   AND QUAL_DESC_CTNT = '장기근속 임직원이 재충전할 수 있도록 휴가와 휴가비 지원 — 원문 항목 장기근속휴가/장기근속시상 중 휴가 부분 (근속 연차 기준·휴가 일수·휴가비 금액 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 40;

-- ── seegene ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'seegene');
-- childcare (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '씨젠 어린이집 운영 (ESG 사회 페이지 복리후생 프로그램 가족 영역 — 정원·대상 연령·운영 사업장 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'childcare'
   AND BENEFIT_NM = '씨젠 어린이집'
   AND BENEFIT_CTGR_CD = 'family'
   AND QUAL_DESC_CTNT = 'ESG 사회 페이지 복리후생 프로그램 가족 영역: 씨젠 어린이집 운영 — 정원·대상 연령·운영 사업장 미기재'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 72;

-- ── silicon2 ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'silicon2');
-- parking (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'work_env'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'parking'
   AND BENEFIT_NM = '차량 지원'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '차량 지원(법인차량 및 주차비 지원)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 84;

-- ── simmtech ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'simmtech');
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속 및 우수/공로 포상 (공식 페이지 회사생활 항목명 그대로 — 근속 연수·포상 금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '장기근속 포상'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '장기근속 및 우수/공로 포상 (공식 페이지 회사생활 항목명 그대로 — 근속 연차·포상 금액 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 10;

-- ── sk_innovation ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_innovation');
-- event (note)
UPDATE TCOMPANY_BENEFIT SET NOTE_CTNT = '경조금 지급 (추정)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'event'
   AND BENEFIT_NM = '경조사 지원'
   AND BENEFIT_CTGR_CD = 'family'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '경조휴가 및 경조금 (추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 53;

-- ── soulbrain ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'soulbrain');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절/생일/창립기념 선물'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '명절선물, 생일선물, 창립기념일 선물 (추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 84;

-- ── taihan ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'taihan');
-- long_service_bonus (desc)
UPDATE TCOMPANY_BENEFIT SET QUAL_DESC_CTNT = '장기근속 포상 (공식 인사제도 페이지 복지제도 포상 항목 — 근속 연수 기준·포상 내용·금액 미기재)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'long_service_bonus'
   AND BENEFIT_NM = '장기근속 포상'
   AND BENEFIT_CTGR_CD = 'compensation'
   AND QUAL_DESC_CTNT = '장기근속 포상 (공식 인사제도 페이지 복지제도 포상 항목 — 근속 연차 기준·포상 내용·금액 미기재)'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 31;

-- ── tck ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'tck');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절/생일/결혼기념 포인트'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '명절 복지포인트, 생일/결혼기념일 축하 포인트 (추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 85;

-- ── voronoi ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'voronoi');
-- event (note)
UPDATE TCOMPANY_BENEFIT SET NOTE_CTNT = '각종 경조사 지원 (추정)'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'event'
   AND BENEFIT_NM = '경조사 지원'
   AND BENEFIT_CTGR_CD = 'family'
   AND QUAL_DESC_CTNT IS NULL
   AND NOTE_CTNT = '각종 경조사 지원 및 경조휴가 (추정)'
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 50;
-- parking (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'work_env'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'parking'
   AND BENEFIT_NM = '주차장 제공'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '주차장 제공'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 82;

-- ── wemade ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'wemade');
-- holiday_gift (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'compensation'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'holiday_gift'
   AND BENEFIT_NM = '명절 상품권'
   AND BENEFIT_CTGR_CD = 'perks'
   AND QUAL_DESC_CTNT = '설날/추석 백화점 상품권 지급'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 83;

-- ── wonik_ips ──
SET @c = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'wonik_ips');
-- massage (ctgr)
UPDATE TCOMPANY_BENEFIT SET BENEFIT_CTGR_CD = 'health'
 WHERE COMP_ID = @c
   AND BENEFIT_CD = 'massage'
   AND BENEFIT_NM = '안마의자'
   AND BENEFIT_CTGR_CD = 'leisure'
   AND QUAL_DESC_CTNT = '직원휴게시설 내 안마의자 운영'
   AND NOTE_CTNT IS NULL
   AND BADGE_CD = 'est'
   AND SORT_ORDER_NO = 62;

COMMIT;

-- 적용 뒤 확인(읽기 전용):
--   SELECT BENEFIT_CD, BENEFIT_CTGR_CD, COUNT(*) FROM TCOMPANY_BENEFIT
--    WHERE BENEFIT_CD IN ('holiday_gift','work_tools','parking','family_day','massage','welcome_kit')
--    GROUP BY 1,2 ORDER BY 1,2;
--   → 코드마다 카테고리가 **하나씩만** 나와야 한다(분열 0).
--   SELECT COUNT(*) FROM TCOMPANY_BENEFIT;  → 2451
