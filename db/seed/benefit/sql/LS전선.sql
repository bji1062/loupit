-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LS전선 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://www.lscns.co.kr/kr/talent/personnel_benefit.asp
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 인재경영 인사제도/복리후생 페이지(SSR · 원본 HTML 에 복리후생 목록).
--   보조 = 공식 채용 사이트 careers.lscablebiz.com 복리후생(HumanResourceMag3 · 공식 홈 채용공고 링크 · 회사 계정 SAP 채용 사이트) ·
--   자기 도메인 인재육성 페이지 · LS전선 2025-2026 지속가능경영보고서 + 연차보고서(2026-07 발행 · 보고 기간 2025 · 자기 도메인 PDF ·
--   보고 경계는 국내외 종속회사 포함 — 근거 문장은 모두 LS전선 주어라 각주 없음) 25 · 55 · 56 · 57 · 59 · 60 · 64 · 67쪽 ·
--   2025 사업보고서(20260317000719) 별도재무제표 주석 · 2026 반기보고서(20260814004012) 유연근무제 사용현황.
--   비상장(종목코드 없음) · 최대주주 ㈜LS 92.6% · 형제(LS ELECTRIC · 가온전선 · LS마린솔루션 · LS머트리얼즈)와 출처 공유 없음 — 각자 자기 출처.
--   금액: 금액 행 0(원문에 연 금액 없음 · 전 행 정성). 식대 원문 없음.
--   제외: 법정(배우자 출산휴가 20일 · 유급 출산전후 휴가 · 육아휴직 본인+배우자 · 퇴직연금 운영) · 업무 교육(신입 · 직급별 필수 · 멘토링 ·
--   리더십 · 경영 전략 아카데미 · AX 교육) · 권장 휴가(하계 장기 · 연말 · 연계 휴가 사용 권장) · 임원 보수 칸 · 조직문화 소통 프로그램.
--   공고 근거 0행 / 전체 38행 · SORT 섹션 = compensation 10 · perks 20 · work_env 30 · family 40 · time_off 50 · health 60 · growth 70 ·
--   leisure 80 · flexibility 90(보고서에만)
-- 검증 · 감사 판정 반영(2026-10-22): 포상 제도 행에 보고서 38쪽 분임조 우수 제안 포상 병합(보상 섹션 머리 주석 38 · 55쪽) · 채용 사이트 careers.lscablebiz.com 은 LS전선 귀속이라 보조 행 각주 없음 · 항목 페이지 예외 2(통합 밖 리드 집행) · 참고 블록의 보고서 2026-07 발행은 본문 판권 쪽 기준 2026-06-17 발행 — 최종 38행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ls_cable', 'LS전선',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '전선/전력', 'L', 'https://www.lscns.co.kr/kr/talent/personnel_benefit.asp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ls_cable');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lscns.co.kr/kr/talent/personnel_benefit.asp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 공식 홈페이지 보상제도 · 보고서 38 · 55쪽 · 사업보고서 주석 ──
  (@comp_id, 'incentive', '성과급 제도', NULL, 'compensation',
   'est', NULL, TRUE, '연말에 회사, 소속된 조직 및 개인이 달성한 성과에 따른 성과급 제도 운영 (공식 홈페이지 인사제도 보상제도 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'profit_sharing', '이익배분제 (Profit Sharing)', NULL, 'compensation',
   'est', NULL, TRUE, '노사간 합의를 통해 회사 이익의 일정 부분을 임직원들에게 공유하는 이익배분제 제도 운영 (2025-2026 지속가능경영보고서 55쪽 Profit Sharing 제도 운영 항목) — 배분 기준·지급률 미기재', 11),
  (@comp_id, 'excellence_award', '포상 제도 (LS전선Way상 · 우수 연구·개발상 · C.O.R.E.상 · Talent Reward상)', NULL, 'compensation',
   'est', NULL, TRUE, '대표이사 주관 LS전선Way상과 우수 연구·개발상, 각 사업 본부장 주관 C.O.R.E.상 및 Talent Reward상 연중 상시 운영 (2025-2026 지속가능경영보고서 55쪽 포상 제도 운영 항목), 사업장 분임조 활동의 개선 아이디어 중 우수 제안으로 선정된 건에 현금 또는 현물 포상 (같은 보고서 38쪽 기후 관련 KPI 및 인센티브제도 운영 항목) — 포상 기준·금액 미기재', 12),
  (@comp_id, 'long_service_bonus', '장기근속 임직원 장기종업원급여', NULL, 'compensation',
   'est', NULL, TRUE, '회사는 장기 근속 임직원에게 장기종업원급여를 제공, 일정기간 이상을 근무한 임직원에게만 권리 부여 (2025 사업보고서 별도재무제표 주석 장기종업원급여 항목) — 근속 기준·급부 형태·금액 미기재', 13),
  -- ── 생활 · 금융 · 주거 (perks) — 공식 홈페이지 · 공식 채용 사이트 · 보고서 59쪽 ──
  (@comp_id, 'housing_loan', '주택자금 지원 (주택구입·전세자금 대출)', NULL, 'perks',
   'est', NULL, TRUE, '주택구입자금 및 전세자금 지원 (공식 홈페이지 인사제도/복리후생 주택자금 지원 항목), 주택구입자금 및 전세자금 대출 지원 (공식 채용 사이트 복리후생 주택자금 지원 항목) — 한도·이율·자격 요건 미기재', 20),
  (@comp_id, 'housing_support', '주거지원금', NULL, 'perks',
   'est', NULL, TRUE, '주거지원금 (2025-2026 지속가능경영보고서 59쪽 복리후생 프로그램 항목) — 지원 대상·금액·지급 방식 미기재', 21),
  (@comp_id, 'transport', '교통비 지원 (영업사원 교통비 실비 · 신규 입사자 첫 출근 택시비)', NULL, 'perks',
   'est', NULL, TRUE, '출장비 및 영업사원 교통비 실비 지급, 신규 입사자 첫 출근 택시비 지원 (공식 홈페이지 인사제도/복리후생 교통비 지원 항목) — 지원 한도 미기재', 22),
  (@comp_id, 'commute_subsidy', '통근버스 · 셔틀버스 운행', NULL, 'perks',
   'est', NULL, TRUE, '출/퇴근 통근버스 및 셔틀버스 운행 (공식 홈페이지 인사제도/복리후생 교통비 지원 항목), 출/퇴근 통근버스 및 셔틀버스 운영 (사업장) (공식 채용 사이트 복리후생 교통비 지원 항목) — 운행 사업장·노선 미기재', 23),
  (@comp_id, 'relocation', '부임 이사 비용 지원', NULL, 'perks',
   'est', NULL, TRUE, '부임 이사 비용 (2025-2026 지속가능경영보고서 59쪽 복리후생 프로그램 항목) — 지원 대상·한도 미기재', 24),
  (@comp_id, 'birthday_gift', '생일 축하금', NULL, 'perks',
   'est', NULL, TRUE, '생일 축하금 (2025-2026 지속가능경영보고서 59쪽 복리후생 프로그램 항목) — 금액 미기재', 25),
  (@comp_id, 'discount', '임직원 할인몰', NULL, 'perks',
   'est', NULL, TRUE, 'LG/LS 임직원 할인몰 이용 가능 (공식 채용 사이트 복리후생 기타 항목) — 입점 상품·할인율 미기재', 26),
  -- ── 근무 환경 (work_env) — 공식 홈페이지 주택자금 지원 · 보고서 59쪽 ──
  (@comp_id, 'dormitory', '기숙사 · 사원아파트', NULL, 'work_env',
   'est', NULL, TRUE, '지방 사업장의 경우 기숙사 제공 (공식 홈페이지 인사제도/복리후생 주택자금 지원 항목), 기숙사, 사원아파트 (2025-2026 지속가능경영보고서 59쪽 복리후생 프로그램 항목) — 입주 자격·비용 부담 미기재', 30),
  (@comp_id, 'nap_room', '수유실', NULL, 'work_env',
   'est', NULL, TRUE, '수유실 (2025-2026 지속가능경영보고서 59쪽 복리후생 프로그램 항목) — 설치 사업장 미기재', 31),
  -- ── 가족 (family) — 공식 홈페이지 학자금 · 경조비 · 가족친화 제도 · 보고서 59쪽 ──
  (@comp_id, 'child_edu', '자녀 학자금 (중·고·대학 전액)', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 중.고.대학 학자금 전액 지원 (공식 홈페이지 인사제도/복리후생 학자금 지원 항목) — 지원 자녀 수·학기 한도 미기재', 40),
  (@comp_id, 'event', '경조사 지원 (경조금 · 경조휴가 · 경조 물품)', NULL, 'family',
   'est', NULL, TRUE, '각종 경조금 및 경조 휴가 (공식 홈페이지 인사제도/복리후생 경조비 지원 항목), 경조 물품 지원 (공식 채용 사이트 복리후생 경조비 지원 항목) — 경조 유형별 금액·휴가 일수 미기재', 41),
  (@comp_id, 'parenting', '출생 축하금 · 양육 지원금 · 자동 육아휴직', NULL, 'family',
   'est', NULL, TRUE, '출생 축하/양육 지원금 지원, 자동 육아휴직제도 (공식 홈페이지 인사제도/복리후생 가족친화 제도 항목), 자녀 출생·돌 축하금, 손자녀 출산 축하금, 배우자 육아휴직 남성 자동휴직 (1개월), 육아휴직 2년, 임신기 근로 단축 임신기 전 기간 (2025-2026 지속가능경영보고서 59쪽 출산 및 육아 제도 확대 · 복리후생 프로그램 항목) — 축하금·지원금 금액 미기재', 42),
  (@comp_id, 'fertility_support', '난임휴가 (유급 10일)', NULL, 'family',
   'est', NULL, TRUE, '난임휴가 유급 10일(법정 6일에 4일 추가) (2025-2026 지속가능경영보고서 59쪽 출산 및 육아 제도 확대 항목) — 사용 조건 미기재', 43),
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장어린이집 운영 (2025-2026 지속가능경영보고서 59쪽 복리후생 프로그램 항목) — 설치 사업장·정원 미기재', 44),
  -- ── 휴가 (time_off) — 공식 홈페이지 휴가 제도 · 공식 채용 사이트 휴가제도 · 보고서 59쪽 ──
  (@comp_id, 'summer_leave', '하계 휴가 (5일)', NULL, 'time_off',
   'est', NULL, TRUE, '하계 휴가(5일) (공식 홈페이지 인사제도/복리후생 휴가 제도 항목), 유급 하계휴가 5일 (2025-2026 지속가능경영보고서 59쪽 복리후생 프로그램 항목) — 본인 휴가 차감 여부·사용 시기 미기재', 50),
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '리프레시 휴가 (공식 홈페이지 인사제도/복리후생 휴가 제도 항목, 2025-2026 지속가능경영보고서 59쪽 복리후생 프로그램 항목), Refresh 휴가 (공식 채용 사이트 복리후생 휴가제도 항목) — 휴가 일수·부여 조건 미기재', 51),
  (@comp_id, 'leave_general', '징검다리 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '징검다리 휴가 (공식 채용 사이트 복리후생 휴가제도 항목) — 연차 사용일인지·일수·유급 여부 미기재', 52),
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 휴가 (2025-2026 지속가능경영보고서 59쪽 복리후생 프로그램 항목) — 근속 기준·휴가 일수 미기재', 53),
  -- ── 건강 (health) — 공식 홈페이지 의료비 지원 · 기타 · 보고서 59 · 64 · 67쪽 ──
  (@comp_id, 'medical', '의료비 지원 (본인 · 가족)', NULL, 'health',
   'est', NULL, TRUE, '본인 의료비 지원, 가족의료비 지원 (공식 홈페이지 인사제도/복리후생 의료비 지원 항목), 사내 복지기금 지원(부양가족 의료비) (공식 채용 사이트 복리후생 의료비 지원 항목), 의료비 지원 (본인, 가족) (2025-2026 지속가능경영보고서 59쪽 복리후생 프로그램 항목) — 지원 한도·대상 질환 미기재', 60),
  (@comp_id, 'health_check', '종합검진 (본인 매년 · 배우자 격년)', NULL, 'health',
   'est', NULL, TRUE, '종합검진(본인 매년, 배우자 격년) (공식 홈페이지 인사제도/복리후생 의료비 지원 항목), 종합건강검진 지원 (공식 채용 사이트 복리후생 의료비 지원 항목) — 검진 항목·비용 지원 범위 미기재', 61),
  (@comp_id, 'insurance', '단체 정기보험', NULL, 'health',
   'est', NULL, TRUE, '단체 정기보험 가입 (공식 홈페이지 인사제도/복리후생 기타 항목), 단체정기보험 지원 (공식 채용 사이트 복리후생 의료비 지원 항목) — 보장 내용·가입 대상 미기재', 62),
  (@comp_id, 'mental', '심리상담실 (온·오프라인)', NULL, 'health',
   'est', NULL, TRUE, '온·오프라인 심리상담실 운영, 전문 상담사가 제공하는 상담·치료와 함께 가족 심리검사, 팀 소통 프로그램, 스트레스 관리 교육 운영 (2025-2026 지속가능경영보고서 67쪽 심리상담실·건강관리실 운영 항목) — 이용 횟수·비용 부담 미기재', 63),
  (@comp_id, 'clinic', '건강관리실 (간호사 상주)', NULL, 'health',
   'est', NULL, TRUE, '사업장별 건강관리실 운영, 간호사가 상주하여 의약품 지급, 외상 처치, 건강 상담 등 기본 의료 서비스 제공 (2025-2026 지속가능경영보고서 67쪽 심리상담실·건강관리실 운영 항목) — 운영 시간 미기재', 64),
  (@comp_id, 'overseas_safety', '해외 근무자 안전지원 서비스 (I-SOS)', NULL, 'health',
   'est', NULL, TRUE, '해외 근무자와 출장자의 건강과 안전을 보호하기 위해 글로벌 안전지원 서비스인 인터내셔날 SOS(I-SOS) 운영, 현지 의료기관 안내, 진료 예약, 의료 통역, 의료비 지불보증, 긴급 이송 및 후송 지원, 심리상담 서비스 (2025-2026 지속가능경영보고서 64쪽 해외 근무자 안전관리 체계 강화 항목) — 비용 부담 미기재', 65),
  -- ── 성장 · 교육 (growth) — 공식 홈페이지 기타 · 인재육성 · 보고서 25 · 56쪽 ──
  (@comp_id, 'lang', '외국어 학원 지원 · 외국어 합숙 교육', NULL, 'growth',
   'est', NULL, TRUE, '외국어 학원 지원 (공식 홈페이지 인사제도/복리후생 기타 항목), 사외 외국어 비용 지원 (공식 채용 사이트 복리후생 기타 항목), 중장기 외국어 합숙 교육 영어 GBC, EBC · 중국어 현지 인텐시브 과정(5개월), 외국어학원 지원 (공식 홈페이지 인재육성 국제화 교육 항목) — 지원 한도·대상 선발 기준 미기재', 70),
  (@comp_id, 'mba', '특수대학원 · 헬싱키MBA 학위과정 지원', NULL, 'growth',
   'est', NULL, TRUE, '미래 경영자 양성을 위해 다양한 학위과정 지원, 특수대학원 전액 지원, 헬싱키MBA (정식 학위 과정) (공식 홈페이지 인재육성 중장기 교육 항목) — 선발 기준·지원 인원 미기재', 71),
  (@comp_id, 'conference', '해외 연수 (해외 콘퍼런스 · 세미나 참가)', NULL, 'growth',
   'est', NULL, TRUE, '해외 연수(해외 콘퍼런스, 세미나 참가) (공식 홈페이지 인재육성 중장기 교육 항목) — 선발 기준·지원 범위 미기재', 72),
  (@comp_id, 'edu_support', '자율 학습 지원 (e-러닝 · 사이버 교육 과정)', NULL, 'growth',
   'est', NULL, TRUE, '개인 주도 학습은 약 15,000개의 콘텐츠를 활용할 수 있는 e-러닝과 마이크로러닝, 그룹연수원 프로그램, 외부 교육기관 위탁교육 등을 통해 지원 (2025-2026 지속가능경영보고서 56쪽 개인 맞춤형 학습 제공 항목), 사이버 교육 과정 제공(300여 과정) (공식 홈페이지 인재육성 국제화 교육 항목), LS러닝플랫폼 제공, 러닝포인트 (2025-2026 지속가능경영보고서 25쪽 중대이슈 대응 항목) — 러닝포인트 지급 기준·과정 내용 미기재', 73),
  -- ── 여가 · 행사 (leisure) — 공식 홈페이지 기타 · 보고서 57 · 59쪽 ──
  (@comp_id, 'club', '사내 동아리 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동아리 활동 지원 (공식 홈페이지 인사제도/복리후생 기타 항목), 사내 동호회 (2025-2026 지속가능경영보고서 59쪽 복리후생 프로그램 항목) — 지원 금액·동호회 수 미기재', 80),
  (@comp_id, 'resort', '생활연수원 · 호텔 · 콘도 숙박시설 이용', NULL, 'leisure',
   'est', NULL, TRUE, 'LG 생활연수원(울진 소재) 연중무휴 이용 가능, 호텔, 콘도 등 숙박시설 이용(연간 3회) (공식 홈페이지 인사제도/복리후생 기타 항목), 호텔, 콘도 등 국내 숙박시설 이용비 지원 (공식 채용 사이트 복리후생 기타 항목) — 이용비 지원 한도 미기재', 81),
  (@comp_id, 'company_event', '추계 야유회', NULL, 'leisure',
   'est', NULL, TRUE, '추계 야유회 (2025-2026 지속가능경영보고서 59쪽 복리후생 프로그램 항목) — 참여 대상·지원 내용 미기재', 82),
  (@comp_id, 'welcome_kit', '웰컴 키트 (Welcome Kit)', NULL, 'leisure',
   'est', NULL, TRUE, 'Welcome Kit (2025-2026 지속가능경영보고서 57쪽 신규 입사자 온보딩 항목) — 구성 품목 미기재', 83),
  -- ── 근무 유연성 (flexibility) — 보고서 60쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (시차 출퇴근제 · 선택적 근로시간제)', NULL, 'flexibility',
   'est', NULL, TRUE, '시차 출퇴근제와 선택적 근로시간제 운영 (2025-2026 지속가능경영보고서 60쪽 유연근무 강화 항목), 시차출퇴근제 사용자 316명 · 선택근무제 사용자 27명 (2026 반기보고서 유연근무제 사용현황 항목) — 적용 대상·운영 시간대 미기재', 90),
  (@comp_id, 'satellite_office', '거점 오피스 (서울 사무소 워킹라운지)', NULL, 'flexibility',
   'est', NULL, TRUE, '서울 사무소 내 워킹라운지를 포함한 거점 오피스를 통해 근무 장소의 선택 범위 확대 (2025-2026 지속가능경영보고서 60쪽 유연근무 강화 항목) — 이용 대상·거점 수 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
