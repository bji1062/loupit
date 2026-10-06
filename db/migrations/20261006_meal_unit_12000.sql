-- ══════════════════════════════════════════════════════════════════════
-- 식대 기준 금액 재계산 — 1끼 12,000원 x 하루 끼니 x 연 240일 (식대 54행 · 리드 판정 (82))
-- 사용자 결정: 2026-10-06 (식사 단가는 식당에서 한 끼 사 먹을 때의 평균 단가 기준 · 끼니당 12,000원으로 개산 ·
--   끼니가 적힌 행 전부 · 이직 계산기 기본값도 같이 바꾸기). 삼성전자 메모 단독 정정(판정 (81))은 이 안에 흡수됐다.
-- 선례: db/migrations/20260925_official_amount_corrections.sql · 20261005_landf_recollect.sql
--
-- 규칙: 금액(만원) = 1끼 단가 x 하루 끼니 수 x 연 240일. 단가는 회사가 1끼/1일 단가를 밝히면 그 값, 아니면 12,000원.
--   한 끼 288 · 두 끼 576 · 세 끼 864. 옛 432 앵커(일 18,000원 x 240일 = 1끼 6,000원)는 폐기.
--   야식 · 간식 · 편의식 · 음료 · 야근/초과근무 조건부 끼니 · 일부 보조 끼니는 세지 않는다. 검색 요약(ai_parse) 행은 금액 0.
--   회사가 월액 · 포인트를 밝힌 행(보로노이 · 에이피알 · 카카오게임즈 · 넷마블 · 위메이드)과 엠씨넥스 288 은 건드리지 않는다.
--   표 = /home/ubuntu/loupit-evidence/2026-10-06-guide-d/samsung-meal/MEAL-TABLE.tsv (55행 중 SK하이닉스 317 은 제외 — 리드 판정 (84)).
--
-- 무엇을 바꾸나: 추정 19행(금액 · 메모 꼬리 — 옛 「(추정)」 · 「(연 432만원 환산 추정)」 꼬리를 걷고 새 꼬리 「(하루 N끼 x 1끼 U원 x 연 240일 추정 ...)」),
--   정성 35행 -> 추정(금액 · 금액출처 estimated · 정성 해제 · 설명을 메모로 옮기고 새 꼬리). 이름 · 배지 · 출처 · 확인일 · 정렬은 그대로.
--   HD현대 「끼니당 단가 미공개로 금액 미산정」에서 「로 금액 미산정」만 걷음(「끼니당 단가 미공개」는 남김) · 동진쎄미켐 「식대 단가 미기재라 금액 환산 불가」 -> 「식대 단가 미기재」.
--   삼성전자 578 은 메모 본문도 원문 서술로 교체(원문 사본 samsung-meal/samsung-dxrecruit-benefit-20261006.html).
--
-- 가드: 문마다 BENEFIT_ID · 회사 영문명 · 항목 코드 · 이름 · 지금 금액(NULL 안전) · 지금 금액출처 · 지금 정성 여부 · 옛 글자 그대로 · BADGE_CD = official.
--   재직자가 고친 행(verified)은 건드리지 않는다. 멱등: 두 번째 실행은 전부 0행이다. 한 트랜잭션이다.
-- 프리셋(TBENEFIT_PRESET): 이 파일이 다루지 않는다 — db/seed/benefit_presets.sql 을 적재(load.py)가 전량 재삽입한다.
-- 순서 (반드시): 이 파일 -> python3 db/seed/load.py -> release.
--
-- 적용 (운영 LOUPIT 만, 사용자 ! — 베타 DB 에는 적용하지 않는다): mysql -vv 로 적용.
-- 기대: 54문 각각 Rows matched: 1  Changed: 1 · 두 번째 실행은 전부 0 · 행 수는 변하지 않는다(3179).
-- ══════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;
START TRANSACTION;

-- 178 lig_nex1 조·중·석식 제공 : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '조/중/석식 제공 (공식 인사제도 페이지 복리후생 알아보기 건강 항목 — 식대 단가·본인 부담 여부 미기재) (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 178 AND c.COMP_ENG_NM = 'lig_nex1' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '조·중·석식 제공'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '조/중/석식 제공 (공식 인사제도 페이지 복리후생 알아보기 건강 항목 — 식대 단가·본인 부담 여부 미기재) (추정)'
   AND b.BADGE_CD = 'official';

