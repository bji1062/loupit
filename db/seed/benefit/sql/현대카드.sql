-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대카드 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://www.hyundaicard.com/about/common/ko/pageView.hc?id=ckabi0101_01
-- badge: est
--
-- 참고:
--   정본은 비상장 법인 현대카드주식회사(DART 00222374 · 최대주주 현대자동차 37.0%)의 자기 도메인
--   www.hyundaicard.com 회사소개 > 기업문화 페이지다. 셸 HTML 이 같은 도메인 조각 /IR/include/ko/ckabi0101_01_cms01.html 을
--   jQuery load 로 붙인다 — 조각도 원본 HTML(SSR)이라 헤드리스 렌더 불필요. 같은 메뉴 인사철학 페이지(ckrhr0201_01)도 같은 꼴.
--   보조 출처: 같은 도메인 뉴스룸 newsroom.hyundaicard.com 보도자료 · 영상 소개 글(현대카드 주어 글만 · 발행일은 각 글의 날짜 표기) —
--   2025-09-24 인사철학 · 복리후생 개편 · 2025-12-23 사내 셰프 · 2025-07-31 DUGOUT · 2025-07-04 캠핑카 렌트 ·
--   2023-07-20 패밀리데이 · 2023-01-10 기업문화 제도(사내 병원 · 바버숍 · 네일숍 · 핏 캠프 · 재택 · 거점 오피스 · D코인) ·
--   2022-11-07 유연한 근무(플렉스 타임 · 플렉스 런치) ·
--   2022-12-20 연말 프로그램 · 2022-05-02 상시 재택 · 거점 오피스 · D코인 · 플렉스 런치 · 플렉스 타임.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814003422) · 2025 사업보고서(접수 20260318001407)
--   유연근무제도 사용 현황 표(선택근무제 · 원격근무제 사용자 수)와 이해관계자 거래 절 복리후생제도 문장(식당 · 학자금지원).
--   채용 사이트 careerhyundai.recruiter.co.kr 은 현대카드 · 현대커머셜 공동 사이트이고 본문이 벤더 API 호스트
--   (api-builder · api-recruiter — robots Disallow: /)에만 있어 읽지 않았다 — 붙여넣기 보강 후보.
--   귀속: 기업문화 · 인사철학 페이지와 뉴스룸 글 대부분은 현대카드 단수 주어 — 각주 없음.
--   주어가 현대카드 · 현대커머셜 둘인 문장(캠핑카 렌트 · 2022 연말 프로그램)만 출처 괄호에 현대카드·현대커머셜 공통 문구.
--   현대차 기등록 형제 10사 · 대기 현대트랜시스 정본과 겹치는 문장 없음.
--   금액: 원 단위 숫자는 D코인 50만원 · 30만원(첫해 1회 · 2년 주기 계획)뿐 — 전 행 BENEFIT_AMT NULL. stated 0 · 추정 0.
--   제외: 법정(의료보험 · 재해보상 · 유급휴가 · 육아휴직 · 배우자 출산휴가 공시 표) · 업무 교육 · 소통 프로그램
--     (잡페어 · 잡셀링 · CEO 타운홀 미팅 · 크로스톡 · 유닛톡 · 제로 PPT) · 임원 보수 칸 복리후생 규정 지급액 ·
--     우리사주조합 주주 표 칸 · 3시 퇴근 영상 문구(제도 설명 없음) · 2018 직장어린이집 글(현대캐피탈 공동 시기 옛 글) ·
--     기부 행사 · 금융 교육 봉사.
--   공고 근거 0행 / 전체 19행.
--   SORT 섹션 순서 = 정본 기업문화 페이지 등장 순(health 10 · family 20 · perks 30), 보조 출처에만 있는 growth 40 ·
--     flexibility 50 · work_env 60 · leisure 70 · time_off 80.
-- 검증 · 감사 판정 반영(2026-10-23): 재택 행을 2026 반기보고서 유연근무 표 주석(특정 직원 한시 재택)대로 상시 재택근무 (조건부)로 · 선택근무 서술을 공시 문장으로 · 카페테리아 snack_bar 행 삭제하고 사내 식당 meal 행에 병합 · 주택자금 꼬리에서 이율 걷음 · 현대카드 현대커머셜 공동 주어 3행 각주 유지 · 항목 페이지 예외 1(통합 밖 리드 집행) · 참고 블록의 SORT 섹션 설명(perks 30)과 행 수 19행은 이 판정으로 뒤집힘 — 최종 18행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_card', '현대카드',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '금융/카드', 'H', 'https://www.hyundaicard.com/about/common/ko/pageView.hc?id=ckabi0101_01');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_card');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hyundaicard.com/about/common/ko/pageView.hc?id=ckabi0101_01'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 회사소개 기업문화 · 뉴스룸 2023-01 · 2025-09 ──
  (@comp_id, 'clinic', '사내 병원 더 클리닉 (the Clinic)', NULL, 'health',
   'est', NULL, TRUE, '사내 병원 조성 (공식 회사소개 기업문화 페이지 항목), 직원 전용 사내 병원 더 클리닉(the Clinic) 진료과목 가정의학과·내과·소아과·물리치료, 사내 시스템으로 30분 단위 예약 후 이용, 금연 클리닉·수면 관리·비만 관리 등 건강 관리 상담, 대사증후군 관리·건강검진 결과 상담 프로그램 (2023-01 공식 뉴스룸 보도자료 항목) — 진료 비용·운영 시간 미기재', 10),
  (@comp_id, 'fitness', '사내 헬스장 핏 캠프 (Fit Camp)', NULL, 'health',
   'est', NULL, TRUE, '운동시설 조성 (공식 회사소개 기업문화 페이지 항목), 사내 헬스장 핏 캠프(Fit Camp) 운동 기구와 골프·테니스·필라테스 운동 프로그램 (2023-01 공식 뉴스룸 보도자료 항목) — 이용 비용·운영 시간 미기재', 11),
  (@comp_id, 'massage', '직원 전용 네일숍', NULL, 'health',
   'est', NULL, TRUE, '사옥 바로 옆 건물 1층 현대카드 직원 전용 네일숍 (2023-01 공식 뉴스룸 보도자료 항목) — 이용 비용·운영 시간 미기재', 12),
  (@comp_id, 'medical', '의료비', NULL, 'health',
   'est', NULL, TRUE, '의료비 확대 (2025-09 공식 뉴스룸 보도자료 복리후생 제도 개편 항목) — 지원 대상·지원 한도 미기재', 13),

  -- ── 가족 (family) — 회사소개 기업문화 · 2026 반기보고서 · 뉴스룸 2025-09 ──
  (@comp_id, 'childcare', '어린이집', NULL, 'family',
   'est', NULL, TRUE, '어린이집 조성 (공식 회사소개 기업문화 페이지 항목) — 이용 대상·정원·위치 미기재', 20),
  (@comp_id, 'child_edu', '학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금지원 (2026 반기보고서 이해관계자와의 거래 복리후생제도 항목), 영어유치원 신설 (2025-09 공식 뉴스룸 보도자료 복리후생 제도 개편 항목) — 지원 대상·지원 범위·금액 미기재', 21),

  -- ── 생활 · 금융 (perks) — 회사소개 기업문화 · 2026 반기보고서 · 뉴스룸 ──
  (@comp_id, 'meal', '사내 식당 · 카페테리아 · 사내 셰프', NULL, 'perks',
   'est', NULL, TRUE, '식당 (2026 반기보고서 이해관계자와의 거래 복리후생제도 항목), 카페테리아 조성 (공식 회사소개 기업문화 페이지 항목), 임직원의 미식복지를 책임지는 사내 셰프 (2025-12 공식 뉴스룸 영상 소개 항목) — 제공 끼니·식대 지원 범위 미기재', 31),
  (@comp_id, 'housing_loan', '주택자금', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 확대 (2025-09 공식 뉴스룸 보도자료 복리후생 제도 개편 항목) — 지원 방식·지원 대상·한도 미기재', 32),
  (@comp_id, 'barber_shop', '직원 전용 바버숍', NULL, 'perks',
   'est', NULL, TRUE, '사옥 바로 옆 건물 1층 현대카드 직원 전용 바버숍 (2023-01 공식 뉴스룸 보도자료 항목) — 이용 비용·운영 시간 미기재', 33),
  (@comp_id, 'car_rental', '캠핑카 렌트 프로그램', NULL, 'perks',
   'est', NULL, TRUE, '캠핑카 렌트 프로그램으로 임직원 여가 지원 (2025-07 공식 뉴스룸 영상 소개 항목, 현대카드·현대커머셜 공통 문구) — 이용 비용·이용 조건 미기재', 34),

  -- ── 성장 (growth) — 회사소개 인사철학 · 뉴스룸 2025-09 ──
  (@comp_id, 'career', '커리어 마켓 (Career Market)', NULL, 'growth',
   'est', NULL, TRUE, '커리어 마켓 제도를 통한 자발적 인사이동으로 직원이 직접 경력 설계 (공식 회사소개 인사철학 페이지 항목), 직원의 30%가 커리어 마켓을 통해 본인이 원하는 부서로 이동해 근무 (2025-09 공식 뉴스룸 보도자료 항목) — 지원 자격·공모 주기 미기재', 40),

  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 · 뉴스룸 2022-05 · 2023-01 ──
  (@comp_id, 'remote_work', '상시 재택근무 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 2026 상반기 134명·2025년 122명·2024년 725명, 상시재택근무제도를 운영하나 거동불편자·임산부 등 특정 직원에 한하여 한시적으로 재택근무 운영 (2026 반기보고서 유연근무제도 사용 현황 항목) — 신청 절차·재택 일수 미기재', 50),
  (@comp_id, 'flex_work', '선택근무제 · 플렉스 타임', NULL, 'flexibility',
   'est', NULL, TRUE, '근로자대표와의 합의를 통해 전체 임직원에게 선택적근로시간제 운영, 출/퇴근시간을 정할 필요가 있는 일부 직무는 표준근로시간제, 선택근무제 사용자 2026 상반기 2,061명·2025년 2,035명·2024년 2,081명 (2026 반기보고서 유연근무제도 사용 현황 항목), 출퇴근 유연근무제 플렉스 타임(Flex Time)과 하루 중 1시간을 점심시간으로 자율 사용하는 플렉스 런치(Flex Lunch) (2022-11 공식 뉴스룸 보도자료 항목) — 코어타임 미기재', 51),
  (@comp_id, 'satellite_office', '디지털 오피스 강남 (거점 오피스)', NULL, 'flexibility',
   'est', NULL, TRUE, '서울 동남권 및 근교 거주 임직원의 출퇴근 부담을 덜기 위한 강남 거점 오피스, 사무 공간과 업무 설비·휴식 공간 (2022-05 공식 뉴스룸 보도자료 항목), 강남역 인근 첫 거점 오피스 디지털 오피스 강남 (2023-01 공식 뉴스룸 보도자료 항목) — 이용 조건·좌석 수 미기재', 52),

  -- ── 근무 환경 (work_env) — 뉴스룸 2022-05 · 2023-01 ──
  (@comp_id, 'work_tools', '재택근무 IT환경 지원 (디지털 코인)', NULL, 'work_env',
   'est', NULL, TRUE, '재택근무 IT환경 지원 제도로 50만원 상당 디지털 코인(D코인) 지급, 제휴 임직원몰에서 모니터·마우스·키보드·헤드셋 등 업무용 기기 구입 (2023-01 공식 뉴스룸 보도자료 항목), 지급 첫해 50만원·이후 2년마다 30만원 지급 계획 (2022-05 공식 뉴스룸 보도자료 항목) — 2024년 이후 지급 실적 미기재', 60),

  -- ── 여가 · 행사 (leisure) — 뉴스룸 2025-07 · 2023-07 · 2022-12 ──
  (@comp_id, 'sports_ticket', 'DUGOUT (SSG 랜더스필드 야구 관람 공간)', NULL, 'leisure',
   'est', NULL, TRUE, '현대카드 PLCC 파트너 SSG 랜더스필드에 있는 DUGOUT에서 임직원의 가족·동료·지인이 함께 야구 관람 (2025-07 공식 뉴스룸 영상 소개 항목) — 이용 비용·예약 방식 미기재', 70),
  (@comp_id, 'company_event', '패밀리데이 · 연말 기업문화 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '직원과 직원 가족이 함께하는 2023 현대카드 패밀리데이 (2023-07 공식 뉴스룸 영상 소개 항목), 연말 기업문화 프로그램 이어엔드 펍(Year-end Pub)과 임직원 가족을 초청해 사옥 투어와 저녁 식사를 제공하는 패밀리 디너(Family Dinner) (2022-12 공식 뉴스룸 보도자료 항목, 현대카드·현대커머셜 공통 문구) — 개최 주기 미기재', 71),

  -- ── 휴가 (time_off) — 뉴스룸 2022-12 ──
  (@comp_id, 'leave_general', '이어엔드 홀리데이 (Year-end Holiday)', NULL, 'time_off',
   'est', NULL, TRUE, '2022년 12월 마지막 주 임직원에게 이틀간 부여한 이어엔드 홀리데이, 정기휴가와 별개로 특별 부여되는 유급 휴가 (2022-12 공식 뉴스룸 보도자료 항목, 현대카드·현대커머셜 공통 문구) — 2023년 이후 시행 여부 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
