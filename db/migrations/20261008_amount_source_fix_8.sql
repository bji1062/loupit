-- ══════════════════════════════════════════════════════════════════════
-- 금액 표시 정정 8행 — 삼성전자 3행 추정치로 · 1회성 5행 금액 미등록 (리드 판정 (88))
-- 사용자 결정: 2026-10-08 (삼성 3행 estimated 로 정정 · 1회성 5행 금액 미등록으로)
-- 선례: db/migrations/20261006_meal_unit_12000.sql · 20260925_official_amount_corrections.sql
--
-- A) 삼성전자 574 resort 100 · 576 welfare_point 200 · 579 commute_subsidy 120: 삼성전자 채용 사이트 원문에 금액이 없다
--    (2026-04 앵커가 20260710_backfill_dec2 휴리스틱으로 stated 가 된 것). 금액 · 이름 · 배지 · 확인일 그대로, 금액출처만
--    estimated. 적재(backfill_dec2.derive_amt_source)는 NOTE 에 「추정」 · 「환산」이 있으면 estimated 로 읽으므로 시드 NOTE 끝에
--    코퍼스 관례의 「 (추정)」을 붙였고 이 파일도 같은 글자로 맞춘다.
-- B) 한 번 받는 돈을 연 금액으로 적은 5행: 10789 KAI 출산장려금 1,000 · 1465 CJ프레시웨이 근속포상금 1,000 · 1382 CJ ENM 커머스
--    근속포상금 500 · 1424 CJ올리브영 인재추천포상금 500 · 1472 CJ프레시웨이 경조사 지원 150 → 「1회성 NULL」 규칙: 금액 NULL ·
--    금액출처 none · 정성(QUAL_YN TRUE) · 서술은 정성 행 관례대로 QUAL_DESC 로 옮기고 NOTE 는 NULL. 원문 금액 서술은 남기고
--    등록 금액을 가리키던 수집자 메모 「표기값은 상한」(1382 · 1424 · 1465)만 걷는다. 10789 · 1472 는 걷을 메모가 없어 서술 그대로.
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 코드 · 이름 · 옛 금액 · AMT_SOURCE stated · 정성 아님 · 옛 NOTE 글자 그대로 · BADGE_CD = official.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다. 순서 (반드시): 이 파일 -> python3 db/seed/load.py -> release.
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다): mysql -vv 로 적용.
-- 기대: 8문 각각 Rows matched: 1  Changed: 1 · 두 번째 실행 0 · 행 수 3179 그대로 · stated 64 -> 56 · estimated 389 -> 392 · none 2726 -> 2731.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- 574 samsung_elec resort 워터파크/테마파크/휴양소 : stated -> estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.AMT_SOURCE_CD = 'estimated', b.NOTE_CTNT = '워터파크 무료, 테마파크 할인, 호텔/휴양지 숙박 지원 (추정)'
 WHERE b.BENEFIT_ID = 574 AND c.COMP_ENG_NM = 'samsung_elec' AND b.BENEFIT_CD = 'resort' AND b.BENEFIT_NM = '워터파크/테마파크/휴양소'
   AND b.BENEFIT_AMT = 100 AND b.AMT_SOURCE_CD = 'stated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '워터파크 무료, 테마파크 할인, 호텔/휴양지 숙박 지원'
   AND b.BADGE_CD = 'official';

-- 576 samsung_elec welfare_point 선택적 복리포인트 : stated -> estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.AMT_SOURCE_CD = 'estimated', b.NOTE_CTNT = '건강/여행/공연/도서/교육 자율 사용 (추정)'
 WHERE b.BENEFIT_ID = 576 AND c.COMP_ENG_NM = 'samsung_elec' AND b.BENEFIT_CD = 'welfare_point' AND b.BENEFIT_NM = '선택적 복리포인트'
   AND b.BENEFIT_AMT = 200 AND b.AMT_SOURCE_CD = 'stated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '건강/여행/공연/도서/교육 자율 사용'
   AND b.BADGE_CD = 'official';

-- 579 samsung_elec commute_subsidy 통근버스 : stated -> estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.AMT_SOURCE_CD = 'estimated', b.NOTE_CTNT = '수도권 150여 노선, 일 약 800회 운행 (추정)'
 WHERE b.BENEFIT_ID = 579 AND c.COMP_ENG_NM = 'samsung_elec' AND b.BENEFIT_CD = 'commute_subsidy' AND b.BENEFIT_NM = '통근버스'
   AND b.BENEFIT_AMT = 120 AND b.AMT_SOURCE_CD = 'stated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '수도권 150여 노선, 일 약 800회 운행'
   AND b.BADGE_CD = 'official';

