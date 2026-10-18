-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 남양유업 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://company.namyangi.com/ko/company/contents/25
-- badge: est
--
-- 참고:
--   정본 = 자기 도메인 회사 사이트 기업문화 페이지(가족친화제도 · 기타 복지제도 목록, SSR, 날짜 없음).
--   보조 = 2025 남양유업 ESG 정보공개(자기 도메인 ESG자료 게시, PDF 2026-06-30 작성, 인쇄 26쪽 = PDF 28쪽 근로환경 가족친화제도 ·
--     임직원 교육프로그램) — 발행일이 있는 더 새 판이라 정본 페이지에 없는 항목(장기근속 포상 · 거주안정지원금 · 생일 휴가 ·
--     F5데이 PC-OFF · 육아휴직 +1년 · 희망 교육 비용과 교재 서적 구입)을 받친다.
--   공시 = 2026 반기보고서(20260814003731) · 2025 사업보고서(20260319001235) 유연근무제도 사용 현황 표(시차출퇴근제 사용자 수).
--   귀속 = 법인 단독(남양유업 자기 도메인 · 남양유업 발행 보고서 · 남양유업 공시) — 각주 없음. 기등록 형제 없음.
--   시점 = 2024 한앤코 인수 뒤 현 경영진 체제의 현행 페이지 · 2026-06 발행 보고서만 사용(옛 경영진 시절 자료 미사용).
--   금액 = 금액 행 없음(원문에 금액 숫자 없음 — 전 행 정성).
--   제외 = 법정(임신기 단축근무 · 임신기 휴직제도 · 난임치료 휴가(유급) · 유산 휴가(유급) · 태아검진휴가(유급) · 출산휴가(본인, 배우자) ·
--     모성보호 지원제도) · 대응 코드 없음(자율복장제도 · 현지 출퇴근 제도 활성화) · 본인 휴가 사용 장려(징검다리 휴가 활성화) ·
--     업무 교육(법정 교육 · 신입 경력 Skill-up · 평가자 · 직무향상 교육 표) · 급여(신입사원 초봉).
--   공고 근거 0행 / 전체 21행(채용 공고 이미지의 복리후생안내는 대조용).
--   SORT 섹션 = family 10 · flexibility 20 · compensation 30 · perks 40 · time_off 50 · leisure 60 · health 70 · growth 80(보고서에만).
-- 검증 · 감사 판정 반영(2026-10-18): 재택근무제 remote_work 서술에 공시 원격근무제 다섯 기간 사용자 수 - 와 ESG 정보공개 26쪽 출처를 더함(맨 칩 유지) · 하기 휴가 summer_leave 꼬리에 별도 부여 여부 미기재 · 현지 출퇴근 제도는 싣지 않음(리드 판정 155) — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('namyang_dairy', '남양유업',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '식품', 'N', 'https://company.namyangi.com/ko/company/contents/25');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'namyang_dairy');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://company.namyangi.com/ko/company/contents/25'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — 기업문화 페이지 가족친화제도 · 2025 ESG 정보공개 26쪽 ──
  (@comp_id, 'event', '결혼축하금·신혼여행 유급휴가', NULL, 'family',
   'est', NULL, TRUE, '결혼축하금 지급, 신혼여행 유급휴가(7일) (공식 기업문화 페이지 가족친화제도 결혼 항목, 2025 ESG 정보공개 26쪽 가족친화제도 결혼 항목) — 축하금 금액·다른 경조사 지원 미기재', 10),
  (@comp_id, 'parenting', '임신·출산·입학 축하 지원', NULL, 'family',
   'est', NULL, TRUE, '축하파티 및 선물 증정(임신), 출산축하금 지급, 제품지원(분유 등), 입학축하금(초중고), 육아휴직 +1년(법적의무사항 +1년) (2025 ESG 정보공개 26쪽 생애주기별 맞춤 복지제도 임신·출산·육아·교육 항목, 공식 기업문화 페이지 가족친화제도 항목) — 축하금 금액·선물 내용 미기재', 11),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원(유치원/초중고/대학등록금) (공식 기업문화 페이지 가족친화제도 교육 항목, 2025 ESG 정보공개 26쪽 교육 항목) — 지원 금액·한도·자녀 수 미기재', 12),
  -- ── 근무 유연성 (flexibility) — 기업문화 페이지 육아 · 근무지원 · 2025 ESG 정보공개 26쪽 · 공시 ──
  (@comp_id, 'remote_work', '재택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무제(가족친화제도 육아 항목), 재택근무제도(기타 복지제도 근무지원 항목) (공식 기업문화 페이지), 재택근무제(생애주기별 맞춤 복지제도 육아 항목) (2025 ESG 정보공개 26쪽), 원격근무제(재택근무 포함) 사용자 수 2023년~2026년 상반기 모두 - (2025 사업보고서 · 2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 20),
  (@comp_id, 'flex_work', '유연근무제 (선택적 시차출근)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 (선택적 시차출근)(가족친화제도 육아 항목), 유연 근무제도(기타 복지제도 근무지원 항목) (공식 기업문화 페이지), 시차출퇴근제 사용자 수 당반기 141명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 출퇴근 시간대·대상 미기재', 21),
  (@comp_id, 'family_day', '패밀리데이(F5 day)', NULL, 'flexibility',
   'est', NULL, TRUE, '패밀리데이(F5 day)(마지막주 금요일 단축근무) (공식 기업문화 페이지 가족친화제도 육아 항목), F5데이 (2025 ESG 정보공개 26쪽 여가지원 항목) — 단축 시간 미기재', 22),
  (@comp_id, 'pc_off', 'PC-OFF제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF제도 (2025 ESG 정보공개 26쪽 유연 근무 및 건강·여가 지원 여가지원 항목) — 적용 시각·대상 미기재', 23),
  -- ── 보상 (compensation) — 기업문화 페이지 근무지원 · 2025 ESG 정보공개 26쪽 ──
  (@comp_id, 'excellence_award', '모범사원 포상제도(해외연수)', NULL, 'compensation',
   'est', NULL, TRUE, '모범사원 포상제도(해외연수) (공식 기업문화 페이지 기타 복지제도 근무지원 항목, 2025 ESG 정보공개 26쪽 근무지원 항목) — 선정 기준·포상 규모 미기재', 30),
  (@comp_id, 'long_service_bonus', '장기근속 포상제도', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상제도 (2025 ESG 정보공개 26쪽 유연 근무 및 건강·여가 지원 근무지원 항목) — 근속 기준·포상 내용 미기재', 31),
  -- ── 생활 · 주거 (perks) — 기업문화 페이지 근무지원 · 2025 ESG 정보공개 26쪽 ──
  (@comp_id, 'housing_loan', '주택자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 지원 (공식 기업문화 페이지 기타 복지제도 근무지원 항목, 2025 ESG 정보공개 26쪽 근무지원 항목) — 지원 방식·한도·대상 미기재', 40),
  (@comp_id, 'housing_support', '거주안정지원금', NULL, 'perks',
   'est', NULL, TRUE, '거주안정지원금 제도 (2025 ESG 정보공개 26쪽 유연 근무 및 건강·여가 지원 근무지원 항목) — 지급 대상·금액 미기재', 41),
  -- ── 휴가 (time_off) — 기업문화 페이지 여가지원 · 2025 ESG 정보공개 26쪽 ──
  (@comp_id, 'refresh_leave', 'Refresh 휴가', NULL, 'time_off',
   'est', NULL, TRUE, 'Refresh 휴가 활성화 (공식 기업문화 페이지 기타 복지제도 여가지원 항목, 2025 ESG 정보공개 26쪽 여가지원 항목) — 휴가 일수·부여 조건 미기재', 50),
  (@comp_id, 'summer_leave', '하기 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하기 휴가 (공식 기업문화 페이지 기타 복지제도 여가지원 항목, 2025 ESG 정보공개 26쪽 여가지원 항목) — 별도 부여 여부·휴가 일수·유급 여부 미기재', 51),
  (@comp_id, 'birthday_leave', '생일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '생일 휴가 (2025 ESG 정보공개 26쪽 유연 근무 및 건강·여가 지원 여가지원 항목) — 휴가 일수 미기재', 52),
  -- ── 여가 (leisure) — 기업문화 페이지 여가지원 · 2025 ESG 정보공개 26쪽 ──
  (@comp_id, 'summer_vacation_subsidy', '하기 휴가비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비 지원 (공식 기업문화 페이지 기타 복지제도 여가지원 하기 휴가 및 휴가비 지원 항목, 2025 ESG 정보공개 26쪽 여가지원 항목) — 지급 금액·시기 미기재', 60),
  (@comp_id, 'resort', '하기 휴양소 연중 이용', NULL, 'leisure',
   'est', NULL, TRUE, '하기 휴양소 연중 이용 (공식 기업문화 페이지 기타 복지제도 여가지원 항목, 2025 ESG 정보공개 26쪽 여가지원 항목) — 휴양소 위치·이용 비용 미기재', 61),
  (@comp_id, 'club', '써클활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '써클활동 및 기타 행사비 지원 (공식 기업문화 페이지 기타 복지제도 여가지원 항목, 2025 ESG 정보공개 26쪽 여가지원 항목) — 지원 금액·행사 종류 미기재', 62),
  -- ── 건강 (health) — 기업문화 페이지 건강지원 · 2025 ESG 정보공개 26쪽 ──
  (@comp_id, 'health_check', '근로자 종합검진 지원', NULL, 'health',
   'est', NULL, TRUE, '근로자 종합검진 지원 (공식 기업문화 페이지 기타 복지제도 건강지원 항목, 2025 ESG 정보공개 26쪽 건강지원 항목) — 검진 주기·가족 포함 여부 미기재', 70),
  (@comp_id, 'fitness', '사내 피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '사내 피트니스 센터 운영 (공식 기업문화 페이지 기타 복지제도 건강지원 항목, 2025 ESG 정보공개 26쪽 건강지원 항목) — 운영 사업장·이용 시간 미기재', 71),
  -- ── 성장 (growth) — 2025 ESG 정보공개 26쪽 임직원 교육프로그램 ──
  (@comp_id, 'edu_support', '희망 교육 비용 지원', NULL, 'growth',
   'est', NULL, TRUE, '개별적으로 희망하는 교육에 대한 비용 지원, 온라인과 오프라인 교육 수강 (2025 ESG 정보공개 26쪽 임직원 교육프로그램 항목) — 지원 한도·대상 과정 미기재', 80),
  (@comp_id, 'books', '교재 및 서적 구입 지원', NULL, 'growth',
   'est', NULL, TRUE, '교재 및 서적 구입 (2025 ESG 정보공개 26쪽 임직원 교육프로그램 희망 교육 비용 지원 항목) — 지원 한도 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
