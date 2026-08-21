-- ══════════════════════════════════════════════════════════════════════
-- 회사 재무(DART) 3테이블 추가 — TCORP · TCOMPANY_CORP · TCORP_FINANCE
-- 근거: docs/PLAN-회사정보-확장-2026-08-21.md §3·§5-1·§5-2
--
-- **정본은 `db/schema.sql` 이다.** 이 파일은 기존 서빙 DB 를 그 상태로 옮기기 위한 것이며,
-- 신규 프로비저닝은 schema.sql 이 처리한다. 두 파일이 갈라지면 schema.sql 을 따른다.
--
-- 성격: **순수 추가**다. 기존 테이블·컬럼·데이터를 하나도 건드리지 않는다
--       (2026-07-20 브랜드축 마이그레이션과 달리 되돌릴 수 있다 — DROP TABLE 3줄이면 된다).
--
-- 멱등: 전부 `CREATE TABLE IF NOT EXISTS` — 재실행 안전.
--
-- 적용 후 확인:
--   SELECT TABLE_NAME FROM information_schema.TABLES
--    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ('TCORP','TCOMPANY_CORP','TCORP_FINANCE');
--   → 3행이면 성공.
--
-- ⚠ 적용 전 백업 권장(순수 추가라 위험은 낮지만 습관을 깨지 않는다):
--      sudo systemctl start loupit-backup.service
-- ══════════════════════════════════════════════════════════════════════
SET NAMES utf8mb4;

-- 1) 법인 마스터 — 재무의 소유자. 회사가 아니라 법인 단위다.
CREATE TABLE IF NOT EXISTS TCORP (
  CORP_CODE    CHAR(8)      PRIMARY KEY COMMENT 'DART 고유번호 8자리 (corpCode.xml 의 corp_code)',
  CORP_NM      VARCHAR(200) NOT NULL COMMENT 'DART 정식 법인명. 우리 표시명(TCOMPANY.COMP_NM)과 다를 수 있다 — 사명 변경 시 여기가 먼저 바뀐다',
  STOCK_CD     CHAR(6)      DEFAULT NULL COMMENT '종목코드 6자리. NULL = 비상장(CJ올리브네트웍스 등) — 사업보고서가 없을 수 있다',
  ACCT_SET_CD  VARCHAR(20)  NOT NULL DEFAULT 'general'
               COMMENT '지표 세트 — general: 매출·영업이익·순이익 / financial: 금융업. 금융은 ifrs-full_Revenue·dart_OperatingIncomeLoss 가 아예 없다(삼성생명 실측)',
  FS_DIV_CD    VARCHAR(3)   NOT NULL DEFAULT 'CFS'
               COMMENT '이 법인을 표시할 기본 기준 (CFS 연결 / OFS 별도). 지주사는 차이가 극단적이라(LG 9,122억 vs 5,971억) 화면에 반드시 명시한다',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  INDEX idx_corp_stock (STOCK_CD)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='DART 법인 마스터 (재무의 소유자 — 회사가 아니라 법인 단위)';

-- 2) 회사 → 법인 매핑. CORP_CODE 에 UNIQUE 를 걸지 않는 것이 이 테이블의 요점이다
--    (CJ ENM 엔터테인먼트부문·커머스부문이 같은 corp_code 00265324 를 가리킨다 — 실측).
CREATE TABLE IF NOT EXISTS TCOMPANY_CORP (
  COMP_ID    INT         PRIMARY KEY COMMENT '회사 FK (TCOMPANY.COMP_ID). PK = 회사당 법인 1개 — 둘이면 어느 실적인지 정해지지 않는다',
  CORP_CODE  CHAR(8)     NOT NULL COMMENT '법인 FK (TCORP.CORP_CODE). ⚠ UNIQUE 아님 — 한 법인을 여러 페이지가 가리킨다',
  MATCH_CD   VARCHAR(20) NOT NULL DEFAULT 'auto'
             COMMENT '매칭 근거 (auto: 상장사 정확일치 1건, manual: 사람 검수). 계열사 오매핑 전력(bokziri 148/770)이 있어 근거를 남긴다',
  MATCH_NOTE_CTNT VARCHAR(300) DEFAULT NULL COMMENT '검수 메모 (동명 법인 중 선택 근거 등 — 삼성물산 modify_date 판별 같은 것)',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  FOREIGN KEY (COMP_ID) REFERENCES TCOMPANY(COMP_ID) ON DELETE CASCADE,
  FOREIGN KEY (CORP_CODE) REFERENCES TCORP(CORP_CODE),
  INDEX idx_company_corp_code (CORP_CODE)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='회사↔DART법인 매핑 (회사당 1법인, 법인당 N회사 — CJ ENM 2부문이 1법인)';

-- 3) 법인별·연도별 재무. COMP_ID 컬럼이 **없다** — 있으면 CJ ENM 2페이지가 수치를 두 벌 갖는다.
CREATE TABLE IF NOT EXISTS TCORP_FINANCE (
  FIN_ID      INT AUTO_INCREMENT PRIMARY KEY COMMENT '재무 수치 PK',
  CORP_CODE   CHAR(8)       NOT NULL COMMENT '법인 FK (TCORP.CORP_CODE) — 회사가 아니라 법인에 매단다',
  BSNS_YEAR   SMALLINT      NOT NULL COMMENT '사업연도 (bsns_year)',
  FS_DIV_CD   VARCHAR(3)    NOT NULL COMMENT '연결(CFS)/별도(OFS). NOT NULL 이다 — 기준 없는 수치는 부정확한 주장이 된다',
  ACCT_ID     VARCHAR(120)  NOT NULL
              COMMENT '표준계정 ID (ifrs-full_Revenue, dart_OperatingIncomeLoss, ifrs-full_ProfitLoss). ⚠ account_nm 이 아니다 — 이름은 회사마다 다르고, sj_div 로 거르면 SK하이닉스처럼 CIS 에 싣는 회사가 에러 없이 빈다',
  ACCT_NM     VARCHAR(200)  DEFAULT NULL COMMENT '회사 표기 계정명 (참고용 — 판정 근거로 쓰지 않는다)',
  AMT_VAL     DECIMAL(24,0) DEFAULT NULL COMMENT '금액(원). 조 단위를 담아야 해 DECIMAL(24,0). NULL = 해당 회사에 그 계정이 없음(금융업 등) — 0 이 아니다',
  RCEPT_NO    VARCHAR(20)   DEFAULT NULL COMMENT '공시 접수번호 (출처 추적·재검증 근거)',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  FOREIGN KEY (CORP_CODE) REFERENCES TCORP(CORP_CODE) ON DELETE CASCADE,
  UNIQUE KEY uq_corp_fin (CORP_CODE, BSNS_YEAR, FS_DIV_CD, ACCT_ID),
  INDEX idx_corp_fin_lookup (CORP_CODE, BSNS_YEAR)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='법인별 연도별 재무 (DART 공시 — 법인 단위 1벌, 연결/별도 공존)';
