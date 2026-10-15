-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 영원무역 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.youngone.co.kr/recruit/humanaffairs/welfare
-- badge: est
--
-- 참고:
--   정본 = 자기 도메인 인재채용 복리후생 페이지(SSR · 9항목 · 꼬리말 YOUNGONE CORPORATION 사업자번호 = DART 영원무역).
--   보조 = 영원무역 2025 지속가능경영보고서(자기 도메인 ESG Report 목록 · 2026-07-01 게시 · 42 · 44 · 46 · 47쪽) ·
--   공식 보도자료 2026-08-18(영원무역그룹 주어 → company_event 일부에 그룹 공통 문구 각주) ·
--   OpenDART 2026 반기보고서(20260814003968 유연근무제도 사용 현황).
--   렌더 = 원본 HTML · PDF 텍스트 추출. 보고 범위 = 영원무역홀딩스 · 영원무역이나 비재무 성과는 별도법인 영원무역 기준이고
--   근거 문장 주어가 영원무역이라 각주 없음.
--   금액 = meal 576(하루 2끼 × 12,000원 × 240일 추정) · parenting 240(월 20만원 육아수당 연 환산) — 나머지 NULL.
--   제외 = 법정(출산전후휴가 · 육아휴직 · 배우자 출산휴가 · 가족돌봄 · 임신기 단축 · 태아 검진 · 특수건강검진) ·
--   업무 교육(리더십 · 승진자 · 직무 · 법정의무) · 해외 생산법인 시설 · 임원 보수.
--   공고 근거 0행 / 전체 21행.
--   SORT = health 10 · perks 20 · leisure 30 · family 40 · growth 50 · compensation 60 · flexibility 70 · work_env 80
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 항목 페이지 예외 4(통합 밖 리드 집행) — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('youngone', '영원무역',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '패션', 'Y', 'https://www.youngone.co.kr/recruit/humanaffairs/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'youngone');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.youngone.co.kr/recruit/humanaffairs/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 복리후생 페이지 / 보고서 42 · 44쪽 ──
  (@comp_id, 'clinic', '건강관리실·건강관리 프로그램', NULL, 'health',
   'est', NULL, TRUE, '건강관리실 운영, 건강관리 프로그램 운영 (공식 채용 페이지 복리후생 항목), 사내 건강관리실에서 응급처치·가벼운 부상 처치·의약품 관리, 뇌·심혈관 질환 위험도가 높은 근로자 대상 매월 셋째주 수요일 예방 프로그램 운영 (2025 지속가능경영보고서 42쪽 임직원 건강관리실 운영 항목) — 운영 사업장·의료 인력 구성 미기재', 10),
  (@comp_id, 'health_check', '임직원 건강검진·암검사비용 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강검진 지원 (공식 채용 페이지 복리후생 항목), 전문 검진센터와 업무협약을 통해 전체 임직원을 대상으로 매년 건강검진 프로그램 지원, 개인별 특성을 고려한 종합건강검진 지원, 연령 기준에 따라 복부검사(만 35세 이상)·여성검사(만 30세 이상) 비용 지원 (2025 지속가능경영보고서 42쪽 임직원 대상 건강 증진 프로그램 항목) — 검진 비용 한도·가족 검진 여부 미기재', 11),
  (@comp_id, 'fitness', '사내 체육관', NULL, 'health',
   'est', NULL, TRUE, '사내 체육관 운영 (공식 채용 페이지 복리후생 항목), 명동·만리동·상대원동에 체육시설 운영 (2025 지속가능경영보고서 42쪽 임직원 대상 건강 증진 프로그램 사내체육시설 항목) — 이용 시간·운동 프로그램 미기재', 12),
  (@comp_id, 'massage', '헬스키퍼 (안마)', NULL, 'health',
   'est', NULL, TRUE, '헬스키퍼(안마) 안마 프로그램 운영 (2025 지속가능경영보고서 42쪽 임직원 대상 건강 증진 프로그램 항목), 국가자격증을 보유한 시각장애인 안마사를 헬스키퍼 직무로 채용해 임직원 헬스케어 (같은 보고서 44쪽 임직원 다양성 강화 항목) — 이용 횟수·운영 사업장 미기재', 13),
  (@comp_id, 'insurance', '단체 보험 (해외파견직원 등)', NULL, 'health',
   'est', NULL, TRUE, '해외파견직원 등 상해보험 가입, 상해 및 질병(외래, 입원, 처방 조제) 보장 (2025 지속가능경영보고서 42쪽 임직원 대상 건강 증진 프로그램 단체 보험 항목), 해외 출장 및 파견 임직원 상해보험 가입 지원 (같은 쪽 임직원 보건관리 항목) — 보장 한도·국내 근무자 가입 여부 미기재', 14),
  (@comp_id, 'overseas_safety', '해외출장·파견자 예방접종', NULL, 'health',
   'est', NULL, TRUE, '해외출장 또는 파견자 예방접종 지원 (2025 지속가능경영보고서 42쪽 임직원 대상 건강 증진 프로그램 항목), 해외 출장 및 파견 임직원에게 현지 맞춤형 예방접종 지원 (같은 쪽 임직원 보건관리 항목) — 접종 비용 부담 범위 미기재', 15),

  -- ── 생활 · 금융 (perks) — 복리후생 페이지 / 보고서 47쪽 ──
  (@comp_id, 'meal', '사내 식당 (중식·석식 제공)', 576, 'perks',
   'est', '사내 식당 운영 (중식/석식 제공) (공식 채용 페이지 복리후생 항목) — 식대 단가 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 20),
  (@comp_id, 'housing_loan', '주택자금 및 가계자금 대부', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 및 가계자금 대부 (공식 채용 페이지 복리후생 항목, 2025 지속가능경영보고서 47쪽 복리후생 제도 항목) — 대부 한도·이율·자격 미기재', 21),
  (@comp_id, 'birthday_gift', '생일 쿠폰', NULL, 'perks',
   'est', NULL, TRUE, '생일 쿠폰 지원 (2025 지속가능경영보고서 47쪽 복리후생 제도 항목) — 쿠폰 금액·사용처 미기재', 22),
  (@comp_id, 'transport', '임산부 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '임산부 교통비 100만원 지원 (2025 지속가능경영보고서 47쪽 가족 친화적 문화 조성을 위한 지원 제도 출산·육아 지원 항목) — 지급 시기·지급 방식 미기재', 23),

  -- ── 여가 (leisure) — 복리후생 페이지 / 보고서 47쪽 / 보도자료 ──
  (@comp_id, 'club', '사내 동호회·동호회비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 사내 동호회 운영 (공식 채용 페이지 복리후생 항목), 다양한 사내 동호회 운영 및 동호회비 지원 (2025 지속가능경영보고서 47쪽 복리후생 제도 항목) — 동호회비 지원 금액 미기재', 30),
  (@comp_id, 'resort', '콘도 회원권', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 회원권 (공식 채용 페이지 복리후생 항목), 콘도 회원권 지원 (2025 지속가능경영보고서 47쪽 복리후생 제도 · 여가활동 지원 항목) — 이용 가능 시설·이용 일수 미기재', 31),
  (@comp_id, 'library', '사내 도서관', NULL, 'leisure',
   'est', NULL, TRUE, '사내 도서관 운영 (2025 지속가능경영보고서 47쪽 복리후생 제도 항목) — 위치·장서 규모 미기재', 32),
  (@comp_id, 'company_event', '임직원 가족 초청 음악회·자녀 초청 행사', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 가족 초청 음악회 (2025 지속가능경영보고서 47쪽 가족 친화적 문화 조성을 위한 지원 제도 여가활동 지원 항목), 만 4세에서 초등학생 임직원 자녀들이 부모의 회사를 방문해 직업을 체험하는 Bring Your Kids to Work 2015년부터 매년 개최 (2026-08-18 공식 보도자료 항목, 영원무역그룹 공통 문구) — 음악회 개최 주기 미기재', 33),

  -- ── 가족 (family) — 복리후생 페이지 / 보고서 47쪽 ──
  (@comp_id, 'child_edu', '자녀 학자금·고교·대학 입학금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (공식 채용 페이지 복리후생 항목), 고등학교·대학교 입학 시 각각 2백만원·1백만원 입학금 지원 (2025 지속가능경영보고서 47쪽 가족 친화적 문화 조성을 위한 지원 제도 임직원 자녀 지원 항목) — 학자금 지원 학년·한도 미기재', 40),
  (@comp_id, 'parenting', '육아수당·자녀 입학 축하선물', 240, 'family',
   'est', '만 6세 이하 자녀를 둔 임직원에게 월 20만원 육아수당, 초등학교·중학교 입학 시 입학 축하선물, 아웃도어 의류 및 자전거 선물 (2025 지속가능경영보고서 47쪽 가족 친화 지원 제도 항목) — 월 20만원을 연 240만원으로 환산', FALSE, NULL, 41),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (2025 지속가능경영보고서 47쪽 복리후생 제도 항목) — 경조금 금액·경조휴가 일수 미기재', 42),

  -- ── 성장 (growth) — 보고서 46쪽 ──
  (@comp_id, 'edu_support', '사이버연수원', NULL, 'growth',
   'est', NULL, TRUE, '매월 운영되는 사이버연수원을 통해 임직원들이 시공간의 제약 없이 자율적으로 필요한 직무 지식을 습득할 수 있도록 상시 학습 환경 지원 (2025 지속가능경영보고서 46쪽 임직원 역량 개발 항목), 사이버연수원교육 전 임직원 대상 수시 운영 (같은 쪽 2025년 임직원 교육 현황 표 항목) — 과정 구성·수강 비용 부담 미기재', 50),

  -- ── 보상 (compensation) — 보고서 47쪽 ──
  (@comp_id, 'long_service_bonus', '장기 근속자 시상', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속자 시상 (2025 지속가능경영보고서 47쪽 복리후생 제도 항목), 장기간 회사와 함께해 온 임직원의 헌신과 노고에 감사하는 장기 근속자 시상제도 (같은 쪽 일과 삶의 균형 항목) — 근속 기준·포상 내용 미기재', 60),

  -- ── 근무 유연성 (flexibility) — 보고서 47쪽 / 반기보고서 ──
  (@comp_id, 'flex_work', '학부모 시차 출근제 (자녀를 둔 임직원)', NULL, 'flexibility',
   'est', NULL, TRUE, '2025년 도입, 초등학교 6학년 이하 자녀를 둔 임직원에게 30분 단위로 출퇴근 시간을 조정할 수 있는 시차근무제 운영, 2025년 기준 36명 활용 (2025 지속가능경영보고서 47쪽 가족 친화적 문화 조성 항목), 시차출퇴근제 사용자 수 2026년 상반기 30명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 조정 가능 범위 미기재', 70),

  -- ── 근무 환경 (work_env) — 보고서 47쪽 ──
  (@comp_id, 'nap_room', '수유실 (만리사옥)', NULL, 'work_env',
   'est', NULL, TRUE, '만리사옥 내 수유실 운영 (2025 지속가능경영보고서 47쪽 가족 친화적 문화 조성을 위한 지원 제도 출산·육아 지원 항목) — 이용 대상·시설 구성 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
