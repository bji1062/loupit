-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 시프트업 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://shiftup.co.kr/recruit/benefit.php
-- badge: est
--
-- 참고:
--   정본 = 자기 도메인 채용안내 복리후생 페이지(SSR · 원본 HTML 에 항목 9개 · 렌더 없음).
--   보조 = OpenDART 2026 반기보고서(접수 20260814004160) — 유연근무제 활용 표 · 보상위원회 의안 · 보험가입 주석.
--   귀속 = 법인 자기 도메인 · 자기 공시뿐 · 그룹 · 형제 없음 · 각주 없음.
--   금액 = 금액 행 0(원문에 숫자 없음 · 전 행 정성).
--   제외 = 업무 환경(내용 없는 라벨) · HTML 주석 속 옛 블록(개인별 법인카드 등) · 육아휴직 · 배우자 출산휴가(법정) ·
--          공시 표 시차출퇴근제 · 원격근무제(사용자 0 · 자기 출처 언급 없음) · RSU · 주식매수선택권(재량 부여) · 임원 보수 칸.
--   공고 근거 0행 / 전체 11행 · SORT 섹션 순서 = health · family · perks · compensation(정본 순) · flexibility(공시만).
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 — 최종 11행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('shift_up', '시프트업',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '게임', 'S', 'https://shiftup.co.kr/recruit/benefit.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'shift_up');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://shiftup.co.kr/recruit/benefit.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 공식 채용 페이지 · 2026 반기보고서 ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '건강한 회사생활을 하실 수 있도록 정기적인 건강검진 지원 (공식 채용 페이지 복리후생 건강검진 항목) — 검진 주기·비용 지원 범위 미기재', 10),
  (@comp_id, 'insurance', '단체보험 (상해보험)', NULL, 'health',
   'est', NULL, TRUE, '건강하고 안정적인 회사생활을 위한 상해 보험 지원 (공식 채용 페이지 복리후생 단체보험 항목), 종업원 단체상해보험 가입 (2026 반기보고서 재무제표 주석 보험가입 내용 항목) — 보장 범위·가족 적용 여부 미기재', 11),
  -- ── 가족 (family) — 공식 채용 페이지 ──
  (@comp_id, 'event', '경조 휴가 및 경조금', NULL, 'family',
   'est', NULL, TRUE, '기쁨과 슬픔을 함께하는 마음으로 경조사 지원, 경조 휴가 및 경조금 (공식 채용 페이지 복리후생 경조 휴가 및 경조금 항목) — 경조 대상·휴가 일수·경조금 금액 미기재', 20),
  (@comp_id, 'parenting', '임신/출산 지원', NULL, 'family',
   'est', NULL, TRUE, '새 생명의 탄생을 축하하고 실질적으로 출산/육아에 도움이 되도록 지원 (공식 채용 페이지 복리후생 임신/출산 지원 항목) — 지원 내용·금액 미기재', 21),
  -- ── 생활 · 금융 (perks) — 공식 채용 페이지 ──
  (@comp_id, 'meal', '식비 지원', NULL, 'perks',
   'est', NULL, TRUE, '업무에 필요한 식비 지원 (공식 채용 페이지 복리후생 식비/교통비 지원 항목) — 지원 방식·금액·끼니 미기재', 30),
  (@comp_id, 'transport', '교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '업무에 필요한 교통비 지원 (공식 채용 페이지 복리후생 식비/교통비 지원 항목) — 지원 방식·금액 미기재', 31),
  (@comp_id, 'housing_loan', '사내대출 (생활안정·주택마련)', NULL, 'perks',
   'est', NULL, TRUE, '필요한 곳(생활안정, 주택마련)에 사내대출을 통해 생활안정 지원 (공식 채용 페이지 복리후생 사내대출 항목) — 대출 한도·이율 미기재', 32),
  -- ── 보상 (compensation) — 공식 채용 페이지 · 2026 반기보고서 ──
  (@comp_id, 'holiday_gift', '명절 복지포인트', NULL, 'compensation',
   'est', NULL, TRUE, '풍요로운 명절을 위한 복지포인트 지급 (공식 채용 페이지 복리후생 명절 복지포인트 항목) — 포인트 금액·지급 횟수 미기재', 40),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기간 근속에 감사한 마음을 담아 장기근속 선물 지급 (공식 채용 페이지 복리후생 장기근속 포상 항목) — 근속 기준·선물 내용 미기재', 41),
  (@comp_id, 'incentive', '직원 성과 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '직원 성과 인센티브 지급, 임직원 인센티브 지급 (2026 반기보고서 이사회 내 위원회 보상위원회 2026년 2월 의안 항목) — 지급 대상·지급 기준·지급률 미기재', 42),
  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 ──
  (@comp_id, 'flex_work', '선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용, 선택근무제 사용자 35명 (2026 반기보고서 직원 등 현황 유연근무제 사용 현황 항목, 2026년 6월말 기준) — 대상 직무·사용 조건 미기재', 50)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
