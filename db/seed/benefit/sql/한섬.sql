-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한섬 복리후생 데이터 (신규 회사 — 웨이브 13)
-- 출처: AI 파싱 (2026-10-20)
-- URL: https://recruit.ehyundai.com/company-introduction/view.nhd?coCd=HDHAN
-- badge: est
--
-- 참고:
--   정본 = 현대백화점그룹 통합 채용 사이트의 (주)한섬 법인 전용 회사소개 페이지(coCd=HDHAN) 복리후생 블록 5카드.
--   서버 렌더(원본 HTML div.for-flex.benefit-box 에 본문 · 헤드리스 없음). 법인 자기 도메인 www.handsome.co.kr 의
--   GNB 채용공고 링크가 같은 채용 사이트 coCd=HDHAN 으로 간다. 페이지 h3 한섬 · 소재지 서울시 강남구 도산대로 523 ·
--   설립일 1987년 5월 25일 · 사업영역 패션, 라이프스타일, 뷰티 로 법인을 밝힌다 → 법인 전용 페이지라 그룹 각주 없음.
--   형제 법인 페이지(현대백화점 HDEHR · 현대홈쇼핑 HDHOME)는 카드 제목 · 설명이 전혀 다르다(템플릿 아님).
--   그룹 공통 문서(채용 메인 현대백화점그룹 복리후생 · 회사별 상이 단서)는 한 줄도 쓰지 않았다.
--   보조 = 법인 자기 도메인 ESG 페이지 2곳(인권·윤리경영 social01 · 안전·보건 social02) ·
--         OpenDART 2025 사업보고서(20260313001074) · 2026 반기보고서(20260814003340).
--   자기 발행 지속가능경영보고서 PDF 는 파일 호스트 img.handsome.co.kr 의 robots 가 전체 금지라 받지 않았다.
--   금액: 원 단위 숫자 0건 — 19행 전부 금액 NULL(stated 0 · 추정 0).
--   제외: 임산부 2시간 단축 근무(법정 임신기 근로시간 단축) · 일반/특수건강진단 · 이상 소견 사후관리(법정) ·
--         우리사주조합 주주 표 한 칸 · 사내근로복지기금 출연 이사회 안건(판단 요청) · 임원 보수 칸 금액.
--   공고 근거 0행 / 전체 19행.
--   SORT 섹션 = 정본 첫 등장 순: flexibility 10 · time_off 20 · perks 30 · compensation 40 · leisure 50 ·
--         growth 60 · family 70 · health 80.
-- 검증 · 감사 판정 반영(2026-10-20): PS 성과급 profit_sharing 출처 괄호를 2026 반기보고서로 · 헤더 메뉴 영문 ESG 페이지의 임산부 근로시간 단축 임신 전 기간 확대를 parenting 이름과 서술에 병합(상회분) · 사내근로복지기금 출연 안건은 싣지 않음(리드 판정 164) · 글로벌 연수 conference 유지 · 같은 웨이브 형제 현대그린푸드 · 기등록 현대백화점과 각주 없음 · 참고 블록 제외 줄의 임산부 단축 근무는 이 판정으로 뒤집힘 — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('handsome', '한섬',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '패션', 'H', 'https://recruit.ehyundai.com/company-introduction/view.nhd?coCd=HDHAN');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'handsome');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.ehyundai.com/company-introduction/view.nhd?coCd=HDHAN'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 정본 몰입하는 한섬인 · Special 한섬인 Days 카드, ESG 페이지, 공시 ──
  (@comp_id, 'flex_work', '부분 자율 출근제', NULL, 'flexibility',
   'est', NULL, TRUE, '업무 몰입을 위한 최적의 출근시간 선택, 8시~9시 30분 출근 (공식 채용 페이지 복리후생 몰입하는 한섬인 항목), 부분 자율 출근제 운영 (공식 ESG 페이지 인권·윤리경영 일과 삶의 균형 항목), 시차출퇴근제 · 선택근무제(부분자율출근제 포함) 사용 (2026 반기보고서 유연근무제도 사용 현황 항목) — 의무 근무 시간대·퇴근 시각 기준 미기재', 10),
  (@comp_id, 'family_day', '가족사랑의 날', NULL, 'flexibility',
   'est', NULL, TRUE, '가족사랑의 날에는 1시간 일찍 퇴근 (공식 채용 페이지 복리후생 Special 한섬인 Days 항목), 가족과 함께하는 시간을 위해 연 6회 가족사랑의 날 지정 운영 (공식 ESG 페이지 인권·윤리경영 일과 삶의 균형 항목) — 지정 날짜 미기재', 11),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 2026년 상반기 24명, 2025년 25명, 2024년 23명 (2026 반기보고서 · 2025 사업보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 12),

  -- ── 휴가 (time_off) — 정본 몰입하는 한섬인 · Special 한섬인 Days 카드, ESG 페이지 ──
  (@comp_id, 'leave_general', 'IM DAY 자기계발 휴가·2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '분기별 1회 사무실 출근 대신 전시회, 시장조사 등 외부활동을 통해 인사이트를 얻는 IMDAY 제공 (공식 채용 페이지 복리후생 몰입하는 한섬인 항목), 분기별 자기계발 휴가(IM DAY) 및 2시간 단위 휴가 제도 운영 (공식 ESG 페이지 인권·윤리경영 일과 삶의 균형 항목) — 유급 여부·사용 한도 미기재', 20),
  (@comp_id, 'summer_leave', '여름 휴가 최대 4일', NULL, 'time_off',
   'est', NULL, TRUE, '최대 4일 여름 휴가 지원 (공식 채용 페이지 복리후생 Special 한섬인 Days 항목) — 본인 휴가 사용일인지·유급 여부 미기재', 21),
  (@comp_id, 'long_service_leave', '근속 5년 주기 리프레쉬 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '근속 5년마다 리프레쉬 휴가 5일 제공 (공식 채용 페이지 복리후생 Special 한섬인 Days 항목), 장기 근속자 대상 리프레시 휴가 (공식 ESG 페이지 인권·윤리경영 일과 삶의 균형 항목) — 유급 여부·사용 시기 미기재', 22),

  -- ── 생활 · 금융 (perks) — 정본 한섬인의 선물 · 성장하는 한섬인 · 한섬인은 건강하고, 행복하게 카드 ──
  (@comp_id, 'discount', '한섬 브랜드 최대 50% 할인', NULL, 'perks',
   'est', NULL, TRUE, '한섬 브랜드 최대 50% 할인 혜택 (공식 채용 페이지 복리후생 한섬인의 선물 항목) — 연간 한도·대상 브랜드 미기재', 30),
  (@comp_id, 'welfare_point', '카페테리아 복지제도', NULL, 'perks',
   'est', NULL, TRUE, '한섬인의 자기 계발/성장을 위해 카페테리아 복지제도 지원 (공식 채용 페이지 복리후생 성장하는 한섬인 항목) — 연간 배정액·지급 방식 미기재', 31),
  (@comp_id, 'housing_loan', '주택자금대출', NULL, 'perks',
   'est', NULL, TRUE, '주택자금대출 (공식 채용 페이지 복리후생 한섬인은 건강하고, 행복하게 항목) — 대출 한도·이율·대상 미기재', 32),

  -- ── 보상 (compensation) — 정본 한섬인의 선물 카드, 공시 ──
  (@comp_id, 'holiday_gift', '명절·창립기념일 현금 또는 포인트', NULL, 'compensation',
   'est', NULL, TRUE, '명절, 창립기념일에는 현금 또는 포인트 지급 (공식 채용 페이지 복리후생 한섬인의 선물 항목) — 지급 금액 미기재', 40),
  (@comp_id, 'profit_sharing', 'PS(Profit Sharing) 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '전임직원을 대상으로 관리 세후이익의 일부를 소요재원으로 하여 차등지급하는 보상적 성과급, 직급에 따라 차등지급 (2026 반기보고서 보수지급기준 PS 항목) — 연간 지급률·지급 시기 미기재', 41),

  -- ── 여가 (leisure) — 정본 한섬인의 선물 · 한섬인은 건강하고, 행복하게 카드 ──
  (@comp_id, 'summer_vacation_subsidy', '여름휴가 현금 또는 포인트', NULL, 'leisure',
   'est', NULL, TRUE, '여름휴가에는 현금 또는 포인트 지급 (공식 채용 페이지 복리후생 한섬인의 선물 항목) — 지급 금액 미기재', 50),
  (@comp_id, 'club', '사내동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 (공식 채용 페이지 복리후생 한섬인은 건강하고, 행복하게 항목) — 활동비 지원 여부·동호회 수 미기재', 51),

  -- ── 성장 (growth) — 정본 성장하는 한섬인 카드 ──
  (@comp_id, 'conference', '글로벌 연수', NULL, 'growth',
   'est', NULL, TRUE, '패션/유통 트렌드를 직접 경험할 수 있는 글로벌 연수 지원 (공식 채용 페이지 복리후생 성장하는 한섬인 항목) — 대상·선발 기준·연수 기간 미기재', 60),

  -- ── 가족 (family) — 정본 한섬인은 건강하고, 행복하게 카드, ESG 페이지 ──
  (@comp_id, 'parenting', '출산 축하금·자녀를 둔 직원 30분 단축 근무·임신 전 기간 단축 근무', NULL, 'family',
   'est', NULL, TRUE, '출산 축하금 (공식 채용 페이지 복리후생 한섬인은 건강하고, 행복하게 항목), 자녀를 둔 직원 대상 30분 단축 근무 시행 (공식 ESG 페이지 인권·윤리경영 여성 인력 지원 항목), 임산부 근로시간 단축을 임신 전 기간으로 확대 (공식 ESG 페이지 영문판 Support for the Female Workforce 항목) — 축하금 금액·단축 근무 대상 자녀 연령 미기재', 70),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 (공식 채용 페이지 복리후생 한섬인은 건강하고, 행복하게 항목) — 지원 학령·한도 미기재', 71),
  (@comp_id, 'childcare', '어린이집 한섬아이', NULL, 'family',
   'est', NULL, TRUE, '어린이집 한섬아이 운영 (공식 ESG 페이지 인권·윤리경영 여성 인력 지원 항목) — 정원·이용 대상 미기재', 72),

  -- ── 건강 (health) — 정본 한섬인은 건강하고, 행복하게 카드, ESG 페이지 ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '건강검진 (공식 채용 페이지 복리후생 한섬인은 건강하고, 행복하게 항목), 전 임직원 대상 건강검진 시행 (공식 ESG 페이지 안전·보건 건강관리 활동 항목) — 검진 주기·비용 지원 범위 미기재', 80),
  (@comp_id, 'mental', 'EAP 상담', NULL, 'health',
   'est', NULL, TRUE, 'EAP (공식 채용 페이지 복리후생 한섬인은 건강하고, 행복하게 항목), EAP(Employee Assistance Program) 제공, 직무(업무관련, 관계갈등, 경력/적성 등) 상담 · 개인/가정(스트레스, 정서관리 등) 상담 · 전문(법률자문, 세무 등) 상담 (공식 ESG 페이지 안전·보건 건강관리 활동 항목) — 상담 횟수·이용 대상 범위 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
