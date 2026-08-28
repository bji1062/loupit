-- ══════════════════════════════════════════════════════════════════════
-- 직원 현황 1테이블 추가 — TCORP_EMPLOY
-- 근거: docs/SPEC/17-회사정보-지표.md SP-MET-4(스키마)·SP-MET-5(합계행)·SP-MET-6(급여 단위)
--
-- **정본은 `db/schema.sql` 이다.** 이 파일은 기존 서빙 DB 를 그 상태로 옮기기 위한 것이며,
-- 신규 프로비저닝은 schema.sql 이 처리한다. 두 파일이 갈라지면 schema.sql 을 따른다
-- (드리프트는 `server/tests/test_corp_employ_schema.py::test_CE10_migration_matches_schema` 가 막는다).
--
-- 성격: **순수 추가**다. 기존 테이블·컬럼·데이터를 하나도 건드리지 않는다 — 되돌리려면
--       `DROP TABLE TCORP_EMPLOY;` 한 줄이면 된다.
--
-- ⚠ **선행 조건**: `20260821_add_corp_finance.sql` 이 먼저 적용돼 `TCORP` 가 있어야 한다.
--    없으면 FK 생성에서 errno 150 으로 실패한다(조용히 넘어가지 않는다 — 그게 맞다).
--
-- ⚠ **재무 테이블은 손대지 않는다.** SP-MET-2 의 금융업 대안(자산총계)은 `TCORP_FINANCE` 에
--    `ACCT_ID='ifrs-full_Assets'` **행이 추가될 뿐**이다. `ACCT_ID` 가 문자열이라 새 지표를
--    넣는 데 DDL 이 필요 없다 — 이 마이그레이션에 재무 관련 문장이 하나도 없는 이유다.
--
-- 멱등: `CREATE TABLE IF NOT EXISTS` — 재실행 안전.
--
-- 적용 후 확인:
--   SELECT TABLE_NAME FROM information_schema.TABLES
--    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='TCORP_EMPLOY';
--   → 1행이면 성공.
--
-- ⚠ 적용 전 백업 권장(순수 추가라 위험은 낮지만 습관을 깨지 않는다):
--      sudo systemctl start loupit-backup.service
-- ══════════════════════════════════════════════════════════════════════
SET NAMES utf8mb4;

-- 법인별·연도별 직원 현황. COMP_ID 컬럼이 **없다** — 재무와 같은 이유로 법인 단위다
-- (있으면 CJ ENM 2페이지가 인원을 두 벌 갖고, 한쪽만 갱신되는 순간 조용히 갈라진다).
--
-- 부문(fo_bbm)×성별(sexdstn) 원문을 그대로 1벌 저장한다. 회사 단위 값(평균연봉·평균근속·
-- 직원수)은 인원 가중평균으로 집계 시점에 계산한다(SP-MET-8) — 저장하지 않는다.
-- RAW_* 는 정규화 규칙이 바뀌었을 때 **재수집 없이 재계산**하기 위한 근거다.
CREATE TABLE IF NOT EXISTS TCORP_EMPLOY (
  EMPLOY_ID      INT AUTO_INCREMENT PRIMARY KEY COMMENT '직원 현황 PK',
  CORP_CODE      CHAR(8)      NOT NULL COMMENT '법인 FK (TCORP.CORP_CODE)',
  BSNS_YEAR      SMALLINT     NOT NULL COMMENT '사업연도',
  SEGMENT_NM     VARCHAR(200) NOT NULL COMMENT '사업부문 원문 (fo_bbm). 합계행이면 "성별합계" 등',
  SEX_CD         VARCHAR(10)  NOT NULL COMMENT '성별 원문 (sexdstn). 표시하지 않는다 — 집계에만 쓴다',
  TOTAL_ROW_YN   BOOLEAN      NOT NULL DEFAULT FALSE COMMENT '합계행 판정 결과(SP-MET-5). 부문행과 함께 오면 이 행만 센다',
  HEADCNT        INT          DEFAULT NULL COMMENT '인원 (sm)',
  TENURE_YEAR    DECIMAL(5,2) DEFAULT NULL COMMENT '평균 근속(년, 정규화). NULL=파싱 실패 — 0 이 아니다',
  AVG_SALARY_AMT BIGINT       DEFAULT NULL COMMENT '1인평균급여(원, 단위 정규화 후). 타당 범위 밖이면 NULL',
  RAW_TENURE_NM  VARCHAR(50)  DEFAULT NULL COMMENT '근속 원문 — "92개월"·"13년 6월" 등. 재정규화 근거',
  RAW_SALARY_NM  VARCHAR(50)  DEFAULT NULL COMMENT '급여 원문 — 단위가 연도마다 바뀐다(SP-MET-6)',
  RCEPT_NO       VARCHAR(20)  DEFAULT NULL COMMENT '공시 접수번호',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  UNIQUE KEY uq_corp_employ (CORP_CODE, BSNS_YEAR, SEGMENT_NM, SEX_CD),
  INDEX idx_corp_employ_lookup (CORP_CODE, BSNS_YEAR),
  FOREIGN KEY (CORP_CODE) REFERENCES TCORP(CORP_CODE) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='법인별 연도별 직원 현황 (DART 사업보고서 — 부문×성별 원문 1벌)';
