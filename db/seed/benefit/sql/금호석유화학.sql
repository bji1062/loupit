-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 금호석유화학 복리후생 데이터 (신규 회사 — 웨이브 6)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.kkpc.com/kor/recruit/welfareSystem/
-- badge: est
--
-- 참고:
--   정본은 금호석유화학㈜ 자기 도메인 www.kkpc.com GNB 인재채용 > 복지제도 페이지다.
--   SSR 이라 원본 HTML 의 div.talentedCont 안에 3카테고리 21항목(유연함 6 · 도전과 성장 7 ·
--   건강과 가족 8)이 p.s_txt3 텍스트로 있다. 헤드리스 렌더 · 이미지 판독 불필요.
--   보조 출처는 법인이 직접 발행한 지속가능경영보고서 2025(발행 2026.06 · 보고 기간 2025년)
--   PDF 85~90쪽 본문 장이다. 계열사 장(126쪽~)은 쓰지 않았다. 같은 도메인 인재채용 > 인사제도
--   페이지의 PERFORMANCE 항목(인센티브)도 근거로 썼다. 그 페이지의 교육안내 · 복리후생 블록은
--   HTML 주석 안에 있어 공개 원문이 아니다 — 쓰지 않았다.
--   귀속: 자기 도메인 페이지 · 자기 발행 보고서라 그룹 각주 없음. 페이지에 그룹 · 계열 단서 0.
--   그룹 통합 채용 사이트 recruit.kkpc.com 은 쓰지 않았다(그룹 공통 · 메뉴가 POST 전용).
--   금액: 금액 행 0. 보고서 88~89쪽 숫자는 전부 1회성(출산축하금 · 산후조리비 · 입양축하금) ·
--   한도(난임시술비 회당 최대 · 주택 대출 1회당 한도) · 대상 한정(재활수당 월액 · 보장구)이라
--   금액 칸 NULL 로 두고 서술에 남겼다.
--   제외: 법정(출산휴가 · 육아휴직 1년 6개월 · 육아기 단축 · 가족돌봄휴직/휴가 · 유산사산휴가 ·
--   태아검진 시간 · 초과근무 수당 · 재취업 지원 프로그램 — 직원 1,606명) · 장려 휴가(장기휴가
--   장려 · 유급 휴가 사용 장려) · 업무 교육(멘토링 · KCPD MBA 선발 과정 · 여성 리더십 · 직급 교육) ·
--   자율 복장 · 제안 제도 · 안전 포상 · 협력사 대상 지원.
--   공고 근거 0행 / 전체 28행. 신규 코드 0.
--   SORT 섹션 순서 = 정본 페이지 첫 등장 순서: flexibility 10 · compensation 20 · leisure 30 ·
--   growth 40 · health 50 · perks 60 · family 70, 보고서에만 있는 work_env 80 · time_off 90.
-- 검증 · 감사 판정 반영(2026-10-14): 보건관리실 clinic 추가 · 재활수당 금액 NULL 유지 — 최종 29행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kumho_petrochemical', '금호석유화학',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화학', 'K', 'https://www.kkpc.com/kor/recruit/welfareSystem/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kumho_petrochemical');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.kkpc.com/kor/recruit/welfareSystem/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 복지제도 유연함 · 보고서 88쪽 ──
  (@comp_id, 'flex_work', '유연·시차·탄력근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연/시차/탄력근무제 (공식 채용 페이지 복지제도 유연함 항목), 유연근무제(탄력근무·재택근무·시차출퇴근제) 시행, 필요 시 탄력근무 신청을 통해 초과근무 시간만큼 타 요일 근무시간으로 차감 (2025 지속가능경영보고서 88쪽 유연근무제 운영 항목) — 코어타임·적용 직군 미기재', 10),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제(탄력근무·재택근무·시차출퇴근제) 시행 (2025 지속가능경영보고서 88쪽 유연근무제 운영 항목) — 재택근무 대상·사용 횟수·신청 조건 미기재', 11),
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF 제도 (공식 채용 페이지 복지제도 유연함 항목), 퇴근시간 15분 경과 시 PC 자동 차단 (2025 지속가능경영보고서 88쪽 유연근무제 운영 항목) — 적용 대상·예외 신청 절차 미기재', 12),

  -- ── 보상·금전 (compensation) — 복지제도 유연함 · 인사제도 · 보고서 87쪽 ──
  (@comp_id, 'long_service_bonus', '장기근속포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속포상 (공식 채용 페이지 복지제도 유연함 항목) — 근속 기준 연수·포상 내용·금액 미기재', 20),
  (@comp_id, 'incentive', '성과 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '회사 및 개인의 성과에 따라 보장되는 인센티브 제도 (공식 채용 페이지 인사제도 PERFORMANCE 항목), 전 임직원 대상 성과 인센티브 제도 운영 (2025 지속가능경영보고서 87쪽 평가 체계 및 보상 항목) — 지급 기준·지급률 미기재', 21),

  -- ── 여가·라이프 (leisure) — 복지제도 유연함 · 도전과 성장 · 건강과 가족 · 보고서 89~90쪽 ──
  (@comp_id, 'resort', '휴양시설 제공 (금호리조트 외)', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설 제공(금호리조트 외) (공식 채용 페이지 복지제도 유연함 항목) — 이용 가능 시설 목록·이용 한도·본인 부담 미기재', 30),
  (@comp_id, 'club', '사내 동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 지원 (공식 채용 페이지 복지제도 도전과 성장 항목), 사내 동호회 활동 운영 (2025 지속가능경영보고서 89쪽 임직원 건강 관리 지원 항목) — 동호회 수·지원금 미기재', 31),
  (@comp_id, 'summer_vacation_subsidy', '휴가비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비 지원 (공식 채용 페이지 복지제도 건강과 가족 항목) — 지급액·지급 시기·지급 조건 미기재', 32),
  (@comp_id, 'culture_day', '금호문화데이', NULL, 'leisure',
   'est', NULL, TRUE, '임직원이 함께 공연을 관람할 수 있는 기회 제공 (2025 지속가능경영보고서 90쪽 2025년 임직원 소통 프로그램 금호문화데이 항목) — 운영 횟수·대상·비용 지원 범위 미기재', 33),

  -- ── 성장·교육 (growth) — 복지제도 도전과 성장 · 보고서 85~86 · 90쪽 ──
  (@comp_id, 'books', '도서구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서구입비 지원 (공식 채용 페이지 복지제도 도전과 성장 항목), 금호책드림 경영진 추천 도서 제공·임직원 독서 참여 지원 (2025 지속가능경영보고서 90쪽 2025년 임직원 소통 프로그램 항목) — 지원 한도·금액 미기재', 40),
  (@comp_id, 'edu_support', '정례 교양특강 (명사 초청)', NULL, 'growth',
   'est', NULL, TRUE, '정례 교양특강(명사 초청) (공식 채용 페이지 복지제도 도전과 성장 항목), 사내 교육 플랫폼 Wink-A 인문학 커리큘럼 수강 지원 (2025 지속가능경영보고서 85쪽 주요 교육 프로그램 항목) — 개최 주기·수강 비용 부담 미기재', 41),
  (@comp_id, 'lang', '외국어 학습·시험 응시 지원', NULL, 'growth',
   'est', NULL, TRUE, '외국어 학습/시험 응시 지원 (공식 채용 페이지 복지제도 도전과 성장 항목), 2025년 전 임직원을 대상으로 OPIc 교육 프로그램 지원 확대 (2025 지속가능경영보고서 86쪽 글로벌 비즈니스 역량 제고 항목) — 지원 한도·응시료 지원 횟수 미기재', 42),
  (@comp_id, 'self_development', '직무전문자격(증) 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무전문자격(증) 취득 지원 (공식 채용 페이지 복지제도 도전과 성장 항목), 국내·외 공인 자격증 및 국가기술 자격증 취득 지원, 고용형태나 직급에 관계없이 누구나 신청 가능, 자격 취득을 위한 지원 기간 최대 3년, 학원비·교재비·응시료 지원 및 국내 시험 미실시 시 해외 응시 항공료 지원 (2025 지속가능경영보고서 86쪽 직무 전문 자격 취득 지원 제도 항목) — 1인당 지원 한도·대상 자격증 목록 미기재', 43),

  -- ── 건강 (health) — 복지제도 건강과 가족 · 보고서 89쪽 ──
  (@comp_id, 'medical', '의료비 지원 (본인·배우자·자녀)', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원(본인 및 배우자/자녀) (공식 채용 페이지 복지제도 건강과 가족 항목), 연간 한도 내 질병·치과 치료비 지원 (2025 지속가능경영보고서 89쪽 임직원 건강 관리 지원 항목) — 연간 한도 금액·본인 부담률 미기재', 50),
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체 상해보험 가입 (공식 채용 페이지 복지제도 건강과 가족 항목) — 보장 범위·가족 포함 여부 미기재', 51),
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진 (공식 채용 페이지 복지제도 건강과 가족 항목), 정기 건강검진 지원 (2025 지속가능경영보고서 89쪽 임직원 건강 관리 지원 항목) — 검진 주기·비용 지원 범위·가족 포함 여부 미기재', 52),
  (@comp_id, 'mental', '심리상담 서비스 (EAP)', NULL, 'health',
   'est', NULL, TRUE, '심리상담 서비스 운영, 근로자 지원 프로그램(EAP)으로 업무 내외적 요인에 의한 스트레스를 외부 전문기관 상담 및 코칭을 통해 예방 (2025 지속가능경영보고서 89쪽 임직원 건강 관리 지원 · 근로자 지원 프로그램 항목) — 이용 횟수·가족 이용 여부·비용 부담 미기재', 53),
  (@comp_id, 'clinic', '보건관리실 (본사·울산·여수)', NULL, 'health',
   'est', NULL, TRUE, '본사, 울산사업장, 여수사업장에 보건관리실을 구축하고 전담인력(간호사)을 채용하여 현장 중심의 건강관리 체계 운영 (2025 지속가능경영보고서 89쪽 임직원 건강 관리 지원 항목) — 진료 범위·운영 시간 미기재', 54),

  -- ── 경제적 부가혜택 (perks) — 복지제도 건강과 가족 · 보고서 89쪽 ──
  (@comp_id, 'transport', '교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '교통비 지원 (공식 채용 페이지 복지제도 건강과 가족 항목) — 지급액·지급 방식·대상 미기재', 60),
  (@comp_id, 'welfare_point', '복지카드 포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지카드 포인트 제공 (공식 채용 페이지 복지제도 건강과 가족 항목) — 연간 포인트 금액·사용처 미기재', 61),
  (@comp_id, 'housing_support', '지방사업장 주거비 지원', NULL, 'perks',
   'est', NULL, TRUE, '지방사업장 주거비 지원 (공식 채용 페이지 복지제도 건강과 가족 항목) — 지원 금액·대상 사업장·지원 기간 미기재', 62),
  (@comp_id, 'housing_loan', '주택자금 무이자 대출', NULL, 'perks',
   'est', NULL, TRUE, '무주택 임직원 대상 주택 매매자금 및 전·월세 보증금 마련을 위한 무이자 대출 지원, 1회당 4천만 원·최대 2회 한도 (2025 지속가능경영보고서 89쪽 임직원 주거 안정 지원 항목) — 상환 기간·근속 요건 미기재', 63),

  -- ── 가족·돌봄 (family) — 복지제도 건강과 가족 · 보고서 88~89쪽 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (공식 채용 페이지 복지제도 건강과 가족 항목), 2022년부터 희망퇴직자 대상 자녀 학자금 지원 기간 확대 및 퇴직 이후 일정 기간 지속 지원 (2025 지속가능경영보고서 89쪽 퇴직자 지원 항목) — 지원 학령·한도·자녀 수 제한 미기재', 70),
  (@comp_id, 'parenting', '임신·출산·육아 지원 (Kumho-CARE)', NULL, 'family',
   'est', NULL, TRUE, '출산장려제도 (공식 채용 페이지 복지제도 건강과 가족 항목), 임신축하패키지 임산부 용품 등 축하 선물 지급, 임신기간 근로단축 법정 기간(임신 12주 이내, 32주 이후) 외 4주 추가 부여, 출산축하금 첫째 500만 원·둘째 1,000만 원·셋째 2,000만 원·넷째 이상 3,000만 원, 산후조리비 출산 자녀당 100만 원, 유치원·초등학교·중학교·고등학교 입학 축하금, 입양축하금 자녀 1인당 300만 원, 초등학교 입학 돌봄 휴직 1개월 (2025 지속가능경영보고서 88쪽 Kumho-CARE 표, 2025년 기준) — 입학 축하금 금액·돌봄 휴직 유급 여부 미기재', 71),
  (@comp_id, 'fertility_support', '난임 지원 (시술비·휴가)', NULL, 'family',
   'est', NULL, TRUE, '난임시술비 회당 최대 300만 원 무제한 지원, 난임휴가 12일 (법정 6일에 6일 추가) (2025 지속가능경영보고서 88쪽 Kumho-CARE 표 임신 항목, 2025년 기준) — 추가 6일의 유급 여부 미기재', 72),
  (@comp_id, 'disability_family_support', '장애인 재활수당·보장구 구입비', NULL, 'family',
   'est', NULL, TRUE, '재활수당 대상자 1인당 월 50만 원, 보장구 구입비 대상자 1인당 400만 원(필요 시 매 3년마다) (2025 지속가능경영보고서 88쪽 Kumho-CARE 표 장애인 항목, 2025년 기준) — 지원 대상(임직원 본인·가족) 범위·장애 정도 요건 미기재', 73),

  -- ── 근무환경 (work_env) — 보고서 88~89쪽 ──
  (@comp_id, 'nap_room', '임산부 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '임산부의 휴식 및 수유 지원을 위한 전용 휴게실 운영, 침대·리클라이너·모유 보관용 냉장고·공기청정기 등 편의시설 구비, 임산부가 상시 이용 가능 (2025 지속가능경영보고서 88쪽 임산부 휴게실 항목) — 설치 사업장 미기재', 80),
  (@comp_id, 'dormitory', '사택 (공장·중앙연구소 신규 채용자·근무지 이동 직원)', NULL, 'work_env',
   'est', NULL, TRUE, '공장 및 중앙연구소 근무자 중 신규 채용자(경력직 포함) 및 근무지 이동 직원 대상 사택 제공 (2025 지속가능경영보고서 89쪽 임직원 주거 안정 지원 항목) — 입주 기간·본인 부담 미기재', 81),

  -- ── 휴가 (time_off) — 보고서 88쪽 ──
  (@comp_id, 'leave_general', '입양휴가 5일 (유급)', NULL, 'time_off',
   'est', NULL, TRUE, '입양휴가 5일(유급) (2025 지속가능경영보고서 88쪽 Kumho-CARE 표 입양 항목, 2025년 기준) — 사용 기한·분할 사용 여부 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
