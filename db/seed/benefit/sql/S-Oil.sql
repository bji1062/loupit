-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- S-Oil 복리후생 데이터
-- 출처: AI 파싱 (2026-09-26)
-- URL: https://www.s-oil.com/company/recruit/Benefit.aspx
-- badge: est
--
-- 참고:
-- 재수집(2026-09-26): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다 — 대조 보고서 2026-09-25-official-compare
-- 감사(RA-1 2026-09-26) 반영: health_check 100 추정 승계 · 긴급자금 융자 welfare_fund_loan 분리 · 체육행사 company_event 분리 · 탄력적 근로시간제 flex_work · CEO 표창제도 excellence_award 추가
--   정본은 S-OIL 주식회사 자기 도메인 www.s-oil.com 의 인재채용 > 인사정보 탭 세 페이지와 2025 ESG 보고서다.
--     ① https://www.s-oil.com/company/recruit/Benefit.aspx (복리후생 6묶음 — CAREERS_BENEFIT_URL)
--     ② https://www.s-oil.com/company/recruit/HRSystem.aspx (인사제도 > 조직문화 프로그램 3항목)
--     ③ https://www.s-oil.com/company/recruit/Support.aspx (인재육성)
--     ④ 2025 S-OIL ESG 보고서 국문 PDF (www.s-oil.com FileDownload.aspx, 보고기간 2025-01-01~12-31,
--        PDF 26쪽 신체·마음 건강 관리 · 31쪽 여성 친화적 환경 조성·업무 효율성 증대 · 32쪽 선도적인 복리후생·기타 복지 프로그램)
--   ①②③ 은 서버렌더 텍스트라 이미지 판독이 필요 없다(소제목만 이미지 alt). 원문 사본은 2026-09-25 대조 때 받은 것을
--   재사용했다(이번 세션 신규 요청 0회). robots.txt 는 HTML 점검 페이지를 돌려줘 규칙 없음으로 처리.
--   단일 법인(본사 마포·공장 울산) 자기 도메인이라 그룹 통합 각주는 없다.
--
--   조건을 되살렸다: KTX 교통비와 독신사원 주거비용은 ① 의 엔지니어(공장근무) 관련 묶음 항목이라
--     행 서술에 공장 근무 엔지니어 대상을 적었다. 주거지원은 두 항목 모두 독신 대상이다.
--   구본의 덧붙임을 걷었다: 사우회·장제용품·생일선물 · 재해지원 최고 2천만원 · 스트레칭 타임 ·
--     Job Posting(② 에서 HTML 주석 처리된 블록 — 유령) · 매주 수요일 패밀리데이 · 매월 KTX · 10년간 연금 ·
--     동/하계 휴양소 · 사택. 어느 공식 원문에도 없다.
--   빠진 공식 항목을 채웠다: 직장 어린이집 · 체력단련실 · 건강관리센터 · 출산 축하금·산후조리원 ·
--     중식 · Refreshment Point · 장기근속 기념품·기념여행 · PC-OFF · 부임준비금·이사비.
--   재코딩 1: dormitory → housing_support (원문 라벨이 주거지원·주거비용 지원이고 사택·기숙사 시설 언급이 없다).
--   구본에서 뺀 행 4: family_day(원문 없음) · edu_support·lang(사내 교육 과정 운영 — 비용 지원 아님) ·
--     career(Job Rotation 은 인사제도, 멘토링은 신입 적응 과정).
--   금액: 원문 명시 금액 0건. 구본 추정치 4건 승계(incentive 500 · medical 100 · child_edu 300 · resort 50, NOTE 끝 추정 표기).
--     구본 health_check 100 은 추정 표기 없는 수치라 승계하지 않았다. event·transport·pension_support 추정치는
--     1회성·주기 가정·구조 불일치라 버렸다.
--   제외: 기본급·제수당·수당 지원·T&I수당(급여성) · 퇴직금 누진율(퇴직급여) · 무재해기념금·무재해 기념품(대응 어휘 없음) ·
--     탄력적 근로시간제(부서 상황·업무량에 따른 회사 운영 제도) · 난임치료휴가·수유실·육아휴직 대체인력 ·
--     비자발적 퇴직자 전직 지원 · CEO 표창제도 · S-OIL AI Assistant · 사내 익명게시판 · 신입 집합교육·OJT·멘토링·Dynamic Rookies.
--   SORT 섹션 순서는 ① 페이지에서 카테고리가 처음 나온 순서다
--     (compensation 10 · health 20 · perks 30 · family 40 · leisure 50 · time_off 60 · flexibility 70 · growth 80).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('s_oil', 'S-Oil',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '정유/화학', 'S', 'https://www.s-oil.com/company/recruit/Benefit.aspx');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 's_oil');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.s-oil.com/company/recruit/Benefit.aspx'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'bonus', '상여금', NULL, 'compensation',
   'est', NULL, TRUE, '상여금 연 800% (공식 채용 페이지 인사정보 복리후생 급여제도 항목 — 지급 시기·분할 방식 미기재)', 10),
  (@comp_id, 'incentive', '성과급', 500, 'compensation',
   'est', '성과급 경영실적에 따라 지급 (공식 채용 페이지 인사정보 복리후생 급여제도 항목 — 지급률·지급액 미기재) (추정)', FALSE, NULL, 11),
  (@comp_id, 'long_service_bonus', '장기근속 기념품·기념여행', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 기념품 및 기념여행 (2025 ESG 보고서 기타 복지 프로그램 항목 — 근속 연수 기준·여행 내용 미기재)', 12),
  (@comp_id, 'excellence_award', 'CEO 표창제도', NULL, 'compensation',
   'est', NULL, TRUE, '핵심가치에 기반한 CEO 표창제도 운영 (2025 ESG 보고서 핵심가치 내재화 항목 — 포상 내용·선정 기준 미기재)', 13),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인/배우자 및 자녀 치료비 및 병실료 지원 (공식 채용 페이지 인사정보 복리후생 건강증진 지원 항목 — 지원 한도 미기재) (추정)', FALSE, NULL, 20),
  (@comp_id, 'health_check', '정기 건강검진 (본인·배우자)', 100, 'health',
   'est', '임직원 본인·배우자 일반검진 또는 종합검진, 성인병·암을 포함한 종합 건강진단과 선택적·집중 검진 (공식 채용 페이지 인사정보 복리후생 건강증진 지원 항목·2025 ESG 보고서 — 검진 비용 한도 미기재) (추정)', FALSE, NULL, 21),
  (@comp_id, 'mental', '심리상담 (가족 포함)', NULL, 'health',
   'est', NULL, TRUE, '직장, 가정, 대인관계 등 일상생활에서 겪는 고충 해결을 위한 외부 전문기관의 심리상담 서비스 제공 (공식 채용 페이지 인사정보 인사제도 조직문화 프로그램 항목). 2025 ESG 보고서는 임직원 및 가족(배우자 및 자녀) 대상 심리 상담 외 법률, 재무 등 전문가 상담도 지원한다고 기재 — 이용 횟수 미기재', 22),
  (@comp_id, 'fitness', '사내 체력단련실', NULL, 'health',
   'est', NULL, TRUE, '사내 체력단련실 운영 (공식 채용 페이지 인사정보 인사제도 조직문화 프로그램 항목). 2025 ESG 보고서는 본사와 공장에서 운영 중으로 기재 — 이용 시간·이용료 미기재', 23),
  (@comp_id, 'clinic', '건강관리센터 (간호사 상시 근무)', NULL, 'health',
   'est', NULL, TRUE, '사내 건강관리센터 운영 (공식 채용 페이지 인사정보 인사제도 조직문화 프로그램 항목). 2025 ESG 보고서는 본사와 공장에 간호사 상시 근무, 응급처치·의약품 제공으로 기재하고 무료 독감 예방접종·기초질환 관리·금연 및 비만 관리 등 건강 증진 프로그램도 기재 — 운영 시간 미기재', 24),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'housing_loan', '주택자금 융자', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입/전세자금 장기 저리융자 (공식 채용 페이지 인사정보 복리후생 생활지원 항목). 2025 ESG 보고서는 주택자금 저금리 융자로 기재 — 융자 한도·이율 미기재', 30),
  (@comp_id, 'pension_support', 'New Pension', NULL, 'perks',
   'est', NULL, TRUE, 'New Pension 지원 (공식 채용 페이지 인사정보 복리후생 생활지원 항목). 2025 ESG 보고서는 2015년 도입, 회사의 중장기적인 경영성과에 따라 차등적으로 적립되는 구조로 기재 — 적립 금액·수령 조건 미기재', 31),
  (@comp_id, 'housing_support', '주거 지원 (독신 사원)', NULL, 'perks',
   'est', NULL, TRUE, '주거지원 독신부 임시주거 지원 (공식 채용 페이지 인사정보 복리후생 생활지원 항목), 공장 근무 엔지니어 대상 독신사원 주거비용 지원 (같은 페이지 엔지니어(공장근무) 관련 항목) — 지원 금액·기간 미기재', 32),
  (@comp_id, 'transport', 'KTX 교통비 지원 (공장 근무 엔지니어)', NULL, 'perks',
   'est', NULL, TRUE, '공장 근무 엔지니어 대상 교통비 지원, KTX 왕복기준 2회 지원 (공식 채용 페이지 인사정보 복리후생 엔지니어(공장근무) 관련 항목 — 지원 주기·구간 미기재)', 33),
  (@comp_id, 'welfare_point', 'Refreshment Point', NULL, 'perks',
   'est', NULL, TRUE, 'Refreshment Point 지급 (공식 채용 페이지 인사정보 복리후생 여가활동지원 항목, 2025 ESG 보고서 기타 복지 프로그램 항목 — 연간 포인트 금액·사용처 미기재)', 34),
  (@comp_id, 'relocation', '부임준비금·이사비', NULL, 'perks',
   'est', NULL, TRUE, '이동명령을 받은 임직원에게 부임준비금 및 이사비 지원 (2025 ESG 보고서 주거 및 생활안정지원 항목 — 지원 금액 미기재)', 35),
  (@comp_id, 'meal', '중식 지원', NULL, 'perks',
   'est', NULL, TRUE, '중식 지원 (2025 ESG 보고서 기타 복지 프로그램 항목 — 제공 방식·식대 단가 미기재)', 36),
  (@comp_id, 'welfare_fund_loan', '긴급자금 융자', NULL, 'perks',
   'est', NULL, TRUE, '재해나 의료 등 긴급한 사유로 대출이 필요한 임직원에게 일정 한도 내 자금 융자 (2025 ESG 보고서 주거 및 생활안정지원 항목 — 융자 한도·이율 미기재)', 37),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '유치원, 초등, 중등자녀 매분기 정액 지원, 고등학생·대학생자녀 등록금/수업료 전액 지원, 지체장애/자폐증자녀 특수교육비 추가지원 (공식 채용 페이지 인사정보 복리후생 생활지원 항목 — 정액 금액·자녀 수 한도 미기재) (추정)', FALSE, NULL, 40),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 발생시 축하/위로금 지급, 특별휴가 부여 (공식 채용 페이지 인사정보 복리후생 회사생활지원 항목 — 경조금 금액·휴가 일수 미기재)', 41),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '2017년부터 운영해 온 직장 어린이집, 육아를 하는 본사 및 공장 전 직원 대상 (2025 ESG 보고서 여성 친화적 환경 조성 항목 — 정원·이용료 미기재)', 42),
  (@comp_id, 'parenting', '출산 축하금·산후조리원 지원', NULL, 'family',
   'est', NULL, TRUE, '출산 축하금 지급, 산후조리원 지원, 임산부 사무기구 지원 (2025 ESG 보고서 여성 친화적 환경 조성 항목 — 축하금·지원 금액 미기재)', 43),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 활동 장려 및 운영비 지원 (공식 채용 페이지 인사정보 복리후생 회사생활지원 항목 — 운영비 금액 미기재)', 50),
  (@comp_id, 'resort', '법인콘도 지원', 50, 'leisure',
   'est', '법인콘도 지원 (2025 ESG 보고서 기타 복지 프로그램 항목 — 이용 횟수·본인 부담 미기재) (추정)', FALSE, NULL, 51),
  (@comp_id, 'company_event', '체육의 날·노사화합체육대회', NULL, 'leisure',
   'est', NULL, TRUE, '체육의 날 행사, 노사화합체육대회 (공식 채용 페이지 인사정보 복리후생 여가활동지원 체육활동지원 항목 — 개최 주기·참가 대상 미기재)', 52),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '집중휴가제·2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '집중휴가제 실시, 연 1회 2주간 휴가사용 의무화(사무직/기술직) (공식 채용 페이지 인사정보 복리후생 여가활동지원 항목). 2025 ESG 보고서는 2주간의 집중휴가 제도와 함께 휴가를 2시간 단위로 분할 사용하는 제도로 기재', 60),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'Smart Work 제도, PC-OFF 제도 등 정시 퇴근문화 정착 (공식 채용 페이지 인사정보 인사제도 조직문화 프로그램 항목. 2025 ESG 보고서는 전사 운영으로 기재 — 적용 시각·예외 절차 미기재)', 70),
  (@comp_id, 'flex_work', '탄력적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '부서 상황과 업무량을 감안해 근로시간을 탄력적으로 운영하는 탄력적 근로시간제(2019년부터), 전사 PC-Off 제도와 함께 근무시간 자율 조정 지원 (2025 ESG 보고서 업무 효율성 증대 항목 — 적용 부서·정산 단위 미기재)', 71),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'conference', '외부 세미나·컨퍼런스 참여 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무와 관련한 외부 세미나 또는 컨퍼런스 참여를 적극 지원 (공식 채용 페이지 인사정보 인재육성 Global 인재 육성 항목 — 지원 비용 범위 미기재)', 80),
  (@comp_id, 'mba', '국내외 MBA·IFP School 석사과정', NULL, 'growth',
   'est', NULL, TRUE, '우수직원을 대상으로 국내외 MBA 유학과 프랑스 IFP School 이공계 석사과정 지원 (공식 채용 페이지 인사정보 인재육성 Global 인재 육성 항목 — 선발 인원·비용 부담 범위 미기재)', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
