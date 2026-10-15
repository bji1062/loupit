-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한국카본 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.hcarbon.com/ko/recruit/system.do
-- badge: est
--
-- 참고:
--   정본은 상장 법인 ㈜한국카본의 자기 도메인 www.hcarbon.com Recruit > HR System 페이지다.
--   SSR 이라 원본 HTML 에 보상제도 블록과 복리후생 12칸(ul.system__benefits)이 다 있다. 렌더 · 이미지 판독 불필요.
--   보조 출처: 같은 도메인 ESG > Social > Human Rights Management 페이지 임직원 현황 공개 탭의
--   ㈜한국카본 복지/교육 문단(기준일 2025-12-31) · 같은 도메인 영문 HR System 페이지(헤더 ENG 메뉴) ·
--   OpenDART 2026 반기보고서(접수 20260814000604) 직원 등 현황 유연근무제도 사용 현황 표.
--   직원 919명(2026-06-30 반기보고서) · 858명(ESG 페이지 2025-12-31) — 1,000인 미만.
--   귀속: 페이지 주어가 한국카본 단수이고 그룹 · 계열사 공통 단서가 없다. ESG 문단 주어는 ㈜한국카본.
--   형제(한국화이바 등) 문장 혼입 없음 — 코퍼스 · 대기 폴더에 같은 그룹 법인 없음. 각주 없음.
--   금액: 원문에 원 단위 숫자 0건. 금액 행은 식대 1행뿐(중식 1끼 × 12,000원 × 240일 = 288, 추정).
--   제외: 법정(4대 보험 · 연차 · 반차 · 육아휴직 · 배우자 출산휴가 사용자 수 표) · 안전화(보호구) ·
--     업무 교육(입문 OJT · 직급별 공통 · 직무 역량 향상) · 기본연봉(임금) · 임원 보수 칸 상여 문장 ·
--     원격근무제(공시 사용자 수 -, 회사 복지 문장 없음).
--   공고 근거 0행 / 전체 18행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(compensation 10 · leisure 20 · work_env 30 · family 40 ·
--     flexibility 50 · perks 60 · time_off 70), ESG 페이지에만 있는 growth 80.
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 식대 행 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 18행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hankuk_carbon', '한국카본',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '화학', 'H', 'https://www.hcarbon.com/ko/recruit/system.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hankuk_carbon');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hcarbon.com/ko/recruit/system.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 공식 채용 페이지 HR System 보상제도 · 복리후생 선물 지급 ──
  (@comp_id, 'incentive', '성과연봉 (인센티브)', NULL, 'compensation',
   'est', NULL, TRUE, '성과 중심의 차등 보상 시스템 운영, 성과에 따른 변동 인센티브를 통한 보상 (공식 채용 페이지 HR System 보상제도 성과연봉 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'holiday_gift', '명절·창립기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절, 창립기념일 선물 지급 (공식 채용 페이지 HR System 복리후생 선물 지급 항목) — 선물 품목·금액 미기재', 11),
  (@comp_id, 'long_service_bonus', '장기근속사원 선물', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속사원 선물 지급 (공식 채용 페이지 HR System 복리후생 선물 지급 항목) — 근속 기준·선물 품목 미기재', 12),

  -- ── 여가 (leisure) — 공식 채용 페이지 HR System 복리후생 ──
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영 (공식 채용 페이지 HR System 복리후생 동호회 지원 항목) — 지원 금액·동호회 종류 미기재', 20),
  (@comp_id, 'resort', '콘도·리조트 이용권', NULL, 'leisure',
   'est', NULL, TRUE, '콘도·리조트 이용권 (공식 채용 페이지 HR System 복리후생 생활편의 지원 항목) — 이용 횟수·본인 부담 미기재', 21),
  (@comp_id, 'travel_support', '국내·외 배낭여행비용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '국내·외 배낭여행비용 지원 (공식 채용 페이지 HR System 복리후생 리프레시 항목) — 지원 금액·대상·선발 여부 미기재', 22),

  -- ── 근무환경 (work_env) — 공식 채용 페이지 HR System 복리후생 ──
  (@comp_id, 'uniform', '근무복 제공 (일부 직종)', NULL, 'work_env',
   'est', NULL, TRUE, '근무복 제공, 일부 직종에 한함 (공식 채용 페이지 HR System 복리후생 의복 지원 항목) — 대상 직종 미기재', 30),
  (@comp_id, 'dormitory', '기숙사 운영 (일부 지역)', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 운영, 일부 지역에 한함 (공식 채용 페이지 HR System 복리후생 주거 지원 항목), 기숙사 제공 (공식 ESG 인권경영 페이지 복지/교육 항목) — 운영 지역·입주 조건 미기재', 31),

  -- ── 가족 (family) — 공식 채용 페이지 HR System 복리후생 · ESG 인권경영 페이지 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지급 (공식 채용 페이지 HR System 복리후생 학자금 지원 항목), 자녀 학자금 지원 (공식 ESG 인권경영 페이지 복지/교육 항목) — 지원 학령·금액 한도 미기재', 40),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금, 경조휴가, 화환, 상조용품 지원 (공식 채용 페이지 HR System 복리후생 경조사 지원 항목), 경조 휴가/경조금 지급 (공식 ESG 인권경영 페이지 복지/교육 항목) — 경조 기준·금액·휴가 일수 미기재', 41),

  -- ── 근무 유연성 (flexibility) — 공식 채용 페이지 HR System 복리후생 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 실시, 7시부터 9시까지 출근 시간 조정 가능, 일부 지역에 한함 (공식 채용 페이지 HR System 복리후생 유연근무제 실시 항목), 시차출퇴근제·선택근무제 (2026 반기보고서 유연근무제도 사용 현황 항목) — 적용 지역·대상 직무 미기재', 50),

  -- ── 생활 편의 (perks) — 공식 채용 페이지 HR System 복리후생 ──
  (@comp_id, 'commute_subsidy', '통근버스 운행 (밀양 지역)', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운행, 밀양 지역 (공식 채용 페이지 HR System 복리후생 교통편 지원 항목), 통근버스 운행 (공식 ESG 인권경영 페이지 복지/교육 항목) — 노선·운행 시간 미기재', 60),
  (@comp_id, 'meal', '중식(비) 제공', 288, 'perks',
   'est', '중식(비) 제공 (공식 채용 페이지 HR System 복리후생 생활편의 지원 항목) — 식대 단가·사내 식당 여부 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 61),

  -- ── 휴가 (time_off) — 공식 채용 페이지 HR System 복리후생 · ESG 인권경영 페이지 ──
  (@comp_id, 'birthday_leave', '기념일(패밀리)데이', NULL, 'time_off',
   'est', NULL, TRUE, '기념일(패밀리)데이 시행 (공식 채용 페이지 HR System 복리후생 리프레시 항목), anniversary/family day leave (공식 영문 채용 페이지 Employee Benefits Refresh Programs 항목) — 기념일 범위·휴가 일수·유급 여부 미기재', 70),
  (@comp_id, 'refresh_leave', 'Refresh 휴가 (유급 3일)', NULL, 'time_off',
   'est', NULL, TRUE, 'Refresh 휴가, 유급 3일 (공식 채용 페이지 HR System 복리후생 휴가제도 항목) — 부여 주기·사용 조건 미기재', 71),
  (@comp_id, 'leave_general', '2시간 단위 휴가 · Bonus 휴가 제도', NULL, 'time_off',
   'est', NULL, TRUE, '반일 휴가의 절반 단위 휴가(quarter-day), Bonus 휴가 제도 운영 (공식 채용 페이지 HR System 복리후생 휴가제도 항목) — Bonus 휴가 부여 일수·부여 조건 미기재', 72),
  (@comp_id, 'summer_leave', '하계 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계 휴가 (공식 ESG 인권경영 페이지 복지/교육 항목) — 연차 사용일인지·일수·유급 여부 미기재', 73),

  -- ── 성장 (growth) — 공식 ESG 인권경영 페이지 ──
  (@comp_id, 'edu_support', '자기계발 사내외 교육·교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '임직원의 자기계발을 위한 사내외 교육 주기적 실시, 교육비 지원 (공식 ESG 인권경영 페이지 복지/교육 항목) — 교육 과정·지원 범위 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
