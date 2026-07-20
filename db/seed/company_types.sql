-- ══════════════════════════════════════════════════════════════════════
-- 기업유형 6종 시드 (SP-SEED-4.1)
-- 소스: job_change/server/seed/seed.py COMPANY_TYPES (큐레이션 상수, 재게시 아님)
-- 멱등: INSERT IGNORE (UNIQUE COMP_TP_CD)
-- ══════════════════════════════════════════════════════════════════════
SET NAMES utf8mb4;

-- 성장률·성장문구·안정성 3컬럼은 브랜드 축 제거(2026-07-20)로 드랍됐다.
-- 남은 것은 코드(comp_tp_cd)와 표시명(comp_tp_nm)뿐 — 직접입력 유형 선택·정적 페이지 라벨용.
INSERT IGNORE INTO TCOMPANY_TYPE
  (COMP_TP_CD, COMP_TP_NM)
VALUES
  ('large',     '대기업'),
  ('mid',       '중견기업'),
  ('public',    '공기업'),
  ('startup',   '스타트업'),
  ('foreign',   '외국계'),
  ('freelance', '프리랜서');
