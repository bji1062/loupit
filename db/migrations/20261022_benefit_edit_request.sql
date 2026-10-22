-- ══════════════════════════════════════════════════════════════════════
-- 복지 등록·수정 운영자 확인 — TBENEFIT_EDIT_REQUEST 추가 + TBENEFIT_EDIT_LOG.ACTOR_KIND_CD (2026-10-22)
-- 근거: 2026-10-21 사용자 결정 · docs/SPEC/13-참여-로그인.md SP-AUTH-9 · SP-AUTH-19 · docs/SPEC/02-데이터베이스-스키마.md SP-DB-17.8
--
-- **정본은 `db/schema.sql` 이다.** 이 파일은 기존 서빙 DB(LOUPIT)를 그 상태로 옮기기 위한 것이며 새 표의 DDL 은
-- 바이트까지 같다(test_benefit_edit_request BR-1 이 드리프트를 막는다).
--
-- 하는 일 세 가지:
--   1) 새 표 TBENEFIT_EDIT_REQUEST — 회원 등록·수정 요청 큐. 본체(TCOMPANY_BENEFIT)에 상태 칸을 넣지 않는 것이 핵심이다
--      (그 표를 읽는 곳이 많아 하나만 빠뜨려도 대기 건이 공개된다).
--   2) TBENEFIT_EDIT_LOG 에 ACTOR_KIND_CD 칸 — 공개 이력의 편집 주체 구분 (member, operator).
--   3) 운영자 CLI 가 남긴 기존 이력을 operator 로 옮긴다 — 회원 없음 + 메모가 운영자로 시작하는 행, 그리고 삭제 행.
--      (공개 이력에서 운영자 정정이 탈퇴로 보이던 것을 고친다.)
--
-- 성격: 새 표 + 칸 1개 추가 + 이력 몇 행 갱신 — 기존 데이터 삭제 없음. 되돌리기 = DROP TABLE TBENEFIT_EDIT_REQUEST 와
--   ALTER TABLE TBENEFIT_EDIT_LOG DROP COLUMN ACTOR_KIND_CD (코드 롤백이 선행되어야 한다).
-- 멱등: CREATE TABLE IF NOT EXISTS · 칸은 information_schema 확인 뒤에만 ADD · 갱신은 이미 operator 인 행을 건너뛴다.
--
-- ⚠ **API 재시작 전에** 적용한다 — 새 코드는 ACTOR_KIND_CD 를 읽고 새 표에 쓰므로, 없으면 편집 이력 조회가 500 이 된다.
--   LOUPIT 만 적용한다 (베타는 무시).
--
-- 적용 후 확인:
--   information_schema.COLUMNS 에서 TBENEFIT_EDIT_LOG.ACTOR_KIND_CD 1행, TBENEFIT_EDIT_REQUEST 표 1행이면 성공.
--   (⚠ 이 주석에 따옴표·세미콜론을 쓰지 않는다 — 테스트의 SQL 분할기가 주석 속 것도 센다)
-- ══════════════════════════════════════════════════════════════════════
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS TBENEFIT_EDIT_REQUEST (
  EDIT_REQUEST_ID  INT AUTO_INCREMENT PRIMARY KEY COMMENT '복지 등록·수정 확인 요청 PK',
  COMP_ID          INT          NOT NULL COMMENT '대상 회사 FK (TCOMPANY.COMP_ID, ON DELETE CASCADE)',
  MBR_ID           INT          NOT NULL COMMENT '요청 회원 FK (TMEMBER.MBR_ID, ON DELETE CASCADE. 단 탈퇴는 소프트 삭제(STATUS_CD)라 CASCADE 는 타지 않는다 — 승인 때 요청 회원이 활성인지 다시 본다)',
  REQ_TYPE_CD      VARCHAR(8)   NOT NULL COMMENT '요청 유형 (create, update) — 값집합 SP-DB-17.8',
  BENEFIT_ID       INT          DEFAULT NULL COMMENT 'update 대상 복지 FK (TCOMPANY_BENEFIT.BENEFIT_ID). ON DELETE SET NULL — 대상이 지워지면 승인 시 target_gone',
  BENEFIT_CD       VARCHAR(30)  DEFAULT NULL COMMENT 'update = 대상 코드 / create = 회원이 고른 표준 코드 (목록에 없음이면 NULL)',
  BENEFIT_NM       VARCHAR(100) NOT NULL COMMENT '회원이 적은 복지 이름 (사용자 입력 원문)',
  BENEFIT_AMT      INT          DEFAULT NULL COMMENT '회원이 적은 연간 금액 (만원). 정성이면 NULL',
  QUAL_YN          BOOLEAN      NOT NULL DEFAULT FALSE COMMENT '정성 여부',
  NOTE_CTNT        VARCHAR(200) DEFAULT NULL COMMENT '비고 (사용자 입력 원문)',
  EDIT_NOTE_CTNT   VARCHAR(500) DEFAULT NULL COMMENT '편집 사유 (사용자 입력 원문, 승인되면 공개 이력에 남는다)',
  BASE_TOKEN_VAL   VARCHAR(40)  DEFAULT NULL COMMENT 'update 제출 때 대상 행의 낙관적 동시성 토큰 (승인 때 현재 행과 다르면 stale)',
  BEFORE_VAL       JSON         DEFAULT NULL COMMENT 'update 제출 때 대상 행 스냅샷 (운영자가 전 → 후를 본다)',
  STATUS_CD        VARCHAR(12)  NOT NULL DEFAULT 'pending' COMMENT '처리 상태 (pending, approved, rejected) — 값집합 SP-DB-17.8',
  DECIDED_BY_ID    INT          DEFAULT NULL COMMENT '결정 운영자 ID (콘솔 세션에서 주입)',
  DECIDED_DTM      DATETIME     DEFAULT NULL COMMENT '결정 일시',
  DECIDE_NOTE_CTNT VARCHAR(500) DEFAULT NULL COMMENT '결정 사유 (거절이면 회원에게 보인다)',
  APPLIED_BENEFIT_CD VARCHAR(30) DEFAULT NULL COMMENT '승인 때 운영자가 고른 표준 코드 (create)',
  RESULT_BENEFIT_ID INT         DEFAULT NULL COMMENT '승인으로 생기거나 바뀐 복지 FK (TCOMPANY_BENEFIT.BENEFIT_ID). ON DELETE SET NULL',
  EDIT_LOG_ID      INT          DEFAULT NULL COMMENT '승인으로 생긴 편집 이력 FK (TBENEFIT_EDIT_LOG.EDIT_LOG_ID). ON DELETE SET NULL',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  INDEX idx_beneditreq_status (STATUS_CD, INS_DTM),
  INDEX idx_beneditreq_member (MBR_ID, COMP_ID, INS_DTM),
  FOREIGN KEY (COMP_ID)           REFERENCES TCOMPANY(COMP_ID)                    ON DELETE CASCADE,
  FOREIGN KEY (MBR_ID)            REFERENCES TMEMBER(MBR_ID)                      ON DELETE CASCADE,
  FOREIGN KEY (BENEFIT_ID)        REFERENCES TCOMPANY_BENEFIT(BENEFIT_ID)         ON DELETE SET NULL,
  FOREIGN KEY (RESULT_BENEFIT_ID) REFERENCES TCOMPANY_BENEFIT(BENEFIT_ID)         ON DELETE SET NULL,
  FOREIGN KEY (EDIT_LOG_ID)       REFERENCES TBENEFIT_EDIT_LOG(EDIT_LOG_ID)       ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='복지 등록·수정 확인 요청 큐 (회원 제출 → 운영자 콘솔 승인 뒤에만 TCOMPANY_BENEFIT 에 반영, 2026-10-21 사용자 결정)';

-- MySQL 은 ADD COLUMN IF NOT EXISTS 를 지원하지 않으므로 동적 SQL 로 멱등성을 만든다.
SET @db := DATABASE();

SET @sql := (
  SELECT IF(COUNT(*) = 0,
    'ALTER TABLE TBENEFIT_EDIT_LOG ADD COLUMN ACTOR_KIND_CD VARCHAR(8) NOT NULL DEFAULT ''member'' COMMENT ''편집 주체 구분 (member, operator) — 값집합 SP-DB-17.8. operator = 운영자 CLI 정정·삭제(ACTOR_MBR_ID NULL), 공개 이력에 운영자로 표시. member 인데 ACTOR_MBR_ID NULL = 탈퇴'' AFTER ACTOR_MBR_ID',
    'SELECT "skip: ACTOR_KIND_CD 이미 있음"')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'TBENEFIT_EDIT_LOG' AND COLUMN_NAME = 'ACTOR_KIND_CD');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE TBENEFIT_EDIT_LOG
   SET ACTOR_KIND_CD = 'operator'
 WHERE ACTOR_KIND_CD <> 'operator'
   AND ((ACTOR_MBR_ID IS NULL AND EDIT_NOTE_CTNT LIKE '운영자%') OR EDIT_TYPE_CD = 'delete');
