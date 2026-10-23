-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK실트론 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://www.sksiltron.com/ko/esg/social.do
-- badge: est
--
-- 참고:
--   정본 = 자기 도메인 ESG Factbook 사회 페이지(SSR · 발행일 표기 없음 · 정량 데이터 2021~2023) ·
--   주 출처 = 자기 도메인 2026 지속가능경영보고서(PDF 94쪽 · 2026-09 작성 · 보고 기간 2025-01-01~2025-12-31 일부 2026 상반기 ·
--   보고 범위 SK실트론 국내외 전 사업장 · 사회적 가치만 행복채움 포함) · 보조 = OpenDART 2026 반기보고서(20260814001582) ·
--   2025 사업보고서(20260331003949) 유연근무제도 사용 현황 표 · 렌더 없음(원본 HTML · PDF 텍스트 · 공시 XML).
--   귀속: 전 행 이 법인 자기 발행 단독 보고서 · 자기 도메인 페이지 · 이 법인 공시 — 각주 없음.
--   mySUNI 는 보고서가 그룹 교육 플랫폼이라 적지만 이 법인 보고서 문장이라 각주 없음.
--   SK Careers(그룹 통합 채용)와 recruiter.co.kr 채용 호스트(robots 전면 금지)는 쓰지 않음.
--   금액: 금액 행 0 — Refresh Point 금액 · 암케어 물품 140만 원(조건부 1회성)은 NULL.
--   제외: 법정(임산부 단축 근무 · 육아기 근로시간 단축 · 태아검진 휴가 · 임신 휴직 · 일반/특수검진 · 법정 틀 연 6일 ·
--   재취업지원 교육과 퇴직 예정자 커리어 상담 — 직원 3,624명) · 업무 교육(입문 · 리더십 · Growing College · DT · AI 과정) ·
--   보상휴가 없음 · 노사 안건 중 명절상여 통상임금 반영(임금) · 식사개선 TF(내용 없음) · 사내 커피 전문점 사진 캡션.
--   공고 근거 0행 / 전체 26행 · SORT 섹션 순서 = 정본 페이지 등장 순 health · flexibility · time_off · family ·
--   work_env · leisure · growth, 보조 출처 전용 perks · compensation 은 끝.
-- 검증 · 감사 판정 반영(2026-10-23): 피트니스 행에서 혈당 · 수면 · 절주 프로그램을 걷어 운동 몫만 · 입학기 자녀 돌봄 휴직 서술에 초등을 살림 · 난임치료 휴가 유급 3일 행은 2026-11-27 법 개정 뒤 상회분이 사라져 그날 삭제 대상 · 항목 페이지 예외 3(통합 밖 리드 집행) · 참고 블록의 공고 근거 0행 / 전체 26행은 전체 28행 — 최종 28행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sk_siltron', 'SK실트론',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '반도체소재', 'S', 'https://www.sksiltron.com/ko/esg/social.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_siltron');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.sksiltron.com/ko/esg/social.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — ESG Factbook 사회 페이지 · 2026 지속가능경영보고서 36~37쪽 · 47쪽 ──
  (@comp_id, 'clinic', '건강관리실·간호사 순회 건강 상담', NULL, 'health',
   'est', NULL, TRUE, '사업장별 전문 보건인력이 상주하는 건강관리실 운영 (ESG Factbook 사회 페이지 구성원 건강 항목), 간호사 순회 캠페인으로 전 사업장·서울 사무소 방문 혈압·혈당 측정 및 1:1 건강 상담 (2026 지속가능경영보고서 36쪽 근골격계 질환 예방 활동 항목) — 운영 시간·진료 범위 미기재', 10),
  (@comp_id, 'health_check', '종합검진 (만 35세 이상)·여성 정밀검진·생애 전환기 검진', NULL, 'health',
   'est', NULL, TRUE, '만 35세 이상 구성원 종합검진, 여성 정밀검진 프로그램(근속 7년 이상), 생애 전환기 검진 프로그램(만 40세 심장정밀, 만 50세 뇌정밀 검사) (ESG Factbook 사회 페이지 건강증진 프로그램 운영 항목) — 검진 주기·비용 지원 범위 미기재', 11),
  (@comp_id, 'mental', '심리상담실', NULL, 'health',
   'est', NULL, TRUE, '심리 상담실 활용 힐링 프로그램 운영 (2026 지속가능경영보고서 47쪽 신체적/정신적 건강 증진 항목), 사내 대면/비대면 심리 상담 운영, 구미정신건강복지센터를 통한 사외 심리상담 (같은 보고서 37쪽 마음 건강 관리 항목) — 상담 횟수·이용 비용 미기재', 12),
  (@comp_id, 'fitness', '행복동 피트니스 센터·체력증진 프로그램', NULL, 'health',
   'est', NULL, TRUE, '행복동 피트니스 센터 활용 건강 증진 프로그램 실행 (2026 지속가능경영보고서 47쪽 신체적/정신적 건강 증진 항목), 체력증진 프로그램 운영과 운동 및 다이어트를 통한 건강 개선 지원 (같은 보고서 37쪽 신체 건강 관리 · 다이어트/근력강화 항목) — 이용 시간·이용 비용 미기재', 13),
  (@comp_id, 'smoking_cessation', '금연클리닉', NULL, 'health',
   'est', NULL, TRUE, '금연클리닉을 통한 생활습관 개선 및 보조제 지원 (2026 지속가능경영보고서 37쪽 금연 프로그램 항목) — 운영 기간·참가 대상 미기재', 14),
  (@comp_id, 'medical', '암케어 서비스', NULL, 'health',
   'est', NULL, TRUE, '암 발병 구성원 대상 대형병원 신속 진료 예약·병원 진료 치료 동행, 암 치료 후 면역강화물품 제공(140만 원) (2026 지속가능경영보고서 37쪽 암케어 서비스 항목) — 의료비 지원 여부 미기재', 15),

  -- ── 근무 유연성 (flexibility) — 2026 지속가능경영보고서 47쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제·Happy Friday', NULL, 'flexibility',
   'est', NULL, TRUE, '사무기술직은 유연근무제를 도입해 업무 특성과 상황을 고려한 자율적인 출퇴근, 매월 두 번째 금요일 Happy Friday 운영, 기능직 4조 2교대 근무제로 근무 일수 감축 (2026 지속가능경영보고서 47쪽 업무특성별 맞춤형 근무제도 항목), 선택근무제 사용자 2026년 반기 1,255명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 정산 기간·Happy Friday 운영 방식 미기재', 20),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 2026년 반기 17명, 2025년 99명, 2024년 52명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 21),
  (@comp_id, 'family_day', 'Smart Day (매주 수요일 정시퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '매주 수요일을 Smart Day로 지정해 정시퇴근 장려, 사무직 대상 (2026 지속가능경영보고서 47쪽 업무특성별 맞춤형 근무제도 항목) — 퇴근 시각·적용 사업장 미기재', 22),

  -- ── 휴가 (time_off) — 2026 지속가능경영보고서 47쪽 · ESG Factbook 사회 페이지 ──
  (@comp_id, 'birthday_leave', '생일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연차 외의 약정 휴가로 생일 휴가 부여 (2026 지속가능경영보고서 47쪽 업무별 맞춤형 근무제도 공통 항목) — 휴가 일수·유급 여부 미기재', 30),
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연차 외의 약정 휴가로 하계휴가 부여 (2026 지속가능경영보고서 47쪽 업무별 맞춤형 근무제도 공통 항목) — 휴가 일수·사용 시기 미기재', 31),
  (@comp_id, 'long_service_leave', '장기근속 포상 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연차 외의 약정 휴가로 장기근속 포상 휴가 부여 (2026 지속가능경영보고서 47쪽 업무별 맞춤형 근무제도 공통 항목, ESG Factbook 사회 페이지 일과 삶의 균형 실현 항목) — 근속 기준·휴가 일수 미기재', 32),
  (@comp_id, 'leave_general', '재량 휴가 (사무직)', NULL, 'time_off',
   'est', NULL, TRUE, '사무직 재량 휴가 부여 (2026 지속가능경영보고서 47쪽 업무별 맞춤형 근무제도 사무직 항목) — 휴가 일수·부여 조건 미기재', 33),

  -- ── 가족 (family) — 2026 지속가능경영보고서 43쪽 · ESG Factbook 사회 페이지 ──
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, 'SK실트론 어린이집 운영 (ESG Factbook 사회 페이지 모성 보호 제도 항목), 사내 어린이집의 장기 운영 (2026 지속가능경영보고서 43쪽 여성 인력 성장 지원 항목) — 정원·이용 대상 미기재', 40),
  (@comp_id, 'parenting', '자녀 입학·출산 축하금·입학기 자녀 돌봄 휴직', NULL, 'family',
   'est', NULL, TRUE, '자녀 입학 및 출산 축하금 지급, 초등 입학기 자녀 돌봄 휴직 도입(법정 육아휴직 외 최대 1년 추가 사용 가능) (2026 지속가능경영보고서 43쪽 생애 주기별 가족친화 제도 항목) — 축하금 금액·돌봄 휴직 중 급여 여부 미기재', 41),
  (@comp_id, 'fertility_support', '난임치료 휴가 유급 3일 (법정 유급 2일에 1일 추가)', NULL, 'family',
   'est', NULL, TRUE, '난임치료 휴가 운영, 유급 3일(법정 유급 2일에 1일 추가) (2026 지속가능경영보고서 43쪽 생애 주기별 가족친화 제도 항목) — 시술비 지원 여부 미기재', 42),

  -- ── 근무 환경 (work_env) — ESG Factbook 사회 페이지 · 2026 지속가능경영보고서 43쪽 ──
  (@comp_id, 'nap_room', '맘스라운지 (Mom’s Lounge)', NULL, 'work_env',
   'est', NULL, TRUE, 'Mom’s Lounge 운영·환경 개선 (ESG Factbook 사회 페이지 모성 보호 제도 항목), 맘스라운지 환경 개선 등 보육·휴식 인프라 확충 (2026 지속가능경영보고서 43쪽 여성 인력 성장 지원 항목) — 설치 사업장·시설 구성 미기재', 50),

  -- ── 여가 · 행사 (leisure) — 2026 지속가능경영보고서 41쪽 · 47쪽 · ESG Factbook 사회 페이지 ──
  (@comp_id, 'company_event', '가족 초청 행사·소확행 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '구성원 가족 회사 초청 행사, 가족과 함께하는 소확행 프로그램 운영 (2026 지속가능경영보고서 47쪽 일과 여가 제도 항목), 플라워·비누 만들기 등 가족과 함께 하는 힐링 프로그램 월 1회 (ESG Factbook 사회 페이지 구성원 가족 행복 증진 항목) — 행사 시기·참가 대상 미기재', 60),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 지원제도 운영 (2026 지속가능경영보고서 47쪽 여가생활 증진 항목) — 지원 금액·지원 방식 미기재', 61),
  (@comp_id, 'resort', '동계·하계 휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '동계·하계 휴양소 운영 (2026 지속가능경영보고서 41쪽 노사 소통 채널 주요 성과 항목), 하계/동계 휴양소 위한 Refresh Point 제도 운영 (같은 보고서 47쪽 구성원 가족 행복 증진 항목) — 휴양소 위치·이용 조건 미기재', 62),

  -- ── 성장 · 교육 (growth) — 2026 지속가능경영보고서 44쪽 · ESG Factbook 사회 페이지 ──
  (@comp_id, 'edu_support', 'mySUNI 학습 플랫폼', NULL, 'growth',
   'est', NULL, TRUE, 'mySUNI 그룹 교육 플랫폼 기반 다양한 영역 내 자기주도학습 (2026 지속가능경영보고서 44쪽 자기계발 항목), 직무 외 다양한 영역에 대해 자기주도 학습 (ESG Factbook 사회 페이지 자기계발 지원 항목) — 수강 비용 지원 범위 미기재', 70),
  (@comp_id, 'self_development', '실트론 University 자격증 지원', NULL, 'growth',
   'est', NULL, TRUE, '실트론 University 실트론 전용 교육 플랫폼 기반 업무 유관 자격증 지원 (2026 지속가능경영보고서 44쪽 자기계발 항목) — 지원 대상 자격증·지원 금액 미기재', 71),
  (@comp_id, 'conference', '기술세미나 참석 지원', NULL, 'growth',
   'est', NULL, TRUE, '기술 Trend Insight 확장 위한 기술세미나 지원 (2026 지속가능경영보고서 44쪽 기술 역량 항목), SEMICON·SEDEX 기술세미나 참석 (ESG Factbook 사회 페이지 기술특화 항목) — 참석 대상·비용 지원 범위 미기재', 72),

  -- ── 생활 · 금융 (perks) — 2026 지속가능경영보고서 21쪽 · 41쪽 · 47쪽 ──
  (@comp_id, 'commute_subsidy', '통근버스 (수소 전기버스)', NULL, 'perks',
   'est', NULL, TRUE, '경유 버스를 수소전기버스로 교체해 임직원 통근 편의 증대, 수소 전기버스(통근용) (2026 지속가능경영보고서 21쪽 친환경 모빌리티 전환 항목) — 운행 노선·대상 사업장 미기재', 80),
  (@comp_id, 'welfare_fund_loan', '사내 직접 대출제도', NULL, 'perks',
   'est', NULL, TRUE, '사내 직접 대출제도, 구성원 복지 차원에서 운영 (2026 지속가능경영보고서 41쪽 RBA 제3자 점검 항목) — 대출 용도·한도·이율 미기재', 81),
  (@comp_id, 'welfare_point', 'Refresh Point', NULL, 'perks',
   'est', NULL, TRUE, 'Refresh Point 제도 운영, 연간 복지포인트를 지급해 국내외 여행·휴양·레저 활동 등 본인이 원하는 방식으로 사용 (2026 지속가능경영보고서 47쪽 건강한 조직 문화 구성 항목), Refresh Point 지원제도 신설 (같은 보고서 41쪽 노사 소통 채널 주요 성과 항목) — 포인트 금액·지급 기준 미기재', 82),

  -- ── 보상 (compensation) — 2026 지속가능경영보고서 45쪽 · 46쪽 ──
  (@comp_id, 'incentive', 'Target Incentive·Profit Sharing', NULL, 'compensation',
   'est', NULL, TRUE, 'Incentive Bonus: Target Incentive(목표달성상여금), Profit Sharing(이익 분배)을 평가결과에 따라 지급 (2026 지속가능경영보고서 45쪽 보상제도 항목) — 지급 기준·지급률 미기재', 90),
  (@comp_id, 'excellence_award', 'Special Recognition·Small Recognition', NULL, 'compensation',
   'est', NULL, TRUE, 'Special Recognition: 탁월한 성과 달성 시 별도 보상 지급 (2026 지속가능경영보고서 45쪽 보상제도 항목), Small Recognition 프로그램으로 일상 속 성과에 대한 즉각적인 격려 제공 (같은 보고서 46쪽 C·A 운영 도입 항목) — 포상 기준·포상 내용 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
