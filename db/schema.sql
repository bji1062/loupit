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
                      COMMENT '출처 신뢰도 배지 — 복지 존재의 확실성 (official: 공식 확인, est: 추정)',
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
