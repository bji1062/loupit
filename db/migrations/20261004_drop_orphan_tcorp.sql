-- ══════════════════════════════════════════════════════════════════════
-- 고아 법인 정리 — 회사 등록을 해제한 LG 지주 · LS 지주 · HPSP 의 DART 법인 행(TCORP)과 재무 · 직원 행
-- 대상: 00120021 LG(003550) · 00105952 LS(006260) · 01288827 HPSP(403870)
-- 배경: 등록 해제 마이그레이션 3편(20261001_unregister_lg_holding.sql · 20261001_unregister_ls_holding.sql ·
--   20261002_unregister_hpsp.sql)은 TCOMPANY_CORP 연결만 지우고 TCORP 는 남겼다 — load_corp.py 의 TCORP 를 지우지 않는
--   설계를 따른 것이고 생성기는 TCOMPANY_CORP 를 거쳐 읽어 화면 영향은 0이다. 남은 비용은 DART 수동 수집기
--   (dart_finance.py · dart_employ.py)가 TCORP 전량을 돌아 세 법인을 계속 부르는 것이다.
-- 다시 생기지 않는 이유: TCORP 를 만드는 곳은 load_corp.py(corp_code_map.csv) 하나이고 세 법인 줄은 등록 해제 때 지웠다.
-- 가드: 법인 코드 · DART 이름 · 종목코드가 모두 같고 회사 연결(TCOMPANY_CORP)이 없을 때만 지운다 — 누가 세 회사를
--   다시 등록해 연결이 생겼으면 0행으로 끝난다(TCOMPANY_CORP 의 FK 는 NO ACTION 이라 가드가 없어도 연결이 있으면 실패한다).
-- 재무 · 직원은 FK ON DELETE CASCADE 지만 -vv 에 행 수가 보이도록 먼저 지운다.
-- 멱등: 두 번째 실행은 전부 0행. 한 트랜잭션 · DDL 0. 시드 · 생성기 · web/assets 변경 없음 — load.py · release 필요 없음.
--
-- 🚨 비가역: TCORP · TCORP_FINANCE · TCORP_EMPLOY 3테이블 백업 먼저(DART 재수집으로만 복구).
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   1) 백업 — TCORP · TCORP_FINANCE · TCORP_EMPLOY (참조 9테이블 백업에는 재무 · 직원 테이블이 없다)
--   2) 이 파일을 mysql -vv 로 적용
-- 기대: 확인 SELECT 3행(fin 88 · 88 · 16 · emp 22 · 50 · 8 · links 0) · DELETE 3문 = 192 · 80 · 3 rows affected ·
--   적용 뒤 TCORP 145 · TCORP_FINANCE 10560 · TCORP_EMPLOY 5888 · TCOMPANY_CORP 146 그대로 · 두 번째 실행 0 · 0 · 0.
--   (2026-10-04 운영 SELECT 기준 — 그 뒤 DART 수집을 다시 돌렸으면 재무 · 직원 행 수는 달라질 수 있다)
-- ══════════════════════════════════════════════════════════════════════

START TRANSACTION;

SELECT t.CORP_CODE, t.CORP_NM, t.STOCK_CD,
       (SELECT COUNT(*) FROM TCORP_FINANCE f WHERE f.CORP_CODE = t.CORP_CODE) AS fin,
       (SELECT COUNT(*) FROM TCORP_EMPLOY e WHERE e.CORP_CODE = t.CORP_CODE) AS emp,
       (SELECT COUNT(*) FROM TCOMPANY_CORP cc WHERE cc.CORP_CODE = t.CORP_CODE) AS links
  FROM TCORP t WHERE t.CORP_CODE IN ('00120021', '00105952', '01288827');

DELETE f FROM TCORP_FINANCE f
  JOIN TCORP t ON t.CORP_CODE = f.CORP_CODE
 WHERE (t.CORP_CODE, t.CORP_NM, t.STOCK_CD) IN (('00120021', 'LG', '003550'), ('00105952', 'LS', '006260'), ('01288827', 'HPSP', '403870'))
   AND NOT EXISTS (SELECT 1 FROM TCOMPANY_CORP cc WHERE cc.CORP_CODE = t.CORP_CODE);

DELETE e FROM TCORP_EMPLOY e
  JOIN TCORP t ON t.CORP_CODE = e.CORP_CODE
 WHERE (t.CORP_CODE, t.CORP_NM, t.STOCK_CD) IN (('00120021', 'LG', '003550'), ('00105952', 'LS', '006260'), ('01288827', 'HPSP', '403870'))
   AND NOT EXISTS (SELECT 1 FROM TCOMPANY_CORP cc WHERE cc.CORP_CODE = t.CORP_CODE);

DELETE FROM TCORP
 WHERE (CORP_CODE, CORP_NM, STOCK_CD) IN (('00120021', 'LG', '003550'), ('00105952', 'LS', '006260'), ('01288827', 'HPSP', '403870'))
   AND NOT EXISTS (SELECT 1 FROM TCOMPANY_CORP cc WHERE cc.CORP_CODE = TCORP.CORP_CODE);

COMMIT;
