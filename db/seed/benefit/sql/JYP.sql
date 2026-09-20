-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- JYP Ent. 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-20)   ※ 웨이브 4 계약 문서 날짜는 2026-09-19, 실제 수집일은 2026-09-20
-- URL: https://recruit.jype.com/ko/benefits
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 상장 법인 JYP Ent. 자기 도메인(jype.com)의 정규직 채용 사이트
--       recruit.jype.com 의 Work & Life 페이지 한 곳뿐이다. 3자 사이트 인용 0건.
--       귀속: www.jype.com 푸터 FAMILY → JYP RECRUIT → GNB Work & Life → /ko/benefits.
--       www 와 recruit 가 같은 OV 인증서(O = JYP Entertainment Corporation)를 쓰고
--       전 페이지 푸터가 © JYP ENTERTAINMENT Corp. 다 — 그룹 포털도 3자 ATS 도 아니다.
--       Next.js App Router SSR 프리렌더라 헤드리스 브라우저가 필요 없다. 원본 HTML 의
--       section[id^=benefits-] > li > h3/p 로 12항목 4카테고리가 그대로 떨어지고,
--       self.__next_f 플라이트 페이로드(22,478자)를 디코드해 한글 문자열을 전수로 뽑아도
--       가시 텍스트에 없는 항목은 나오지 않았다(숨은 항목 0).
--       robots: recruit.jype.com 은 User-Agent * 에 Allow / 와 Disallow /api/ 뿐이라
--       /ko/benefits 허용. 계약대로 호스트마다 robots 를 단독으로 먼저 받고 본문을 요청했다.
--       ⚠ /api/ 가 금지라 공고·복지 JSON 을 긁으면 안 된다. HTML 만이 경로다.
--       ⚠ 같은 채용 사이트가 자회사 Blue Garage 공고 10건도 싣는다. 그 법인은
--         자기 도메인 bluegarage.co 에 자기 복지 목록 4개를 따로 두는 별도 법인이라
--         이 파일의 어떤 행도 거기서 오지 않았다. 공고 본문에는 복리후생 섹션이 아예 없다.
--         /benefits 에 적용 범위·계열사별 상이 면책 문구가 한 줄도 없고 형제 법인이
--         비상장이라 코퍼스에 들어올 일이 없어 그룹 통합 각주는 달지 않았다.
--       12항목 → 한 항목에 제도가 묶여 있어 분해했다(건강관리 4 · 경조사 지원 3 ·
--         리프레시 제도 3 · 유연 근무제 3 · 복지 포인트 2). 제외 1항목 → **20행**.
--       제외: 무사고 안전 운전 수당 — 급여성 수당이고 원문이 (매니저 대상)으로
--         직군을 한정한다. 한정을 지우면 허위가 되고 수당은 복지가 아니다.
--       제외: 입사자·리더십·세미나 교육 제공 — 회사 주도 교육 커리큘럼이라 행이 아니다.
--         같은 문장의 교육 비용 지원분만 self_development 로 남겼다.
--       금액: 페이지에 원 단위 금액이 0건이다. 정량 표현은 근속 15일 유급휴가·주 1회 재택·
--         중식과 석식 무료·유치원~고등학생뿐이라 전부 금액이 아니다.
--         → 20행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE. 신규 회사라 승계할 값도 없다.
--       법정 제도: 4대보험·퇴직급여·연차·육아 관련 문구가 페이지에 아예 없다.
--         ⚠ 판단이 갈리는 두 건은 근거표에 사유를 적었다 —
--         (1) 선택적 근로제도는 flex_work 로 남겼다. 사용자가 도입을 강제받는 제도가
--             아니고(노사 서면합의로 도입하는 선택 제도) 계약 열거 목록에도
--             generator/data/legal_baseline.json 에도 없다.
--         (2) 매년 건강검진은 health_check 로 남겼다. 사무직 일반건강진단 주기를
--             상회하고 건강검진 휴가가 붙어 있으며, 역시 열거 목록·기준선 양쪽에 없다.
--       신규 코드 1개: smoking_cessation(금연 성공 축하금). 근거는 근거표 「신규 코드」절.
--       이메일 도메인 관측: jype.com (채용 개인정보처리방침 privacy.jype.com/recruit 의
--         recruit@jype.com · privacy@jype.com 등. MX 는 SMTP.GOOGLE.com — 웹과 같은 도메인).
--       ⚠ 검증·감사 판정 반영(2026-09-19): 20행 그대로. 행 조치 없음 — smoking_cessation(SORT 72) 신규 코드가
--       채택됐고 SORT 20·70·90 은 법정 제도가 아니라는 판정으로 유지한다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('jyp', 'JYP Ent.',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '엔터테인먼트', 'J', 'https://recruit.jype.com/ko/benefits');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'jyp');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.jype.com/ko/benefits'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 원문 Work·Refresh 카테고리 ──
  (@comp_id, 'meal', 'JYP BOB (사내식당)', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 JYP BOB 에서 유기농 식단의 중식과 석식 무료 제공 (공식 채용 페이지 Work & Life 의 Work 항목) — 식대 단가·운영 시간 미기재', 10),
  (@comp_id, 'welfare_point', '복지 포인트', NULL, 'perks',
   'est', NULL, TRUE, '문화·도서구입·생일 등 다양한 용도로 쓰는 복지포인트 지급 (공식 채용 페이지 Work & Life 의 Refresh 항목) — 연간 포인트 금액·사용 기한 미기재', 11),
  (@comp_id, 'snack_bar', '사내 카페 이용 포인트', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페 이용 포인트 제공 (공식 채용 페이지 Work & Life 의 복지 포인트 항목) — 포인트 금액·이용 한도 미기재', 12),

  -- ── 유연근무 (flexibility) — 원문 Work 카테고리 유연 근무제 항목 ──
  (@comp_id, 'flex_work', '유연 근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로제도 운영 (공식 채용 페이지 Work & Life 의 유연 근무제 항목) — 정산 기간·의무 근무 시간대·적용 직군 미기재', 20),
  (@comp_id, 'remote_work', '재택근무 (주 1회)', NULL, 'flexibility',
   'est', NULL, TRUE, '주 1회 재택근무 (공식 채용 페이지 Work & Life 의 유연 근무제 항목) — 적용 직군·신청 절차 미기재', 21),

  -- ── 근무 환경 (work_env) — 원문 Work 카테고리 유연 근무제 항목 ──
  (@comp_id, 'free_seating', '자율좌석제', NULL, 'work_env',
   'est', NULL, TRUE, '자율좌석제 운영 (공식 채용 페이지 Work & Life 의 유연 근무제 항목) — 적용 사무실·좌석 배정 방식 미기재', 30),

  -- ── 여가·라이프 (leisure) — 원문 Refresh·Life·Family 카테고리 ──
  (@comp_id, 'leisure_ticket', '문화 활동 (콘서트 초대권)', NULL, 'leisure',
   'est', NULL, TRUE, '소속 아티스트의 콘서트 초대권 제공 (공식 채용 페이지 Work & Life 의 Refresh 항목) — 연간 제공 횟수·매수·대상 공연 미기재', 40),
  (@comp_id, 'summer_vacation_subsidy', '하계 휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '하계 휴가비 지원 (공식 채용 페이지 Work & Life 의 리프레시 제도 항목) — 지급액·지급 시기 미기재', 41),
  (@comp_id, 'club', '동호회 활동', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 운영 (공식 채용 페이지 Work & Life 의 Life 항목) — 동호회 수·활동비 지원 여부 미기재', 42),
  (@comp_id, 'resort', '휴양 시설', NULL, 'leisure',
   'est', NULL, TRUE, '전국 제휴 휴양 시설 할인 혜택 (공식 채용 페이지 Work & Life 의 Family 항목) — 제휴처·할인율·이용 한도 미기재', 43),

  -- ── 휴가 (time_off) — 원문 Refresh·Family 카테고리 ──
  (@comp_id, 'long_service_leave', '리프레시 제도 (근속 유급휴가)', NULL, 'time_off',
   'est', NULL, TRUE, '3·6·10·15·20년 근속 시 15일 유급휴가 (공식 채용 페이지 Work & Life 의 리프레시 제도 항목) — 사용 기한·분할 사용 가능 여부 미기재', 50),
  (@comp_id, 'leave_general', '반려동물 경조 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '반려동물 경조 휴가 제공 (공식 채용 페이지 Work & Life 의 경조사 지원 항목) — 휴가 일수·대상 범위 미기재', 51),

  -- ── 보상·금전 (compensation) — 원문 Refresh 카테고리 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상·표창', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 및 표창 (공식 채용 페이지 Work & Life 의 리프레시 제도 항목) — 포상 금액·표창 기준 미기재', 60),

  -- ── 건강·의료 (health) — 원문 Life 카테고리 건강관리 항목 ──
  (@comp_id, 'health_check', '건강검진·독감 예방접종', NULL, 'health',
   'est', NULL, TRUE, '매년 건강검진과 건강검진 휴가 제공, 독감 예방접종 지원 (공식 채용 페이지 Work & Life 의 건강관리 항목) — 검진 항목·대상 범위·휴가 일수 미기재', 70),
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체 상해보험 가입 (공식 채용 페이지 Work & Life 의 건강관리 항목) — 보장 범위·보험료 부담 주체 미기재', 71),
  (@comp_id, 'smoking_cessation', '금연 성공 축하금', NULL, 'health',
   'est', NULL, TRUE, '금연 성공 축하금 지급 (공식 채용 페이지 Work & Life 의 건강관리 항목) — 지급액·인정 기준 미기재', 72),
  (@comp_id, 'mental', '멘탈케어 프로그램', NULL, 'health',
   'est', NULL, TRUE, '멘탈케어 프로그램 지원 (공식 채용 페이지 Work & Life 의 건강관리 항목) — 상담 횟수·가족 이용 가능 여부 미기재', 73),

  -- ── 성장·교육 (growth) — 원문 Life 카테고리 ──
  (@comp_id, 'self_development', '자기 계발 교육비', NULL, 'growth',
   'est', NULL, TRUE, '직무·어학·OA 등 자기 계발 교육 비용 지원 (공식 채용 페이지 Work & Life 의 Life 항목) — 연간 한도·정산 방식 미기재', 80),

  -- ── 가족·돌봄 (family) — 원문 Family 카테고리 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사비·경조 휴가·화환 및 조화·상조 서비스 지원 (공식 채용 페이지 Work & Life 의 Family 항목) — 경조금 액수·휴가 일수·상조 서비스 범위 미기재', 90),
  (@comp_id, 'child_edu', '자녀 학습 지원금', NULL, 'family',
   'est', NULL, TRUE, '유치원부터 고등학생 자녀까지 학습 지원금 제공 (공식 채용 페이지 Work & Life 의 Family 항목) — 지원 한도·자녀 수 제한 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