-- 210 naver 사내 식당·캔틴 (조식·점심·저녁 무료) : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '매일 점심·저녁 무료 사내 식당, 각 층 캔틴의 조식 메뉴(샌드위치·김밥·과일·음료) 무료 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 210 AND c.COMP_ENG_NM = 'naver' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내 식당·캔틴 (조식·점심·저녁 무료)'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '매일 점심·저녁 무료 사내 식당, 각 층 캔틴의 조식 메뉴(샌드위치·김밥·과일·음료) 무료 (추정)'
   AND b.BADGE_CD = 'official';

-- 351 neowiz 구내식당 (하루 세 끼 무료) : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '구내식당 하루 세 끼 모두 무료, Take Out 메뉴 포함 (공식 채용 페이지 네오위즈 혜택 항목 · 영문 채용 페이지 조식·중식·석식 무료 항목) — 1식 단가 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 351 AND c.COMP_ENG_NM = 'neowiz' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '구내식당 (하루 세 끼 무료)'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '구내식당 하루 세 끼 모두 무료, Take Out 메뉴 포함 (공식 채용 페이지 네오위즈 혜택 항목 · 영문 채용 페이지 조식·중식·석식 무료 항목) — 1식 단가 미기재 (추정)'
   AND b.BADGE_CD = 'official';

-- 406 wgames 조·중·석식 무상 제공 : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '조, 중, 석식 무상 제공 — 삼시세끼 무상 제공 (공식 채용 페이지 근무환경 복지제도 항목 — 식대 단가·제공 방식 미기재) (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 406 AND c.COMP_ENG_NM = 'wgames' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '조·중·석식 무상 제공'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '조, 중, 석식 무상 제공 — 삼시세끼 무상 제공 (공식 채용 페이지 근무환경 복지제도 항목 — 식대 단가·제공 방식 미기재) (추정)'
   AND b.BADGE_CD = 'official';

-- 578 samsung_elec 구내식당 삼시세끼 무료 : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '사내 삼시 세끼 무료, 매일 바뀌는 한식·중식·일식·양식·인도식 메뉴와 테이크아웃 메뉴 상시 제공 — 식사 단가 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 578 AND c.COMP_ENG_NM = 'samsung_elec' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '구내식당 삼시세끼 무료'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '일 18,000원 x 240일 환산'
   AND b.BADGE_CD = 'official';

-- 612 celltrion 삼시세끼 식사 지원 : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '아침·점심·저녁 식사 지원(서울사무소는 식대 지원) (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 612 AND c.COMP_ENG_NM = 'celltrion' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '삼시세끼 식사 지원'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '아침·점심·저녁 식사 지원(서울사무소는 식대 지원) (연 432만원 환산 추정)'
   AND b.BADGE_CD = 'official';

-- 812 eo_technics 조식/중식/석식 제공 : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '사내식당 조식/중식/석식 제공 (공식 홈페이지 인재채용 복리후생 복지시설 사내식당 항목) — 단가·본인 부담 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 812 AND c.COMP_ENG_NM = 'eo_technics' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '조식/중식/석식 제공'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '사내식당 조식/중식/석식 제공 (공식 홈페이지 인재채용 복리후생 복지시설 사내식당 항목) — 단가·본인 부담 미기재 (추정)'
   AND b.BADGE_CD = 'official';

-- 828 jusung 사내식당 (조식·중식·석식) : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '사내식당 조식/중식/석식 제공, 점심시간 12시~14시 2시간 운영 (공식 채용 사이트 LIFE 건강 · 여가 항목) — 식대 부담 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 828 AND c.COMP_ENG_NM = 'jusung' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내식당 (조식·중식·석식)'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '사내식당 조식/중식/석식 제공, 점심시간 12시~14시 2시간 운영 (공식 채용 사이트 LIFE 건강 · 여가 항목) — 식대 부담 미기재 (추정)'
   AND b.BADGE_CD = 'official';

-- 929 com2us 사내식당 Cooking (조식·중식·석식 무료) : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '조식, 중식, 석식 모두 무료로 제공하는 사내 식당 Cooking (컴투스 ESG 보고서 2025 복지제도 항목 · 2026 구내식당 운영) — 1식 단가 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 929 AND c.COMP_ENG_NM = 'com2us' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내식당 Cooking (조식·중식·석식 무료)'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '조식, 중식, 석식 모두 무료로 제공하는 사내 식당 Cooking (컴투스 ESG 보고서 2025 복지제도 항목 · 2026 구내식당 운영) — 1식 단가 미기재 (추정)'
   AND b.BADGE_CD = 'official';

-- 973 krafton 사내 식당 (조식·중식·석식) : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '조식, 중식, 석식을 모두 제공하는 사내 식당 운영 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 973 AND c.COMP_ENG_NM = 'krafton' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내 식당 (조식·중식·석식)'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '조식, 중식, 석식을 모두 제공하는 사내 식당 운영 (추정)'
   AND b.BADGE_CD = 'official';

