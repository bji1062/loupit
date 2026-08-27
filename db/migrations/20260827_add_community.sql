-- ══════════════════════════════════════════════════════════════════════
-- 커뮤니티(SC15) 4테이블 추가 — TPOST · TPOST_COMMENT · TPOST_REACTION · TPOST_REPORT
-- 근거: docs/SPEC/02-데이터베이스-스키마.md SP-DB-18 · docs/SPEC/14-커뮤니티.md SP-COMM-3 ·
--       docs/PLAN-커뮤니티-회사정보탭-2026-08-27.md §3-2
--
-- **정본은 `db/schema.sql` 이다.** 이 파일은 기존 서빙 DB 를 그 상태로 옮기기 위한 것이며,
-- 신규 프로비저닝은 schema.sql 이 처리한다. 두 파일이 갈라지면 schema.sql 을 따른다
-- (test_community_schema CM-2.6b 가 드리프트를 막는다).
--
-- 성격: **순수 추가**다. 기존 테이블·컬럼·데이터를 하나도 건드리지 않는다 — 되돌리려면
--       DROP TABLE 4줄(자식→부모: TPOST_REPORT, TPOST_REACTION, TPOST_COMMENT, TPOST)이면 된다.
--
-- 전제: 참여 7테이블(SP-DB-17, TMEMBER·TCOMPANY)이 이미 있어야 한다 — FK 부모다.
--       M9 OFF 스키마(참여 테이블 부재)에는 적용하지 마라(FK 생성이 실패한다).
--
-- 멱등: 전부 `CREATE TABLE IF NOT EXISTS` — 재실행 안전(CM-2.12 가 2회 적용을 실증한다).
--
-- 적용 후 확인:
--   SELECT TABLE_NAME FROM information_schema.TABLES
--    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ('TPOST','TPOST_COMMENT','TPOST_REACTION','TPOST_REPORT');
--   → 4행이면 성공.
--
-- ⚠ 적용 전 백업 권장(순수 추가라 위험은 낮지만 습관을 깨지 않는다):
--      sudo systemctl start loupit-backup.service
-- ══════════════════════════════════════════════════════════════════════
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS TPOST (
  POST_ID      INT AUTO_INCREMENT PRIMARY KEY COMMENT '게시글 PK (목록 키셋 커서 `?before=<post_id>`)',
  MBR_ID       INT          DEFAULT NULL COMMENT '작성 회원 FK (TMEMBER.MBR_ID). ON DELETE SET NULL — 탈퇴 후 글 존치·닉네임 조인 표시(NULL 이면 "탈퇴한 회원")',
  CATEGORY_CD  VARCHAR(12)  NOT NULL COMMENT '카테고리 (notice, free, career, suggestion) — 값집합 SP-DB-18.5. notice 는 운영자(OPERATOR_EMAILS)만 작성(앱 강제, FR-124)',
  TITLE_NM     VARCHAR(100) NOT NULL COMMENT '제목 (사용자 입력 원문 — 저장은 바인딩, 표시 이스케이프는 클라이언트 textContent, NFR21). 소프트 삭제 시 "(삭제됨)" 마스킹',
  BODY_CTNT    TEXT         NOT NULL COMMENT '본문 (앱 상한 5,000자 — 줄바꿈만, 마크다운·HTML 없음). 소프트 삭제 시 빈 문자열 마스킹(원문 보존 안 함)',
  COMP_ID      INT          DEFAULT NULL COMMENT '회사 태그 FK (TCOMPANY.COMP_ID, 선택 — "이 회사 이야기"). ON DELETE SET NULL',
  LIKE_CNT     INT          NOT NULL DEFAULT 0 COMMENT '좋아요 수 (비정규화 카운터 — TPOST_REACTION 삽입·삭제와 같은 트랜잭션에서 ±1)',
  COMMENT_CNT  INT          NOT NULL DEFAULT 0 COMMENT '댓글 수 (비정규화 카운터 — 활성 댓글만. 댓글 소프트 삭제 시 -1, 운영자 hidden 은 불변)',
  STATUS_CD    VARCHAR(12)  NOT NULL DEFAULT 'active' COMMENT '상태 (active, deleted, hidden) — 값집합 SP-DB-18.5. deleted=본인 소프트 삭제, hidden=운영자 신고 조치. 둘 다 상세 404',
  EDITED_YN    BOOLEAN      NOT NULL DEFAULT FALSE COMMENT '수정 여부 (본인 PUT 시 TRUE — "수정됨" 표시, FR-125)',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시 (일일 상한 카운트 기준 — INS_DTM >= UTC_DATE())',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  -- 목록 3종 정렬의 키셋 커서 인덱스 — 전부 STATUS_CD 선행(active 만 읽는다) + POST_ID 후행(커서).
  INDEX idx_post_cat_cursor  (STATUS_CD, CATEGORY_CD, POST_ID),
  INDEX idx_post_like_cursor (STATUS_CD, LIKE_CNT, POST_ID),
  INDEX idx_post_cmt_cursor  (STATUS_CD, COMMENT_CNT, POST_ID),
  INDEX idx_post_comp        (COMP_ID, POST_ID),
  FOREIGN KEY (MBR_ID)  REFERENCES TMEMBER(MBR_ID)   ON DELETE SET NULL,
  FOREIGN KEY (COMP_ID) REFERENCES TCOMPANY(COMP_ID) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='커뮤니티 게시글 (조회수 컬럼 없음 — 봇이 실사용의 수백 배라 거짓 숫자가 된다. 소프트 삭제)';

CREATE TABLE IF NOT EXISTS TPOST_COMMENT (
  COMMENT_ID   INT AUTO_INCREMENT PRIMARY KEY COMMENT '댓글 PK (댓글 목록 커서 `?after=<comment_id>` — 댓글은 아래로 자란다)',
  POST_ID      INT           NOT NULL COMMENT '글 FK (TPOST.POST_ID). ON DELETE CASCADE — 글이 물리적으로 사라지면 댓글도',
  MBR_ID       INT           DEFAULT NULL COMMENT '작성 회원 FK (TMEMBER.MBR_ID). ON DELETE SET NULL (탈퇴 후 존치)',
  BODY_CTNT    VARCHAR(1000) NOT NULL COMMENT '댓글 본문 (사용자 입력 원문, 표시 이스케이프는 클라이언트). 소프트 삭제 시 빈 문자열',
  STATUS_CD    VARCHAR(12)   NOT NULL DEFAULT 'active' COMMENT '상태 (active, deleted, hidden) — 비활성은 목록에서 body:null 자리만',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시 (일일 상한 카운트 기준)',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  INDEX idx_comment_post_cursor (POST_ID, COMMENT_ID),
  FOREIGN KEY (POST_ID) REFERENCES TPOST(POST_ID)   ON DELETE CASCADE,
  FOREIGN KEY (MBR_ID)  REFERENCES TMEMBER(MBR_ID)  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='커뮤니티 댓글 (대댓글 없음 — 1차 범위. 소프트 삭제)';

CREATE TABLE IF NOT EXISTS TPOST_REACTION (
  REACTION_ID  INT AUTO_INCREMENT PRIMARY KEY COMMENT '반응 PK',
  POST_ID      INT          NOT NULL COMMENT '글 FK (TPOST.POST_ID). ON DELETE CASCADE',
  MBR_ID       INT          NOT NULL COMMENT '회원 FK (TMEMBER.MBR_ID). ON DELETE CASCADE — SET NULL 이면 UNIQUE(POST_ID, MBR_ID) 가 무력화된다',
  REACTION_CD  VARCHAR(8)   NOT NULL DEFAULT 'like' COMMENT '반응 종류 (like) — 값집합 SP-DB-18.5. 싫어요는 1차 범위 밖',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  UNIQUE KEY uq_reaction_post_member (POST_ID, MBR_ID),  -- 회원당 1회. 토글은 INSERT/DELETE + LIKE_CNT ±1 을 한 트랜잭션으로(SP-COMM-5)
  FOREIGN KEY (POST_ID) REFERENCES TPOST(POST_ID)  ON DELETE CASCADE,
  FOREIGN KEY (MBR_ID)  REFERENCES TMEMBER(MBR_ID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='커뮤니티 좋아요 (회원당 글 1회 — UNIQUE 가 LIKE_CNT 정합의 근거)';

CREATE TABLE IF NOT EXISTS TPOST_REPORT (
  REPORT_ID        INT AUTO_INCREMENT PRIMARY KEY COMMENT '신고 PK',
  TARGET_TYPE_CD   VARCHAR(8)   NOT NULL COMMENT '대상 유형 (post, comment) — 값집합 SP-DB-18.5',
  -- ⚠ TARGET_ID 는 **FK 가 아니다** — 두 테이블(TPOST·TPOST_COMMENT)을 가리키므로 하나에 묶을 수 없다.
  --   대상 존재·활성 확인은 접수 시 앱이 한다(404). 대상이 뒤에 사라져도 신고 행은 남는다(감사).
  TARGET_ID        INT          NOT NULL COMMENT '대상 ID (POST_ID 또는 COMMENT_ID — FK 아님, 유형과 함께 해석)',
  MBR_ID           INT          DEFAULT NULL COMMENT '신고 회원 FK (TMEMBER.MBR_ID). ON DELETE SET NULL',
  REASON_CD        VARCHAR(12)  NOT NULL COMMENT '신고 사유 (spam, abuse, privacy, other) — 값집합 SP-DB-18.5',
  DETAIL_CTNT      VARCHAR(300) DEFAULT NULL COMMENT '상세 (사용자 입력 원문, 선택 — 콘솔은 textContent 로만 표시)',
  STATUS_CD        VARCHAR(12)  NOT NULL DEFAULT 'pending' COMMENT '처리 상태 (pending, actioned, dismissed) — 같은 대상의 pending 은 hide 시 일괄 actioned',
  DECIDED_BY_ID    INT          DEFAULT NULL COMMENT '결정 운영자 ID (콘솔 세션에서 자동 주입 — 본문으로 받지 않는다, SP-AUTH-19)',
  DECIDED_DTM      DATETIME     DEFAULT NULL COMMENT '결정 일시',
  DECIDE_NOTE_CTNT VARCHAR(500) DEFAULT NULL COMMENT '결정 사유·비고',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시 (일일 상한 카운트 기준)',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  UNIQUE KEY uq_report_target_member (TARGET_TYPE_CD, TARGET_ID, MBR_ID),  -- 같은 (회원, 대상) 중복 신고 차단 → 409
  INDEX idx_report_status (STATUS_CD, REPORT_ID),
  FOREIGN KEY (MBR_ID) REFERENCES TMEMBER(MBR_ID) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='게시물 신고 큐 (대상은 글·댓글 두 테이블 — TARGET_ID 는 FK 아님. 운영자 hide/dismiss)';

