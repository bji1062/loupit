-- ══════════════════════════════════════════════════════════════════════
-- 초기 등록 9개사 공식 출처 재수집 반영 — 새 시드에서 빠진 행 표적 삭제 25 · 코드 바꾸기 10
-- 사용자 결정: 2026-09-26 (9개 회사 재수집 진행) · 선례: db/migrations/20260925_official_amount_corrections.sql
--
-- 배경:
--   2026-04 초기에 근거 URL 없이 등록된 9개사(SK텔레콤 · SK이노베이션 · SK하이닉스 · LIG넥스원 · NAVER ·
--   카카오페이 · 현대자동차 · S-Oil · 롯데케미칼)를 공식 1차 출처에서 다시 수집했다.
--   수집(Opus ×9) → 적대 검증(Fable ×5, 246행 중 반박 0) → 코퍼스 횡단 감사(Opus) → 통합.
--   정본 = /home/ubuntu/loupit-evidence/2026-09-26-recollect/ — 이 파일의 입력은 감사 audit/integration-audit.md §6 이다.
--   새 시드 9파일은 같은 PR 에서 바뀐다. 멱등 적재(load.py)는 시드에서 빠진 행을 지우지 않고,
--   코드가 바뀐 행은 새 코드로 새 행을 만든다 — 그래서 적재 전에 이 파일이 옛 행을 정리한다.
--
-- 무엇을 바꾸나 (운영 207행 → 이 파일 뒤 182행 → 적재 뒤 259행 · 전체 2451 → 2426 → 2503):
--   (a) 삭제 25행 — 운영에 있는데 새 시드에 없는 행: 공식 원문에 근거 없음 · 사내 교육(수집 규칙 8) ·
--       인사제도 · 성과급을 이익공유로 바꿔 새로 넣는 SK이노베이션 incentive.
--   (b) 코드 바꾸기 10행 — 같은 제도라 행 번호를 잇는다. 코드만 바꾸고 명칭 · 금액 · 카테고리 · 설명 · 순서는
--       이어지는 적재가 새 시드 값으로 덮는다. 새 코드는 10개 모두 그 회사 운영 행에 없다(uq 충돌 0).
--   9사에는 재직자 편집 이력이 없다(2026-09-26 운영 조회 0건). 편집 이력 FK 는 ON DELETE SET NULL 이다.
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다(재직자 행 규약 SP-SEED-12).
-- 멱등: 두 번째 실행은 전부 0행이다 — 지운 행은 없고, 바꾼 행은 지금 코드가 달라졌다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--   적재를 먼저 돌리면 새 코드 행이 먼저 생겨 (b) 가 uq_comp_benefit 중복 키로 실패한다.
--   한 트랜잭션이라 그때는 아무것도 바뀌지 않는다. 이미 적재했다면 (b) 대신 구 코드 행 10개를 지우면 결과가 같다.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   1) 백업
--      cd /home/ubuntu/loupit && set -a && . server/.env && set +a && MYSQL_PWD=$DB_PASSWORD /data/mysql/bin/mysqldump -h $DB_HOST -P $DB_PORT -u $DB_USER --no-tablespaces --single-transaction --default-character-set=utf8mb4 $DB_NAME TCOMPANY TCOMPANY_BENEFIT > /root/loupit-pre-recollect-9-$(date +%Y%m%d%H%M%S).sql
--   2) 적용
--      cd /home/ubuntu/loupit && set -a && . server/.env && set +a && MYSQL_PWD=$DB_PASSWORD /data/mysql/bin/mysql -vv -h $DB_HOST -P $DB_PORT -u $DB_USER $DB_NAME < db/migrations/20260926_recollect_9_official.sql
--   3) 적재
--      cd /home/ubuntu/loupit && python3 db/seed/load.py   (접속 정보는 load.py 가 server/.env 에서 직접 읽는다 · --fresh 금지)
--   4) 릴리스
--      cd /home/ubuntu/loupit && RELEASE_CONFIRM=1 bash infra/deploy/release.sh
-- 기대: DELETE 25문 각각 1 row affected · UPDATE 10문 각각 Rows matched 1 Changed 1. 두 번째 실행은 전부 0.
--   다르면 멈추고 확인하라.
-- 사후 확인(리드): 9사를 떠서 python3 audit/_audit.py check-db <tsv> 불일치 0 · 총 2503행.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- (a) 삭제 25행 — 운영에 있는데 새 시드에 없는 행