-- 1031 tck 조식 · 중식 · 석식 무료 제공 : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '근무시간에 관계없이 조식 · 중식 · 석식 무료 제공 (공식 홈페이지 인재채용 복리후생 식비 지원 및 사내 카페테리아 운영 항목) (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 1031 AND c.COMP_ENG_NM = 'tck' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '조식 · 중식 · 석식 무료 제공'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '근무시간에 관계없이 조식 · 중식 · 석식 무료 제공 (공식 홈페이지 인재채용 복리후생 식비 지원 및 사내 카페테리아 운영 항목) (추정)'
   AND b.BADGE_CD = 'official';

-- 1050 pharma_research 조식·중식·석식 제공 : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '조식, 중식, 석식 제공 (공식 홈페이지 복리후생 항목 — 식대 단가 미기재) (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 1050 AND c.COMP_ENG_NM = 'pharma_research' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '조식·중식·석식 제공'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '조식, 중식, 석식 제공 (공식 홈페이지 복리후생 항목 — 식대 단가 미기재) (추정)'
   AND b.BADGE_CD = 'official';

-- 1089 pearl_abyss 먹거리 지원 (삼시세끼 무료) : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '사내식당 조식·중식·석식 무료 제공 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 1089 AND c.COMP_ENG_NM = 'pearl_abyss' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '먹거리 지원 (삼시세끼 무료)'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '사내식당 조식·중식·석식 무료 제공 (추정)'
   AND b.BADGE_CD = 'official';

-- 1164 hanwha_systems 조·중·석식 제공 : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '사업장 내 양질의 식사(조·중·석식) 제공 (공식 홈페이지 인재채용 인사제도 복리후생 행복한 일터 항목) — 단가·본인 부담 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 1164 AND c.COMP_ENG_NM = 'hanwha_systems' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '조·중·석식 제공'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '사업장 내 양질의 식사(조·중·석식) 제공 (공식 홈페이지 인재채용 인사제도 복리후생 행복한 일터 항목) — 단가·본인 부담 미기재 (추정)'
   AND b.BADGE_CD = 'official';

-- 738 enchem 조식·중식·석식·야식 지원 : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '조식/중식/석식/야식 지원 (하루 3끼 × 1끼 12,000원 × 연 240일 추정, 야식 제외)'
 WHERE b.BENEFIT_ID = 738 AND c.COMP_ENG_NM = 'enchem' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '조식·중식·석식·야식 지원'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '조식/중식/석식/야식 지원 (연 432만원 환산 추정)'
   AND b.BADGE_CD = 'official';

-- 782 eugenetech 사내 식당 3끼 무상 제공 : 432/estimated -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.NOTE_CTNT = '사내 식당에서 3끼 무상 제공 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 782 AND c.COMP_ENG_NM = 'eugenetech' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내 식당 3끼 무상 제공'
   AND b.BENEFIT_AMT = 432 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '사내 식당에서 3끼 무상 제공 (연 432만원 환산 추정)'
   AND b.BADGE_CD = 'official';

-- 704 ecopro 구내식당 (중식·석식) : 288/estimated -> 576/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 576, b.NOTE_CTNT = '구내식당 운영, 중식·석식 제공 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 1식 단가·본인 부담 여부 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 704 AND c.COMP_ENG_NM = 'ecopro' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '구내식당 (중식·석식)'
   AND b.BENEFIT_AMT = 288 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '구내식당 운영, 중식·석식 제공 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 1식 단가·본인 부담 여부 미기재 (추정)'
   AND b.BADGE_CD = 'official';

-- 717 ecopro_bm 구내식당 (중/석식) : 288/estimated -> 576/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 576, b.NOTE_CTNT = '구내식당 운영, 중식·석식 제공 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 식대 단가·본인 부담 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)'
 WHERE b.BENEFIT_ID = 717 AND c.COMP_ENG_NM = 'ecopro_bm' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '구내식당 (중/석식)'
   AND b.BENEFIT_AMT = 288 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '구내식당 운영, 중식·석식 제공 (공식 홈페이지 회사소개 복리후생 기타 지원 항목) — 식대 단가·본인 부담 미기재 (추정)'
   AND b.BADGE_CD = 'official';

