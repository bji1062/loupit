-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 오리온 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://www.orionworld.com/theme/102114/kr/assets/upload/%EC%98%A4%EB%A6%AC%EC%98%A8_2025_ESG_%EB%B3%B4%EA%B3%A0%EC%84%9C(%EA%B5%AD%EB%AC%B8).pdf
-- badge: est
--
-- 참고:
--   정본은 (주)오리온이 직접 발행한 오리온 2025 ESG 보고서 국문 PDF(116쪽, 보고 기간 2025-01-01~12-31)다.
--   법인 자기 도메인 www.orionworld.com 윤리경영 > ESG > ESG 보고서 목록 /html/67 의 다운로드 링크.
--   26쪽 복리후생 한 줄 나열과 27쪽 근로제도/프로그램 표가 정본 구간이고, GRI Index 111쪽이
--   401-2 복리후생 공시 쪽을 26-27 로 스스로 지정한다. 보조는 23~24쪽 임직원 교육체계와 주요 교육 프로그램.
--   렌더 방식: PDF 텍스트 레이어(pypdf 추출). 헤드리스 렌더 0회. 프로브가 받은 사본을 그대로 썼다.
--   귀속: 26~27쪽 문장 주어가 모두 오리온은 이고 그룹 공통 또는 계열사별 상이 단서가 없다.
--     지주 오리온홀딩스 내용(58쪽 배당 · 64~67쪽 지배구조)과 해외 법인 문구는 근거로 쓰지 않았다.
--     기등록 형제 0곳. 그룹 각주 없음.
--   자기 도메인에 채용 · 복리후생 HTML 페이지가 없다. 정규직 ATS orion.recruiter.co.kr/appsite 는
--     robots 금지라 요청하지 않았고, 영업사원 채용 사이트 recruitsales.orionworld.com(2015 표기 ·
--     영업직 전용)은 리드 판정 W5-5 로 쓰지 않았다.
--   금액: 원문에 복지 금액이 0건이라 20행 전부 BENEFIT_AMT NULL(stated 0 · 추정 0). 타사 금액을 쓰지 않았다.
--   제외: 법정(배우자 출산휴가 · 임신기/육아기 단축근무 · 육아휴직 · 가족돌봄휴직 · 특수건강진단 ·
--     대체휴무제) · 업무 교육(입문 · OJT · 멘토링 · 온보딩 · 승격자 · 리더십 · 직무 · 외부 위탁 ·
--     글로벌 인재파견 교육 · 사내 MBA OBS) · 임원 어학교육 · 임직원 소통 제도 · 대리점 대상 복리후생(53~54쪽) ·
--     협력사 대상 복지시설 개방(21쪽).
--   공고 근거 0행 / 전체 20행.
--   SORT 섹션 순서(정본 26~27쪽 첫 등장 순): flexibility 10 · perks 20 · family 30 · health 40 ·
--     leisure 50 · time_off 60 · compensation 70 · work_env 80 · growth 90(보조 23~24쪽).
-- 검증 · 감사 판정 반영(2026-10-10): 마음돌봄서비스 mental 추가 · 관리자 KPI 성과급 연계 문장은 싣지 않음 — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('orion', '오리온',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품', 'O', 'https://www.orionworld.com/theme/102114/kr/assets/upload/%EC%98%A4%EB%A6%AC%EC%98%A8_2025_ESG_%EB%B3%B4%EA%B3%A0%EC%84%9C(%EA%B5%AD%EB%AC%B8).pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'orion');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.orionworld.com/theme/102114/kr/assets/upload/%EC%98%A4%EB%A6%AC%EC%98%A8_2025_ESG_%EB%B3%B4%EA%B3%A0%EC%84%9C(%EA%B5%AD%EB%AC%B8).pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 2025 ESG 보고서 26~27쪽 ──
  (@comp_id, 'remote_work', '장애인 직원 재택근무 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '장애인 직원들을 위한 재택근무 시행 (2025 ESG 보고서 26쪽 DE&I 존중 문화 표 업무환경 개선 항목) — 적용 기준·재택 일수 미기재', 10),
  (@comp_id, 'family_day', '패밀리데이', NULL, 'flexibility',
   'est', NULL, TRUE, '패밀리데이 (2025 ESG 보고서 27쪽 근로제도/프로그램 일과 삶의 균형 항목) — 운영 주기·운영 방식 미기재', 11),
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '구성원의 워라밸 향상 및 유연한 근무여건 조성을 위한 제도 운영, 유연근무제 (2025 ESG 보고서 27쪽 근로제도/프로그램 일과 삶의 균형 항목) — 제도 유형·적용 대상 미기재', 12),
  (@comp_id, 'pc_off', 'PC-off제', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-off제 (2025 ESG 보고서 27쪽 근로제도/프로그램 일과 삶의 균형 항목) — 적용 시간·예외 절차 미기재', 13),

  -- ── 생활 편의 (perks) — 2025 ESG 보고서 26쪽 ──
  (@comp_id, 'welfare_point', '복지포인트·복지몰', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트/복지몰 (2025 ESG 보고서 26쪽 복리후생 항목) — 포인트 배정액·사용처 미기재', 20),
  (@comp_id, 'meal', '무료 사내식당·외식비 지원', NULL, 'perks',
   'est', NULL, TRUE, '외식비 지원, 무료사내식당 (2025 ESG 보고서 26쪽 복리후생 항목) — 제공 끼니·외식비 지원 금액 미기재', 21),
  (@comp_id, 'discount', '자사제품 할인', NULL, 'perks',
   'est', NULL, TRUE, '자사제품 할인 (2025 ESG 보고서 26쪽 복리후생 항목) — 할인율·구매 한도 미기재', 22),

  -- ── 가족 (family) — 2025 ESG 보고서 26~27쪽 ──
  (@comp_id, 'child_edu', '학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원 (2025 ESG 보고서 26쪽 복리후생 항목) — 지원 대상(본인·자녀)·학교급·한도 미기재', 30),
  (@comp_id, 'event', '경조금·경조휴가 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금/경조휴가 지원 (2025 ESG 보고서 26쪽 복리후생 항목) — 경조 사유별 금액·휴가 일수 미기재', 31),
  (@comp_id, 'parenting', '출산 축하금·임신 축하선물', NULL, 'family',
   'est', NULL, TRUE, '출산 축하금, 임신 축하선물 (2025 ESG 보고서 27쪽 근로제도/프로그램 모성보호 항목) — 축하금 금액·선물 내용 미기재', 32),

  -- ── 건강 (health) — 2025 ESG 보고서 26쪽 ──
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (2025 ESG 보고서 26쪽 복리후생 항목) — 지원 대상(본인·가족)·지원 한도 미기재', 40),
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '건강검진 지원 (2025 ESG 보고서 26쪽 복리후생 항목) — 검진 주기·비용 지원 범위 미기재', 41),
  (@comp_id, 'mental', '마음돌봄서비스', NULL, 'health',
   'est', NULL, TRUE, '임직원이 행복한 일상을 향유할 수 있도록 통합 심리적 지원프로그램인 「마음돌봄서비스」 제공, 스트레스 등으로 인한 심리적 이슈 해결 지원, 2025년 이용 인원 40명·이용 횟수 120회 (2025 ESG 보고서 16쪽 인권 고충처리 채널 항목) — 상담 방식·비용 지원 범위 미기재', 42),

  -- ── 여가 (leisure) — 2025 ESG 보고서 26쪽 ──
  (@comp_id, 'resort', '콘도 할인', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 할인 (2025 ESG 보고서 26쪽 복리후생 항목) — 할인 범위·이용 가능 시설 미기재', 50),

  -- ── 휴가 (time_off) — 2025 ESG 보고서 27쪽 ──
  (@comp_id, 'leave_general', '징검다리 연휴·특별휴가', NULL, 'time_off',
   'est', NULL, TRUE, '징검다리 연휴/특별휴가 운영 (2025 ESG 보고서 27쪽 근로제도/프로그램 일과 삶의 균형 항목) — 연차 사용일인지·일수·유급 여부 미기재', 60),

  -- ── 보상 (compensation) — 2025 ESG 보고서 27쪽 ──
  (@comp_id, 'excellence_award', '윤리경영 실천·신제품 개발·공로 포상', NULL, 'compensation',
   'est', NULL, TRUE, '회사의 성장과 발전에 기여한 구성원에 대한 공로를 치하하고 동기부여를 위한 제도 운영, 윤리경영 실천 우수포상, 신제품 개발 포상, 공로 포상 (2025 ESG 보고서 27쪽 근로제도/프로그램 포상제도 항목) — 포상 기준·포상 내용 미기재', 70),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 (2025 ESG 보고서 27쪽 근로제도/프로그램 포상제도 항목) — 근속 기준 연수·포상 내용 미기재', 71),

  -- ── 근무 환경 (work_env) — 2025 ESG 보고서 27쪽 ──
  (@comp_id, 'nap_room', '맘스룸', NULL, 'work_env',
   'est', NULL, TRUE, '맘스룸 (2025 ESG 보고서 27쪽 근로제도/프로그램 모성보호 항목) — 설치 사업장·이용 시간 미기재', 80),

  -- ── 성장 (growth) — 2025 ESG 보고서 23~24쪽 (보조) ──
  (@comp_id, 'lang', '사내 어학교육·전화외국어', NULL, 'growth',
   'est', NULL, TRUE, '사내 어학교육(영어/중국어/베트남어) (2025 ESG 보고서 23쪽 임직원 교육체계, 24쪽 Global 인재 육성 해당 임직원 대상 사내 어학과정), 전 임직원 대상 사이버 연수원 전화외국어 (24쪽 임직원 주요 교육 프로그램) — 수강 대상 선발 기준·수강료 부담 미기재', 90),
  (@comp_id, 'edu_support', '사이버 연수원·임직원 특강', NULL, 'growth',
   'est', NULL, TRUE, '전 임직원 대상 사이버 연수원(온라인/독서통신/마이크로러닝) (2025 ESG 보고서 24쪽 임직원 주요 교육 프로그램), 임직원 특강(경제 전망/트렌드/시장 변화/AI 이해 등) (23쪽 임직원 교육체계) — 수강 한도·과정 수 미기재', 91),
  (@comp_id, 'mba', 'MBA 양성과정 (핵심 인재 대상)', NULL, 'growth',
   'est', NULL, TRUE, '핵심 인재 대상 MBA 양성과정(연세대 AMBA 과정 위탁) (2025 ESG 보고서 24쪽 임직원 주요 교육 프로그램, 23쪽 MBA 양성 과정(외부 대학)) — 선발 기준·학비 지원 범위 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
