-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KG모빌리티 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://www.kg-mobility.com/cm/apply/employee-benefit
-- badge: est
--
-- 참고:
--   정본 = 공식 홈페이지 채용 복리후생 탭(자기 도메인 SPA · 항목 텍스트는 라우트 번들 JS 안 · 렌더 없음).
--   같은 목록이 HR 센터 화면에도 있음. 보조 = 2024 사회경영보고서(자기 도메인 PDF · 2025년 6월 작성 ·
--   보고 기간 2024-01-01 ~ 2024-12-31 · KG모빌리티 단독) PDF 11쪽 일과 삶의 균형 · 공식 홈페이지 안전보건 화면
--   임직원 건강 증진 칸 · 2026 반기보고서(20260814001969) 및 2025 사업보고서(20260318000964) 유연 근무제도 사용 현황 표.
--   귀속 = 법인 자기 도메인 · 법인 단독 보고서 · 공시 — 각주 없음. 코퍼스에 KG 계열 형제 없음.
--   금액 = 식대 1행만 추정(중식 무료 1끼 × 12,000원 × 240일 = 288). stated 0행.
--   제외 = 법정(배우자 출산휴가제 · 육아기 단축근무제 · 남성 육아휴직 사용 권장 · 가족돌봄휴직 · 모성보호 휴가 및 휴직 ·
--   연차촉진제 · 반일 휴가 · 일반 및 특수 건강검진 · 정기 건강검진) · 근무 교대조 운영 · 업무 교육 · 안전 포상.
--   공고 근거 0행 / 전체 25행.
--   SORT 섹션 순서 = health 10 · perks 20 · family 30 · leisure 40 · compensation 50 · time_off 60 · flexibility 70(보조 출처만).
-- 검증 · 감사 판정 반영(2026-10-18): 사내정비소 car_wash 행 삭제 · 자사 차량 구입 혜택 discount 행에 사내정비소 운영 병합(코드 이름의 세차가 원문에 없음) · 명절 선물/현금 holiday_gift 항목 페이지 예외 1(통합 밖 리드 집행) · 참고 블록의 공고 근거 0행 / 전체 25행은 전체 24행 — 최종 24행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kg_mobility', 'KG모빌리티',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '자동차', 'K', 'https://www.kg-mobility.com/cm/apply/employee-benefit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kg_mobility');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.kg-mobility.com/cm/apply/employee-benefit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 채용 페이지 건강지원 · 생활지원 + 사회경영보고서 + 안전보건 화면 ──
  (@comp_id, 'health_check', '종합 건강검진·가족 건강검진권·독감 예방접종', NULL, 'health',
   'est', NULL, TRUE, '종합 건강검진 (공식 채용 페이지 복리후생 건강지원 항목), 직원 본인+ 가족 건강검진권 제공 (2024 사회경영보고서 일과 삶의 균형 폭넓은 복지 항목), 독감(인플루엔자) 예방접종 시행 (공식 홈페이지 안전보건 임직원 건강 증진 항목) — 검진 주기·비용 지원 범위 미기재', 10),
  (@comp_id, 'clinic', '사내 건강관리실·한방 병원·물리치료실·재활치료실', NULL, 'health',
   'est', NULL, TRUE, '사내 건강관리실 운영 (공식 채용 페이지 복리후생 건강지원 항목), 사내 한방 병원 운영 · 물리치료실 운영 · 재활치료실 운영(산재자 대상) (2024 사회경영보고서 일과 삶의 균형 폭넓은 복지 항목) — 운영 사업장·운영 시간 미기재', 11),
  (@comp_id, 'fitness', '사내 운동시설·체력 단련실', NULL, 'health',
   'est', NULL, TRUE, '사내 운동시설 운영 (공식 채용 페이지 복리후생 건강지원 항목), 체력 단련실 운영 (2024 사회경영보고서 일과 삶의 균형 폭넓은 복지 항목) — 운영 사업장·이용 조건 미기재', 12),
  (@comp_id, 'insurance', '단체보험·단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체보험 및 단체상해보험 지원 (공식 채용 페이지 복리후생 생활지원 항목) — 보장 내용·가입 대상 미기재', 13),
  (@comp_id, 'medical', '직원 본인·가족 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '직원 본인+ 가족 의료비 지원 (2024 사회경영보고서 일과 삶의 균형 폭넓은 복지 항목) — 지원 한도·대상 가족 범위 미기재', 14),
  -- ── 생활 (perks) — 채용 페이지 생활지원 · 여가지원 + 사회경영보고서 ──
  (@comp_id, 'housing_loan', '주택마련 자금·주택융자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택마련 자금 지원 (공식 채용 페이지 복리후생 생활지원 항목), 주택융자금 지원 (2024 사회경영보고서 일과 삶의 균형 폭넓은 복지 항목) — 대출 한도·이율·대상 미기재', 20),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 지원 (공식 채용 페이지 복리후생 생활지원 항목) — 회사 부담 비율·금액 미기재', 21),
  (@comp_id, 'commute_subsidy', '출퇴근 통근버스', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 통근버스 운영 (공식 채용 페이지 복리후생 생활지원 항목), 통근버스 무료 지원 (2024 사회경영보고서 일과 삶의 균형 폭넓은 복지 항목) — 운행 노선·사업장 미기재', 22),
  (@comp_id, 'discount', '자사 차량 구입 혜택·사내 정비소', NULL, 'perks',
   'est', NULL, TRUE, '자사차량 구입혜택 제공 (공식 채용 페이지 복리후생 여가지원 항목), 사내정비소 운영 (2024 사회경영보고서 일과 삶의 균형 폭넓은 복지 항목) — 할인율·구입 조건, 정비소 이용 대상·비용 부담 미기재', 23),
  (@comp_id, 'meal', '중식 무료 지원', 288, 'perks',
   'est', '중식 무료 지원 (2024 사회경영보고서 일과 삶의 균형 폭넓은 복지 항목) — 식당 운영 방식 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 24),
  -- ── 가족 (family) — 채용 페이지 생활지원 + 사회경영보고서 ──
  (@comp_id, 'event', '경조사 지원·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (공식 채용 페이지 복리후생 생활지원 항목), 경조휴가 (2024 사회경영보고서 일과 삶의 균형 다양한 휴가 및 휴직 항목) — 경조금 금액·휴가 일수 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (공식 채용 페이지 복리후생 생활지원 항목 · 2024 사회경영보고서 일과 삶의 균형 폭넓은 복지 항목) — 지원 학령·한도 미기재', 31),
  (@comp_id, 'childcare', '사내 어린이집 (교육비 무료)', NULL, 'family',
   'est', NULL, TRUE, '사내어린이집 운영, 교육비 무료 (2024 사회경영보고서 일과 삶의 균형 육아지원/가족친화 항목) — 운영 사업장·정원·이용 연령 미기재', 32),
  -- ── 여가 (leisure) — 채용 페이지 여가지원 + 사회경영보고서 ──
  (@comp_id, 'resort', '콘도·하계 휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 및 하계휴양소 운영 (공식 채용 페이지 복리후생 여가지원 항목), 하기 휴양소 운영 (가족 동반) (2024 사회경영보고서 일과 삶의 균형 육아지원/가족친화 항목) — 이용 횟수·본인 부담 미기재', 40),
  (@comp_id, 'club', '사내 동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동지원 (공식 채용 페이지 복리후생 여가지원 항목) — 지원 금액·동호회 종류 미기재', 41),
  (@comp_id, 'company_event', '가족 초청 행사·자녀 영어마을 행사', NULL, 'leisure',
   'est', NULL, TRUE, '가족초청행사 운영 · 자녀 대상 영어마을 행사 운영 (2024 사회경영보고서 일과 삶의 균형 육아지원/가족친화 항목) — 개최 주기·참가 대상 미기재', 42),
  -- ── 보상 (compensation) — 채용 페이지 여가지원 · 포상지원 + 사회경영보고서 ──
  (@comp_id, 'holiday_gift', '명절 선물·귀성버스 지원', NULL, 'compensation',
   'est', NULL, TRUE, '명절선물 및 귀성버스 지원 (공식 채용 페이지 복리후생 여가지원 항목), 명절 귀향/귀성버스 운영 및 선물/현금 지원 (2024 사회경영보고서 일과 삶의 균형 폭넓은 복지 항목) — 선물·현금 금액 미기재', 50),
  (@comp_id, 'excellence_award', '우수사원 포상·만근 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 선발 및 포상, 만근 및 기타 다양한 포상제 확대중 (공식 채용 페이지 복리후생 포상지원 항목) — 선발 기준·포상 내용 미기재', 51),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 (공식 채용 페이지 복리후생 포상지원 항목) — 근속 기준·포상 내용 미기재', 52),
  -- ── 휴가 (time_off) — 채용 페이지 여가지원 + 사회경영보고서 ──
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 휴가 (공식 채용 페이지 복리후생 여가지원 항목), 장기근속휴가 및 가족동반 여행권 (2024 사회경영보고서 일과 삶의 균형 다양한 휴가 및 휴직 항목) — 근속 기준·휴가 일수 미기재', 60),
  (@comp_id, 'leave_general', '반반일 휴가제·자율휴가제·개인 질병 휴직', NULL, 'time_off',
   'est', NULL, TRUE, '반반일 휴가제 · 자율휴가제 · 개인 질병휴직 (유급 등, 최장 18개월) (2024 사회경영보고서 일과 삶의 균형 다양한 휴가 및 휴직 항목) — 자율휴가제 운영 방식·질병휴직 유급 기간 미기재', 61),
  -- ── 근무 유연성 (flexibility) — 사회경영보고서 + 공시 ──
  (@comp_id, 'flex_work', '시차 출퇴근제·조기 출근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차 출퇴근제 운영 · 조기 출근제 운영 (2024 사회경영보고서 일과 삶의 균형 유연한 근무와 새로운 제도 운영 항목), 시차출퇴근제 사용자 수 2026년 반기 97명 (2026 반기보고서 유연 근무제도 사용 현황 항목) — 출퇴근 시간대·대상 미기재', 70),
  (@comp_id, 'family_day', '가정의 날 (주 1회)', NULL, 'flexibility',
   'est', NULL, TRUE, '주 1회 가정의 날 지정 (2024 사회경영보고서 일과 삶의 균형 유연한 근무와 새로운 제도 운영 항목) — 퇴근 시각·대상 미기재', 71),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 2026년 반기 1명 (2026 반기보고서 유연 근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 72)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