-- 10789 kai parenting 출산장려금 : 1000/stated -> 금액 미등록(정성)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = NULL, b.AMT_SOURCE_CD = 'none', b.QUAL_YN = TRUE, b.NOTE_CTNT = NULL, b.QUAL_DESC_CTNT = '출산장려금 1,000만원 지급 (채용사이트 가정/육아지원 항목). 가족친화 직장 페이지: 종전 100만원에서 1·2자녀 각 1,000만원, 3자녀 3,000만원으로 상향 — 자녀 1인당 1회 지급액(연간 반복 지급 아님)'
 WHERE b.BENEFIT_ID = 10789 AND c.COMP_ENG_NM = 'kai' AND b.BENEFIT_CD = 'parenting' AND b.BENEFIT_NM = '출산장려금'
   AND b.BENEFIT_AMT = 1000 AND b.AMT_SOURCE_CD = 'stated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '출산장려금 1,000만원 지급 (채용사이트 가정/육아지원 항목). 가족친화 직장 페이지: 종전 100만원에서 1·2자녀 각 1,000만원, 3자녀 3,000만원으로 상향 — 자녀 1인당 1회 지급액(연간 반복 지급 아님)'
   AND b.BADGE_CD = 'official';

-- 1465 cj_freshway long_service_bonus 근속포상금 : 1000/stated -> 금액 미등록(정성)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = NULL, b.AMT_SOURCE_CD = 'none', b.QUAL_YN = TRUE, b.NOTE_CTNT = NULL, b.QUAL_DESC_CTNT = 'CREATIVE WEEK 2주 유급휴가 + 10년 이상 근속자 50만원~최대 1,000만원'
 WHERE b.BENEFIT_ID = 1465 AND c.COMP_ENG_NM = 'cj_freshway' AND b.BENEFIT_CD = 'long_service_bonus' AND b.BENEFIT_NM = '근속포상금'
   AND b.BENEFIT_AMT = 1000 AND b.AMT_SOURCE_CD = 'stated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = 'CREATIVE WEEK 2주 유급휴가 + 10년 이상 근속자 50만원~최대 1,000만원. 표기값은 상한'
   AND b.BADGE_CD = 'official';

-- 1382 cj_enm_com long_service_bonus 근속포상금 : 500/stated -> 금액 미등록(정성)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = NULL, b.AMT_SOURCE_CD = 'none', b.QUAL_YN = TRUE, b.NOTE_CTNT = NULL, b.QUAL_DESC_CTNT = 'CREATIVE WEEK 근속포상 — 3·5·7년 근속 시 300~500만원 (2주 유급휴가 동반)'
 WHERE b.BENEFIT_ID = 1382 AND c.COMP_ENG_NM = 'cj_enm_com' AND b.BENEFIT_CD = 'long_service_bonus' AND b.BENEFIT_NM = '근속포상금'
   AND b.BENEFIT_AMT = 500 AND b.AMT_SOURCE_CD = 'stated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = 'CREATIVE WEEK 근속포상 — 3·5·7년 근속 시 300~500만원 (2주 유급휴가 동반). 표기값은 상한'
   AND b.BADGE_CD = 'official';

-- 1424 cj_oliveyoung excellence_award 인재추천포상금 : 500/stated -> 금액 미등록(정성)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = NULL, b.AMT_SOURCE_CD = 'none', b.QUAL_YN = TRUE, b.NOTE_CTNT = NULL, b.QUAL_DESC_CTNT = '인재 추천 포상금 300~500만원'
 WHERE b.BENEFIT_ID = 1424 AND c.COMP_ENG_NM = 'cj_oliveyoung' AND b.BENEFIT_CD = 'excellence_award' AND b.BENEFIT_NM = '인재추천포상금'
   AND b.BENEFIT_AMT = 500 AND b.AMT_SOURCE_CD = 'stated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '인재 추천 포상금 300~500만원. 표기값은 상한'
   AND b.BADGE_CD = 'official';

-- 1472 cj_freshway event 경조사 지원 : 150/stated -> 금액 미등록(정성)
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = NULL, b.AMT_SOURCE_CD = 'none', b.QUAL_YN = TRUE, b.NOTE_CTNT = NULL, b.QUAL_DESC_CTNT = '최대 7일 휴가 + 최대 150만원 경조금, 웨딩홀 대관료 150만원 지원'
 WHERE b.BENEFIT_ID = 1472 AND c.COMP_ENG_NM = 'cj_freshway' AND b.BENEFIT_CD = 'event' AND b.BENEFIT_NM = '경조사 지원'
   AND b.BENEFIT_AMT = 150 AND b.AMT_SOURCE_CD = 'stated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '최대 7일 휴가 + 최대 150만원 경조금, 웨딩홀 대관료 150만원 지원'
   AND b.BADGE_CD = 'official';

COMMIT;
