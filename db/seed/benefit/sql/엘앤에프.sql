-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 엘앤에프 복리후생 데이터 (웨이브 1 신규 등록)
-- 출처: AI 파싱 (2026-09-01)
-- URL: https://recruit.landf.co.kr/info/bok_01.html
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 엘앤에프 공식 채용 서브도메인 recruit.landf.co.kr 의 복리후생
--       4개 페이지(bok_01 일과 삶의 행복 / bok_02 생활안정 지원 / bok_03 건강증진 지원 /
--       bok_04 회사생활 영위). 3rd-party(잡플래닛·사람인·잡코리아·블라인드·원티드·캐치)
--       인용 0건. robots.txt 는 두 도메인 모두 전체 허용이고 meta robots 제약도 없다.
--       ⚠ 인코딩 함정: 응답 헤더에 charset 이 없는데 본문은 EUC-KR 이라 cp949 로 명시
--       디코딩해야 한다. UTF-8 가정 파서는 ISO-8859-1 폴백으로 한글이 통째로 깨진다.
--       ⚠ bok_04 의 사내 동호회 블록은 원본 마크업이 2회 중복 출력한다 — 문장이 동일해
--       club 1행으로 병합했다(노출 16 / 고유 14항목).
--       금액: 4개 페이지 전체에 원 단위 금액 표기가 단 하나도 없다(50% · 20% · 3일 ·
--       5년 등 비율·기간뿐). 신규 회사라 승계할 앵커도 없어 20행 전부 무금액 정성행
--       (QUAL_YN TRUE, BENEFIT_AMT NULL) 이다 → DG-2 가 amt_source none 을 도출한다.
--       법정 제도(4대보험·법정 퇴직연금·법정 연차)는 페이지에 언급 자체가 없어 제외 대상도 없다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('landf', '엘앤에프',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '2차전지소재', 'L', 'https://recruit.landf.co.kr/info/bok_01.html');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'landf');

-- 3) 출처 URL 갱신 (INSERT IGNORE 는 기존 행을 갱신하지 않는다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.landf.co.kr/info/bok_01.html'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ── bok_02 생활안정 지원
  (@comp_id, 'long_service_bonus', '장기근속 포상금', NULL, 'compensation',
   'est', NULL, TRUE, '5년 근속 이후부터 5년 단위로 포상금 지급', 10),
  (@comp_id, 'holiday_gift', '명절·근로자의날 선물', NULL, 'compensation',
   'est', NULL, TRUE, '근로자의날(5.1)·설날·추석에 선물 지급', 11),

  -- ── 유연근무 (flexibility) ── bok_01 일과 삶의 행복
  (@comp_id, 'flex_work', '선택적근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, 'Work&Life Balance 를 위한 유연근무제 — 선택적근로시간제 도입·운영', 20),
  (@comp_id, 'remote_work', '재택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제의 일환으로 재택근무제 도입·운영', 21),

  -- ── 휴가 (time_off) ── bok_01 휴가제도 / bok_02 장기근속 포상
  (@comp_id, 'foundation_day_leave', '창립기념 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '창립기념 휴가(7월말) 별도 제공 — 연차 외 별도', 30),
  (@comp_id, 'leave_general', '연중휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연중휴가 3일 별도 제공 — 연차 외 별도', 31),
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기휴가를 장려해 가족과의 생활을 지원하는 refresh 휴가제도', 32),
  (@comp_id, 'long_service_leave', '장기근속 포상 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '5년 근속 이후부터 5년 단위로 포상 휴가 제공', 33),

  -- ── 건강·의료 (health) ── bok_03 건강증진 지원
  (@comp_id, 'health_check', '종합검진 및 정기검진', NULL, 'health',
   'est', NULL, TRUE, '매년 건강검진 지원, 만 40세 이상 직원은 종합검진 추가 지원', 40),
  (@comp_id, 'medical', '제휴병원 의료서비스', NULL, 'health',
   'est', NULL, TRUE, '지역 내 우수병원과 제휴해 최대 20% 할인 혜택 제공', 41),
  (@comp_id, 'fitness', '사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장 운영 — 생활 속 꾸준한 운동 지원', 42),

  -- ── 가족·돌봄 (family) ── bok_02 생활안정 지원
  (@comp_id, 'child_edu', '자녀 학자금(대학교)', NULL, 'family',
   'est', NULL, TRUE, '대학생 자녀에 대해 학자금 지원', 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 발생 시 휴가·경조금·화환·상조용품 지원', 51),

  -- ── 근무환경 (work_env) ── bok_03 사내 헬스장 운영 문장의 공장 편의시설 부분
  (@comp_id, 'lounge', '공장 편의시설(휴게실·안마의자)', NULL, 'work_env',
   'est', NULL, TRUE, '각 공장마다 편의시설 제공 — 안마의자, 휴게실 등', 60),

  -- ── 여가·라이프 (leisure) ── bok_01 / bok_04
  (@comp_id, 'resort', '사외 휴양시설', NULL, 'leisure',
   'est', NULL, TRUE, '전국 주요 관광지에 위치한 휴양소를 무료 또는 할인 금액으로 이용', 70),
  (@comp_id, 'sports_ticket', '스포츠경기 관람권', NULL, 'leisure',
   'est', NULL, TRUE, '삼성라이온즈·대구FC 등 지역 연고팀 홈경기 관람권 지원', 71),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회를 운영하고 매월 활동비 지원', 72),

  -- ── 경제적 부가혜택 (perks) ── bok_02 / bok_04
  (@comp_id, 'pension_support', '개인연금(IRP) 50% 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금(IRP) 납입금액의 50%를 회사가 지원 — 노후보장 목적', 80),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '지역 내 통근버스 무료 운영(왜관·구지공장 한정) — 구지 3개·왜관 2개 노선', 81),
  (@comp_id, 'meal', '사내식당(중식·석식·야식)', NULL, 'perks',
   'est', NULL, TRUE, '사내식당을 운영해 중식·석식·야식을 무상 제공', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
