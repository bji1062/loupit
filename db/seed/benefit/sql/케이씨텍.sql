-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 케이씨텍 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.kctech.co.kr/page/career3.php
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)케이씨텍의 자기 도메인 www.kctech.co.kr 인재채용 > 복지제도 페이지다.
--   SSR 이라 원본 HTML 에 복지 13블록(article.car3-article) 텍스트가 다 있다. 헤드리스 렌더 불필요.
--   HTML 주석으로 막힌 Refresh Day, Family Day 블록 1개는 공개 원문이 아니라 쓰지 않았다.
--   보조 출처: 같은 도메인 인재채용 > 인사제도 페이지 보상체계 이미지(career2-img2.png 1114x324 판독) ·
--     인재채용 > 기업문화 페이지 본문 · OpenDART 2026 반기보고서(접수 20260813001393) 유연근무제도 사용 현황.
--   귀속: 페이지 주어가 케이씨텍 법인 자신이고 그룹 · 계열사 단서가 없다. 지주 (주)케이씨와 형제 법인은
--     코퍼스 · 대기 폴더에 없다. 그룹 채용 ATS(kc-group.recruiter.co.kr)는 robots 가 /app* 를 막아 읽지 않았다.
--   금액: 원문 숫자는 장기근속 포상(1회성)뿐이라 전 행 BENEFIT_AMT NULL. 식대는 끼니 미기재라 NULL.
--   제외: 공시 임원 보수지급기준 성과급 칸 · 공시 시차출퇴근제 · 원격근무제 사용자 0(표의 대시) ·
--     공시 육아휴직 · 배우자 출산휴가(법정) · 기업문화 페이지의 휴가의 날(내용 미기재 — 근거표 판단 요청) ·
--     자유로운 복장 · 소통 게시판 · 사내 소식지(복지 제도 아님).
--   공고 근거 0행 / 전체 20행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(perks 10 · compensation 20 · work_env 30 · family 40 ·
--     time_off 50 · health 60 · leisure 70 · growth 80), 보조 출처에만 있는 flexibility 90.
-- 검증 · 감사 판정 반영(2026-10-14): 기업문화 페이지 휴가의 날 leave_general 추가(리드 판정 117 — 참고 블록의 휴가의 날 판단 요청 줄은 이 판정으로 뒤집힘 · 복지 블록 수는 14) — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kctech', '케이씨텍',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'K', 'https://www.kctech.co.kr/page/career3.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kctech');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.kctech.co.kr/page/career3.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 인재채용 복지제도 ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트를 제공하여 본인의 필요와 선호에 따라 복리후생 품목을 자유롭게 선택, 자기계발·건강증진·여가활용 등 지원 (공식 인재채용 페이지 복지제도 복지포인트 제공 항목) — 포인트 배정액·지급 시기 미기재', 10),
  (@comp_id, 'relocation', '정착지원금 (원거리 출퇴근자)', NULL, 'perks',
   'est', NULL, TRUE, '원거리 출퇴근자를 위한 정착지원금 지원, 기숙사 입주 희망 시 상황에 따라 정착지원금 수령을 권장할 수 있음 (공식 인재채용 페이지 복지제도 기숙사 및 보조금 지원 항목) — 지원 금액·지급 기간 미기재', 11),
  (@comp_id, 'housing_loan', '회사대출제도 (주택구입·임차·생활안정)', NULL, 'perks',
   'est', NULL, TRUE, '주택구입(임차) 혹은 생활안정 등으로 목돈 마련이 필요한 경우 근속년수에 따라 저렴한 이율로 대출금 지원 (공식 인재채용 페이지 복지제도 회사대출제도 운영 항목) — 대출 한도·이율 미기재', 12),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '직원의 편리한 출퇴근을 위하여 주요 지역에 통근버스 운영 (공식 인재채용 페이지 복지제도 출퇴근 통근버스 운영 항목) — 운행 노선·운행 시간 미기재', 13),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '직원의 건강을 고려한 다양한 식사를 매일 무료로 제공 (공식 인재채용 페이지 복지제도 사내식당 운영 항목) — 제공 끼니·식단 구성 미기재', 14),
  (@comp_id, 'snack_bar', '사내 카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '셀프로 이용할 수 있는 음료 자판기와 고급 원두를 카페테리아에서 무료로 이용 (공식 인재채용 페이지 복지제도 사내 카페테리아 운영 항목) — 운영 시간·제공 품목 범위 미기재', 15),
  -- ── 보상 (compensation) — 인재채용 복지제도 · 인사제도 보상체계 ──
  (@comp_id, 'holiday_gift', '명절 포인트 (설날·추석)', NULL, 'compensation',
   'est', NULL, TRUE, '가족과 함께 즐거운 명절을 보낼 수 있도록 매년 설날과 추석에 포인트 지급 (공식 인재채용 페이지 복지제도 복지포인트 제공 항목) — 포인트 금액 미기재', 20),
  (@comp_id, 'profit_sharing', '성과급 (경영목표 달성 연동)', NULL, 'compensation',
   'est', NULL, TRUE, '인센티브, 경영목표 달성 수준에 따른 성과급 지급 (공식 인재채용 페이지 인사제도 보상체계 항목) — 지급 기준·지급률 미기재', 21),
  -- ── 근무환경 (work_env) — 인재채용 복지제도 ──
  (@comp_id, 'dormitory', '기숙사 (원거리 출퇴근자)', NULL, 'work_env',
   'est', NULL, TRUE, '원거리 출퇴근자를 위한 기숙사 입주 지원 (공식 인재채용 페이지 복지제도 기숙사 및 보조금 지원 항목) — 입주 조건·비용 부담 미기재', 30),
  -- ── 가족 (family) — 인재채용 복지제도 ──
  (@comp_id, 'child_edu', '자녀학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀가 높은 역량을 가진 인재로 성장할 수 있도록 고등학교부터 대학교까지 학자금 지원 (공식 인재채용 페이지 복지제도 자녀학자금 지원 항목) — 지원 한도·지원 자녀 수 미기재', 40),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금·상조회 운영, 결혼, 조의, 자녀출산 등 인생의 중요한 날에 경조비와 휴가 등 지원 (공식 인재채용 페이지 복지제도 경조사 지원 항목) — 경조금 금액·휴가 일수 미기재', 41),
  -- ── 휴가 (time_off) — 인재채용 복지제도 ──
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '5년 근속 100만원(+휴가 5일), 10년 근속 300만원(+휴가 7일, 순금 3돈), 20년 근속 1,000만원(+휴가 15일, 순금 3돈) 포상 (공식 인재채용 페이지 복지제도 장기근속 포상 항목) — 휴가 유급 여부·사용 기한 미기재', 50),
  (@comp_id, 'leave_general', '휴가의 날', NULL, 'time_off',
   'est', NULL, TRUE, '휴가의 날을 통해 워라밸 문화 조성 (공식 인재채용 페이지 기업문화 항목) — 연차 사용일인지·일수·유급 여부 미기재', 51),
  -- ── 건강 (health) — 인재채용 복지제도 ──
  (@comp_id, 'health_check', '건강검진 (본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '나와 배우자의 건강을 살필 수 있도록 건강검진 지원 (공식 인재채용 페이지 복지제도 건강관리 지원 항목) — 검진 주기·비용 지원 범위 미기재', 60),
  (@comp_id, 'fitness', '사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장 운영, 직원의 체력 증진과 일상의 활력을 더해줄 다양한 운동기구와 샤워시설 구비 (공식 인재채용 페이지 복지제도 사내 헬스장 운영 항목) — 운영 시간·이용 조건 미기재', 61),
  -- ── 여가 (leisure) — 인재채용 복지제도 · 기업문화 ──
  (@comp_id, 'resort', '휴양시설', NULL, 'leisure',
   'est', NULL, TRUE, '직원들의 휴가생활 편의를 위하여 전국 곳곳에 위치한 고급 휴양시설 확보, 무료 이용 (공식 인재채용 페이지 복지제도 휴양시설 운영 항목) — 이용 횟수·배정 방식 미기재', 70),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '직원의 건전한 취미 활동과 직원 화합을 위한 다양한 동호회 운영, 매월 활동에 따른 지원금 (공식 인재채용 페이지 복지제도 동호회 활동 지원 항목) — 지원금 금액·지원 조건 미기재', 71),
  (@comp_id, 'company_event', '시무식·장기근속 포상식·조직문화 이벤트', NULL, 'leisure',
   'est', NULL, TRUE, '직원이 주인공인 시무식, 장기근속 포상식, 즐겁고 행복한 분위기 조성을 위한 다양한 조직문화 이벤트 (공식 인재채용 페이지 기업문화 항목) — 행사 종류·횟수 미기재', 72),
  -- ── 성장 (growth) — 인재채용 복지제도 ──
  (@comp_id, 'books', '도서지원', NULL, 'growth',
   'est', NULL, TRUE, '역량개발을 위한 도서 무료 지원 (공식 인재채용 페이지 복지제도 도서지원 항목) — 지원 권수·지원 한도 미기재', 80),
  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 · 인재채용 기업문화 ──
  (@comp_id, 'flex_work', '선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용, 선택근무제 사용자 667명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 90),
  (@comp_id, 'family_day', '가정의 날', NULL, 'flexibility',
   'est', NULL, TRUE, '가정의 날을 통해 워라밸 문화 조성 (공식 인재채용 페이지 기업문화 항목) — 운영 요일·운영 방식 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
