-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 대웅제약 복리후생 데이터 (신규 회사 — 웨이브 6)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.daewoong.co.kr/files/esg/ESG/2026_Daewoong_Pharmaceutical_Sustainability_Report(KOR).pdf
-- badge: est
--
-- 참고:
--   정본 = 대웅제약 자기 도메인 발행 2026 지속가능경영보고서 PDF(발간 2026-06-30 · 보고 기간 2025-01-01~12-31)
--     68 · 69 · 70쪽(GRI 401-2 지정 지면) + 67쪽 인재 육성 프로그램 표. 주어가 전부 대웅제약은 인 문장만 옮겼다.
--     보고서 범위는 대웅 · 대웅제약 · 대웅바이오 3사 비재무 정보를 포함하므로 117쪽 복리후생비 같은 합산 숫자는 싣지 않았다.
--     PDF 텍스트 추출(pypdf) · 프로브 사본 재사용(sha256 539490df…c6f55a6a) · 헤드리스 렌더 없음.
--   보조 = 대웅그룹 통합 채용 사이트 career.daewoong.co.kr/about-dw/benefit 주요제도(저작권 Daewoong, Inc. · 법인 구분 없음).
--     기등록 대웅 계열 0 → 이 페이지에만 있는 4행(자율좌석제 · 무제한 교육지원 · 도서지원 · 사내북카페)은
--     서술 끝에 (그룹 통합 채용 기준) 각주. 보고서 근거 행은 각주 없음.
--   공시 = 2025 사업보고서(접수 20260318001528) 직원 등 현황 유연근무제도 주석 — 유연근무제 행 보강에만 썼다.
--   금액: 원문 원 단위 숫자는 리프레시 기간 자기계발 교육비 최대 100만 원 하나 — 한도라 금액 미등록.
--     금액 행 0(stated 0 · 추정 0). 식대 원문 없음.
--   제외: 출산휴가 · 육아휴직 · 모성보호 제도(법정) · 거현량 · 월별 피드백 · 평가 체계 · 직무급(평가 · 보상 체계) ·
--     AX 교육 · AI 활용 교육 · 입문 · 온보딩 · 직책자 교육(업무 교육) · 베어마트(장애인 고용) ·
--     130쪽 목표표의 사내 어린이집 낱말(본문 서술 없음) · 우리사주조합(주주 표 한 칸뿐) · 임원 성과인센티브.
--   공고 근거 0행 / 전체 16행.
--   SORT 섹션 순서(정본 68~70쪽에 처음 나온 순서): health 10 · flexibility 20 · work_env 30 · time_off 40 ·
--     growth 50 · leisure 60 · family 70. 섹션 안은 보고서 행 뒤에 그룹 채용 사이트 행.
-- 검증 · 감사 판정 반영(2026-10-14): 원격근무제 (조건부) remote_work 를 유연근무 행에서 떼어 추가 · 130쪽 사내 어린이집 childcare 추가(참고 블록 제외 목록의 어린이집 낱말 줄은 이 판정으로 뒤집힘) · 학자금 child_edu 유지 — 최종 18행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('daewoong_pharm', '대웅제약',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '제약', 'D', 'https://www.daewoong.co.kr/files/esg/ESG/2026_Daewoong_Pharmaceutical_Sustainability_Report(KOR).pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'daewoong_pharm');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.daewoong.co.kr/files/esg/ESG/2026_Daewoong_Pharmaceutical_Sustainability_Report(KOR).pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 보고서 68 · 69 · 70쪽 ──
  (@comp_id, 'fitness', '대웅지킴이·웰다·웰니스 프로그램', NULL, 'health',
   'est', NULL, TRUE, '근골격계 질환 예방과 건강 증진을 위해 힐리언스 코어 운동센터와 연계한 맞춤형 운동 프로그램 운영, 그룹운동과 1:1 전문 코칭 제공, 오송공장과 용인연구소까지 운영 범위 확대 (2026 지속가능경영보고서 69쪽 대웅지킴이 프로그램), 대사 건강 관리 플랫폼 웰다로 혈당 관리 디바이스와 모바일 앱 연동, 식사 분석·개인화된 AI 코칭, 2025년 전사 확대 적용 추진 (68쪽 대사질환 및 비만 관리 프로그램), 명상·요가·싱잉볼 등 힐링 프로그램을 통한 웰니스 프로그램 운영 (68쪽 웰니스 리조트 프로그램 운영 항목) — 이용 비용·참여 횟수 미기재', 10),
  (@comp_id, 'health_check', '가족 대상 종합 건강검진', NULL, 'health',
   'est', NULL, TRUE, '가족 생애주기 전반의 복지제도로 가족 대상 종합 건강검진 지원 (2026 지속가능경영보고서 70쪽 워킹맘·대디 업무지원 제도 운영), 건강검진 결과가 실질적인 건강 증진으로 이어지도록 AI 기반 건강관리 플랫폼 비즈 36.5 도입, AI 챗봇 나만의 건강 AI코치를 통한 검진 결과 설명과 개인 맞춤형 건강관리 가이드 (69쪽 AI 기반 건강관리 플랫폼), 건강검진 결과 당뇨·고혈압 유소견 및 유질환 임직원 대상 만성질환 관리 플랫폼 웰체크 지원, 연속혈당측정기·혈압측정기 연동 정밀 측정과 생활습관 개선 코칭 (68쪽 만성질환 관리) — 검진 주기·비용 지원 범위·가족 범위 미기재', 11),

  -- ── 근무 유연성 (flexibility) — 보고서 68쪽 + 2025 사업보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '자율적으로 성과를 창출할 수 있는 임직원을 대상으로 유연근무제 운영, 출퇴근 시간을 자율적으로 선택 (2026 지속가능경영보고서 68쪽 자율적 업무 몰입환경 조성 항목), 시차출퇴근제·선택근무제를 직무 특성, 질환, 주거 여건, 임신 및 출산 등 내부 기준에 따른 특별 사유로 활용 (2025 사업보고서 직원 등 현황 유연근무제도 항목) — 코어타임·신청 절차 미기재', 20),
  (@comp_id, 'workation', '워케이션·힐링 연수', NULL, 'flexibility',
   'est', NULL, TRUE, '자연 속에서 업무와 휴식을 병행할 수 있는 워케이션 및 힐링 연수 프로그램 운영, 업무 공간과 웰니스 프로그램 함께 제공 (2026 지속가능경영보고서 68쪽 워케이션 및 힐링 연수 지원 항목) — 이용 기간·장소·대상 미기재', 21),
  (@comp_id, 'remote_work', '원격근무제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '근무 장소를 자율적으로 선택할 수 있도록 지원 (2026 지속가능경영보고서 68쪽 자율적 업무 몰입환경 조성 항목), 원격근무제를 직무 특성, 질환, 주거 여건, 임신 및 출산 등 내부 기준에 따른 특별 사유로 활용 (2026 반기보고서 직원 등 현황 유연근무제도 항목) — 원격근무 장소·횟수·신청 절차 미기재', 22),

  -- ── 근무 환경 (work_env) — 보고서 68 · 70쪽 + 그룹 채용 사이트 스마트워크 ──
  (@comp_id, 'smart_office', '스마트오피스 (베어코웍)', NULL, 'work_env',
   'est', NULL, TRUE, '본사·연구소·공장·지점 전 사업장에 스마트오피스를 구축하여 베어코웍(Bear Cowork), 스마트오피스, 스마트 IT 등 다양한 형태의 자율근무환경 운영 (2026 지속가능경영보고서 68쪽 자율적 업무 몰입환경 조성 항목) — 사업장별 규모·좌석 운영 방식 미기재', 30),
  (@comp_id, 'lounge', '캡슐룸·힐링존', NULL, 'work_env',
   'est', NULL, TRUE, '캡슐룸 및 힐링존 운영 (2026 지속가능경영보고서 70쪽 가족친화 선도기업 선정 항목) — 설치 사업장·이용 시간 미기재', 31),
  (@comp_id, 'free_seating', '자율좌석제', NULL, 'work_env',
   'est', NULL, TRUE, '시간과 장소의 제약 없는 스마트워크로 자율좌석제 (대웅그룹 채용 사이트 주요제도 스마트워크 항목) — 적용 사업장·좌석 운영 방식 미기재 (그룹 통합 채용 기준)', 32),

  -- ── 휴가 (time_off) — 보고서 68쪽 ──
  (@comp_id, 'long_service_leave', '장기 리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '5년 이상 근속한 임직원에게 4주간의 유급휴가 제공 (2026 지속가능경영보고서 68쪽 장기리프레시휴가 및 자기계발지원 항목) — 사용 시기·분할 사용 여부 미기재', 40),

  -- ── 성장·교육 (growth) — 보고서 67 · 68쪽 + 그룹 채용 사이트 무제한 교육지원 ──
  (@comp_id, 'self_development', '리프레시 기간 자기계발 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '리프레시 기간 동안 자기계발 교육이 필요한 경우 최대 100만 원까지 교육비 지원 (2026 지속가능경영보고서 68쪽 장기리프레시휴가 및 자기계발지원 항목) — 지원 대상 교육 범위 미기재', 50),
  (@comp_id, 'career', 'CDP·글로벌 우수 인재 프로그램', NULL, 'growth',
   'est', NULL, TRUE, 'CDP(Career Development Program) 제도를 통해 직원이 스스로 커리어패스를 설계하고 다양한 유관 직무 경험 (2026 지속가능경영보고서 67쪽 인재 육성 프로그램 CDP 항목), 현지 언어·문화 교육, 해외지사 탐방 및 체험 근무 등 글로벌 우수 인재 프로그램 (같은 표 글로벌 우수 인재 프로그램 항목) — 선발 기준·파견 기간·이동 신청 주기 미기재', 51),
  (@comp_id, 'edu_support', '무제한 교육지원', NULL, 'growth',
   'est', NULL, TRUE, '사내/외 교육, 사이버연수원 등 업무와 관련된 내용이라면 언제든 무제한으로 학습할 수 있는 환경 제공 (대웅그룹 채용 사이트 주요제도 무제한 교육지원 항목) — 사외 교육비 한도·신청 절차 미기재 (그룹 통합 채용 기준)', 52),
  (@comp_id, 'books', '도서지원', NULL, 'growth',
   'est', NULL, TRUE, '업무와 관련된 내용이라면 언제든 무제한으로 학습할 수 있도록 도서지원 (대웅그룹 채용 사이트 주요제도 무제한 교육지원 항목) — 지원 한도·지원 방식 미기재 (그룹 통합 채용 기준)', 53),

  -- ── 여가 (leisure) — 보고서 68쪽 + 그룹 채용 사이트 무제한 교육지원 ──
  (@comp_id, 'resort', '대웅가족리프레시', NULL, 'leisure',
   'est', NULL, TRUE, '임직원과 가족이 함께 재충전할 수 있도록 연 2회, 1박 2일 힐링 프로그램 운영, 그룹사 휴양시설인 선마을 힐리언스와 대웅경영개발원 중 원하는 장소 선택 (2026 지속가능경영보고서 68쪽 대웅가족리프레시 프로그램 운영 항목) — 비용 부담·가족 범위 미기재', 60),
  (@comp_id, 'library', '사내북카페', NULL, 'leisure',
   'est', NULL, TRUE, '사내북카페 (대웅그룹 채용 사이트 주요제도 무제한 교육지원 항목) — 설치 사업장·운영 시간 미기재 (그룹 통합 채용 기준)', 61),

  -- ── 가족 (family) — 보고서 70쪽 ──
  (@comp_id, 'parenting', '출산축하금·자녀 입학축하금', NULL, 'family',
   'est', NULL, TRUE, '가족 생애주기 전반의 복지제도로 출산축하금, 자녀 입학축하금 지원 (2026 지속가능경영보고서 70쪽 워킹맘·대디 업무지원 제도 운영) — 지급 금액·입학 학교 급 미기재', 70),
  (@comp_id, 'child_edu', '학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '가족 생애주기 전반의 복지제도로 학자금 지원 (2026 지속가능경영보고서 70쪽 워킹맘·대디 업무지원 제도 운영) — 지원 대상·학교 급·지원 한도 미기재', 71),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 (2026 지속가능경영보고서 130쪽 목표 추진 주요 활동 항목) — 설치 사업장·정원·이용 대상 미기재', 72)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