-- SK텔레콤
-- 소모임 지원 · 원문 0건(구본에서 뺀 행)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 290 AND c.COMP_ENG_NM = 'skt' AND b.BENEFIT_CD = 'club' AND b.BADGE_CD = 'official';
-- 직무교육 프로그램 · 규칙 8
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 286 AND c.COMP_ENG_NM = 'skt' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- 체력단련 휴가 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 276 AND c.COMP_ENG_NM = 'skt' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';

-- SK이노베이션
-- 사내 도서관 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 261 AND c.COMP_ENG_NM = 'sk_innovation' AND b.BENEFIT_CD = 'books' AND b.BADGE_CD = 'official';
-- 통근버스 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 266 AND c.COMP_ENG_NM = 'sk_innovation' AND b.BENEFIT_CD = 'commute_subsidy' AND b.BADGE_CD = 'official';
-- 역량개발 교육 · 규칙 8
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 260 AND c.COMP_ENG_NM = 'sk_innovation' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- 성과급 · L3 — profit_sharing 신규로 대체(재코딩 아님, §5-2)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 244 AND c.COMP_ENG_NM = 'sk_innovation' AND b.BENEFIT_CD = 'incentive' AND b.BADGE_CD = 'official';
-- 주차장 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 250 AND c.COMP_ENG_NM = 'sk_innovation' AND b.BENEFIT_CD = 'parking' AND b.BADGE_CD = 'official';
-- 간식/음료 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 268 AND c.COMP_ENG_NM = 'sk_innovation' AND b.BENEFIT_CD = 'snack_bar' AND b.BADGE_CD = 'official';
-- 야간 교통비 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 267 AND c.COMP_ENG_NM = 'sk_innovation' AND b.BENEFIT_CD = 'transport' AND b.BADGE_CD = 'official';
-- 업무장비 지원 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 247 AND c.COMP_ENG_NM = 'sk_innovation' AND b.BENEFIT_CD = 'work_tools' AND b.BADGE_CD = 'official';

-- SK하이닉스
-- 사내 부속의원 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 305 AND c.COMP_ENG_NM = 'sk_hynix' AND b.BENEFIT_CD = 'clinic' AND b.BADGE_CD = 'official';
-- 사내 동아리 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 314 AND c.COMP_ENG_NM = 'sk_hynix' AND b.BENEFIT_CD = 'club' AND b.BADGE_CD = 'official';
-- 경조사 지원 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 310 AND c.COMP_ENG_NM = 'sk_hynix' AND b.BENEFIT_CD = 'event' AND b.BADGE_CD = 'official';
-- 사내 문화시설 · 원문 0건(시설 나열)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 315 AND c.COMP_ENG_NM = 'sk_hynix' AND b.BENEFIT_CD = 'library' AND b.BADGE_CD = 'official';
-- 사내 편의시설 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 301 AND c.COMP_ENG_NM = 'sk_hynix' AND b.BENEFIT_CD = 'lounge' AND b.BADGE_CD = 'official';
-- 카페테리아 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 320 AND c.COMP_ENG_NM = 'sk_hynix' AND b.BENEFIT_CD = 'snack_bar' AND b.BADGE_CD = 'official';

