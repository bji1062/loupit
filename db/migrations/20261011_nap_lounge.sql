-- ══════════════════════════════════════════════════════════════════════
-- 수면실 · 휴게실 경계 정리 반영 — 코드 바꾸기 7 (nap_room → lounge, 2026-10-11)
-- 사용자 지시: 2026-10-11 「카카오게임즈 수면실도 정리하자」 → 「휴게실 칸으로」
-- 선례: db/migrations/20261010_corpus_fix4.sql
--
-- 배경: 수면실 · 안마의자 · 리클라이너 · 명상실처럼 쉬는 공간은 전부 lounge 로 모으고 nap_room 은 수유 · 모성 · 임산부 공간 전용으로 한다.
--   운영 행은 전부 BADGE_CD = official 이라 upsert(UNIQUE (COMP_ID, BENEFIT_CD))로는 코드 바꾸기가 반영되지 않는다.
--   정본 = /home/ubuntu/loupit-evidence/2026-10-11-nap-lounge/_ACTIONS.md
-- 운영 DB SELECT 확인(2026-10-11): 아래 7행은 각각 정확히 1행 · 전부 BADGE_CD = official · 카테고리 work_env ·
--   재직자 행 없음 · TBENEFIT_EDIT_LOG 는 전체 2행(BENEFIT_ID 971 · 1400)이고 이 7행에 걸린 것이 0 (971 은 크래프톤 resort 행이라 959 와 무관).
--   UNIQUE 충돌 없음: 7사(루닛 · 삼성E&A · 주성엔지니어링 · 텔레칩스 · 위메이드 · 카카오페이 · 크래프톤)에 lounge 행이 아직 없다.
--   (적재가 넣는 새 행 — 위메이드 · 카카오페이 · 크래프톤 · 씨젠 nap_room, 삼성전기 lounge — 자리도 같은 코드 행이 없다.)
--
-- 코드 바꾸기 7 (BENEFIT_ID 회사 코드, nap_room → lounge, BENEFIT_ID 유지)
--   11915 lunit · 9852 samsung_ena · 50193 jusung · 1008 telechips · 33139 wemade · 17571 kakao_pay · 959 krafton
-- 나머지(문안 교체 · 새 행 5: 위메이드 · 카카오페이 · 크래프톤 · 씨젠 nap_room, 삼성전기 lounge)는 적재(load.py)가 한다.
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 지금 코드 · BADGE_CD = official 을 함께 건다.
-- 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 순서 (반드시): 이 파일 → python3 db/seed/load.py → release.
--
-- ⚠ 이번엔 web/assets/js/find.js 가 바뀐다 — git pull 순간 /find 칩 이름이 라이브로 바뀌고 표 이름은 release 뒤에 바뀐다(몇 분 불일치).
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다):
--   0) 머지 → git pull
--   1) 백업 — 적재가 참조 테이블을 모두 다시 쓰므로 참조 9테이블을 뜬다
--   2) 이 파일을 mysql -vv 로 적용
--   3) cd /home/ubuntu/loupit && python3 db/seed/load.py   (--fresh 금지)
--   4) 릴리스
-- 기대: 1회차 UPDATE 7문 각각 1 row affected · 2회차 전부 0 · 적재 뒤 전체 3470행 · 회사 160.
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- ── 코드 바꾸기 (7) — BENEFIT_ID 유지 ──
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'lounge'
 WHERE b.BENEFIT_ID = 11915 AND c.COMP_ENG_NM = 'lunit' AND b.BENEFIT_CD = 'nap_room' AND b.BADGE_CD = 'official';
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'lounge'
 WHERE b.BENEFIT_ID = 9852 AND c.COMP_ENG_NM = 'samsung_ena' AND b.BENEFIT_CD = 'nap_room' AND b.BADGE_CD = 'official';
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'lounge'
 WHERE b.BENEFIT_ID = 50193 AND c.COMP_ENG_NM = 'jusung' AND b.BENEFIT_CD = 'nap_room' AND b.BADGE_CD = 'official';
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'lounge'
 WHERE b.BENEFIT_ID = 1008 AND c.COMP_ENG_NM = 'telechips' AND b.BENEFIT_CD = 'nap_room' AND b.BADGE_CD = 'official';
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'lounge'
 WHERE b.BENEFIT_ID = 33139 AND c.COMP_ENG_NM = 'wemade' AND b.BENEFIT_CD = 'nap_room' AND b.BADGE_CD = 'official';
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'lounge'
 WHERE b.BENEFIT_ID = 17571 AND c.COMP_ENG_NM = 'kakao_pay' AND b.BENEFIT_CD = 'nap_room' AND b.BADGE_CD = 'official';
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_CD = 'lounge'
 WHERE b.BENEFIT_ID = 959 AND c.COMP_ENG_NM = 'krafton' AND b.BENEFIT_CD = 'nap_room' AND b.BADGE_CD = 'official';

COMMIT;
