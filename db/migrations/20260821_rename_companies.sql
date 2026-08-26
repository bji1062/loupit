-- ══════════════════════════════════════════════════════════════════════
-- 사명 변경 2건 — 표시명 갱신 + 옛 이름 별칭 보존
-- 근거: DART 개황 API(company.json). docs/PLAN-회사정보-확장-2026-08-21.md §5-1
--
--   LIG넥스원   → LIG디펜스앤에어로스페이스(구 LIG넥스원)
--                  DART 정식명 `엘아이지디펜스앤에어로스페이스(주)`, 2026-03-31 주총 결의,
--                  DART 갱신 2026-04-15. 도메인도 이미 `ligdna.com` 으로 등록돼 있다
--                  (db/seed/company_email_domain.sql §방산 주석 참조).
--   엔씨소프트  → 엔씨소프트(NC)
--                  DART 정식명 `(주)엔씨`(NC Corporation), 갱신 2026-05-04.
--
-- **병기형인 이유**: 옛 이름에 검색 유입이 걸려 있다. `NC` 는 두 글자라 단독으로 쓰면
-- 검색 매칭이 약하고, `엘아이지디펜스앤에어로스페이스` 는 반대로 너무 길다.
--
-- ⚠ **URL slug(COMP_ENG_NM)는 건드리지 않는다.** `ncsoft`·`lig_nex1` 그대로다 —
--   바꾸면 /company/ncsoft·/company/lig-nex1 의 색인과 외부 링크가 통째로 깨진다.
--   표시명과 주소는 서로 독립이며, 그래서 이 변경으로 링크 자산은 잃지 않는다.
--
-- ⚠ **별칭을 함께 넣는 것이 이 마이그레이션의 절반이다.** 표시명만 바꾸면
--   `company_meta.build_company_meta()` 의 200-seed 조인(`by_name.get(comp_nm)`)이 깨져
--   재시드 때 옛 별칭이 fallback 으로 사라진다. 시드 쪽은 `LIG_ALIASES` override 로 막았고,
--   여기서는 현재 서빙 DB 에 직접 넣는다. 계약: server/tests/test_seed_integrity.py SI-R1.
--
-- 멱등: UPDATE 는 값 고정, 별칭은 uq_comp_alias 에 기대는 INSERT IGNORE — 재실행 안전.
-- 되돌리기: COMP_NM 을 옛 값으로 UPDATE 하면 된다(별칭은 남겨도 무해).
--
-- 적용 후 **정적 재생성 필수** — 회사 페이지는 정적이라 재생성 전까지 옛 이름이 서빙된다.
-- ══════════════════════════════════════════════════════════════════════
SET NAMES utf8mb4;

-- 1) 표시명 갱신
UPDATE TCOMPANY SET COMP_NM = 'LIG디펜스앤에어로스페이스(구 LIG넥스원)'
 WHERE COMP_ENG_NM = 'lig_nex1';
UPDATE TCOMPANY SET COMP_NM = '엔씨소프트(NC)'
 WHERE COMP_ENG_NM = 'ncsoft';

-- 2) 새 이름 별칭 추가 (옛 이름은 이미 있으므로 INSERT IGNORE 가 건너뛴다)
INSERT IGNORE INTO TCOMPANY_ALIAS (COMP_ID, ALIAS_NM)
  SELECT COMP_ID, 'LIG디펜스앤에어로스페이스' FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1';
INSERT IGNORE INTO TCOMPANY_ALIAS (COMP_ID, ALIAS_NM)
  SELECT COMP_ID, 'LIG디펜스' FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1';
INSERT IGNORE INTO TCOMPANY_ALIAS (COMP_ID, ALIAS_NM)
  SELECT COMP_ID, 'LIG D&A' FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1';
INSERT IGNORE INTO TCOMPANY_ALIAS (COMP_ID, ALIAS_NM)
  SELECT COMP_ID, 'LIG DnA' FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1';
INSERT IGNORE INTO TCOMPANY_ALIAS (COMP_ID, ALIAS_NM)
  SELECT COMP_ID, 'LIG' FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1';