-- 카카오페이
-- 경조사/생일 지원 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 902 AND c.COMP_ENG_NM = 'kakao_pay' AND b.BENEFIT_CD = 'event' AND b.BADGE_CD = 'official';
-- 주차비 지원 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 913 AND c.COMP_ENG_NM = 'kakao_pay' AND b.BENEFIT_CD = 'parking' AND b.BADGE_CD = 'official';
-- 전사 전면 재택 · 원문 0건(「원격근무」는 그리팅 UI 문자열)
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 895 AND c.COMP_ENG_NM = 'kakao_pay' AND b.BENEFIT_CD = 'remote_work' AND b.BADGE_CD = 'official';
-- 스톡옵션 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 892 AND c.COMP_ENG_NM = 'kakao_pay' AND b.BENEFIT_CD = 'stock_option' AND b.BADGE_CD = 'official';

-- S-Oil
-- Job Rotation/Posting · Job Posting = HTML 주석 속 유령 · Job Rotation = 인사제도
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 238 AND c.COMP_ENG_NM = 's_oil' AND b.BENEFIT_CD = 'career' AND b.BADGE_CD = 'official';
-- 직무교육 · 규칙 8
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 235 AND c.COMP_ENG_NM = 's_oil' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';
-- 패밀리데이 · 원문 0건
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 226 AND c.COMP_ENG_NM = 's_oil' AND b.BENEFIT_CD = 'family_day' AND b.BADGE_CD = 'official';
-- 어학교육 · 규칙 8
DELETE b FROM TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
 WHERE b.BENEFIT_ID = 237 AND c.COMP_ENG_NM = 's_oil' AND b.BENEFIT_CD = 'lang' AND b.BADGE_CD = 'official';

-- (b) 코드 바꾸기 10행 — 같은 제도라 행 번호를 잇는다(코드만 바꾸고 나머지는 적재가 덮는다)

-- SK텔레콤
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'sports_ticket'
 WHERE b.BENEFIT_ID = 296 AND c.COMP_ENG_NM = 'skt' AND b.BENEFIT_CD = 'discount' AND b.BADGE_CD = 'official';

-- SK하이닉스
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'mba'
 WHERE b.BENEFIT_ID = 311 AND c.COMP_ENG_NM = 'sk_hynix' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';

-- LIG넥스원
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'leave_general'
 WHERE b.BENEFIT_ID = 163 AND c.COMP_ENG_NM = 'lig_nex1' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';

-- NAVER
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'stock_option'
 WHERE b.BENEFIT_ID = 191 AND c.COMP_ENG_NM = 'naver' AND b.BENEFIT_CD = 'profit_sharing' AND b.BADGE_CD = 'official';
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'insurance'
 WHERE b.BENEFIT_ID = 197 AND c.COMP_ENG_NM = 'naver' AND b.BENEFIT_CD = 'medical' AND b.BADGE_CD = 'official';
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'leisure_ticket'
 WHERE b.BENEFIT_ID = 209 AND c.COMP_ENG_NM = 'naver' AND b.BENEFIT_CD = 'discount' AND b.BADGE_CD = 'official';

-- 카카오페이
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'car_rental'
 WHERE b.BENEFIT_ID = 912 AND c.COMP_ENG_NM = 'kakao_pay' AND b.BENEFIT_CD = 'work_tools' AND b.BADGE_CD = 'official';

-- S-Oil
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'housing_support'
 WHERE b.BENEFIT_ID = 227 AND c.COMP_ENG_NM = 's_oil' AND b.BENEFIT_CD = 'dormitory' AND b.BADGE_CD = 'official';

-- 롯데케미칼
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'leave_general'
 WHERE b.BENEFIT_ID = 462 AND c.COMP_ENG_NM = 'lotte_chem' AND b.BENEFIT_CD = 'refresh_leave' AND b.BADGE_CD = 'official';
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'self_development'
 WHERE b.BENEFIT_ID = 472 AND c.COMP_ENG_NM = 'lotte_chem' AND b.BENEFIT_CD = 'edu_support' AND b.BADGE_CD = 'official';

COMMIT;
