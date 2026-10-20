-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- GS칼텍스 복리후생 데이터 (신규 회사 — 웨이브 13)
-- 출처: AI 파싱 (2026-10-20)
-- URL: https://www.gscaltex.com/kr/recruit/hrsystem/welfarebenefits
-- badge: est
--
-- 참고:
--   정본은 법인 GS칼텍스(주) 자기 도메인 www.gscaltex.com 의 Recruit > 인사제도 > 복리후생 페이지(SSR).
--   복리후생제도 표 5구분(주거지원 · 건강증진 · 자녀양육 지원 · 자기계발 및 여가 지원 · 생활안정 지원 29불릿)과
--   Welfare System 본문 4문단(건강증진프로그램 · 구성원상담프로그램(EAP) · 선택적 복지제도 운영 · Work & Life Balance 추구).
--   보조 출처: 같은 도메인 인사제도 > 인사제도 페이지(보상 · 조직문화 항목) · 인사제도 > 인재육성 페이지(우수 인재 육성 항목) ·
--   헤더 메뉴 영문판 Employee Benefits 페이지(국문과 같은 구성 — 생활안정자금이 Loan 임을 밝힘) ·
--   OpenDART 2026 반기보고서(접수 20260814002233) · 2025 사업보고서(접수 20260331004120) 유연근무제도 사용 현황 표.
--   렌더 방식은 원본 HTML 태그 제거(헤드리스 렌더 0회). 지속가능성보고서 PDF 는 robots 금지 경로(/download/)라 받지 않았고,
--   채용 사이트 recruit.gscaltex.com 은 robots 가 모든 UA 를 막아 받지 않았다.
--   귀속: 페이지 주어가 회사 자신이고 GS그룹 주어 · 계열사별 상이 단서 없음 — 각주 없음. 비상장 법인(종목코드 없음) ·
--   최대주주 지에스에너지 50.0퍼센트. 기등록 형제 GS건설 · GS리테일은 각자 자기 보고서 PDF 정본이라 이번 출처와 문장 겹침 없음.
--   금액: stated 0 · 추정 1(복지포인트 350만 포인트 1포인트 1원 환산). 한도 · 이율 · 1회성 축하금 · 기간 상한 금액 · 매칭 금액(주기 미기재)은 NULL.
--   제외: 법정(출산축하휴가 10일 · 육아 휴직 및 단축근무) · 업무 교육(코칭 · 멘토링 · 리더십 · 직무역량 육성 · 글로벌 기업연수과정 ·
--   Self-designed Learning 직무 전문가 과정) · 급여 조정(연봉 차등 조정) · 인사(승진 · 직무순환) · 자율복장제(복지 코드 없음) ·
--   원격근무(공시가 2023년부터 실시하지 않는다고 밝힘).
--   공고 근거 0행 / 전체 25행.
--   SORT 섹션 순서 = 정본 페이지에 카테고리가 처음 나온 순서
--   (perks 10 · work_env 20 · health 30 · family 40 · growth 50 · leisure 60 · time_off 70),
--   보조 출처에만 있는 카테고리는 끝(compensation 80 · flexibility 90). 수유실(본문)은 work_env, 난임치료비(건강증진 표)는 family 섹션.
-- 검증 · 감사 판정 반영(2026-10-20): 자기 도메인 SHE 경영 보건관리 페이지의 부속의원 clinic 추가 · 글로벌 기업연수과정을 mba 이름과 서술에 흡수(파견형 육성) · 금연은 건강증진 프로그램 fitness 한 행 유지 · 단체상해 국문 최대 2억 원 유지 · 항목 페이지 예외 1(통합 밖 리드 집행) · 참고 블록 제외 줄의 글로벌 기업연수과정과 보조 출처 줄은 이 판정으로 뒤집힘 — 최종 26행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('gs_caltex', 'GS칼텍스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '정유/화학', 'G', 'https://www.gscaltex.com/kr/recruit/hrsystem/welfarebenefits');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'gs_caltex');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.gscaltex.com/kr/recruit/hrsystem/welfarebenefits'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활 · 금융 (perks) — 복리후생 주거지원 · 자기계발 및 여가 지원 · 생활안정 지원 ──
  (@comp_id, 'housing_loan', '주택 융자 (주택구입·전세 자금)', NULL, 'perks',
   'est', NULL, TRUE, '주택 융자: 주택구입/전세 자금 (1억5천만 원 한도, 연 0.5%) (공식 홈페이지 복리후생 주거지원 항목) — 상환 기간·대상 조건 미기재', 10),
  (@comp_id, 'welfare_point', '복지포인트 350만 포인트 (Welcafe)', 350, 'perks',
   'est', '임직원에게 일정 포인트(350만 포인트)를 지급하고 문화생활, 체육시설 등에서 사용한 후 회사 시스템(welcafe)에서 정산 (공식 홈페이지 복리후생 선택적 복지제도 운영 항목) — 지급 주기 미기재, 1포인트 1원 기준 환산', FALSE, NULL, 11),
  (@comp_id, 'welfare_fund_loan', '생활안정자금', NULL, 'perks',
   'est', NULL, TRUE, '생활안정자금 (4,000만원 한도, 연2.2%) (공식 홈페이지 복리후생 생활안정 지원 항목), Loan for emergency living expenses (공식 영문 홈페이지 Employee Benefits 항목) — 상환 기간·대상 조건 미기재', 12),
  (@comp_id, 'pension_support', '개인형 퇴직연금(IRP) 매칭 지원', NULL, 'perks',
   'est', NULL, TRUE, '노후 대비 개인형 퇴직연금(IRP) 지원 (매칭 그랜트 본인 25만 원, 회사 25만 원), 퇴직연금 관련 경영성과급 DC 납부 지원 (공식 홈페이지 복리후생 생활안정 지원 항목) — 매칭 주기·납부 조건 미기재', 13),

  -- ── 근무 환경 (work_env) — 복리후생 주거지원 · Work & Life Balance 추구 ──
  (@comp_id, 'dormitory', '사택·기숙사 (여수공장·연구소)', NULL, 'work_env',
   'est', NULL, TRUE, '사택(여수공장) 및 기숙사(연구소 및 여수공장) (공식 홈페이지 복리후생 주거지원 항목) — 입주 자격·비용 부담 미기재', 20),
  (@comp_id, 'nap_room', '수유실', NULL, 'work_env',
   'est', NULL, TRUE, '수유실 설치 (공식 홈페이지 복리후생 Work & Life Balance 추구 항목) — 설치 사업장·운영 방식 미기재', 21),

  -- ── 건강 (health) — 복리후생 건강증진 · 건강증진프로그램 · 구성원상담프로그램(EAP) ──
  (@comp_id, 'medical', '의료비·치과보철료 지원 (본인·배우자·자녀)', NULL, 'health',
   'est', NULL, TRUE, '의료비 (1억 원 한도, 본인/배우자/자녀), 치과보철료 (500만원 한도, 본인/배우자/자녀) (공식 홈페이지 복리후생 건강증진 항목) — 지원 비율·한도 적용 기간 미기재', 30),
  (@comp_id, 'health_check', '종합건강검진 (임직원·배우자)', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 배우자 종합건강검진 실시, 독감 등 예방접종 (공식 홈페이지 복리후생 건강증진프로그램 항목) — 검진 주기·검진 항목 미기재', 31),
  (@comp_id, 'fitness', '건강증진 프로그램', NULL, 'health',
   'est', NULL, TRUE, '건강강좌를 비롯하여 금연/비만/근골격계 질환 예방 등 다양한 건강증진 프로그램 운영 (공식 홈페이지 복리후생 건강증진프로그램 항목) — 운영 주기·참여 대상 미기재', 32),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 가입 (최대 2억 원, 업무중 산재포함) (공식 홈페이지 복리후생 건강증진 항목) — 보장 항목·가입 대상 미기재', 33),
  (@comp_id, 'mental', '구성원 상담 프로그램(EAP)', NULL, 'health',
   'est', NULL, TRUE, '2007년부터 외부전문가 상담 지원, 임직원과 그 가족들이 대인관계 갈등, 스트레스 등 각종 고충과 재무설계, 자녀 인성 및 진로 등의 문제에 대해 전문가와 직접 상담 (공식 홈페이지 복리후생 구성원상담프로그램(EAP) 항목) — 이용 횟수·비용 부담 미기재', 34),
  (@comp_id, 'clinic', '부속의원', NULL, 'health',
   'est', NULL, TRUE, '부속의원 운영, 전문 의료진이 최신 의료장비를 이용하여 기본검진, 추적검사로 임직원의 건강 관리 (공식 홈페이지 안전보건환경 경영 보건관리 임직원 건강관리 항목) — 운영 사업장·진료 과목 미기재', 35),

  -- ── 가족 (family) — 복리후생 자녀양육 지원 · 건강증진 · 생활안정 지원 ──
  (@comp_id, 'parenting', '출산·입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '출산축하금 (첫째 600만원, 둘째 1,000만원, 셋째 이상 1,500만원), 입학축하금 (초등학교, 중학교, 고등학교 240만원) (공식 홈페이지 복리후생 자녀양육 지원 항목) — 입학축하금 학교급별 지급 방식 미기재', 40),
  (@comp_id, 'child_edu', '자녀 학자금·유치원 교육비', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 (고등학교/대학교 전액, 자녀 수 제한 없음), 유치원 교육비 (2년간 240만원) (공식 홈페이지 복리후생 자녀양육 지원 항목) — 유치원 교육비 지급 방식 미기재', 41),
  (@comp_id, 'childcare', '직장 어린이집 (본사·여수공장)', NULL, 'family',
   'est', NULL, TRUE, '어린이집 운영 (본사 및 여수공장) (공식 홈페이지 복리후생 자녀양육 지원 항목) — 정원·이용 조건 미기재', 42),
  (@comp_id, 'fertility_support', '난임치료비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임치료비 지원 (공식 홈페이지 복리후생 건강증진 항목) — 지원 한도·횟수 미기재', 43),
  (@comp_id, 'event', '경조휴가·경조금·장례지원 서비스', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 경조금 (결혼/사망/회갑/칠순/팔순 등), 장례지원 서비스 (공식 홈페이지 복리후생 생활안정 지원 항목) — 경조 유형별 휴가 일수·금액 미기재', 44),

  -- ── 성장 · 교육 (growth) — 복리후생 자기계발 및 여가 지원 · 인재육성 우수 인재 육성 ──
  (@comp_id, 'edu_support', '온라인 교육 시스템', NULL, 'growth',
   'est', NULL, TRUE, '온라인 교육 시스템을 통한 다양한 교육 Contents 지원 (공식 홈페이지 복리후생 자기계발 및 여가 지원 항목) — 과정 구성·수강 조건 미기재', 50),
  (@comp_id, 'mba', 'MBA/Global on-line 과정·글로벌 기업연수과정 (우수 인재 육성)', NULL, 'growth',
   'est', NULL, TRUE, '국내외 유수대학 MBA/Global on-line 과정, 글로벌 기업연수과정 (공식 홈페이지 인재육성 우수 인재 육성 항목) — 선발 기준·연수 기간·지원 범위 미기재', 51),

  -- ── 여가 (leisure) — 복리후생 자기계발 및 여가 지원 · Work & Life Balance 추구 ──
  (@comp_id, 'resort', '콘도·휴양소·인재개발원 생활관', NULL, 'leisure',
   'est', NULL, TRUE, '전국 콘도 및 휴양소 (전국 30여개 시설), 인재개발원 생활관 (청평) (공식 홈페이지 복리후생 자기계발 및 여가 지원 항목), 전국 콘도미니엄, 연중 휴양소 지원 (Work & Life Balance 추구 항목) — 이용 횟수·비용 부담 미기재', 60),
  (@comp_id, 'club', '동호회 활동 (80여 개)', NULL, 'leisure',
   'est', NULL, TRUE, '구성원들이 80여 개의 동호회 활동을 통해 여가를 활용 (공식 홈페이지 복리후생 Work & Life Balance 추구 항목), We also support some 80 employee clubs (공식 영문 홈페이지 Work & Life Balance 항목) — 지원 방식·금액 미기재', 61),

  -- ── 휴가 (time_off) — 복리후생 자기계발 및 여가 지원 · Work & Life Balance 추구 ──
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2주간의 리프레시(refresh) 휴가 제도 (공식 홈페이지 복리후생 Work & Life Balance 추구 항목), 리프레시(refresh) 휴가 실시 (자기계발 및 여가 지원 항목) — 부여 주기·유급 여부·대상 조건 미기재', 70),
  (@comp_id, 'long_service_leave', '장기근속 기념금품·휴가 (5년 단위)', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 기념금품 및 휴가 (5년 단위) (공식 홈페이지 복리후생 자기계발 및 여가 지원 항목) — 휴가 일수·기념금품 내용 미기재', 71),

  -- ── 보상 (compensation) — 인사제도 보상 ──
  (@comp_id, 'profit_sharing', '전사 성과급 (경영 성과 연동)', NULL, 'compensation',
   'est', NULL, TRUE, '경영 성과에 따른 전사 성과급 지급 (공식 홈페이지 인사제도 보상 항목) — 지급 기준·지급률 미기재', 80),
  (@comp_id, 'incentive', '개인 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '평가에 따른 개인인센티브 지급 (공식 홈페이지 인사제도 보상 항목) — 지급 기준·지급률 미기재', 81),

  -- ── 근무 유연성 (flexibility) — 인사제도 조직문화 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '자율출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '자율출퇴근제: 08시~10시 (여수 공장 07시~09시) 사이 출근하여 8시간 근무 (공식 홈페이지 인사제도 조직문화 항목), 시차출퇴근제를 도입 (2026 반기보고서 유연근무제도 사용 현황 항목, 2026년 6월말 적용 직원 1,313명) — 적용 제외 직무 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
