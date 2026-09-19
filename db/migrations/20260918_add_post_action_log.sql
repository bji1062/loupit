-- ══════════════════════════════════════════════════════════════════════
-- 커뮤니티 운영자 조치 이력 1테이블 추가 — TPOST_ACTION_LOG (2026-09-18)
-- 근거: docs/SPEC/13-참여-로그인.md SP-AUTH-19.7 · docs/SPEC/02-데이터베이스-스키마.md SP-DB-18.7
--
-- **정본은 `db/schema.sql` 이다.** 이 파일은 기존 서빙 DB(LOUPIT·loupit_beta)를 그 상태로 옮기기 위한
-- 것이며 두 파일의 DDL 은 바이트까지 같다(test_console_views_db CV-12 가 드리프트를 막는다).
--
-- 성격: **순수 추가** — 기존 테이블·데이터 무접촉. 되돌리기 = DROP TABLE TPOST_ACTION_LOG 한 줄.
-- 전제: TMEMBER(참여 테이블)가 있어야 한다 — FK 부모. M9 OFF 스키마에는 적용하지 마라.
-- 멱등: `CREATE TABLE IF NOT EXISTS` — 재실행 안전.
--
-- ⚠ **앱 재시작 전에** 적용한다 — 새 코드는 숨김·복구·신고 hide 때 이 표에 쓰므로, 표가 없으면 그 조치가
--   500 이 된다(되돌리기 트랜잭션이라 상태는 안 바뀐다). beta(loupit_beta)도 같은 코드를 돌리므로 함께.
--
-- 적용 후 확인:
--   information_schema.TABLES 에서 현재 스키마의 TPOST_ACTION_LOG 가 1행이면 성공.
--   (⚠ 이 주석에 따옴표·세미콜론을 쓰지 않는다 — 테스트의 SQL 분할기가 주석 속 것도 센다)
-- ══════════════════════════════════════════════════════════════════════
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS TPOST_ACTION_LOG (
  ACTION_LOG_ID        INT AUTO_INCREMENT PRIMARY KEY COMMENT '운영자 조치 이력 PK (추가 전용)',
  TARGET_TYPE_CD       VARCHAR(8)   NOT NULL COMMENT '대상 유형 (post, comment) — TPOST_REPORT 와 같은 값집합',
  TARGET_ID            INT          NOT NULL COMMENT '대상 ID (POST_ID 또는 COMMENT_ID — FK 아님: 두 테이블을 가리키고, 대상이 사라져도 이력은 남아야 한다)',
  ACTION_CD            VARCHAR(8)   NOT NULL COMMENT '조치 (hide, restore)',
  FROM_STATUS_CD       VARCHAR(12)  NOT NULL COMMENT '조치 전 대상 상태 (active, hidden)',
  TO_STATUS_CD         VARCHAR(12)  NOT NULL COMMENT '조치 후 대상 상태 (hidden, active)',
  SOURCE_CD            VARCHAR(8)   NOT NULL COMMENT '경로 (board: 콘솔 게시판 직접 조치, report: 신고 처리의 hide)',
  REPORT_ID            INT          DEFAULT NULL COMMENT '신고 처리 경유면 그 신고 ID (TPOST_REPORT.REPORT_ID — FK 아님, 이력 존치)',
  REPORTS_ACTIONED_CNT INT          NOT NULL DEFAULT 0 COMMENT '이 조치로 함께 닫힌 대기 신고 수 (접미 _CNT)',
  NOTE_CTNT            VARCHAR(500) DEFAULT NULL COMMENT '운영자 메모 (숨김·복구 모두 — 대상 행에는 메모 칸이 없다)',
  ACTOR_MBR_ID         INT          DEFAULT NULL COMMENT '조치한 운영자 FK (TMEMBER.MBR_ID, **세션에서 주입** — 본문으로 받지 않는다). ON DELETE SET NULL (이력 존치)',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '기록 일시 (불변 append-only — 감사 4종 미적용, MOD 없음)',
  INDEX idx_action_target (TARGET_TYPE_CD, TARGET_ID, ACTION_LOG_ID),
  INDEX idx_action_actor  (ACTOR_MBR_ID, INS_DTM),
  FOREIGN KEY (ACTOR_MBR_ID) REFERENCES TMEMBER(MBR_ID) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='커뮤니티 운영자 조치 이력 (숨김·복구 — 불변 append-only, 대상 행 MOD_ID 는 마지막 조작자만 남으므로 전체 이력은 여기)';
