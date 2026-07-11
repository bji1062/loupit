-- ══════════════════════════════════════════════════════════════════════
-- 기업유형 6종 시드 (SP-SEED-4.1)
-- 소스: job_change/server/seed/seed.py COMPANY_TYPES (큐레이션 상수, 재게시 아님)
-- 멱등: INSERT IGNORE (UNIQUE COMP_TP_CD)
-- ══════════════════════════════════════════════════════════════════════
SET NAMES utf8mb4;

INSERT IGNORE INTO TCOMPANY_TYPE
  (COMP_TP_CD, COMP_TP_NM, GROWTH_RATE_VAL, GROWTH_LABEL_NM, STABILITY_SCORE_NO)
VALUES
  ('large',     '대기업',     0.0400, '대기업 평균 4%',     90),
  ('mid',       '중견기업',   0.0270, '중견기업 평균 2.7%', 70),
  ('public',    '공기업',     0.0300, '공기업 평균 3%',      95),
  ('startup',   '스타트업',   0.1000, '스타트업 평균 10%',   30),
  ('foreign',   '외국계',     0.0500, '외국계 평균 5%',      60),
  ('freelance', '프리랜서',   0.0200, '프리랜서 평균 2%',    20);
