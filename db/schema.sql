-- ══════════════════════════════════════════════════════════════════════
-- loupit 참조 데이터베이스 정본 DDL (SP-DB-2~10)
-- 대상 스키마: LOUPIT (MySQL 8.0, utf8mb4, lower_case_table_names=0)
-- 유지 참조 테이블 5종만 정의. 로그인/회원/프로파일러 등 16개 테이블은
-- 영구 제외(SP-DB-11) — 본 파일 어디에도 생성하지 않는다.
-- 재적용 안전(idempotent): 전 테이블 `CREATE TABLE IF NOT EXISTS`.
-- 생성 순서(FK 의존, SP-DB-8): TCOMPANY_TYPE → TCOMPANY →
--   (TCOMPANY_ALIAS, TCOMPANY_BENEFIT, TBENEFIT_PRESET)
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- ─────────────────────────────────────────────────────────────────────
-- TCOMPANY_TYPE — 기업유형 마스터 (SP-DB-2)
-- 6종({large,startup,mid,foreign,public,freelance}). 직접입력 유형 선택·정적 페이지 라벨용.
-- (브랜드 축 제거 2026-07-20 — 성장률·안정성 컬럼은 20260720 마이그레이션으로 드랍됨)
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS TCOMPANY_TYPE (
  COMP_TP_ID          INT AUTO_INCREMENT PRIMARY KEY COMMENT '기업유형 PK',
  COMP_TP_CD          VARCHAR(20)  NOT NULL UNIQUE
                      COMMENT '기업유형 코드 (large, startup, mid, foreign, public, freelance)',
  COMP_TP_NM          VARCHAR(20)  NOT NULL COMMENT '표시 라벨 (대기업, 스타트업, 중견기업, 외국계, 공기업, 프리랜서)',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='기업유형 6종 마스터 (비교 브랜드 축)';

-- ─────────────────────────────────────────────────────────────────────
-- TCOMPANY — 회사 마스터 (SP-DB-3)
-- 복지 데이터 보유 회사만 등록(~96개). COMP_ENG_NM·COMP_NM 각각 UNIQUE.
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS TCOMPANY (
  COMP_ID              INT AUTO_INCREMENT PRIMARY KEY COMMENT '회사 PK',
  COMP_ENG_NM          VARCHAR(30)  NOT NULL UNIQUE
                       COMMENT '회사 영문 식별명 (samsung_elec, cj 등 — URL/로고 매핑 키, 과거 id)',
  COMP_NM              VARCHAR(100) NOT NULL UNIQUE COMMENT '회사 정식 명칭 (삼성전자 등)',
  COMP_TP_ID           INT          NOT NULL COMMENT '기업유형 FK (TCOMPANY_TYPE.COMP_TP_ID)',
  INDUSTRY_NM          VARCHAR(50)  COMMENT '산업 분류 (전자/반도체, 핀테크 등)',
  LOGO_NM              VARCHAR(10)  COMMENT '로고 약어 (S, CJ, T 등)',
  WORK_STYLE_VAL       JSON         COMMENT '근무 형태 {remote, flex, unlimitedPTO, refreshLeave, overtime}',
  CAREERS_BENEFIT_URL  VARCHAR(500) COMMENT '공식 채용/복지 페이지 URL (출처 아웃링크)',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  FOREIGN KEY (COMP_TP_ID) REFERENCES TCOMPANY_TYPE(COMP_TP_ID),
  FULLTEXT INDEX idx_comp_nm (COMP_NM) WITH PARSER ngram
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='회사 마스터 (복지 데이터 보유 ~96개만 등록)';

-- ─────────────────────────────────────────────────────────────────────
-- TCOMPANY_ALIAS — 검색 별칭 (SP-DB-4)
-- 회사당 1건 이상. (COMP_ID, ALIAS_NM) UNIQUE. 회사 삭제 시 CASCADE.
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS TCOMPANY_ALIAS (
  ALIAS_ID  INT AUTO_INCREMENT PRIMARY KEY COMMENT '별칭 PK',
  COMP_ID   INT          NOT NULL COMMENT '회사 FK (TCOMPANY.COMP_ID)',
  ALIAS_NM  VARCHAR(100) NOT NULL COMMENT '검색용 별칭 (삼성, 삼성전자, samsung 등)',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  FOREIGN KEY (COMP_ID) REFERENCES TCOMPANY(COMP_ID) ON DELETE CASCADE,
  UNIQUE KEY uq_comp_alias (COMP_ID, ALIAS_NM),
  INDEX idx_alias_nm (ALIAS_NM)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='검색 별칭 (회사당 1건 이상)';

-- ─────────────────────────────────────────────────────────────────────
-- TCOMPANY_BENEFIT — 회사별 복지 (SP-DB-5, SP-DB-7 DEC-2)
-- 신규 컬럼 AMT_SOURCE_CD(금액 신뢰도, BADGE_CD와 독립축) 포함.
-- 제거 컬럼 VERIFIED_BY_ID(FK→TMEMBER, 회원 테이블 제거로 무효) 미정의(SP-DB-12).
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS TCOMPANY_BENEFIT (
  BENEFIT_ID          INT AUTO_INCREMENT PRIMARY KEY COMMENT '복지항목 PK',
  COMP_ID             INT          NOT NULL COMMENT '회사 FK (TCOMPANY.COMP_ID)',
  BENEFIT_CD          VARCHAR(30)  NOT NULL COMMENT '복지 코드 (meal, transport, welfare_point, health_check 등, 회사 내 유니크)',
  BENEFIT_NM          VARCHAR(100) NOT NULL COMMENT '복지 표시명 (식대, 통근버스 등)',
  BENEFIT_AMT         INT          DEFAULT NULL COMMENT '연간 환산 금액 (만원). 정성 항목은 NULL, 음수 불가',
  BENEFIT_CTGR_CD     VARCHAR(20)  NOT NULL
                      COMMENT '복지 카테고리 9종 (compensation, flexibility, work_env, time_off, health, family, growth, leisure, perks)',
  BADGE_CD            VARCHAR(10)  NOT NULL DEFAULT 'est'
                      COMMENT '출처 신뢰도 배지 — 복지 존재의 확실성 (official: 공식 확인, est: 추정, verified: 재직자 확인 — SC14 사용자 등록/수정 SP-AUTH-9)',
  AMT_SOURCE_CD       VARCHAR(10)  NOT NULL DEFAULT 'estimated'
                      COMMENT '금액 신뢰도 (stated: 공식 명시금액, estimated: 앵커 추정, none: 정성/금액없음) — DEC-2, BADGE_CD와 독립. 불확실성 밴드 근거. API JSON 필드명 amt_source',
  BADGE_SRC_CD        VARCHAR(20)  DEFAULT NULL
                      COMMENT '출처 유형 (scrape_official, scrape_fallback, ai_parse, manual, user_report)',
  BADGE_SRC_URL_CTNT  VARCHAR(500) DEFAULT NULL COMMENT '출처 URL (공식 페이지 등 근거 링크, 출처표기 의무 핵심)',
  VERIFIED_DTM        DATETIME     DEFAULT NULL COMMENT '마지막 출처 재확인 시점 (신선도 기준, 감사 DTM과 별개)',
  EXPIRES_DTM         DATETIME     DEFAULT NULL COMMENT '유효 만료 시점 (VERIFIED_DTM + 카테고리 TTL). 경과 시 만료 취급·밴드 확대',
  NOTE_CTNT           VARCHAR(200) COMMENT '비고/상세 설명 (예: 일 18,000원 x 240일 환산)',
  QUAL_YN             BOOLEAN      NOT NULL DEFAULT FALSE COMMENT '정성적 복지 여부 (TRUE: 금액 환산 불가 → BENEFIT_AMT NULL, AMT_SOURCE_CD none)',
  QUAL_DESC_CTNT      VARCHAR(500) COMMENT '정성적 복지 상세 텍스트 (짧은 발췌만, 원문 복제 금지)',
  SORT_ORDER_NO       SMALLINT     DEFAULT 0 COMMENT '표시 정렬 순서',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  FOREIGN KEY (COMP_ID) REFERENCES TCOMPANY(COMP_ID) ON DELETE CASCADE,
  UNIQUE KEY uq_comp_benefit (COMP_ID, BENEFIT_CD),
  INDEX idx_benefit_comp (COMP_ID, SORT_ORDER_NO)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='회사별 복지 (배지·출처·만료·금액신뢰도 메타 포함)';

-- ─────────────────────────────────────────────────────────────────────
-- TBENEFIT_PRESET — 기업유형별 기본복지 (SP-DB-6)
-- 역할 = 비교 툴 직접 입력 모드 템플릿(회사페이지 폴백 아님). AMT_SOURCE_CD·
-- 출처/만료 메타는 두지 않는다(프리셋은 실회사 관측이 아니므로 개념 없음).
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS TBENEFIT_PRESET (
  PRESET_ID           INT AUTO_INCREMENT PRIMARY KEY COMMENT '프리셋 PK',
  COMP_TP_ID          INT          NOT NULL COMMENT '기업유형 FK (TCOMPANY_TYPE.COMP_TP_ID)',
  BENEFIT_CD          VARCHAR(30)  NOT NULL COMMENT '복지 코드',
  BENEFIT_NM          VARCHAR(100) NOT NULL COMMENT '복지 표시명',
  BENEFIT_AMT         INT          DEFAULT NULL COMMENT '연간 환산 금액 (만원, 정성 항목은 NULL)',
  BENEFIT_CTGR_CD     VARCHAR(20)  NOT NULL
                      COMMENT '복지 카테고리 9종 (compensation, flexibility, work_env, time_off, health, family, growth, leisure, perks)',
  BADGE_CD            VARCHAR(10)  NOT NULL DEFAULT 'est' COMMENT '데이터 신뢰도 (프리셋은 통상 est: 공식 확인 아님, D3.10)',
  DEFAULT_CHECKED_YN  BOOLEAN      NOT NULL DEFAULT TRUE COMMENT '직접 입력 자동 채움 시 초기 체크 여부 (클라이언트 checked 초기값 소스)',
  SORT_ORDER_NO       SMALLINT     DEFAULT 0 COMMENT '표시 정렬 순서',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  FOREIGN KEY (COMP_TP_ID) REFERENCES TCOMPANY_TYPE(COMP_TP_ID),
  INDEX idx_preset_type (COMP_TP_ID, SORT_ORDER_NO)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='기업유형별 기본복지 (비교 툴 직접 입력 모드 템플릿)';

-- ─────────────────────────────────────────────────────────────────────
-- TCOMPARE_LOG — 익명 비교 실행 로그 (INV-1 개정 2026-07-14, "실시간 비교 TOP 10")
-- 저장은 회사쌍 comp_id + 시각뿐. 사용자 식별자·IP·세션·연봉 등 입력값 무저장 —
-- FR-07(사용자 데이터 서버 미전송)의 예외는 이 익명 쌍 카운트로 한정한다.
-- 소비: GET /comparisons/trending (최근 7일 쌍별 COUNT 상위 10).
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS TCOMPARE_LOG (
  CMP_LOG_ID  BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '로그 PK',
  A_COMP_ID   INT NOT NULL COMMENT '현재 직장(A) 회사 FK (TCOMPANY.COMP_ID)',
  B_COMP_ID   INT NOT NULL COMMENT '이직 후보(B) 회사 FK (TCOMPANY.COMP_ID)',
  INS_DTM     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '실행 일시 (집계 윈도우 기준)',
  FOREIGN KEY (A_COMP_ID) REFERENCES TCOMPANY(COMP_ID) ON DELETE CASCADE,
  FOREIGN KEY (B_COMP_ID) REFERENCES TCOMPANY(COMP_ID) ON DELETE CASCADE,
  INDEX idx_cmp_log_dtm (INS_DTM)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='익명 비교 실행 로그 (쌍+시각만 — 사용자 식별자·입력값 무저장)';

-- ============================================================================
-- SC14 참여(로그인·재직인증·복지편집) 7테이블 — SP-DB-17 정본 DDL (M9)
-- FK 부모→자식 생성순서: TMEMBER → TCOMPANY_EMAIL_DOMAIN → TSESSION → TAUTH_CODE →
--   TEMPLOY_VERIFICATION → TEMPLOY_VRF_REQUEST → TBENEFIT_EDIT_LOG.
-- 원문 토큰·코드·회사이메일 컬럼 부재(해시/HMAC만, T9·AU-4·NFR30). TMEMBER PII=이메일·닉네임 2종(AU-3).
-- ============================================================================

CREATE TABLE IF NOT EXISTS TMEMBER (
  MBR_ID          INT AUTO_INCREMENT PRIMARY KEY COMMENT '회원 PK',
  LOGIN_EMAIL_NM  VARCHAR(255) DEFAULT NULL COMMENT '로그인 이메일 (UNIQUE, 탈퇴 시 NULL 파기 — INV-8). PII 2종 중 1',
  NICKNAME_NM     VARCHAR(30)  NOT NULL COMMENT '공개 닉네임 (UNIQUE, 편집이력 표시용). PII 2종 중 2',
  STATUS_CD       VARCHAR(12)  NOT NULL DEFAULT 'active' COMMENT '회원 상태 (active, withdrawn) — ENUM 금지·값집합 SP-DB-17.8',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  UNIQUE KEY uq_member_email    (LOGIN_EMAIL_NM),
  UNIQUE KEY uq_member_nickname (NICKNAME_NM)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='회원 (무비밀번호·PII=이메일·닉네임 2종뿐, T9·AU-3)';

CREATE TABLE IF NOT EXISTS TCOMPANY_EMAIL_DOMAIN (
  DOMAIN_ID       INT AUTO_INCREMENT PRIMARY KEY COMMENT '도메인 PK',
  COMP_ID         INT          NOT NULL COMMENT '회사 FK (TCOMPANY.COMP_ID)',
  EMAIL_DOMAIN_NM VARCHAR(255) NOT NULL COMMENT '회사 이메일 도메인 (예: samsung.com, 소문자 정규화)',
  ACTIVE_YN       BOOLEAN      NOT NULL DEFAULT TRUE COMMENT '활성 여부 (FALSE면 도메인 인증 비활성 → 수동 승인 폴백)',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  UNIQUE KEY uq_company_domain (COMP_ID, EMAIL_DOMAIN_NM),  -- (회사,도메인) 쌍 유일. 그룹 공용 도메인(samsung.com·sk.com)을 계열사 다수에 매핑 허용(DG-5 그룹단위 인증 결정 2026-07-23)
  INDEX idx_domain_company (COMP_ID),
  FOREIGN KEY (COMP_ID) REFERENCES TCOMPANY(COMP_ID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='회사↔이메일 도메인 화이트리스트 (도메인 인증 근거). 한 도메인이 계열사 여러 회사에 매핑 가능(그룹 공용)';

CREATE TABLE IF NOT EXISTS TSESSION (
  SESSION_ID      INT AUTO_INCREMENT PRIMARY KEY COMMENT '세션 PK',
  MBR_ID          INT          NOT NULL COMMENT '회원 FK (TMEMBER.MBR_ID)',
  TOKEN_HASH_VAL  CHAR(64)     NOT NULL COMMENT '세션 토큰 SHA-256 해시 (원문 무저장·쿠키 전용, T9). UNIQUE 조회키',
  EXPIRES_DTM     DATETIME     NOT NULL COMMENT '만료 일시 (INS + session_ttl_days)',
  REVOKED_DTM     DATETIME     DEFAULT NULL COMMENT '폐기 일시 (로그아웃·강제만료 시 세팅, FR-104)',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  UNIQUE KEY uq_session_token (TOKEN_HASH_VAL),
  INDEX idx_session_member (MBR_ID),
  FOREIGN KEY (MBR_ID) REFERENCES TMEMBER(MBR_ID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='세션 (SHA-256 해시만·원문 토큰 컬럼 부재, T9·AU-4)';

CREATE TABLE IF NOT EXISTS TAUTH_CODE (
  AUTH_CODE_ID    INT AUTO_INCREMENT PRIMARY KEY COMMENT '인증 코드 PK',
  PURPOSE_CD      VARCHAR(16)  NOT NULL COMMENT '용도 (login, employ_verify) — 값집합 SP-DB-17.8',
  CODE_HASH_VAL   CHAR(64)     NOT NULL COMMENT '6자리 코드 SHA-256 해시 (원문 무저장, T9)',
  TARGET_HASH_VAL CHAR(64)     NOT NULL COMMENT '대상 이메일/회사이메일 SHA-256 해시 (조회키, 원문 무저장, T9)',
  COMP_ID         INT          DEFAULT NULL COMMENT '재직 인증 대상 회사 FK (TCOMPANY.COMP_ID, login 시 NULL)',
  MBR_ID          INT          DEFAULT NULL COMMENT '요청 회원 FK (TMEMBER.MBR_ID, 신규 로그인 시 NULL)',
  ATTEMPT_CNT     SMALLINT     NOT NULL DEFAULT 0 COMMENT '검증 시도 횟수 (code_max_attempts 초과 시 무효, 접미 _CNT 비준)',
  EXPIRES_DTM     DATETIME     NOT NULL COMMENT '코드 만료 일시 (INS + login_code_ttl_min)',
  CONSUMED_DTM    DATETIME     DEFAULT NULL COMMENT '소비 일시 (성공 검증 시 세팅, 재사용 차단)',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  INDEX idx_authcode_target (TARGET_HASH_VAL, PURPOSE_CD),
  FOREIGN KEY (COMP_ID) REFERENCES TCOMPANY(COMP_ID) ON DELETE CASCADE,
  FOREIGN KEY (MBR_ID)  REFERENCES TMEMBER(MBR_ID)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='로그인·재직 인증 코드 (코드·이메일 해시만, T9·AU-4)';

CREATE TABLE IF NOT EXISTS TEMPLOY_VERIFICATION (
  EMPLOY_VRF_ID       INT AUTO_INCREMENT PRIMARY KEY COMMENT '재직 인증 PK',
  MBR_ID              INT          NOT NULL COMMENT '회원 FK (TMEMBER.MBR_ID)',
  COMP_ID             INT          DEFAULT NULL COMMENT '인증된 회사 FK (TCOMPANY.COMP_ID). ON DELETE SET NULL (IDOR·회사삭제 방어)',
  VRF_METHOD_CD       VARCHAR(12)  NOT NULL COMMENT '인증 방식 (domain, manual) — 값집합 SP-DB-17.8',
  COMP_EMAIL_HASH_VAL CHAR(64)     NOT NULL COMMENT '회사 이메일 HMAC-SHA256 (원문 무저장·검증 직후 파기, T9·NFR30). UNIQUE=한 회사이메일 1계정',
  EXPIRES_DTM         DATETIME     DEFAULT NULL COMMENT '재직 인증 만료 (employ_vrf_ttl_days, NULL=무기한)',
  REVOKED_DTM         DATETIME     DEFAULT NULL COMMENT '폐기 일시 (탈퇴·재검증 실패 시)',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  UNIQUE KEY uq_employ_email (COMP_EMAIL_HASH_VAL),
  INDEX idx_employ_member (MBR_ID),
  FOREIGN KEY (MBR_ID)  REFERENCES TMEMBER(MBR_ID)  ON DELETE CASCADE,
  FOREIGN KEY (COMP_ID) REFERENCES TCOMPANY(COMP_ID) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='재직 인증 (회사 이메일 HMAC만·원문 컬럼 부재, T9·AU-4·NFR30)';

CREATE TABLE IF NOT EXISTS TEMPLOY_VRF_REQUEST (
  VRF_REQUEST_ID  INT AUTO_INCREMENT PRIMARY KEY COMMENT '수동 승인 요청 PK',
  MBR_ID          INT          NOT NULL COMMENT '요청 회원 FK (TMEMBER.MBR_ID)',
  COMP_ID         INT          NOT NULL COMMENT '요청 대상 회사 FK (TCOMPANY.COMP_ID)',
  STATUS_CD       VARCHAR(12)  NOT NULL DEFAULT 'pending' COMMENT '처리 상태 (pending, approved, rejected) — 값집합 SP-DB-17.8',
  EVIDENCE_CTNT   VARCHAR(1000) DEFAULT NULL COMMENT '재직 증빙 서술 (이스케이프 저장, 원문 복제 금지, NFR21)',
  DECIDED_BY_ID   INT          DEFAULT NULL COMMENT '결정 운영자 ID (CLI)',
  DECIDED_DTM     DATETIME     DEFAULT NULL COMMENT '결정 일시',
  DECIDE_NOTE_CTNT VARCHAR(500) DEFAULT NULL COMMENT '결정 사유·비고',
  INS_ID  INT COMMENT '입력자 ID',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '입력 일시',
  MOD_ID  INT COMMENT '수정자 ID',
  MOD_DTM TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
  INDEX idx_vrfreq_status (STATUS_CD, INS_DTM),
  FOREIGN KEY (MBR_ID)  REFERENCES TMEMBER(MBR_ID)  ON DELETE CASCADE,
  FOREIGN KEY (COMP_ID) REFERENCES TCOMPANY(COMP_ID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='재직 수동 승인 큐 (도메인 미등록 회사 폴백, 운영자 CLI 처리)';

CREATE TABLE IF NOT EXISTS TBENEFIT_EDIT_LOG (
  EDIT_LOG_ID     INT AUTO_INCREMENT PRIMARY KEY COMMENT '편집 이력 PK',
  BENEFIT_ID      INT          DEFAULT NULL COMMENT '대상 복지 FK (TCOMPANY_BENEFIT.BENEFIT_ID). ON DELETE SET NULL — 복지 하드 삭제(운영자 CLI) 후에도 편집 이력 존치(COMP_ID로 조회, ACTOR_MBR_ID SET NULL 과 동일 보존 규약)',
  COMP_ID         INT          NOT NULL COMMENT '대상 회사 FK (TCOMPANY.COMP_ID, 조회 인덱스용 비정규화)',
  ACTOR_MBR_ID    INT          DEFAULT NULL COMMENT '편집 회원 FK (TMEMBER.MBR_ID). ON DELETE SET NULL (탈퇴 후 이력 존치·닉네임 조인 표시)',
  EDIT_TYPE_CD    VARCHAR(8)   NOT NULL COMMENT '편집 유형 (create, update, delete) — 값집합 SP-DB-17.8',
  BEFORE_VAL      JSON         DEFAULT NULL COMMENT '변경 전 스냅샷 (create 시 NULL)',
  AFTER_VAL       JSON         DEFAULT NULL COMMENT '변경 후 스냅샷 (delete 시 NULL)',
  EDIT_NOTE_CTNT  VARCHAR(500) DEFAULT NULL COMMENT '편집 사유·출처 (기여자 입력, 이스케이프)',
  INS_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '기록 일시 (불변 append-only — 감사 4종 미적용, MOD 없음)',
  INDEX idx_editlog_comp  (COMP_ID, INS_DTM),
  INDEX idx_editlog_actor (ACTOR_MBR_ID, INS_DTM),
  FOREIGN KEY (BENEFIT_ID)   REFERENCES TCOMPANY_BENEFIT(BENEFIT_ID) ON DELETE SET NULL,
  FOREIGN KEY (ACTOR_MBR_ID) REFERENCES TMEMBER(MBR_ID)              ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='복지 편집 이력 (불변 append-only, 나무위키식 공개 — 누가·언제·before→after)';
