-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 동원산업 복리후생 데이터 (신규 회사 — 웨이브 10)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.dongwon.com/kr/recruitment/culture
-- badge: est
--
-- 참고:
--   정본 = 동원산업 자기 도메인(DART 홈 주소 www.dongwon.com · 꼬리말 동원산업 (주) 사업자 등록번호) 채용 메뉴
--     기업 문화 페이지 — 인사제도 · 교육제도 · 지원제도 세 탭이 원본 HTML(Next.js SSR)에 다 들어 있다. 렌더 없음.
--   귀속: 이 사이트는 동원그룹 포털(그룹소개 메뉴 · 꼬리말 Dongwon Group 저작권)이고 페이지 주어가 동원 · 동원인이다.
--     계열사별 상이 단서는 없다 → 자기 도메인 그룹 주어 페이지(단서 없음)로 보고 이 페이지 근거 15행 출처 괄호에
--     동원그룹 공통 문구 각주. 동원F&B · 동원시스템즈 · 스타키스트 등 자회사 제도는 이 페이지 밖이라 싣지 않았다.
--   보조 = 2026 반기보고서(접수 20260814000602) 직원 등 현황 유연근무제도 사용 현황 표 — 시차출퇴근제 · 원격근무제 2행.
--     2025 사업보고서(접수 20260318001195) 같은 표와 숫자가 겹친다. 공시 근거 행은 각주 없음.
--   금액: 원문에 원 · 만원 숫자 없음 → 금액 행 0(stated 0 · 추정 0). 식대 원문 없음.
--   제외: 육성형 평가 · 승진 · 차등 보상제도(인사 체계) · 동원 D.N.A · 독서교육 · Value · Step Up · 직무역량 ·
--     핵심인재 · 맞춤형 · 리더십 · 경영자 교육(업무 교육) · 선택근무제(세 기간 모두 사용자 없음) ·
--     육아휴직 · 육아기 단축근무 · 배우자 출산휴가 사용 현황(법정) · 연결 주석의 일부 기업 장기종업원급여(다른 법인).
--   공고 근거 0행 / 전체 17행.
--   SORT 섹션 순서(정본 페이지에 처음 나온 순서): growth 10 · perks 20 · family 30 · time_off 40 ·
--     compensation 50 · health 60 · leisure 70 · flexibility 80(공시만).
-- 검증 · 감사 판정 반영(2026-10-15): 헤더 메뉴 영문판 기업 문화 교육제도 Future Leaders, Global Experts 칸의 어학 교육 프로그램 lang · Dongwon MBA와 글로벌 지역전문가 mba 2행 추가(동원그룹 공통 문구 각주) · 참고 블록의 공고 근거 0행 / 전체 17행은 전체 19행 · 항목 페이지 예외 3(통합 밖 리드 집행) — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('dongwon_industries', '동원산업',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품', 'D', 'https://www.dongwon.com/kr/recruitment/culture');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'dongwon_industries');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.dongwon.com/kr/recruitment/culture'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 · 교육 (growth) — 기업 문화 교육제도 탭 ──
  (@comp_id, 'edu_support', '목요세미나 저명인사 초빙강의', NULL, 'growth',
   'est', NULL, TRUE, '1974년 9월 26일부터 시작한 목요세미나, 매주 목요일 저명인사 초빙강의 (공식 채용 페이지 기업 문화 교육제도 목요세미나 항목, 동원그룹 공통 문구) — 참여 대상·참여 방식 미기재', 10),
  (@comp_id, 'lang', '어학 교육 프로그램 (Global Experts)', NULL, 'growth',
   'est', NULL, TRUE, 'As global frontiers, we offer training programs that enhance not only language proficiency but also cultural understanding and global business insight (공식 채용 페이지 영문판 기업 문화 교육제도 Future Leaders, Global Experts 항목, 동원그룹 공통 문구) — 대상 선발 기준·교육 방식·비용 부담 미기재', 11),
  (@comp_id, 'mba', 'Dongwon MBA · 글로벌 지역전문가', NULL, 'growth',
   'est', NULL, TRUE, 'Dongwon MBA, An in-house MBA program designed to nurture future leaders of Dongwon, Global Regional Expert Program, Participants spend one year immersed in local life, engaging in various activities to gain deeper understanding of the language, culture, and industries of the region (공식 채용 페이지 영문판 기업 문화 교육제도 Future Leaders, Global Experts 항목, 동원그룹 공통 문구) — 선발 기준·파견 지역·비용 부담 미기재', 12),

  -- ── 생활 · 금융 · 주거 (perks) — 기업 문화 지원제도 탭 ──
  (@comp_id, 'housing_loan', '주택자금대출 (신협)', NULL, 'perks',
   'est', NULL, TRUE, '주택자금대출(신협) 운영 (공식 채용 페이지 기업 문화 지원제도 주거지원 항목, 동원그룹 공통 문구) — 대출 한도·이율 미기재', 20),
  (@comp_id, 'welfare_point', '복지포인트 (동원몰 포인트)', NULL, 'perks',
   'est', NULL, TRUE, '동원몰 포인트 지급 (공식 채용 페이지 기업 문화 지원제도 복지포인트 항목, 동원그룹 공통 문구) — 포인트 금액·지급 주기 미기재', 21),
  (@comp_id, 'discount', '임직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '임직원 할인 (공식 채용 페이지 기업 문화 지원제도 복지포인트 항목, 동원그룹 공통 문구) — 할인 대상·할인율 미기재', 22),
  (@comp_id, 'commute_subsidy', '출퇴근 셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '본사, 사업장 셔틀버스 운영 (공식 채용 페이지 기업 문화 지원제도 출퇴근 셔틀버스 항목, 동원그룹 공통 문구) — 운행 노선·사업장별 운행 여부 미기재', 23),

  -- ── 가족 (family) — 기업 문화 지원제도 탭 ──
  (@comp_id, 'parenting', '자녀입학축하금 · 출산축하금 · Hello Baby Kit', NULL, 'family',
   'est', NULL, TRUE, '자녀입학축하금 초등~고등학교 입학 축하금 지원, 출산축하금 자녀출산시마다 축하금 지원, Hello Baby Kit 임신·출산 축하물품 지원 (공식 채용 페이지 기업 문화 지원제도 가정관련 항목, 동원그룹 공통 문구) — 축하금 금액 미기재', 30),
  (@comp_id, 'childcare', '사내 어린이집 (동원어린이집)', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 대상 동원어린이집 운영 (공식 채용 페이지 기업 문화 지원제도 사내 어린이집 항목, 동원그룹 공통 문구) — 어린이집 위치·정원 미기재', 31),

  -- ── 휴가 (time_off) — 기업 문화 지원제도 탭 ──
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연중 4일 유급휴가 부여 (공식 채용 페이지 기업 문화 지원제도 리프레시 휴가 항목, 동원그룹 공통 문구) — 부여 조건·사용 시기 미기재', 40),

  -- ── 보상 (compensation) — 기업 문화 지원제도 탭 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '10 / 15 / 20 / 25 / 30년 근속자 포상 (공식 채용 페이지 기업 문화 지원제도 장기근속 항목, 동원그룹 공통 문구) — 포상 내용·금액 미기재', 50),

  -- ── 건강 (health) — 기업 문화 지원제도 탭 ──
  (@comp_id, 'insurance', '단체상해보험 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 질병 및 상해 보장 (공식 채용 페이지 기업 문화 지원제도 단체상해보험 지원 항목, 동원그룹 공통 문구) — 보장 한도·가족 포함 여부 미기재', 60),
  (@comp_id, 'health_check', '정기 건강검진', NULL, 'health',
   'est', NULL, TRUE, '정기 건강검진 실시 (공식 채용 페이지 기업 문화 지원제도 건강검진 및 심리상담 항목, 동원그룹 공통 문구) — 검진 주기·비용 지원 범위 미기재', 61),
  (@comp_id, 'mental', '심리·건강 상담', NULL, 'health',
   'est', NULL, TRUE, '전문 심리/건강 상담 (공식 채용 페이지 기업 문화 지원제도 건강검진 및 심리상담 항목, 동원그룹 공통 문구) — 상담 방식·이용 횟수 미기재', 62),
  (@comp_id, 'fitness', '피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '본사, 사업장 피트니스 센터 운영 (공식 채용 페이지 기업 문화 지원제도 피트니스 센터 항목, 동원그룹 공통 문구) — 사업장별 운영 여부 미기재', 63),

  -- ── 여가 (leisure) — 기업 문화 지원제도 탭 ──
  (@comp_id, 'resort', '휴양시설 지원', NULL, 'leisure',
   'est', NULL, TRUE, '전국 주요 관광지 24개 유명 리조트 (공식 채용 페이지 기업 문화 지원제도 휴양시설지원 항목, 동원그룹 공통 문구) — 이용 일수·비용 지원 범위 미기재', 70),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 동호회 활동 지원 (공식 채용 페이지 기업 문화 지원제도 동호회 활동 지원 항목, 동원그룹 공통 문구) — 지원 금액·지원 방식 미기재', 71),

  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용 여부 활용 · 시차출퇴근제 사용자 2024년 4명 · 2025년 8명 · 2026년 상반기 16명 (2026 반기보고서 유연근무제도 사용 현황 표 항목) — 출퇴근 시간대·대상 직무 미기재', 80),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용 여부 활용 · 원격근무제(재택근무 포함) 사용자 2024년 12명 · 2025년 5명 · 2026년 상반기 2명 (2026 반기보고서 유연근무제도 사용 현황 표 항목) — 대상 직무·사용 조건 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
