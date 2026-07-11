-- ══════════════════════════════════════════════════════════════════════
-- DEC-2 백필: 출처 신뢰도(official) 승격 + 금액 신뢰도(amt_source) 정밀화
--             + 신선도/만료(VERIFIED_DTM/EXPIRES_DTM)
-- 근거: SPEC/02 SP-DB-13 (RESEARCH §6 CHANGE·§4.1·§4.3, DEC-2, OI-3/OI-6)
-- 적용 시점: db/schema.sql → db/seed/reference.sql → db/seed/benefit/sql/*.sql
--           적재 이후(SP-DB-10 적용 순서 4단계). 96(→95)개 등록분 대상.
-- 멱등: 전 UPDATE가 조건부(WHERE)·COALESCE 기반 — 재실행 안전.
--
-- ── DG-1(만료 TTL) 정정 안내 ──
-- SPEC/02 SP-DB-13 원문은 카테고리별 차등 TTL(compensation 6개월 /
-- perks 9개월 / time_off·flexibility 12개월 / 그 외 18개월)을 제시했으나,
-- 이후 docs/TASK/00-빌드순서-마일스톤.md §4(결정 게이트 레지스트리, 정본)가
-- "DG-1 = 균일 18개월 TTL(초단순 — 카테고리 차등 대신 전 카테고리 18개월)"
-- 로 최종 확정했다(2026-07-11). TASK/00은 결정 게이트를 소유하는 정본이므로
-- 본 마이그레이션은 SPEC/02 원문 대신 이 확정값(균일 18개월)을 구현한다.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- 1) 출처 신뢰도: 큐레이션 복지는 공식 페이지 기반 → official 승격 (DEC-2).
--    출처 유형 기본값 ai_parse(기존 backfill 관례), 이미 값이 있으면 보존.
UPDATE TCOMPANY_BENEFIT
   SET BADGE_CD = 'official'
 WHERE BADGE_CD = 'est';

UPDATE TCOMPANY_BENEFIT
   SET BADGE_SRC_CD = 'ai_parse'
 WHERE BADGE_SRC_CD IS NULL;

-- 2) 금액 신뢰도(amt_source) 도출 (OI-6/DG-2 확정 규칙):
--    (a) 정성 복지 또는 금액 없음 → none
UPDATE TCOMPANY_BENEFIT
   SET AMT_SOURCE_CD = 'none'
 WHERE QUAL_YN = TRUE OR BENEFIT_AMT IS NULL;

--    (b) 금액 있고 '(추정)'/'추정'/환산 표기 또는 비고 없음 → estimated (앵커 추정)
UPDATE TCOMPANY_BENEFIT
   SET AMT_SOURCE_CD = 'estimated'
 WHERE BENEFIT_AMT IS NOT NULL
   AND (NOTE_CTNT LIKE '%추정%' OR NOTE_CTNT LIKE '%환산%' OR NOTE_CTNT IS NULL);

--    (c) 금액 있고 공식 명시(추정 표기 없음) → stated
UPDATE TCOMPANY_BENEFIT
   SET AMT_SOURCE_CD = 'stated'
 WHERE BENEFIT_AMT IS NOT NULL
   AND NOTE_CTNT IS NOT NULL
   AND NOTE_CTNT NOT LIKE '%추정%'
   AND NOTE_CTNT NOT LIKE '%환산%';

-- 3) 신선도/만료: VERIFIED_DTM = 수집일(미기재분 시드 배치일로 통일),
--    EXPIRES_DTM = VERIFIED_DTM + 균일 18개월 TTL (DG-1 확정, TASK/00 §4).
UPDATE TCOMPANY_BENEFIT
   SET VERIFIED_DTM = COALESCE(VERIFIED_DTM, '2026-07-10 00:00:00');

UPDATE TCOMPANY_BENEFIT
   SET EXPIRES_DTM = DATE_ADD(VERIFIED_DTM, INTERVAL 18 MONTH)
 WHERE EXPIRES_DTM IS NULL;
