-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대그린푸드 복리후생 데이터 (신규 회사 — 웨이브 13)
-- 출처: AI 파싱 (2026-10-20)
-- URL: https://recruit.ehyundai.com/company-introduction/view.nhd?coCd=HDGF
-- badge: est
--
-- 참고:
--   정본 = 현대백화점그룹 채용 사이트의 (주)현대그린푸드 법인 전용 회사소개 페이지(coCd=HDGF) 복리후생 카드 5장.
--     SSR(원본 HTML 에 항목 텍스트 전부 · 헤드리스 없음). 귀속 경로 = 법인 자기 도메인 www.hyundaigreenfood.com
--     머리 메뉴 「채용」 → recruit.ehyundai.com → 회사소개 → 현대그린푸드(coCd=HDGF · h3 현대그린푸드).
--     법인 전용 페이지라 각주 없음(기등록 형제 현대백화점 시드와 같은 처리). 형제 HDEHR 카드와 카드 제목 뼈대는 같고
--     설명문은 다르다(난임 · 가사도우미 · 안식월 · 무인경비는 HDEHR 에만, 가족 검진 확대 · 귀향여비 · 휴가비 ·
--     5년마다 포상휴가는 HDGF 에만) — 템플릿 아님. 그룹 채용 메인 「현대백화점그룹 복리후생」(회사별 상이 단서)은 쓰지 않았다.
--   보조 = 같은 사이트 현대그린푸드 채용 공고 복리후생 블록(게시 중 3건 동일 문장 · hireId 2026582 · 2026583 · 2026594,
--     형제 현대홈쇼핑 공고에는 이 블록 없음) · 2025년 12월 16일 자기 도메인 보도자료(건강친화기업 인증) ·
--     OpenDART 2025 사업보고서(20260316001009 · 유연근무제도 사용 현황 · 이사회 의결 · 임원 보수 칸 PS 문장 · 주석).
--   공고 근거 2행(event · discount 단독) / 전체 19행 — 공고는 한시적 출처.
--   금액: 원문에 원 단위 금액 0건 — 19행 전부 정성(NULL). stated 0 · 추정 0.
--   제외: 출산 전후 휴가 90일 · 배우자 출산휴가 20일(법정) · 우리사주조합 주주 표 한 칸 · 원격근무제(세 기간 모두 -) ·
--     지속가능경영보고서 PDF(robots 가 /Contents/ 금지 — 받지 않음).
--   SORT 섹션 순서 = 정본 카드 순 flexibility · health · leisure · compensation · growth · time_off · family, 보조만 perks.
-- 검증 · 감사 판정 반영(2026-10-20): 유연근무 flex_work 와 PS profit_sharing 출처 괄호를 2026 반기보고서로 · 사내근로복지기금 출연 안건 welfare_fund 행 삭제(리드 판정 164 · 검증 유지 권고 뒤집음) · 공고 블록은 그룹 템플릿을 법인별로 고친 HDGF 등록 공고라 71 · 80 각주 없이 유지(10-20 · 10-21 마감 · 감사 시점 공개 중) · 참고 블록의 공고 근거 2행 / 전체 19행은 전체 18행 · 형제 현대홈쇼핑 공고 줄과 보조 줄의 2025 사업보고서는 이 판정으로 뒤집힘 — 최종 18행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_greenfood', '현대그린푸드',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식자재/급식', 'H', 'https://recruit.ehyundai.com/company-introduction/view.nhd?coCd=HDGF');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_greenfood');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.ehyundai.com/company-introduction/view.nhd?coCd=HDGF'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 정본 카드 1 · 사업보고서 ──
  (@comp_id, 'pc_off', 'PC OFF 시스템', NULL, 'flexibility',
   'est', NULL, TRUE, '유통업계 최초로 퇴근시간 이후 자동으로 PC OFF 시스템 도입, 불필요한 야근 방지와 일가정 양립 지원 (공식 채용 페이지 복리후생 가족까지 행복한 회사 항목) — 적용 대상·예외 기준 미기재', 10),
  (@comp_id, 'flex_work', '시차출퇴근제·선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제, 선택근무제 운영 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 11),

  -- ── 건강 (health) — 정본 카드 2 · 카드 4 · 보도자료 ──
  (@comp_id, 'health_check', '건강검진 (배우자·직계가족 확대)', NULL, 'health',
   'est', NULL, TRUE, '배우자 및 직계가족도 건강검진 혜택을 받을 수 있도록 지원 기준 확대 (공식 채용 페이지 복리후생 직원들의 건강을 책임지는 회사 항목), 건강검진 (채용 공고 복리후생 항목) — 검진 주기·비용 지원 범위 미기재', 20),
  (@comp_id, 'mental', '종합 컨설팅·전문 상담 프로그램', NULL, 'health',
   'est', NULL, TRUE, '임직원들이 겪고 있는 다양한 이슈에 대해 종합 컨설팅 서비스 제공 (공식 채용 페이지 복리후생 직원들의 건강을 책임지는 회사 항목), 감정 노동자의 직무 스트레스 관리 등 정신건강을 위한 전문 상담 프로그램 (2025년 12월 공식 보도자료 건강친화기업 인증 항목) — 상담 횟수·가족 이용 여부 미기재', 21),
  (@comp_id, 'fitness', '건강 프로그램·피트니스 프로그램', NULL, 'health',
   'est', NULL, TRUE, '건강관련 프로그램 등록 지원 (공식 채용 페이지 복리후생 능력을 키워주는 회사 항목), 혈당 관리나 체지방 조절을 위한 요가·줌바·체형교정 트레이닝 등 피트니스 프로그램, 신청자 대상 체력 증진·비만 관리 프로그램 (2025년 12월 공식 보도자료 건강친화기업 인증 항목) — 지원 한도·운영 장소 미기재', 22),
  (@comp_id, 'smoking_cessation', '금연 프로그램', NULL, 'health',
   'est', NULL, TRUE, '임직원들 중 신청자 대상 금연 프로그램 운영 (2025년 12월 공식 보도자료 건강친화기업 인증 항목) — 프로그램 내용·지원 방식 미기재', 23),

  -- ── 여가 (leisure) — 정본 카드 3 ──
  (@comp_id, 'resort', '휴양소 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴양소 이용 기회를 확대해 더 많은 직원들이 건강한 쉼을 누릴 수 있도록 지원 (공식 채용 페이지 복리후생 Refresh를 지원하는 회사 항목), 휴양시설 이용 (채용 공고 복리후생 항목) — 휴양소 위치·이용 횟수·본인 부담 미기재', 30),
  (@comp_id, 'summer_vacation_subsidy', '휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 대상 년 3회(설날, 추석, 하계휴가) 귀향여비와 휴가비 지급 중 휴가비 (공식 채용 페이지 복리후생 Refresh를 지원하는 회사 항목), 휴가비 지급 (채용 공고 복리후생 항목) — 시기별 지급 항목·금액 미기재', 31),

  -- ── 보상 (compensation) — 정본 카드 3 · 공고 · 사업보고서 ──
  (@comp_id, 'holiday_gift', '귀향여비·선물대', NULL, 'compensation',
   'est', NULL, TRUE, '임직원 대상 년 3회(설날, 추석, 하계휴가) 귀향여비와 휴가비 지급 중 귀향여비 (공식 채용 페이지 복리후생 Refresh를 지원하는 회사 항목), 선물대 지급 (채용 공고 복리후생 항목) — 시기별 지급 항목·금액 미기재', 40),
  (@comp_id, 'profit_sharing', 'PS (Profit Sharing)', NULL, 'compensation',
   'est', NULL, TRUE, '전임직원을 대상으로 관리 세후이익의 일부를 소요재원으로 하여 차등지급하는 보상적 성과급, 직급에 따라 차등지급 (2026 반기보고서 보수 산정기준 PS 항목) — 연간 지급률 미기재', 41),

  -- ── 성장 (growth) — 정본 카드 4 ──
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격증 등 임직원들의 역량 개발 지원 (공식 채용 페이지 복리후생 능력을 키워주는 회사 항목) — 대상 자격증 범위·지원 한도 미기재', 50),
  (@comp_id, 'lang', '어학 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학 등 임직원들의 역량 개발 지원 (공식 채용 페이지 복리후생 능력을 키워주는 회사 항목) — 대상 과정·지원 한도 미기재', 51),
  (@comp_id, 'conference', '교육·세미나 참석 지원', NULL, 'growth',
   'est', NULL, TRUE, '교육/세미나 참석 등 임직원들의 역량 개발 지원 (공식 채용 페이지 복리후생 능력을 키워주는 회사 항목) — 비용 한도·연간 횟수 미기재', 52),

  -- ── 휴가 (time_off) — 정본 카드 4 ──
  (@comp_id, 'long_service_leave', '장기근속 포상휴가·포상금', NULL, 'time_off',
   'est', NULL, TRUE, '10년 이상 장기근속자에게 5년마다 포상휴가 및 포상금 제공 (공식 채용 페이지 복리후생 능력을 키워주는 회사 항목), 장기근속포상 (채용 공고 복리후생 항목) — 휴가 일수·포상금 금액 미기재', 60),

  -- ── 가족 (family) — 정본 카드 5 · 공고 ──
  (@comp_id, 'parenting', '자동 육아휴직 의무화', NULL, 'family',
   'est', NULL, TRUE, '출산휴가 종료 후 자동 시행할 수 있도록 육아휴직 의무화, 의무 사용 (공식 채용 페이지 복리후생 여성이 근무하기 좋은 회사 항목) — 육아휴직 기간·급여 보전 미기재', 70),
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금 및 경조휴가, 결혼 및 애사지원 (채용 공고 복리후생 항목) — 경조 종류별 금액·휴가 일수 미기재', 71),

  -- ── 생활 · 금융 (perks) — 공고 · 보도자료 · 사업보고서 ──
  (@comp_id, 'discount', '임직원 구입 할인 (현대백화점·현대/기아차)', NULL, 'perks',
   'est', NULL, TRUE, '현대백화점 이용시 구입금액 할인, 현대/기아차 구입시 가격 혜택 (채용 공고 복리후생 항목) — 할인율·한도 미기재', 80),
  (@comp_id, 'meal', '맞춤형 케어푸드·영양상담', NULL, 'perks',
   'est', NULL, TRUE, '임직원 개인별 영양상담과 맞춤형 케어푸드 제공, 임직원 대상 맞춤형 건강식 제공 (2025년 12월 공식 보도자료 건강친화기업 인증 항목) — 제공 끼니·대상 범위·본인 부담 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
