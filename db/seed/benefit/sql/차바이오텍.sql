-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 차바이오텍 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.chabio.com/esg/social.cha
-- badge: est
--
-- 참고:
--   정본 = 차바이오텍 자기 도메인(OpenDART 홈 주소 www.chabio.com) ESG 경영 사회 페이지 가족친화 근로환경 조성 절
--     (유연근무 및 근로시간 제도 · 복지·지원 및 조직문화 제도 목록) + 근로자 교육훈련 프로그램 절 + 임직원보상 프로그램 절.
--     주어는 당사(주식회사 차바이오텍). SSR 원본 HTML 에 본문이 있다 · 헤드리스 렌더 없음.
--     같은 페이지가 http://www.chabiotech.co.kr/esg/social.cha 에도 바이트까지 같게 실려 있다(sha256 475f65d5…).
--   보조 1 = 공식 뉴스룸 news.chabio.com(자기 도메인 · 저작권 CHA BIO GROUP) 기사 5편.
--     주어가 차바이오텍인 창립 22주년 기사(2024-11)는 각주 없음. 주어가 차바이오그룹 · 차병원·차바이오그룹인 기사
--     (피트니스센터 2023-09 · 사내 도서관 2023-08 · 사내카페 2025-04 · R&D 박사과정 2026-03 · CHA대상 2026-01)는
--     출처 괄호 안에 그룹 공통 문구 각주. 피트니스센터 기사는 이용 법인에 차바이오텍을 이름으로 적었다.
--   보조 2 = 차병원·차바이오그룹 통합 채용 사이트 recruit.chamc.co.kr 복리후생 화면(법인 구분 없음 ·
--     각 기관 및 회사별로 다소 차이가 있을 수 있음 단서). 이 법인 적용이 확인되는 항목만 썼다 —
--     셔틀버스(행선지 차바이오컴플렉스 = 차바이오텍 주사업장) · 구내 직원식당 식비(각 기관 및 회사에서 지원 · 차바이오컴플렉스
--     구내식당은 뉴스룸 2025-04 기사로 확인). 두 행은 서술 끝에 (그룹 통합 채용 기준) 각주.
--   공시 = 2026 반기보고서(접수 20260813001660) 직원 등 현황 유연근무제도 사용 현황 표 — 유연근무 행 보강에만 썼다.
--   금액: 금액 행 0(stated 0 · 추정 0). 원 단위 숫자는 R&D 박사과정 등록금 50% 회사 부담(비율) 하나 — 금액 미등록.
--     구내식당 식비는 끼니 · 단가 미기재라 NULL.
--   제외: 법정 · 보호 중심 휴가 및 휴직 제도 목록 전부(산전후휴가 · 육아휴직 · 배우자 출산휴가 · 생리휴가 · 난임치료 휴가 ·
--     가족돌봄 휴가 및 휴직) · 육아기 · 임신기 근로시간 단축 · 가족돌봄 등을 위한 근로시간 단축(법정) · 간주 근로시간제(산정 방식) ·
--     직무발명 보상(법정) · 노사협의회 · 사회공헌 · 그룹 채용 사이트의 단체상해보험(의료/재단 부문) · 콘도 · 대학교 등록금 ·
--     명절 및 근로자의 날 선물 · 장기근속 황금열쇠 · 사내 예식장 · 의료비 감면 세부(이 법인 적용 미확인 또는 법인 원문 행과 겹침) ·
--     우리사주조합(주주 표 빈 칸) · 화장품 특판(사업 문장) · 헤어 커트 행사(일회성).
--   공고 근거 0행 / 전체 19행.
--   SORT 섹션 순서(정본 페이지에 처음 나온 순서): flexibility 10 · family 20 · time_off 30 · leisure 40 · health 50 ·
--     growth 60 · compensation 70 · 보조 출처에만 있는 perks 80. 섹션 안은 정본 행 뒤에 뉴스룸 · 그룹 채용 사이트 행.
-- 검증 · 감사 판정 반영(2026-10-15): 장기근속 포상 행에 2025년 12월 뉴스룸 기사 출처 · 학위 행에 차바이오 MBA 병합(참고 블록 보조 기사 5편은 이 판정으로 7편) · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('cha_biotech', '차바이오텍',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오', 'C', 'https://www.chabio.com/esg/social.cha');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cha_biotech');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.chabio.com/esg/social.cha'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — ESG 사회 페이지 + 2026 반기보고서 ──
  (@comp_id, 'flex_work', '탄력적 근로시간제·시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '근로시간을 조정하여 일과 가정 양립을 지원하는 탄력적 근로시간제 (공식 ESG 페이지 가족친화 유연근무 및 근로시간 제도 항목), 시차출퇴근제 도입 (2026 반기보고서 유연근무제도 사용 현황 항목) — 적용 대상·운영 방식 미기재', 10),

  -- ── 가족 (family) — ESG 사회 페이지 ──
  (@comp_id, 'event', '경조휴가 및 경조금 지원', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 경조금 지원 (공식 ESG 페이지 가족친화 복지·지원 및 조직문화 제도 항목) — 경조 범위·경조금 액수·휴가 일수 미기재', 20),
  (@comp_id, 'parenting', '자녀 입학 축하 선물', NULL, 'family',
   'est', NULL, TRUE, '자녀 입학 축하 선물 제도 (공식 ESG 페이지 가족친화 복지·지원 및 조직문화 제도 항목) — 대상 학교급·선물 내용 미기재', 21),
  (@comp_id, 'child_edu', '임직원 자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 학자금 지원 (공식 ESG 페이지 가족친화 복지·지원 및 조직문화 제도 항목) — 지원 학교급·지원 금액 미기재', 22),

  -- ── 휴가 (time_off) — ESG 사회 페이지 + 공식 뉴스룸 ──
  (@comp_id, 'leave_general', '포상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '포상휴가 (공식 ESG 페이지 가족친화 복지·지원 및 조직문화 제도 항목) — 부여 기준·휴가 일수 미기재', 30),
  (@comp_id, 'long_service_leave', '장기근속 표창·특별 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '매년 창립기념일 행사에서 장기 근속한 직원 포상, 2024년 3년·5년·10년·20년 근속자에게 표창과 특별 휴가 (공식 뉴스룸 2024년 11월 창립 22주년 기사 항목), 2025년 창립기념일 15년 장기근속 포상 (공식 뉴스룸 2025년 12월 장기근속자 기사 항목) — 휴가 일수·포상 내용 미기재', 31),

  -- ── 여가 · 행사 (leisure) — ESG 사회 페이지 + 공식 뉴스룸 ──
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 지원 (공식 ESG 페이지 가족친화 복지·지원 및 조직문화 제도 항목) — 지원 금액·동호회 종류 미기재', 40),
  (@comp_id, 'welcome_kit', '신규입사자 웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '신규입사자 웰컴키트 지원 (공식 ESG 페이지 가족친화 복지·지원 및 조직문화 제도 항목) — 구성품 미기재', 41),
  (@comp_id, 'company_event', '창립기념일 행사', NULL, 'leisure',
   'est', NULL, TRUE, '매년 창립기념일에 행사를 열어 직원들에게 휴식 선물, 2024년 차바이오컴플렉스 대강당 앞 다과와 직원 소통 시간 (공식 뉴스룸 2024년 11월 창립 22주년 기사 항목) — 행사 일정·참여 대상 미기재', 42),
  (@comp_id, 'library', '사내 도서관 리서치플라자', NULL, 'leisure',
   'est', NULL, TRUE, '차바이오컴플렉스 사내 도서관 리서치플라자, 전공 도서와 교양 도서 약 1만 5천 권, 학술 자료 전자도서관 시스템 (공식 뉴스룸 2023년 8월 사내 도서관 기사 항목, 차바이오그룹 공통 문구) — 이용 시간·대출 한도 미기재', 43),

  -- ── 건강 (health) — ESG 사회 페이지 + 공식 뉴스룸 ──
  (@comp_id, 'health_check', '임직원 건강검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강검진 지원 (공식 ESG 페이지 가족친화 복지·지원 및 조직문화 제도 항목) — 검진 주기·비용 지원 범위 미기재', 50),
  (@comp_id, 'medical', '임직원 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 의료비 지원 (공식 ESG 페이지 가족친화 복지·지원 및 조직문화 제도 항목) — 지원 대상·범위·한도 미기재', 51),
  (@comp_id, 'fitness', '사내 피트니스센터', NULL, 'health',
   'est', NULL, TRUE, '차바이오컴플렉스 8층 피트니스센터, 차바이오텍 등 계열사 임직원 이용, 웨이트존과 수영장, 전문 트레이너와 수영 강사 상주, 출근 전·점심시간·퇴근 후 이용 (공식 뉴스룸 2023년 9월 피트니스센터 기사 항목, 차바이오그룹 공통 문구) — 이용료 미기재', 52),

  -- ── 성장 · 교육 (growth) — ESG 사회 페이지 + 공식 뉴스룸 ──
  (@comp_id, 'edu_support', '사이버연수원', NULL, 'growth',
   'est', NULL, TRUE, '근로자가 Web과 모바일로 사이버연수원에 접속하여 교육훈련 프로그램 이수, 필수학점과 선택학점 운영 (공식 ESG 페이지 근로자 교육훈련 프로그램 항목) — 개설 과정·비용 부담 미기재', 60),
  (@comp_id, 'mba', '연구원 R&D 박사과정·차바이오 MBA', NULL, 'growth',
   'est', NULL, TRUE, '차의과학대학교 바이오소재공학과 계약학과 연구원 R&D 박사과정, 석사 학위를 보유한 근속 1년 이상 연구직 지원, 등록금의 50% 회사 부담 (공식 뉴스룸 2026년 3월 사내 학위 기사 항목, 차병원·차바이오그룹 공통 문구), 선임급 이상 직원이 신청하는 차바이오 MBA(경영석사과정), 매년 한 차례 모집, 교육비의 50% 기업 부담 (공식 뉴스룸 2023년 9월 차바이오 MBA 기사 항목, 차바이오그룹 공통 문구) — 선발 인원·선발 기준 미기재', 61),

  -- ── 보상 (compensation) — ESG 사회 페이지 + 공식 뉴스룸 ──
  (@comp_id, 'excellence_award', '표창·포상 제도', NULL, 'compensation',
   'est', NULL, TRUE, '표창·포상 규정 등 내부규정을 통한 금전적·비금전적 임직원보상 프로그램 (공식 ESG 페이지 임직원보상 프로그램 항목), 한 해 동안 핵심가치를 실천한 직원과 부서에 주는 CHA대상 (공식 뉴스룸 2026년 1월 시상 기사 항목, 차병원·차바이오그룹 공통 문구) — 포상 기준·포상 내용 미기재', 70),

  -- ── 생활 · 편의 (perks) — 그룹 통합 채용 사이트 + 공식 뉴스룸 ──
  (@comp_id, 'commute_subsidy', '출퇴근 셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '판교역에서 차바이오컴플렉스와 분당차병원까지 출퇴근 셔틀버스 운행 (차병원·차바이오그룹 채용 사이트 복리후생 항목) — 운행 시간·배차 간격 미기재 (그룹 통합 채용 기준)', 80),
  (@comp_id, 'meal', '구내 직원식당 식비 지원', NULL, 'perks',
   'est', NULL, TRUE, '구내 직원식당 이용 시 각 기관 및 회사에서 식비 지원 (차병원·차바이오그룹 채용 사이트 복리후생 항목) — 지원 금액·제공 끼니 미기재 (그룹 통합 채용 기준)', 81),
  (@comp_id, 'snack_bar', '사내카페', NULL, 'perks',
   'est', NULL, TRUE, '차바이오컴플렉스 지하 1층 사내카페, 직원들의 복지를 위해 아침 8시부터 저녁 6시까지 운영 (공식 뉴스룸 2025년 4월 사내카페 기사 항목, 차바이오그룹 공통 문구) — 음료 가격·회사 부담 미기재', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
