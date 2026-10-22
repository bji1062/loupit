-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한솔제지 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://www.hansolpaper.co.kr/recruit/manage
-- badge: est
--
-- 참고:
--   정본은 상장 법인 한솔제지 자기 도메인 hansolpaper.co.kr 인재채용 > 인사제도 페이지(서버렌더 · 복리후생 낱말 있음).
--   이 페이지에는 항목 목록이 없어 행의 근거는 같은 사이트 지속가능경영 > 자료실(/management/data)의
--   2026 한솔제지 지속가능경영보고서 국문 PDF(2026-06 발행 · 보고 기간 2025년 · 한솔제지 단독 발행 · 주어 「한솔제지는」)다.
--   인쇄 73쪽 임직원 건강 관리 · 81쪽 임직원 심리상담 프로그램 · 84쪽 자기주도 교육 · 86쪽 역량육성 지원제도와 인재 육성 커리큘럼 ·
--   87쪽 조직문화 및 복리후생(주요 복리후생 제도 · 건전한 기업문화) · 88쪽 존중 문화 7요소 표 · 89쪽 임직원 소통(거목협의회).
--   보조 출처: 같은 사이트 사회책임경영 페이지(/management/social) 산업안전 관리실적 기타 항목 ·
--   OpenDART 2026 반기보고서(20260813001710) · 2025 사업보고서 기재정정(20260313001328) 유연근무제도 사용 현황 표.
--   렌더: 서버렌더 HTML + PDF 텍스트 추출(헤드리스 없음). 귀속: 법인 단독 보고서 · 법인 자기 도메인 — 각주 없음.
--   그룹 채용 ATS(hansol.recruiter.co.kr)는 robots 전면 금지라 읽지 않았다. 기등록 형제 한솔케미칼과 문장이 다르다.
--   금액: 원문 숫자는 외국어학원 최대 연간 120만원(한도)뿐 — 20행 전부 BENEFIT_AMT NULL(정성). stated 0 · 추정 0.
--   행 분할: 장기근속 및 정년 퇴직자 대우 → long_service_leave · retirement_support / 교육 → lang · self_development · edu_support · conference.
--   병합: Healing 휴가제(2시간 단위) + 팀장 안식월 → leave_general 한 행 / As One Day · 가족 초청 · 어린이 캠프 · 소통 행사 → company_event 한 행.
--   제외: 법정(출산휴가 · 육아휴직 · 재취업지원서비스 진로설계교육 · 휴게시설 설치 · 근골격계 · 뇌심혈관 예방) · 업무 교육(사내 아카데미 ·
--     온보딩 · 멘토링 · 직무교육 · 사외위탁 · 해외연수 · Junior CDP 직무 Rotation) · 임원 보수 칸 복리후생 · 자유 복장제(복지 코드 없음) ·
--     공시 원격근무제 사용자 수(세 기간 모두 -) · 우리사주조합(주주 표 한 칸뿐).
--   공고 근거 0행 / 전체 20행. 신규 코드 0.
--   SORT 섹션 순서 = 정본에 항목이 없어 보고서 87쪽 주요 복리후생 제도 첫 등장 순, 그 뒤 쪽 순:
--     family 10 · health 20 · time_off 30 · growth 40 · perks 50 · flexibility 60 · leisure 70 · work_env 80.
-- 검증 · 감사 판정 반영(2026-10-22): 유형 mid 를 large 로(판정 170 · OpenDART 공정위공시에 대규모기업집단현황공시 개별회사용 제출 = 공시대상기업집단 한솔 소속) · 반반차 Healing 휴가제와 팀장 안식월 한 행을 2시간 단위 Healing 휴가제 leave_general 과 팀장 안식월제 (조건부) refresh_leave 로 분리 · 82쪽 핵심인재 MBA 를 mba 로 추가 · 73쪽 휴게시설 설치는 산업안전보건법 휴게시설 설치 의무 실적이라 싣지 않음(리드 판정 175) · 참고 블록의 병합 줄과 행 수 20행은 이 판정으로 뒤집힘 — 최종 22행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hansol_paper', '한솔제지',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '제지', 'H', 'https://www.hansolpaper.co.kr/recruit/manage');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hansol_paper');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hansolpaper.co.kr/recruit/manage'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — 2026 지속가능경영보고서 87쪽 주요 복리후생 제도 ──
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '결혼, 출산, 장례 등 경조사에 경조 휴가 및 경조금 지원 (2026 지속가능경영보고서 87쪽 주요 복리후생 제도 경조사 지원 항목) — 경조 사유별 지급 금액·휴가 일수 미기재', 10),
  (@comp_id, 'child_edu', '자녀 학자금 지원 (중·고·대학교)', NULL, 'family',
   'est', NULL, TRUE, '자녀의 중·고등학교 및 대학교 입학금, 수업료, 기성회비 지원 (2026 지속가능경영보고서 87쪽 주요 복리후생 제도 학자금 지원 항목) — 지원 한도·자녀 수 제한 미기재', 11),
  -- ── 건강 (health) — 보고서 87 · 81 · 88 · 73쪽 · 홈페이지 사회책임경영 ──
  (@comp_id, 'medical', '의료비 지원 (본인·배우자·자녀)', NULL, 'health',
   'est', NULL, TRUE, '본인, 배우자, 자녀에 대하여 의료비 지원 (2026 지속가능경영보고서 87쪽 주요 복리후생 제도 의료 지원 항목) — 지원 한도·본인 부담 비율 미기재', 20),
  (@comp_id, 'health_check', '정기 건강검진', NULL, 'health',
   'est', NULL, TRUE, '정기 건강검진 (2026 지속가능경영보고서 87쪽 건전한 기업문화 항목의 일과 삶의 균형 향상 제도) — 검진 항목·검진 주기·비용 지원 범위 미기재', 21),
  (@comp_id, 'mental', 'EAP 심리상담 (임직원·직계 가족)', NULL, 'health',
   'est', NULL, TRUE, '외부 전문기관과 연계한 근로자지원(EAP) 프로그램, 임직원은 물론 직계 가족까지 이용, 직장 내 스트레스 관리부터 개인 생활 문제까지 비대면 상담과 심리검사 해석 상담 (2026 지속가능경영보고서 81쪽 임직원 심리상담 프로그램 항목), 그룹 EAP 전 사업장 대상 스트레스, 건강, 자녀교육 등의 전문 상담 제공 (같은 보고서 88쪽 존중 문화 CONSIDERATION 항목), 정신(심리)건강 증진사업 (공식 홈페이지 사회책임경영 산업안전 관리실적 항목) — 이용 횟수 한도·비용 부담 미기재', 22),
  (@comp_id, 'fitness', '건강관리 프로그램 (체중 관리·신체 기능 강화)', NULL, 'health',
   'est', NULL, TRUE, '체중 관리와 신체 기능 강화를 위한 건강관리 프로그램 운영, 임직원의 신체 활동 증진과 생활습관 개선 지원 (2026 지속가능경영보고서 73쪽 임직원 건강 관리 항목) — 운영 주기·참여 대상 미기재', 23),
  (@comp_id, 'smoking_cessation', '금연프로그램', NULL, 'health',
   'est', NULL, TRUE, '금연프로그램 (공식 홈페이지 사회책임경영 산업안전 관리실적 기타 항목) — 프로그램 내용·참여 대상·지원 방식 미기재', 24),
  -- ── 휴가 (time_off) — 보고서 87 · 88 · 86쪽 ──
  (@comp_id, 'long_service_leave', '장기근속 유급휴가·휴가비', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 임직원에 대하여 유급휴가 및 휴가비 지급 (2026 지속가능경영보고서 87쪽 주요 복리후생 제도 장기근속 및 정년 퇴직자 대우 항목) — 근속 연수 기준·휴가 일수·휴가비 금액 미기재', 30),
  (@comp_id, 'leave_general', '2시간 단위 Healing 휴가제', NULL, 'time_off',
   'est', NULL, TRUE, 'Healing 휴가제 2시간 단위 휴가 사용 가능 (2026 지속가능경영보고서 88쪽 존중 문화 CONSIDERATION 항목) — 사용 한도·신청 방식 미기재', 31),
  (@comp_id, 'refresh_leave', '팀장 안식월제 (조건부)', NULL, 'time_off',
   'est', NULL, TRUE, '팀장 안식월 제도 운영 (2026 지속가능경영보고서 86쪽 팀장 CDP 체계구축 항목), 팀장 안식월제 (같은 보고서 87쪽 건전한 기업문화 항목) — 안식월 기간·유급 여부·부여 조건 미기재', 32),
  -- ── 성장 (growth) — 보고서 87 · 86 · 84쪽 ──
  (@comp_id, 'retirement_support', '정년퇴직자 유급휴가·휴가비', NULL, 'growth',
   'est', NULL, TRUE, '정년퇴직자에 대하여 유급휴가 및 휴가비 지급 (2026 지속가능경영보고서 87쪽 주요 복리후생 제도 장기근속 및 정년 퇴직자 대우 항목) — 휴가 일수·휴가비 금액·부여 시기 미기재', 40),
  (@comp_id, 'lang', '외국어학원·외국어검정 지원', NULL, 'growth',
   'est', NULL, TRUE, '외국어학원 지원 사내 어학등급에 따라 최대 연간 120만원 지원, 외국어검정 지원 연간 2회 지원 (2026 지속가능경영보고서 86쪽 역량육성 지원제도 교육비 항목), 외국어 지원(학습, 검정) 상시운영 (같은 쪽 인재 육성 커리큘럼 항목) — 대상 과정·검정 비용 지원 범위 미기재', 41),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격증 지원 상시운영 (2026 지속가능경영보고서 86쪽 인재 육성 커리큘럼 항목), 자격증 취득 지원 (같은 보고서 84쪽 자기주도 교육 항목) — 대상 자격·비용 지원 범위 미기재', 42),
  (@comp_id, 'edu_support', '사이버교육·독서통신·학습동아리', NULL, 'growth',
   'est', NULL, TRUE, '사이버교육 상시운영, 학습동아리 상반기(1~5월)·하반기(6~11월) 운영 (2026 지속가능경영보고서 86쪽 인재 육성 커리큘럼 항목), 독서통신, 학습동아리(스펀지), 스마트러닝 (같은 보고서 84쪽 자기주도 교육 항목) — 과정 범위·비용 지원 범위 미기재', 43),
  (@comp_id, 'conference', '컨퍼런스 참여·외부교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '컨퍼런스 참여 (2026 지속가능경영보고서 84쪽 자기주도 교육 항목), 외부교육 지원 (같은 보고서 86쪽 역량육성 지원제도 교육비 항목) — 지원 한도·대상 행사 기준 미기재', 44),
  (@comp_id, 'career', '자율 직무 선택제', NULL, 'growth',
   'est', NULL, TRUE, '자율 직무 선택제를 운영하여 임직원에게 직무 선택의 기회 제공, 직무 이동 과정에서 불이익이 발생하지 않도록 제도적으로 보장 (2026 지속가능경영보고서 86쪽 인재 역량 강화 항목) — 신청 요건·선발 기준 미기재', 45),
  (@comp_id, 'mba', '핵심인재 MBA (임원·팀장 대상)', NULL, 'growth',
   'est', NULL, TRUE, '핵심인재(임원/팀장)육성 MBA (2026 지속가능경영보고서 82쪽 한솔경영체계 인재육성 체계 항목) — 선발 기준·과정 내용·학위 여부·비용 지원 범위 미기재', 46),
  -- ── 생활 · 금융 (perks) — 보고서 87쪽 ──
  (@comp_id, 'housing_support', '주거비 지원', NULL, 'perks',
   'est', NULL, TRUE, '안정적 주거 환경 조성을 위한 주거비용 지원 (2026 지속가능경영보고서 87쪽 주요 복리후생 제도 주거비 지원 항목), 주거 지원금 (같은 쪽 건전한 기업문화 항목) — 지원 대상·지원 금액·지원 방식 미기재', 50),
  (@comp_id, 'welfare_point', '복지 포인트', NULL, 'perks',
   'est', NULL, TRUE, '여가생활, 자기계발 등에 사용할 수 있는 복지 포인트 지급 (2026 지속가능경영보고서 87쪽 주요 복리후생 제도 복지 포인트 항목) — 포인트 금액·지급 주기 미기재', 51),
  -- ── 근무 유연성 (flexibility) — 보고서 87쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (자율 출퇴근제·시차출퇴근제·선택근무제)', NULL, 'flexibility',
   'est', NULL, TRUE, '자율 출퇴근제를 포함한 유연근무제 도입 (2026 지속가능경영보고서 87쪽 건전한 기업문화 항목), 시차출퇴근제 사용자 128명, 선택근무제 사용자 447명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 제도별 적용 대상·사용 조건 미기재', 60),
  -- ── 여가 · 행사 (leisure) — 보고서 87 · 88 · 89쪽 ──
  (@comp_id, 'company_event', 'As One Day·가족 초청 행사·어린이 캠프', NULL, 'leisure',
   'est', NULL, TRUE, 'As One Day 스포츠 및 문화행사 분기별 1회 실시, 가족친화프로그램 연 1회의 가족 초청 행사 정례화 (2026 지속가능경영보고서 88쪽 존중 문화 항목), 어린이 캠프 (같은 보고서 87쪽 건전한 기업문화 항목), 혹서기 아이스크림 현장 지원, 커피차 및 팥빙수 이벤트, 어린이날 행사, 명절맞이 행사, 시네마 데이 등 현장 지원과 소통 프로그램 (같은 보고서 89쪽 임직원 소통 항목) — 참가 대상·비용 부담 미기재', 70),
  -- ── 근무 환경 (work_env) — 보고서 89쪽 ──
  (@comp_id, 'dormitory', '기숙사 (장항·대전·천안공장)', NULL, 'work_env',
   'est', NULL, TRUE, '2025년 4월부터 11월까지 장항, 대전, 천안공장의 기숙사 시설 개선 (2026 지속가능경영보고서 89쪽 임직원 소통 거목협의회 항목) — 입주 대상·이용료 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