-- 1206 hyundai_rotem 중식 제공·조석식 일부 지원 : 288/estimated -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.NOTE_CTNT = '중식 제공, 조·석식 일부 지원 (공식 채용 사이트 복지제도 근무여건 항목), 사내 식당 운영 (2026 지속가능경영보고서 복지제도 편의제공 항목) — 식대 단가·조석식 지원 범위 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정, 조·석식 일부 지원은 제외)'
 WHERE b.BENEFIT_ID = 1206 AND c.COMP_ENG_NM = 'hyundai_rotem' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '중식 제공·조석식 일부 지원'
   AND b.BENEFIT_AMT = 288 AND b.AMT_SOURCE_CD = 'estimated' AND b.QUAL_YN = FALSE AND b.NOTE_CTNT = '중식 제공, 조·석식 일부 지원 (공식 채용 사이트 복지제도 근무여건 항목), 사내 식당 운영 (2026 지속가능경영보고서 복지제도 편의제공 항목) — 식대 단가·조석식 지원 범위 미기재 (추정)'
   AND b.BADGE_CD = 'official';

-- 1017 telechips 구내식당 조식·중식·석식 무료 : NULL/none -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '구내식당 조식/중식/석식 무료 제공, 삼시세끼 무료 지원 (공식 채용 사이트 복리후생 FUN OFFICE LIFE 항목) — 사업장 범위·운영 시간 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 1017 AND c.COMP_ENG_NM = 'telechips' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '구내식당 조식·중식·석식 무료'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '구내식당 조식/중식/석식 무료 제공, 삼시세끼 무료 지원 (공식 채용 사이트 복리후생 FUN OFFICE LIFE 항목) — 사업장 범위·운영 시간 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 1130 hanmi_pharm 구내식당 조식·중식·석식 (사업장별 상이) : NULL/none -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '구내식당 운영, 조식·중식·석식 제공, 사업장별 상이 (공식 채용 사이트 복리후생 구내식당 운영 항목, 한미그룹 공통 문구) — 사업장별 제공 끼니·식대 부담 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 1130 AND c.COMP_ENG_NM = 'hanmi_pharm' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '구내식당 조식·중식·석식 (사업장별 상이)'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '구내식당 운영, 조식·중식·석식 제공, 사업장별 상이 (공식 채용 사이트 복리후생 구내식당 운영 항목, 한미그룹 공통 문구) — 사업장별 제공 끼니·식대 부담 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 7465 hd_hyundai 아침·점심·저녁 무료 제공 : NULL/none -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '직원 식당에서 아침·점심·저녁을 무료로 제공하며 매일 10개 메뉴(중식 기준) 중 자유 선택. 끼니당 단가 미공개 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 7465 AND c.COMP_ENG_NM = 'hd_hyundai' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '아침·점심·저녁 무료 제공'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '직원 식당에서 아침·점심·저녁을 무료로 제공하며 매일 10개 메뉴(중식 기준) 중 자유 선택. 끼니당 단가 미공개로 금액 미산정 (그룹 통합 채용 기준) 계열사 간 일부 상이 가능' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 8790 hankook_tire 사내식당 식사 제공 : NULL/none -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '사내식당에서 조식·중식·석식 제공(일부 사업장은 조식·중식 제공) (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 8790 AND c.COMP_ENG_NM = 'hankook_tire' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내식당 식사 제공'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '사내식당에서 조식·중식·석식 제공(일부 사업장은 조식·중식 제공)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 11813 douzone 사내 식사·간식 제공 : NULL/none -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '강촌 본사 및 을지타워에서 무료 사내식당(조·중·석식)과 간식 제공 (더존ICT그룹 채용공고 사내 식사/간식 제공 항목 · 복리후생제도 페이지 복리후생시설 항목 사내식당(조,중,석식 제공) — 그 밖의 사업장 제공 여부 미기재) (그룹 통합 채용 기준) (하루 3끼 × 1끼 12,000원 × 연 240일 추정, 간식 제외)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 11813 AND c.COMP_ENG_NM = 'douzone' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내 식사·간식 제공'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '강촌 본사 및 을지타워에서 무료 사내식당(조·중·석식)과 간식 제공 (더존ICT그룹 채용공고 사내 식사/간식 제공 항목 · 복리후생제도 페이지 복리후생시설 항목 사내식당(조,중,석식 제공) — 그 밖의 사업장 제공 여부 미기재) (그룹 통합 채용 기준)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 15235 tse 카페테리아 : NULL/none -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '카페테리아 — 무료 아침, 점심, 저녁 제공 (공식 채용안내 복리후생 페이지 항목 — 끼니별 단가·운영 사업장 미기재) (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 15235 AND c.COMP_ENG_NM = 'tse' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '카페테리아'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '카페테리아 — 무료 아침, 점심, 저녁 제공 (공식 채용안내 복리후생 페이지 항목 — 끼니별 단가·운영 사업장 미기재)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 40836 samsung_electro 사내 식당 : NULL/none -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '조식·중식·석식 다양한 메뉴(Take-Out 포함) 무료 제공 (공식 채용 페이지 회사생활 사내 식당 항목 — 식대 단가 미기재) (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 40836 AND c.COMP_ENG_NM = 'samsung_electro' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내 식당'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '조식·중식·석식 다양한 메뉴(Take-Out 포함) 무료 제공 (공식 채용 페이지 회사생활 사내 식당 항목 — 식대 단가 미기재)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 502 bh 사내식당 조식·중식·석식·야식 무상 제공 : NULL/none -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '사내식당 운영(조식, 중식, 석식, 야식 제공) (공식 홈페이지 복지제도 항목), 임직원 식사 무상제공 (2025 비에이치 ESG 보고서 근무환경 지원 구내식당) — 식대 단가 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정, 야식 제외)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 502 AND c.COMP_ENG_NM = 'bh' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내식당 조식·중식·석식·야식 무상 제공'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '사내식당 운영(조식, 중식, 석식, 야식 제공) (공식 홈페이지 복지제도 항목), 임직원 식사 무상제공 (2025 비에이치 ESG 보고서 근무환경 지원 구내식당) — 식대 단가 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 541 samsung_bio 사내식당 하루 네 끼 무료 : NULL/none -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '다양한 메뉴의 건강식을 하루 네 끼(조식, 중식, 석식 및 야식) 무료 제공, 바이오플라자 920석 규모 식당과 푸드코트, 테이크아웃 메뉴 무상 제공 (공식 채용 페이지 사내 문화 및 편의 항목 · 공식 홈페이지 사내복지 항목 — 식대 금액 미기재) (하루 3끼 × 1끼 12,000원 × 연 240일 추정, 야식 제외)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 541 AND c.COMP_ENG_NM = 'samsung_bio' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내식당 하루 네 끼 무료'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '다양한 메뉴의 건강식을 하루 네 끼(조식, 중식, 석식 및 야식) 무료 제공, 바이오플라자 920석 규모 식당과 푸드코트, 테이크아웃 메뉴 무상 제공 (공식 채용 페이지 사내 문화 및 편의 항목 · 공식 홈페이지 사내복지 항목 — 식대 금액 미기재)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 8407 wonik_ips 사내식당 무상 식사 : NULL/none -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '사내식당 운영 — 조/중/석/간식 무상지급 (하루 3끼 × 1끼 12,000원 × 연 240일 추정, 간식 제외)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 8407 AND c.COMP_ENG_NM = 'wonik_ips' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내식당 무상 식사'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '사내식당 운영 — 조/중/석/간식 무상지급' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 9754 dongjin_semichem 사내식당·식대 지원 : NULL/none -> 864/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 864, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '사내식당 운영 또는 식대 지원. 사업장·연구소 구내식당에서 조식·중식·석식·간식 제공하고 구내식당이 없는 경우 식대 지원 (끼니 구성은 본사 인사제도 페이지 2019 기준 — 식대 단가 미기재) (하루 3끼 × 1끼 12,000원 × 연 240일 추정, 간식 제외)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 9754 AND c.COMP_ENG_NM = 'dongjin_semichem' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내식당·식대 지원'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '사내식당 운영 또는 식대 지원. 사업장·연구소 구내식당에서 조식·중식·석식·간식 제공하고 구내식당이 없는 경우 식대 지원 (끼니 구성은 본사 인사제도 페이지 2019 기준 — 식대 단가 미기재라 금액 환산 불가)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 265 sk_innovation 중식·석식 제공 : NULL/none -> 576/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 576, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '중/석식 제공 (공식 인사제도 평가/보상 페이지 복리후생 기타 항목 — 제공 방식·식대 단가 미기재) (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 265 AND c.COMP_ENG_NM = 'sk_innovation' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '중식·석식 제공'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '중/석식 제공 (공식 인사제도 평가/보상 페이지 복리후생 기타 항목 — 제공 방식·식대 단가 미기재)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 369 nepes 사내식당 중식·석식 : NULL/none -> 576/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 576, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '사내식당에서 중식·석식 제공, 서울 근무자와 공장 외 근무자는 식비 별도 지급 — 식비 금액 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 369 AND c.COMP_ENG_NM = 'nepes' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내식당 중식·석식'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '사내식당에서 중식·석식 제공, 서울 근무자와 공장 외 근무자는 식비 별도 지급 — 식비 금액 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 1114 hanmi_semi 중식·석식 무료 제공 : NULL/none -> 576/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 576, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '삼성웰스토리 푸드 서비스로 중식·석식 무료 제공 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 1114 AND c.COMP_ENG_NM = 'hanmi_semi' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '중식·석식 무료 제공'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '삼성웰스토리 푸드 서비스로 중식·석식 무료 제공' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 1238 hyundai_muvex 구내식당 : NULL/none -> 576/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 576, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '구내식당 운영, 중식·석식 제공 (공식 홈페이지 인사정책 복지제도 사내지원 항목) — 1식 단가 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 1238 AND c.COMP_ENG_NM = 'hyundai_muvex' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '구내식당'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '구내식당 운영, 중식·석식 제공 (공식 홈페이지 인사정책 복지제도 사내지원 항목) — 1식 단가 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 8355 landf 사내 식당 (1일 2식 무상) : NULL/none -> 576/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 576, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '「본우리집밥」 입점 사내 식당에서 균형 잡힌 식단 기반의 다양한 메뉴 제공, 1일 2식 무상 지원, 다이어트를 위한 간편식 별도 제공 (공식 채용 사이트 복리후생 제도 소개 사내 식당 항목) — 제공 끼니 구성 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정, 간편식 제외)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 8355 AND c.COMP_ENG_NM = 'landf' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내 식당 (1일 2식 무상)'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '「본우리집밥」 입점 사내 식당에서 균형 잡힌 식단 기반의 다양한 메뉴 제공, 1일 2식 무상 지원, 다이어트를 위한 간편식 별도 제공 (공식 채용 사이트 복리후생 제도 소개 사내 식당 항목) — 제공 끼니 구성 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 11553 sk_biopharm 사내 식당 (중·석식) : NULL/none -> 576/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 576, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '사내 식당 운영, 중식·석식 제공 (공식 홈페이지 지속가능경영 복리후생 회사 생활 항목 — 식대 단가·본인 부담 여부 미기재) (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 11553 AND c.COMP_ENG_NM = 'sk_biopharm' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내 식당 (중·석식)'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '사내 식당 운영, 중식·석식 제공 (공식 홈페이지 지속가능경영 복리후생 회사 생활 항목 — 식대 단가·본인 부담 여부 미기재)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 13477 gc_biopharma 사내 식당 : NULL/none -> 576/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 576, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '건강한 식습관을 위한 사내 식당 운영, 공식 채용사이트 GC녹십자 영문 복리후생 페이지는 중식·석식 무료 제공으로 명시 (국문 페이지에는 무료 여부·식대 단가 미기재) (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 13477 AND c.COMP_ENG_NM = 'gc_biopharma' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내 식당'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '건강한 식습관을 위한 사내 식당 운영, 공식 채용사이트 GC녹십자 영문 복리후생 페이지는 중식·석식 무료 제공으로 명시 (국문 페이지에는 무료 여부·식대 단가 미기재)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 13570 jyp JYP BOB (사내식당) : NULL/none -> 576/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 576, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '사내식당 JYP BOB 에서 유기농 식단의 중식과 석식 무료 제공 (공식 채용 페이지 Work & Life 의 Work 항목) — 식대 단가·운영 시간 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 13570 AND c.COMP_ENG_NM = 'jyp' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = 'JYP BOB (사내식당)'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '사내식당 JYP BOB 에서 유기농 식단의 중식과 석식 무료 제공 (공식 채용 페이지 Work & Life 의 Work 항목) — 식대 단가·운영 시간 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 15384 psk 사내식당 (중식·석식) : NULL/none -> 576/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 576, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '사내식당 운영, 중석식 제공 (공식 ESG 임직원 페이지 조직문화 주거 생활 항목·공식 채용 페이지 복지 항목 식비 지원 — 식대 단가·본인 부담 여부 미기재) (그룹 통합 채용 기준) (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 15384 AND c.COMP_ENG_NM = 'psk' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내식당 (중식·석식)'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '사내식당 운영, 중석식 제공 (공식 ESG 임직원 페이지 조직문화 주거 생활 항목·공식 채용 페이지 복지 항목 식비 지원 — 식대 단가·본인 부담 여부 미기재) (그룹 통합 채용 기준)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 985 classys 중식·석식 식비 지원 : NULL/none -> 576/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 576, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '중식 지원, 식대 걱정 없이 든든하게 먹고 일함, 개인 법인카드로 중식 결제, 중식과 석식 식비 지원 (2025 지속가능경영보고서 경제적 안정 항목 · 공식 홈페이지 ESG Social 중식/석식 지원 항목) — 1식 단가·제공 방식 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 985 AND c.COMP_ENG_NM = 'classys' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '중식·석식 식비 지원'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '중식 지원, 식대 걱정 없이 든든하게 먹고 일함, 개인 법인카드로 중식 결제 (공식 채용 사이트 복리 후생 중식 지원 · 개인 법인카드 지원 항목), 중식과 석식 식비 지원 (2025 지속가능경영보고서 경제적 안정 항목 · 공식 홈페이지 ESG Social 중식/석식 지원 항목) — 1식 단가·제공 방식 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 457 rainbow_robotics 중식 제공 : NULL/none -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '중식 제공 (공식 채용 공고 복리후생 항목), 구내 식당 (공식 홈페이지 인재채용 Work Environments 항목) — 조식·석식 제공 여부·본인 부담 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 457 AND c.COMP_ENG_NM = 'rainbow_robotics' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '중식 제공'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '중식 제공 (공식 채용 공고 복리후생 항목), 구내 식당 (공식 홈페이지 인재채용 Work Environments 항목) — 조식·석식 제공 여부·본인 부담 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 593 samchundang 중식비 제공 : NULL/none -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '중식비 제공 (금액 미공개) (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 593 AND c.COMP_ENG_NM = 'samchundang' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '중식비 제공'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '중식비 제공 (금액 미공개)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 657 isens 중식 지원 : NULL/none -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '중식비 포인트 지급(서울), 구내식당 운영(송도, 원주) (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 657 AND c.COMP_ENG_NM = 'isens' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '중식 지원'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '중식비 포인트 지급(서울), 구내식당 운영(송도, 원주)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 1253 hyundai_autoever 직원식당·중식 제공 : NULL/none -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '직원식당 운영 (공식 채용 사이트 Life 직원식당 항목), 쾌적한 사내식당에서 맛있는 한 끼 중식 제공 — 사내식당 운영 또는 중식비 지원은 사업장별 상이 (같은 사이트 People 맛있고 든든한 중식 제공 항목) (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 1253 AND c.COMP_ENG_NM = 'hyundai_autoever' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '직원식당·중식 제공'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '직원식당 운영 (공식 채용 사이트 Life 직원식당 항목), 쾌적한 사내식당에서 맛있는 한 끼 중식 제공 — 사내식당 운영 또는 중식비 지원은 사업장별 상이 (같은 사이트 People 맛있고 든든한 중식 제공 항목)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 1315 hugel 조식 제공 : NULL/none -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '조식 제공 (공식 채용 사이트 휴젤 라이프 업무와 삶에 몰입할 수 있도록 항목 · 2025 연간 리포트 Working Environment 항목) — 제공 사업장·중식 제공 여부 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 1315 AND c.COMP_ENG_NM = 'hugel' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '조식 제공'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '조식 제공 (공식 채용 사이트 휴젤 라이프 업무와 삶에 몰입할 수 있도록 항목 · 2025 연간 리포트 Working Environment 항목) — 제공 사업장·중식 제공 여부 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 6520 silicon2 주 5회 점심 제공 : NULL/none -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '주 5회 점심 제공 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 6520 AND c.COMP_ENG_NM = 'silicon2' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '주 5회 점심 제공'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '주 5회 점심 제공' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 10863 hanwha_life 중식비 : NULL/none -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '중식비 (공식 복리후생 페이지 생활안정지원 항목명 그대로 — 점심 한 끼 대상임은 명시, 지원 단가·구내식당 운영 여부 미기재) (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 10863 AND c.COMP_ENG_NM = 'hanwha_life' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '중식비'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '중식비 (공식 복리후생 페이지 생활안정지원 항목명 그대로 — 점심 한 끼 대상임은 명시, 지원 단가·구내식당 운영 여부 미기재)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 12388 stpharm 중식 식대 제공 : NULL/none -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '식대 제공, 중식 (에스티팜 홈페이지 Careers 페이지 Office 항목에만 기재) — 제공 방식·식대 단가 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 12388 AND c.COMP_ENG_NM = 'stpharm' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '중식 식대 제공'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '식대 제공, 중식 (에스티팜 홈페이지 Careers 페이지 Office 항목에만 기재) — 제공 방식·식대 단가 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 16312 s_oil 중식 지원 : NULL/none -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '중식 지원 (2025 ESG 보고서 기타 복지 프로그램 항목 — 제공 방식·식대 단가 미기재) (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 16312 AND c.COMP_ENG_NM = 's_oil' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '중식 지원'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '중식 지원 (2025 ESG 보고서 기타 복지 프로그램 항목 — 제공 방식·식대 단가 미기재)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 44 hmm 식대 지원 : NULL/none -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '모바일 식권 플랫폼으로 중식대 및 야근식대 포인트 지급, 약 300개 제휴점 이용 가능 (공식 채용 사이트 복리후생 식대지원 항목) — 1식 단가·월 지급액 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정, 야근식대 제외)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 44 AND c.COMP_ENG_NM = 'hmm' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '식대 지원'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '모바일 식권 플랫폼으로 중식대 및 야근식대 포인트 지급, 약 300개 제휴점 이용 가능 (공식 채용 사이트 복리후생 식대지원 항목) — 1식 단가·월 지급액 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 292 skt 사내식당 더 테이블·EBB 아침식사 : NULL/none -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = 'T타워 지하 2층 사내식당 겸 복합 문화 공간 더 테이블 운영. 아침 일찍 출근한 구성원에게 아침식사를 무료로 제공하는 EBB(Early Bird Breakfast) (공식 뉴스룸 2022년·2026년 기사) — 중식 식대 지원 여부·본인 부담 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 292 AND c.COMP_ENG_NM = 'skt' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '사내식당 더 테이블·EBB 아침식사'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = 'T타워 지하 2층 사내식당 겸 복합 문화 공간 더 테이블 운영 (공식 뉴스룸 2022년 기사·공식 홈페이지 임직원 건강증진 페이지). 아침 일찍 출근한 구성원에게 아침식사를 무료로 제공하는 EBB(Early Bird Breakfast) (공식 뉴스룸 2022년·2026년 기사) — 중식 식대 지원 여부·본인 부담 미기재' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 11919 lunit 점심/저녁 식사 지원 : NULL/none -> 288/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 288, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '점심·저녁 식사 지원, 2025 지속가능경영보고서는 지정 근로시간 내 중식 및 초과 근무 시 석식 비용 지원으로 기재 (공식 채용 페이지 「점심/저녁/간식지원」 항목 — 식대 단가 미기재, 서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음) (하루 1끼 × 1끼 12,000원 × 연 240일 추정, 초과 근무 시 석식 제외)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 11919 AND c.COMP_ENG_NM = 'lunit' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '점심/저녁 식사 지원'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '점심·저녁 식사 지원, 2025 지속가능경영보고서는 지정 근로시간 내 중식 및 초과 근무 시 석식 비용 지원으로 기재 (공식 채용 페이지 「점심/저녁/간식지원」 항목 — 식대 단가 미기재, 서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 15249 fadu 식대 지원 : NULL/none -> 360/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 360, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '점심과 저녁(야근 시) 각 15,000원 식대 별도 지원 (공식 채용 사이트 복지 혜택 몰입을 위한 환경 제공 항목 — 끼니 단가만 명시되고 월·연 한도 미기재) (점심 1끼 15,000원 × 연 240일 추정, 야근 시 저녁 제외)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 15249 AND c.COMP_ENG_NM = 'fadu' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '식대 지원'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '점심과 저녁(야근 시) 각 15,000원 식대 별도 지원 (공식 채용 사이트 복지 혜택 몰입을 위한 환경 제공 항목 — 끼니 단가만 명시되고 월·연 한도 미기재)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

-- 11886 robotis 식대지원 : NULL/none -> 432/estimated
UPDATE TCOMPANY_BENEFIT b JOIN TCOMPANY c ON c.COMP_ID = b.COMP_ID
   SET b.BENEFIT_AMT = 432, b.AMT_SOURCE_CD = 'estimated', b.QUAL_YN = FALSE, b.NOTE_CTNT = '식대 지원 일 18,000원, 연장근로 시 10,000원 추가 (공식 채용 페이지 업무지원 항목 — 월·연 단위 지급액과 지급 방식 미기재) (하루 18,000원 × 연 240일 추정, 연장근로 추가분 제외)', b.QUAL_DESC_CTNT = NULL
 WHERE b.BENEFIT_ID = 11886 AND c.COMP_ENG_NM = 'robotis' AND b.BENEFIT_CD = 'meal' AND b.BENEFIT_NM = '식대지원'
   AND b.BENEFIT_AMT IS NULL AND b.AMT_SOURCE_CD = 'none' AND b.QUAL_YN = TRUE AND b.QUAL_DESC_CTNT = '식대 지원 일 18,000원, 연장근로 시 10,000원 추가 (공식 채용 페이지 업무지원 항목 — 월·연 단위 지급액과 지급 방식 미기재)' AND b.NOTE_CTNT IS NULL
   AND b.BADGE_CD = 'official';

COMMIT;
