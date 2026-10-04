-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 덕산네오룩스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.dsnl.co.kr/recruit_03.aspx
-- badge: est
--
-- 참고:
--   정본은 덕산네오룩스 공식 홈페이지 www.dsnl.co.kr 헤더 메뉴 인재정보 → 복리후생(/recruit_03.aspx)이다. 서버 렌더 HTML 에
--   항목 18개가 제목+한 줄 설명으로 있다. 머리 문장 주어가 덕산그룹이고 같은 목록이 덕산그룹 채용 사이트
--   recruit.oneduksan.com 복리후생 페이지와 글자까지 같다(덕산하이메탈 홈페이지 같은 메뉴도 오탈자 3곳만 다름) —
--   그래서 이 페이지에만 기댄 서술은 덕산그룹 공통 문구라고 적었다.
--   법인 고유 근거: 같은 사이트 ESG → ESG 보고서(/ethics_00.aspx)에서 받는 2026 덕산네오룩스㈜ ESG보고서(주어 덕산네오룩스(주))
--     31쪽 구성원 복리후생 제도 · 주요 복지 프로그램 표, 29쪽 구성원 보상 체계, 18쪽 사내복지근로기금 설립, 36쪽 건강증진 지원 프로그램.
--     2025 ESG보고서 18쪽 통근버스 도입은 보조.
--   보조: 같은 홈페이지 인재정보 → 인사제도(/recruit_02.aspx) 평가 및 보상제도 이미지(덕산그룹 공통 문구).
--   robots: www.dsnl.co.kr 전체 허용 · recruit.oneduksan.com robots 없음 · 덕산네오룩스 채용 ATS dsneolux.career.greetinghr.com 은
--     robots 전체 금지라 읽지 않았다(홈페이지 · ESG보고서로 행을 세웠다).
--   금액: 복지포인트 100 은 ESG보고서 명시값(회사 공식 수치). 구본 추정 승계 4(health_check 100 · child_edu 200 · resort 50 ·
--     holiday_gift 20 — 전부 틀 값, NOTE 끝에 (추정)). 구본 welfare_point 200 은 공식 100 으로 바꿨고, event 50 은 경조금이라,
--     long_service_leave 50 은 회사 고유값인데 원문에 전제가 없어 승계하지 않았다.
--   제외: 직무 역량 교육 · 주요 교육 운영 프로그램(회사 주도 교육 과정) · 스톡옵션(근속기간과 고유성과에 따른 비정기 부여) ·
--     직무발명보상 · 정기 건강검진 · 특수검진 · 유소견자 상담 · 모성보호 · 가족돌봄 등 법정 제도 · 장애인 근로자 재택근무.
--   재코딩: edu_support → self_development(본인 학자금 — 구본 라벨 직무 역량 교육은 회사 주도 교육 과정이라 제외).
--   SORT 섹션 순서 = 홈페이지 목록에서 카테고리가 처음 나온 순서, 보고서에만 있는 카테고리는 끝
--     (perks 10 · compensation 20 · leisure 30 · time_off 40 · health 50 · growth 60 · family 70 ·
--     flexibility 80 · work_env 90).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-6): 행 조치 없음 — 덕산그룹 주어 복리후생 페이지에만 있는 4행은 리드 판정 ㉝ 대로 그룹 공통 문구 각주와 함께 유지 — 최종 23행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('duksan_neolux', '덕산네오룩스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '디스플레이소재', 'D', 'https://www.dsnl.co.kr/recruit_03.aspx');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'duksan_neolux');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.dsnl.co.kr/recruit_03.aspx'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 홈페이지 복지포인트 · 사내 카페 · 주거지원비 / 2026 보고서 통근버스 · 사내복지기금 · 조직활성화 비용 ──
  (@comp_id, 'welfare_point', '선택적 복리후생 포인트', 100, 'perks',
   'est', '선택적 복리후생 지원을 위한 포인트 지원(연간 100만원) (2026 ESG보고서 주요 복지 프로그램), 자기계발·여가·생활편의 등에 개인별 필요에 따라 사용 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구)', FALSE, NULL, 10),
  (@comp_id, 'snack_bar', '사내 카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '카페테리아 운영 — 커피머신과 한강 라면 조리기, 다양한 종류의 아이스크림 상시 구비 (2026 ESG보고서 구성원 근무환경 개선), 간식 및 음료 제공 사내 카페 운영 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구)', 11),
  (@comp_id, 'housing_support', '주거지원비·신입사원 보증금 지원', NULL, 'perks',
   'est', NULL, TRUE, '단신 부임자 주거지원비 지원(6년), 신입사원 보증금 지원(3년간 1,000만원) (2026 ESG보고서 주요 복지 프로그램), 원거리 거주자의 안정적인 주거생활을 위한 6년간 주거지원비 지원 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구) — 월 지원액·보증금 반환 조건 미기재', 12),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '출/퇴근 통근버스 지원 (2026 ESG보고서 주요 복지 프로그램), 2024년 통근버스를 새로 도입해 출퇴근 교통 접근성이 낮은 지역 직원의 출퇴근 지원 (2025 ESG보고서 ESG 핵심성과) — 노선·운행 횟수 미기재', 13),
  (@comp_id, 'welfare_fund_loan', '사내복지기금 생활안정 자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '2025년 구성원의 생활 안정과 복리후생 증진을 위해 사내복지기금 설립(임직원의 경조사 지원, 생활안정 자금 대출 등) (2026 ESG보고서 ESG 핵심성과 사내복지근로기금 설립) — 대출 한도·이율 미기재', 14),
  (@comp_id, 'team_dinner', '조직별 조직활성화 비용', NULL, 'perks',
   'est', NULL, TRUE, '조직별 조직활성화 비용 지원 (2026 ESG보고서 주요 복지 프로그램 사내 조직활성화 지원) — 지원 금액·사용 범위 미기재', 15),

  -- ── 보상·금전 (compensation) — 홈페이지 명절 선물 / 2026 보고서 구성원 보상 체계 변동급 ──
  (@comp_id, 'holiday_gift', '명절 선물', 20, 'compensation',
   'est', '설/추석 연 2회 선물 지급 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구) — 선물 금액 미기재 (추정)', FALSE, NULL, 20),
  (@comp_id, 'incentive', '경영성과급·성과인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과급(회사, 조직, 개인의 성과 달성에 따라 차등 지급), 성과인센티브(회사(공동) 목표, 조직 목표, 개인 목표 달성도를 종합적으로 고려해 성과에 따라 차등 지급) (2026 ESG보고서 구성원 보상 체계 변동급), 경영성과급 (공식 홈페이지 인사제도 평가 및 보상제도, 덕산그룹 공통 문구) — 지급 기준·지급률 미기재', 21),
  (@comp_id, 'excellence_award', '개선제안·연구개발 포상', NULL, 'compensation',
   'est', NULL, TRUE, '개선제안포상(지원, 생산/품질 부서의 업무 개선 성과에 따라 차등 지급), 연구개발포상(R&D 개발 기여자 및 매출 창출 기여자에게 지급) (2026 ESG보고서 구성원 보상 체계 변동급), R&D성과보상 (공식 홈페이지 인사제도 평가 및 보상제도, 덕산그룹 공통 문구) — 포상 금액·선정 인원 미기재', 22),

  -- ── 여가·라이프 (leisure) — 홈페이지 창립기념일 · 무비데이 · 사내 동호회 · 하계 휴양시설 ──
  (@comp_id, 'company_event', '창립기념일 행사·무비데이', NULL, 'leisure',
   'est', NULL, TRUE, '창립기념일 행사 진행 및 기념품 제공, 임직원 및 가족/지인들과 함께 하는 무비데이 운영 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구) — 개최 주기·기념품 내용 미기재', 30),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 운영 및 동호회 비용 지원 (2026 ESG보고서 주요 복지 프로그램), 동호회 활동 등 교류 프로그램 지속 지원 (2026 ESG보고서 구성원 소통 채널의 다각화), 다양한 사내 동호회 운영/지원 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구) — 지원 금액 미기재', 31),
  (@comp_id, 'resort', '하계 휴양시설', 50, 'leisure',
   'est', '하계 성수기 휴양시설 무료 지원 (2026 ESG보고서 주요 복지 프로그램), 당사 제휴 휴양시설 추첨/제공 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구) — 이용 일수 미기재 (추정)', FALSE, NULL, 32),

  -- ── 시간·휴가 (time_off) — 홈페이지 장기근속자 포상 / 2026 보고서 전염성 질환 유급휴가 ──
  (@comp_id, 'long_service_leave', '장기근속자 포상 (리프레쉬 휴가 등)', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자에게 근속메달, 기념패, 포상금, 해외여행, 리프레쉬 휴가 등 제공 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구) — 근속연수 기준·휴가 일수·포상금 금액 미기재', 40),
  (@comp_id, 'leave_general', '전염성 질환 유급휴가', NULL, 'time_off',
   'est', NULL, TRUE, '전염성 질환 유급휴가 지원 (2026 ESG보고서 주요 복지 프로그램 의료비 지원) — 휴가 일수·대상 질환 미기재', 41),

  -- ── 건강·의료 (health) — 홈페이지 사내 헬스장 · 종합검진비 / 2026 보고서 건강검진비 · 건강증진시설 ──
  (@comp_id, 'fitness', '사내 헬스장·체육시설', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장, 체육시설 (2026 ESG보고서 주요 복지 프로그램), 상시 헬스장 운영 및 운영비 지속 지원 (2026 ESG보고서 건강증진 지원 프로그램), 체력증진 및 스트레스 해소를 위한 사내 헬스장 운영 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구)', 50),
  (@comp_id, 'health_check', '구성원·배우자 건강검진비', 100, 'health',
   'est', '구성원 및 배우자 대상 건강검진비 지원 (2026 ESG보고서 주요 복지 프로그램), 정기검진 外 개인 종합검진 지원 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구) — 지원 한도 미기재 (추정)', FALSE, NULL, 51),

  -- ── 성장·교육 (growth) — 홈페이지 외국어 교육 지원 · 본인 학자금 지원 ──
  (@comp_id, 'lang', '외국어 교육비·시험비 지원', NULL, 'growth',
   'est', NULL, TRUE, '임직원 어학능력 발전을 위한 외국어 교육 지원 (교육비, 시험비) (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구), 외국어 교육 (2026 ESG보고서 주요 교육 운영 프로그램) — 지원 한도 미기재', 60),
  (@comp_id, 'self_development', '본인 학자금', NULL, 'growth',
   'est', NULL, TRUE, '본인 학자금 지원 (2026 ESG보고서 주요 복지 프로그램), 정규대학 및 대학원 재학시 지원 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구) — 지원 한도·조건 미기재', 61),

  -- ── 가족·돌봄 (family) — 홈페이지 자녀 학자금 · 자녀 입학 축하금 · 경조사 / 2026 보고서 장례용품 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', 200, 'family',
   'est', '자녀 학자금 지원 (2026 ESG보고서 주요 복지 프로그램), 대학교 전액 실비 지원 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구) — 자녀 수·학년별 한도 미기재 (추정)', FALSE, NULL, 70),
  (@comp_id, 'parenting', '자녀 입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '자녀 입학 축하금 지원 (2026 ESG보고서 주요 복지 프로그램), 유치원 ~ 고등학교 입학 시 축하금 지원 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구) — 축하금 금액 미기재', 71),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼, 부고, 출산, 졸업 관련 경조금 및 경조휴가 제공, 장례용품 지원 (2026 ESG보고서 주요 복지 프로그램), 사내복지기금을 통한 임직원 경조사 지원 (2026 ESG보고서 사내복지근로기금 설립), 임직원 및 가족 경조사 발생시 경조금 및 휴가, 경조물품 지원 (공식 홈페이지 복리후생 항목, 덕산그룹 공통 문구) — 경조 종류별 금액·휴가 일수 미기재', 72),

  -- ── 근무 유연성 (flexibility) — 2026 보고서 선택적 근로시간제 · DS Refresh Day ──
  (@comp_id, 'flex_work', '선택적 근로시간제·DS Refresh Day', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로시간제, 오전 10시부터 오후 3시까지의 코어타임을 제외한 시간에 자율 출퇴근, 부분적 주 4일 근무제 DS Refresh Day 시행 (2026 ESG보고서 구성원 복리후생 제도), 자유로운 출퇴근(유연근무제) (2026 ESG보고서 주요 복지 프로그램) — DS Refresh Day 시행 주기·대상 미기재', 80),

  -- ── 근무환경 (work_env) — 2026 보고서 휴게실(안마의자) ──
  (@comp_id, 'lounge', '휴게실 (안마의자)', NULL, 'work_env',
   'est', NULL, TRUE, '휴게실(안마의자) (2026 ESG보고서 주요 복지 프로그램 사내 조직활성화 지원), 사내 10분 회복실 (2026 ESG보고서 구성원 복리후생 제도 사진)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
