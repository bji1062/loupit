-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DN오토모티브 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.dnautomotive.com/sub/recruitment/personnel.asp
-- badge: est
--
-- 참고:
--   정본은 상장 법인 DN오토모티브(주)의 자기 도메인 www.dnautomotive.com 인재 채용 > 인사제도 페이지다.
--   SSR 이라 원본 HTML 에 복리 후생 블록(Welfare Benefits · 건강 관리 프로그램 · 전문 교육 프로그램 ·
--   Smart Working Culture)이 다 있다. 헤드리스 렌더 · 이미지 판독 불필요.
--   보조 출처 1: 같은 도메인 채용정보 페이지가 링크한 회사 계정 그리팅 채용 사이트
--   dnautomotive.career.greetinghr.com/welfare (인사 제도 > 복리 후생 · SSR) — 정본보다 항목이 많다.
--   보조 출처 2: 같은 도메인 지속가능경영 > ESG 경영 페이지(UN SDGs 건강과 복지 칸).
--   보조 출처 3: 헤더 메뉴의 영문판 인사제도 페이지(건강검진 주기 확인용).
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814001265) 직원 등 현황 — 직원 1,564명,
--   유연근무제 미활용(시차출퇴근 · 선택근무 · 원격근무 사용자 수 모두 없음) — 근무 유연성 행 없음.
--   귀속: 두 페이지 모두 주어가 DN AUTOMOTIVE 단수이고 계열사 · 그룹 공통 단서가 없다. 각주 없음.
--   DN그룹(지주 DN · 형제 DN솔루션즈) 채용 사이트 문장은 쓰지 않았다. 코퍼스 · 대기 폴더에 DN 형제 없음.
--   금액: 식대 1행만 추정(중식 무료 1끼 × 12,000원 × 240일 = 288). 나머지 원문에 원 단위 숫자 없음 —
--   독감접종비 50% 는 비율이라 NULL.
--   제외: 업무 교육(APQP · PM · 리더십 · 워크샵 프로그램 · 입문 · 법정 · 직무역량 교육) ·
--     Refresh 휴가제도(하계 1주 · 동계 1주 휴가 권장 — 권장 휴가, 근거표 판단 요청) ·
--     연구소 사무공간 · 복리후생 규정 운영 · 커리어 개발 관리.
--   공고 근거 0행 / 전체 16행.
--   SORT 섹션 순서: perks 10 · leisure 20 · family 30 · health 40 · growth 50 · work_env 60.
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · Refresh 휴가 권장은 싣지 않음 유지(리드 판정 135) · 항목 페이지 예외 1 · 점검기 중간 인증서(통합 밖 리드 · 등록 집행) — 최종 16행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('dn_automotive', 'DN오토모티브',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '자동차부품', 'D', 'https://www.dnautomotive.com/sub/recruitment/personnel.asp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'dn_automotive');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.dnautomotive.com/sub/recruitment/personnel.asp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활·편의 (perks) — 인사제도 Welfare Benefits · Smart Working Culture, 채용 사이트 복지 시설 · 기타 복지 지원 ──
  (@comp_id, 'housing_loan', '주택자금 지원 (전세자금 대출 이자 지원)', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 지원, 전세자금 대출 이자 지원 (공식 홈페이지 인사제도 복리후생 Welfare Benefits 항목) — 지원 한도·이자 지원율·대상 미기재', 10),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '사내카페 (공식 홈페이지 인사제도 복리후생 Smart Working Culture 항목), 사내 카페 (공식 채용 사이트 인사 제도 복리후생 복지 시설 항목) — 운영 방식·이용 비용 미기재', 11),
  (@comp_id, 'meal', '사내 중식 무료 제공', 288, 'perks',
   'est', '사내 중식 무료 제공, 조식 석식 운영 (공식 채용 사이트 복리후생 복지 시설 항목) — 조식·석식 비용 부담 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정, 조식·석식 제외)', FALSE, NULL, 12),
  (@comp_id, 'commute_subsidy', '통근버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '부산/울산/경남 지역 통근버스 운영 (공식 채용 사이트 인사 제도 복리후생 기타 복지 지원 항목) — 노선·운행 사업장 미기재', 13),
  (@comp_id, 'birthday_gift', '생일 축하 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일 축하 선물, 생일자에게 모바일 상품권 지급 (공식 채용 사이트 인사 제도 복리후생 항목) — 상품권 금액 미기재', 14),

  -- ── 여가 (leisure) — 인사제도 Welfare Benefits, 채용 사이트 Refresh 휴가제도 ──
  (@comp_id, 'resort', '제휴 콘도·숙박시설 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '여가 복지몰 운영, 제휴 콘도 시설 이용지원 (공식 홈페이지 인사제도 복리후생 Welfare Benefits 항목), 복지몰 운영, 제휴 숙박시설 지원 (공식 채용 사이트 인사 제도 복리후생 항목) — 지원 방식·이용 횟수 미기재', 20),
  (@comp_id, 'summer_vacation_subsidy', '하계 휴가비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '하계 휴가비 지원 (공식 채용 사이트 인사 제도 복리후생 Refresh 휴가제도 항목) — 지급 금액·대상 미기재', 21),

  -- ── 가족 (family) — 인사제도 Welfare Benefits, 채용 사이트 가족 복지 지원, ESG 경영 ──
  (@comp_id, 'event', '경조사 지원 (경조금·경조휴가·상조물품)', NULL, 'family',
   'est', NULL, TRUE, '경·조사 지원 (공식 홈페이지 인사제도 복리후생 Welfare Benefits 항목), 경조 휴가 및 경조금, 상조물품 및 화환 지급 (공식 채용 사이트 인사 제도 복리후생 가족 복지 지원 항목) — 경조 사유별 금액·휴가 일수 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원 (공식 홈페이지 인사제도 복리후생 Welfare Benefits 항목), 자녀 대학교 학비 지원 (공식 채용 사이트 인사 제도 복리후생 가족 복지 지원 항목) — 지원 금액·한도·대상 자녀 수 미기재', 31),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 운영 (공식 채용 사이트 인사 제도 복리후생 가족 복지 지원 항목), 직장 어린이집 운영 (공식 홈페이지 ESG 경영 UN SDGs 건강과 복지 항목) — 정원·이용 대상 사업장 미기재', 32),

  -- ── 건강 (health) — 인사제도 건강 관리 프로그램 · Smart Working Culture, 채용 사이트 건강검진 지원 · 복지 시설 ──
  (@comp_id, 'health_check', '건강검진 지원·독감접종비 지원', NULL, 'health',
   'est', NULL, TRUE, '건강 검진 지원 (공식 홈페이지 인사제도 복리후생 건강 관리 프로그램 항목), Providing annual health checkups (영문 홈페이지 인사제도 Health Management Programs 항목), 회사 내에서 건강검진 실시, 독감접종비 50% 지원 (공식 채용 사이트 인사 제도 복리후생 건강검진 지원 항목) — 검진 항목·비용 지원 범위·가족 대상 여부 미기재', 40),
  (@comp_id, 'clinic', '건강증진센터 (물리치료사 상주)', NULL, 'health',
   'est', NULL, TRUE, '건강 상담, 재활 및 물리 치료 (공식 홈페이지 인사제도 복리후생 건강 관리 프로그램 항목), 건강증진센터 운영, 물리치료사 상주하여 재활/물리치료 제공, 건강증진프로그램 실시 (공식 채용 사이트 인사 제도 복리후생 건강검진 지원 항목), 보건관리자 상주, 건강증진센터 운영 (공식 홈페이지 ESG 경영 UN SDGs 건강과 복지 항목) — 운영 시간·이용 대상 사업장 미기재', 41),
  (@comp_id, 'fitness', '사내 피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '체력단련실 (공식 홈페이지 인사제도 복리후생 Smart Working Culture 항목), 사내 피트니스 센터 (공식 채용 사이트 인사 제도 복리후생 복지 시설 항목) — 운영 시간·이용 비용 미기재', 42),

  -- ── 성장·교육 (growth) — 인사제도 인재 개발 체계도 · 전문 교육 프로그램, 채용 사이트 영어&직무 교육 지원 ──
  (@comp_id, 'lang', '영어 교육 지원 (사내 원어민 강사·전화영어)', NULL, 'growth',
   'est', NULL, TRUE, '외국어 교육 (공식 홈페이지 인사제도 인재 개발 체계도 기본 역량 항목), 영어 교육 제공 (같은 페이지 복리후생 전문 교육 프로그램 항목), 사내 원어민 강사 상주하여 주 2회 업무시간에 수업 실시, 전화영어 / 온라인강의 / 오프라인강의 지원 (공식 채용 사이트 인사 제도 복리후생 영어&직무 교육 지원 항목) — 수강 대상·비용 지원 범위 미기재', 50),

  -- ── 업무 환경 (work_env) — 인사제도 Smart Working Culture, 채용 사이트 복지 시설 · 기타 복지 지원, ESG 경영 ──
  (@comp_id, 'lounge', '수면실·사내 라운지', NULL, 'work_env',
   'est', NULL, TRUE, '수면실 (공식 홈페이지 인사제도 복리후생 Smart Working Culture 항목), 사내 카페, 수면실 등 휴식 시설 (공식 채용 사이트 인사 제도 복리후생 복지 시설 항목), 직원 스트레스 완화를 위한 수면실 카페가 설치가 된 사내 라운지 운영 (공식 홈페이지 ESG 경영 UN SDGs 건강과 복지 항목) — 운영 시간·설치 사업장 미기재', 60),
  (@comp_id, 'uniform', '근무복 제공', NULL, 'work_env',
   'est', NULL, TRUE, '입사 시 근무복 제공 (공식 채용 사이트 인사 제도 복리후생 기타 복지 지원 항목) — 추가 지급 주기·수량 미기재', 61)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
