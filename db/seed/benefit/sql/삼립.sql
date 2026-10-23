-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼립 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://spcsamlip.co.kr/recruit/hr
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)삼립의 자기 도메인 spcsamlip.co.kr 인재채용 > 인사제도 페이지다(www 는 apex 로 넘어간다).
--   Next.js SSR 이라 원본 HTML 에 보상제도 · 주요 인재육성 제도 · 복리후생 5묶음 15카드가 다 있다. 렌더 · 이미지 판독 불필요.
--   보조 출처는 같은 도메인 보고서 및 정책 목록에 올라 있는 법인 단독 발행 2026 삼립 지속가능경영보고서
--   (PDF 78쪽 · 생성 2026-07 · 보고 기간 2025년 · 보고 범위 삼립 중심 · 상미당홀딩스 데이터는 행복한재단 활동만)
--   20쪽 건강증진활동 · 37쪽 인재 육성 체계 · 43쪽 근무환경 개선과 가족친화 · 46쪽 평가 및 보상.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814001053) · 2025 사업보고서(접수 20260318001066)
--   직원 등의 현황 유연근무제도 사용 현황(시차출퇴근제 · 원격근무제 사용자 수). 직원 3,027명(2026 반기).
--   귀속: 복리후생 묶음 제목이 삼립인만의 혜택이고 보고서는 삼립 주어 문장이라 각주 없음.
--   다만 인사제도 페이지 보상제도 문단 주어가 상미당홀딩스이고 같은 문단에 현장직 보상체계는 계열사별로 상이 단서가 붙어 있다 —
--   성과급 행은 보고서 46쪽 삼립 주어 문장(인센티브 지급)으로 이 법인 적용을 확인하고 페이지 문구에는 상미당홀딩스 공통 문구 각주.
--   SPC 그룹 통합 채용 사이트(spc.recruiter.co.kr)는 robots 전면 금지라 읽지 않았다. 코퍼스에 SPC 형제 없음.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL. 숫자는 리프레시 휴가 4일 · 패밀리데이 시각 · 공시 사용자 수뿐.
--   제외: 법정(난임치료 휴가 연 6일 중 2일 유급 · 임신기 근로시간 단축 · 유사산 휴가 · 출산 전후 휴가 · 육아휴직 1년 6개월 3회 분할 ·
--     모성보호 제도 운영) · 업무 교육(사내 MBA 핵심리더 육성 · 리더십 · 직무 · 법정 의무 · 신입 입문 · 점프업 승진자 과정) ·
--     임원 보수 칸(학자금 · 복지수당 · 휴가비 — 반기보고서 임원 개인 보수 산정 칸) · 소통 · 기업문화 프로그램(포커스 데이 · 랜덤런치버디 ·
--     활짝피자 · 타운홀 · 갓생림픽 · 아이디어 경진대회) · CP 자율준수 우수 직원 포상(준법 관리) · 감정노동 힐링 휴게실(중기 목표 표 · 상담사 대상 계획).
--   공고 근거 0행 / 전체 25행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(compensation 10 · growth 20 · perks 30 · flexibility 40 · leisure 50 · family 60 ·
--     time_off 70 · health 80).
-- 검증 · 감사 판정 반영(2026-10-22): 가족사랑 Challenge 행에 보고서 45쪽 전 직원 신년식 병합 · 보상제도 문단 상미당홀딩스 주어 행은 46쪽 삼립 주어 문장이 받쳐 각주 유지 · 참고 블록 제외 줄의 신년식은 이 판정으로 뒤집힘 — 최종 25행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samlip', '삼립',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품', 'S', 'https://spcsamlip.co.kr/recruit/hr');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samlip');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://spcsamlip.co.kr/recruit/hr'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 인사제도 보상제도 · 복리후생 교육 지원 · 보고서 46쪽 ──
  (@comp_id, 'incentive', '성과 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '업적평가 결과 목표 달성 수준과 업무 성과를 종합적으로 반영하여 인센티브 지급 (2026 지속가능경영보고서 46쪽 임직원 평가 및 보상 항목), 개인성과급 평가 등급에 따라 차등지급 · 조직성과급 조직별 경영성과에 따라 차등지급 (공식 채용 페이지 인사제도 보상제도 항목, 상미당홀딩스 공통 문구) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'long_service_bonus', '장기근속자 해외 연수', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 해외 연수 (공식 채용 페이지 복리후생 교육 지원 항목) — 근속 기준·연수 기간·지원 범위 미기재', 11),
  (@comp_id, 'excellence_award', '우수사원 해외 연수', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 해외 연수 (공식 채용 페이지 복리후생 교육 지원 항목) — 선발 기준·연수 기간·지원 범위 미기재', 12),

  -- ── 성장 · 교육 (growth) — 인사제도 주요 인재육성 제도 · 복리후생 교육 지원 · 보고서 37쪽 ──
  (@comp_id, 'mba', '대학원 진학 지원·국내 대학 MBA', NULL, 'growth',
   'est', NULL, TRUE, '임직원의 자기개발을 통한 개인의 비전 실현을 지원하기 위해 대학원 진학을 권장하고 지원하는 프로그램 운영, 전문인력 양성을 목적으로 미국 · 일본 · 프랑스 등에 장기 기술연수 (공식 채용 페이지 인사제도 주요 인재육성 제도 항목), 국내 대학 MBA (2026 지속가능경영보고서 37쪽 인재 육성 체계 항목) — 지원 대상·선발 기준·지원 범위 미기재', 20),
  (@comp_id, 'lang', '어학 비용 지원', NULL, 'growth',
   'est', NULL, TRUE, '개인의 어학능력 향상을 위해 일정 비용 지원 (공식 채용 페이지 인사제도 직무능력 향상 항목) — 지원 금액·대상 과정 미기재', 21),
  (@comp_id, 'edu_support', '온라인 e-Learning 강의', NULL, 'growth',
   'est', NULL, TRUE, '온라인 e-Learning 강의 (공식 채용 페이지 복리후생 교육 지원 항목), 임직원의 자기계발 기회를 확대하기 위하여 온라인 학습 사이트 e-Academy 운영 (공식 채용 페이지 인사제도 직무능력 향상 항목) — 수강 범위·과정 구성 미기재', 22),

  -- ── 생활 · 금융 (perks) — 복리후생 삼립인만의 혜택 · 생활 지원 ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 (공식 채용 페이지 복리후생 삼립인만의 혜택 항목) — 지급 금액·사용처 미기재', 30),
  (@comp_id, 'discount', '임직원 통합 할인', NULL, 'perks',
   'est', NULL, TRUE, '임직원 통합 할인 (공식 채용 페이지 복리후생 삼립인만의 혜택 항목) — 할인 대상·할인율 미기재', 31),
  (@comp_id, 'meal', '사내식당 운영', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 운영 (공식 채용 페이지 복리후생 생활 지원 항목) — 제공 끼니·식대 지원 범위 미기재', 32),

  -- ── 근무 유연성 (flexibility) — 복리후생 생활 지원 · 휴식 지원 · 보고서 43쪽 · 공시 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출근제 (공식 채용 페이지 복리후생 생활 지원 항목), 근무시간을 유연하게 조정할 수 있는 시차출퇴근제 운영 · 08:00~17:00, 09:00~18:00(기본 시간), 10:00~19:00 출퇴근 중 선택 (2026 지속가능경영보고서 43쪽 시차출퇴근제도 항목), 시차출퇴근제 사용자 수 2026년 반기 58명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·신청 조건 미기재', 40),
  (@comp_id, 'family_day', 'Family Day', NULL, 'flexibility',
   'est', NULL, TRUE, 'Family Day (공식 채용 페이지 복리후생 휴식 지원 항목), 패밀리데이 매월 셋째주 금요일 오후 12시 30분 퇴근으로 약 5시간 단축 근무 (2026 지속가능경영보고서 43쪽 2025년 가족친화 프로그램 운영 실적 항목) — 적용 대상 미기재', 41),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 2025년 10명 · 2026년 반기 5명 (2025 사업보고서 · 2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 42),

  -- ── 여가 · 행사 (leisure) — 복리후생 생활 지원 · 휴식 지원 · 보고서 43쪽 ──
  (@comp_id, 'welcome_kit', '웰컴키트 지급', NULL, 'leisure',
   'est', NULL, TRUE, '웰컴키트 지급 (공식 채용 페이지 복리후생 생활 지원 항목) — 지급 대상·구성품 미기재', 50),
  (@comp_id, 'resort', '휴가 및 휴양시설 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴가 및 휴양시설 지원 (공식 채용 페이지 복리후생 휴식 지원 항목) — 휴양시설 종류·이용 조건·지원 내용 미기재', 51),
  (@comp_id, 'company_event', '가족사랑 Challenge · 신년식', NULL, 'leisure',
   'est', NULL, TRUE, '5월 가정의 달을 맞이하여 어린이 · 어버이 날, 부부의 날 인증사진 및 후기를 업로드하여 선물 증정 (2026 지속가능경영보고서 43쪽 2025년 가족친화 프로그램 운영 실적 항목), 전 직원이 참여하는 신년식 (같은 보고서 45쪽 소통 프로그램 항목) — 선물 내용·참여 조건·행사 내용 미기재', 52),

  -- ── 가족 (family) — 복리후생 휴식 지원 · 교육 지원 · 건강 지원 · 보고서 43쪽 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (공식 채용 페이지 복리후생 휴식 지원 항목) — 경조금 금액·경조휴가 일수 미기재', 60),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (공식 채용 페이지 복리후생 교육 지원 항목) — 지원 학령·지원 금액 미기재', 61),
  (@comp_id, 'parenting', '출산키트·웰컴맘 프로그램', NULL, 'family',
   'est', NULL, TRUE, '출산키트 지급 (공식 채용 페이지 복리후생 건강 지원 항목), 임신과 출산을 앞둔 임직원에게 웰컴맘 프로그램을 통해 축하와 함께 육아용품 제공 · 출산용품 키트 제공 및 건강한 출산 기원 파티 (2026 지속가능경영보고서 43쪽 가족친화 제도 항목) — 키트 구성품 미기재', 62),

  -- ── 휴가 (time_off) — 복리후생 휴식 지원 · 보고서 43쪽 ──
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '리프레시 휴가 지원 (공식 채용 페이지 복리후생 휴식 지원 항목), 연차와 별도로 4일의 유급휴가 추가 부여 (2026 지속가능경영보고서 43쪽 리프레시 휴가 항목) — 부여 조건·사용 주기 미기재', 70),

  -- ── 건강 (health) — 복리후생 건강 지원 · 보고서 20쪽 ──
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 (공식 채용 페이지 복리후생 건강 지원 항목) — 보장 범위·가족 적용 여부 미기재', 80),
  (@comp_id, 'clinic', '건강관리실 운영', NULL, 'health',
   'est', NULL, TRUE, '건강관리실 운영 (공식 채용 페이지 복리후생 건강 지원 항목), 사업장 여건에 맞춰 건강관리실 운영 · 인바디 기기, 혈압기 등 인프라 구축 (2026 지속가능경영보고서 20쪽 건강증진활동 항목) — 운영 사업장·상주 인력 미기재', 81),
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '건강검진 지원 (공식 채용 페이지 복리후생 건강 지원 항목) — 검진 주기·비용 지원 범위 미기재', 82),
  (@comp_id, 'mental', '심리상담 지원 프로그램(EAP)', NULL, 'health',
   'est', NULL, TRUE, '직무 스트레스를 포함한 근로자의 정신건강 관리를 위해 심리상담 지원 프로그램(EAP) 제공 (2026 지속가능경영보고서 20쪽 건강증진활동 항목) — 상담 횟수·가족 이용 여부 미기재', 83),
  (@comp_id, 'fitness', '체력 단련실·요가 프로그램', NULL, 'health',
   'est', NULL, TRUE, '사무직 근로자의 근골격계질환 예방을 위한 요가 프로그램 제공, 비만 관리 건강 챌린지 프로그램 운영, 사업장 여건에 맞춰 체력 단련실 운영 (2026 지속가능경영보고서 20쪽 건강증진활동 항목) — 운영 사업장·이용 시간 미기재', 84),
  (@comp_id, 'smoking_cessation', '금연 건강 챌린지', NULL, 'health',
   'est', NULL, TRUE, '심뇌혈관질환 발병 위험요인 감소를 위해 금연 건강 챌린지 프로그램 운영 (2026 지속가능경영보고서 20쪽 건강증진활동 항목) — 참여 보상·지원 내용 미기재', 85)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
