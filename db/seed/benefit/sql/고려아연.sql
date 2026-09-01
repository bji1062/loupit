-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 고려아연 복리후생 데이터
-- 출처: AI 파싱 (2026-09-01)
-- URL: https://careers.koreazinc.co.kr/hrsystem/welfare
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 **고려아연 공식 채용 도메인**(careers.koreazinc.co.kr — koreazinc.co.kr
--       서브도메인) 인사제도 하위 두 페이지 —
--       ① 「복리후생」(/hrsystem/welfare) — 카드 10장 중 라이브 8장 + 카드별 상세 모달 본문.
--       ② 「교육제도」(/hrsystem/develop) — 글로벌 인재 양성·직무 전문성 교육 목록.
--       robots.txt 는 User-agent: * / Allow:/ 전면 허용(Disallow 없음, Crawl-delay 없음).
--       ⚠ 함정 1 — 복지 항목명은 index 카드에 있으나 수치(762세대·28여개·30여개)와 조건
--         (만 30세 이상·2년 1회)은 **카드 상세 모달**에만 있다. 카드 텍스트만 긁으면 설명이 빈다.
--       ⚠ 함정 2 — 카드 10장 중 5번(통근버스 운영(온산))과 7번(임직원 MBA)의 **리스트 카드가
--         HTML 주석으로 막혀 있다**. 통근버스는 카드와 모달이 **둘 다** 주석이라 페이지에
--         게시된 내용이 아니므로 **행을 만들지 않았다**(회사가 내린 항목을 되살리면 허위가 된다).
--         MBA 는 모달 본문이 라이브 DOM 이고 교육제도 페이지에 「임직원 MBA 및 대학원 지원」이
--         가시 텍스트로 살아 있어 **교육제도 페이지를 근거로** 수록했다.
--       ⚠ 함정 3 — 사택 단지 내 헬스장·풋살장은 **사택 거주자 한정 시설**이라 fitness 행을
--         만들지 않았다(히트맵 고정 라벨이 한정을 지워 사내 피트니스로 읽히면 허위가 된다 —
--         엠씨넥스 child_edu 선례). 시설 언급은 dormitory 행 서술에 병기했다.
--       ⚠ 함정 4 — robots.txt 는 일반 브라우저 UA 로만 200 을 준다. UA 없는 curl 은 WAF 차단
--         안내(EUC-KR)를 200 으로 돌려준다 — 차단으로 오판하기 쉽다.
--       두 페이지 모두 **금액을 일절 공개하지 않는다**. 신규 회사라 승계할 구본 앵커도 없으므로
--       12행 전부 금액 없음(QUAL_YN TRUE)이며 BENEFIT_AMT 는 전부 NULL 이다.
--       법정 제도(4대보험·법정 퇴직연금·법정 연차)는 페이지에도 없고 수록하지 않았다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('korea_zinc', '고려아연',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '비철금속', 'K', 'https://careers.koreazinc.co.kr/hrsystem/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'korea_zinc');

-- 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본은 NULL — INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://careers.koreazinc.co.kr/hrsystem/welfare'
 WHERE COMP_ID = @comp_id;

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '정기 종합검진', NULL, 'health',
   'est', NULL, TRUE, '만 30세 이상 대상 2년 1회 종합 건강검진 지원, 배우자 동반 가능', 10),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '질병 등으로 발생한 본인·배우자·자녀 의료비 지원', 11),
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '사택·기숙사(온산)', NULL, 'work_env',
   'est', NULL, TRUE, '임직원 주거복지로 사택·기숙사 제공. 온산 총 762세대 주거시설(단지 내 헬스장·풋살장 등 거주자 이용 시설, 도예 교실·자녀 영어교실 등 가족 강좌 운영), 본사는 월계동·등촌동·상계동 총 25세대', 20),
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금/취업준비금', NULL, 'family',
   'est', NULL, TRUE, '유아 교육비부터 대학교 학비까지 자녀 학자금 지원, 중·고등학교 입학축하금, 자녀가 대학에 진학하지 않을 경우 취업지원금', 30),
  (@comp_id, 'childcare', '직장 보육시설(온산)', NULL, 'family',
   'est', NULL, TRUE, '온산 사택 안에 위치한 직장 어린이집(새싹어린이집) 운영 — 일과 가정 양립 지원', 31),
  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'mba', '임직원 MBA·대학원 과정 지원', NULL, 'growth',
   'est', NULL, TRUE, '임직원 MBA 및 업무 관련분야 대학원 과정 지원 (교육제도 직무 전문성 교육)', 40),
  (@comp_id, 'lang', '어학 교육', NULL, 'growth',
   'est', NULL, TRUE, '온·오프라인 영어, 스페인어 등 어학 교육 운영 (교육제도 글로벌 인재 양성)', 41),
  (@comp_id, 'edu_support', '직무 위탁교육', NULL, 'growth',
   'est', NULL, TRUE, '필수 공통 직무과정 운영 및 외부 직무 위탁교육 지원', 42),
  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양시설(콘도·하계휴양소)', NULL, 'leisure',
   'est', NULL, TRUE, '전국 28여개 휴양시설·프리미엄 리조트를 임직원 할인가로 이용, 하계휴양소 운영', 50),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '골프·등산·축구·봉사 등 30여개 동호회 운영, 동호회 지원금 및 행사차량 지원', 51),
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '매년 복지포인트 지급 — 여행·문화·자기계발·취미생활 등에 사용', 60),
  (@comp_id, 'housing_loan', '주택구입·전세자금 융자', NULL, 'perks',
   'est', NULL, TRUE, '주거생활 안정을 위해 낮은 이자율로 주택구입 및 전세자금 대출 지원', 61)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
