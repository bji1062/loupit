-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 코스모신소재 복리후생 데이터 (신규 회사 — 웨이브 10)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.cosmoamt.com/?page_id=11177
-- badge: est
--
-- 참고:
--   정본은 상장 법인 코스모신소재(주)의 자기 도메인 www.cosmoamt.com 인재채용 > 인재상 페이지다(워드프레스 SSR).
--   원본 HTML 에 인사제도 4블록 · 복리후생 5묶음(생활 안정 · 건강 증진 · 여가 생활 · 근속/성과 보상 · 기타) ·
--   사내ㆍ외 교육 표가 다 있다(데스크톱 · 모바일 같은 문구 두 벌 — 한 벌로 셈). 헤드리스 렌더 · 이미지 판독 불필요.
--   공시 보조: OpenDART 2026 반기보고서 기재정정(접수 20260930000732) 정관상 사업목적 변경 항목의 기숙사 문장,
--   2025 사업보고서 기재정정(접수 20260602000342) 재무제표 주석 종업원급여(기타장기종업원급여)
--   문장, 위 2026 반기보고서 재무제표 주석 지급보증 · 사용이 제한된 금융자산(우리사주조합 취득 대금 차입 담보) 문장. 직원 459명(2025 사업보고서 직원 현황).
--   공시 유연근무제도 사용 현황 = 당사는 유연근무제도를 활용하고 있지 않습니다(반기 · 사업보고서 둘 다) — 유연근무 행 없음.
--   귀속: 페이지 주어가 코스모신소재(코스모신소재의 내일, 우리가 함께 만듭니다)이고 그룹 · 계열사 단서가 없다.
--   코스모그룹 형제(코스모화학 · 코스모앤컴퍼니 등) 시드는 코퍼스 · 대기 폴더에 없다. 각주 불필요.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL(사내식당은 끼니 미기재).
--   제외: 업무 교육(신입사원 Onboarding · 계층별교육 · 특성화교육 · 공통역량교육 리더쉽 · 조직활성화 과정 ·
--     기술직무교육 · 신입입문교육 OJT) · 배치 전 검진(채용 절차) · 육아휴직 · 배우자 출산휴가 사용 현황(법정) ·
--     반기보고서 연수시설 직무 교육 · 그룹 연수프로그램(업무 교육) · 퇴직연금 확정급여제도(법정).
--   공고 근거 0행 / 전체 23행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(growth 10 · family 20 · perks 30 · work_env 40 · health 50 ·
--     leisure 60 · time_off 70 · compensation 80), 공시에만 있는 행은 compensation 섹션 끝.
-- 검증 · 감사 판정 반영(2026-10-15): 장기근속자 퇴직금 severance_plus 행 삭제(누진 · 가산 원문 없음 · 리드 판정 144) · 재무제표 주석 근거 근속 행 이름을 장기근속 급부로(웨이브 8 · 9 꼴) · 참고 블록의 공고 근거 0행 / 전체 23행은 전체 22행 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 22행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('cosmo_amt', '코스모신소재',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '배터리소재', 'C', 'https://www.cosmoamt.com/?page_id=11177');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cosmo_amt');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.cosmoamt.com/?page_id=11177'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 · 교육 (growth) — 인재상 페이지 인사제도 · 사내ㆍ외 교육 표 ──
  (@comp_id, 'edu_support', '디지털 학습 플랫폼 · 테마교육', NULL, 'growth',
   'est', NULL, TRUE, 'E-Learning & Book Learning & Micro Learning 디지털 학습 플랫폼, 다양한 분야의 교육 제공 (공식 채용 페이지 인재상 인사제도 항목), 테마교육 e-Learning, 독서통신 과정, 테마특강 (같은 페이지 사내·외 교육 표 항목) — 수강 대상·비용 지원 범위 미기재', 10),
  (@comp_id, 'lang', '사내 어학교육 (영어 · 일본어 · 중국어)', NULL, 'growth',
   'est', NULL, TRUE, '사내 어학교육 영어, 일본어, 중국어 (공식 채용 페이지 인재상 사내·외 교육 표 항목) — 수강 대상·비용 부담 미기재', 11),
  (@comp_id, 'mba', 'Cyber MBA 과정 (핵심인력교육)', NULL, 'growth',
   'est', NULL, TRUE, '핵심인력교육 Cyber-MBA과정 (공식 채용 페이지 인재상 사내·외 교육 표 항목) — 선발 기준·학위 취득 여부·비용 지원 범위 미기재', 12),
  (@comp_id, 'conference', '사외위탁교육', NULL, 'growth',
   'est', NULL, TRUE, '사외위탁교육 업무관련 교육 (공식 채용 페이지 인재상 사내·외 교육 표 항목) — 교육 기관·비용 지원 범위·대상 미기재', 13),

  -- ── 가족 (family) — 인재상 페이지 복리후생 생활 안정 지원 · 기타 복리후생 ──
  (@comp_id, 'parenting', '자녀 입학축하금', NULL, 'family',
   'est', NULL, TRUE, '자녀 입학축하금 (공식 채용 페이지 인재상 복리후생 생활 안정 지원 항목) — 대상 학교급·지급 금액 미기재', 20),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 (공식 채용 페이지 인재상 복리후생 생활 안정 지원 항목) — 지원 학교급·지원 한도 미기재', 21),
  (@comp_id, 'event', '경조휴가 · 경조금', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 경조금 지급 (공식 채용 페이지 인재상 기타 복리후생 항목) — 경조 범위·휴가 일수·지급 금액 미기재', 22),

  -- ── 생활 · 금융 (perks) — 인재상 페이지 복리후생 생활 안정 지원 · 기타 복리후생 ──
  (@comp_id, 'welfare_fund', '사내 근로복지기금 운영', NULL, 'perks',
   'est', NULL, TRUE, '사내 근로복지기금 운영 (공식 채용 페이지 인재상 복리후생 생활 안정 지원 항목) — 기금 지원 사업·대상 미기재', 30),
  (@comp_id, 'commute_subsidy', '통근버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운영 (공식 채용 페이지 인재상 기타 복리후생 항목) — 운행 노선·사업장 미기재', 31),
  (@comp_id, 'meal', '사내식당 운영', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 운영 (공식 채용 페이지 인재상 기타 복리후생 항목) — 제공 끼니·식대 부담 미기재', 32),
  (@comp_id, 'birthday_gift', '생일자 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일자 선물 지급 (공식 채용 페이지 인재상 기타 복리후생 항목) — 선물 품목·금액 미기재', 33),

  -- ── 근무 환경 (work_env) — 인재상 페이지 복리후생 생활 안정 지원 · 2026 반기보고서 ──
  (@comp_id, 'dormitory', '기숙사 운영 (타지역 거주자)', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 운영 타지역 거주자 대상 (공식 채용 페이지 인재상 복리후생 생활 안정 지원 항목), 신축한 코스모이노베이션스페이스(기숙사) (2026 반기보고서 정관상 사업목적 변경 항목) — 입사 기준·비용 부담 미기재', 40),

  -- ── 건강 (health) — 인재상 페이지 복리후생 건강 증진 지원 · 여가 생활 지원 ──
  (@comp_id, 'health_check', '종합검진 지원 (본인 · 배우자)', NULL, 'health',
   'est', NULL, TRUE, '종합검진 지원 본인 및 배우자 (공식 채용 페이지 인재상 복리후생 건강 증진 지원 항목) — 검진 주기·지원 비용 미기재', 50),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (공식 채용 페이지 인재상 복리후생 건강 증진 지원 항목) — 지원 대상 범위·지원 한도 미기재', 51),
  (@comp_id, 'insurance', '단체상해보험 가입', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 가입 (공식 채용 페이지 인재상 복리후생 건강 증진 지원 항목) — 보장 내용·가족 가입 여부 미기재', 52),
  (@comp_id, 'fitness', '부대시설 운영 (헬스장 · 족구장 · 농구장 · 탁구장)', NULL, 'health',
   'est', NULL, TRUE, '부대시설 운영 헬스장, 족구장, 농구장, 탁구장 등 (공식 채용 페이지 인재상 복리후생 여가 생활 지원 항목) — 이용 시간·사업장 미기재', 53),

  -- ── 여가 (leisure) — 인재상 페이지 복리후생 여가 생활 지원 ──
  (@comp_id, 'club', '사내 동호회 운영 · 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영/지원 (공식 채용 페이지 인재상 복리후생 여가 생활 지원 항목) — 동호회 종류·지원 금액 미기재', 60),
  (@comp_id, 'resort', '회사 제휴 콘도', NULL, 'leisure',
   'est', NULL, TRUE, '회사 제휴 콘도 운영 (공식 채용 페이지 인재상 복리후생 여가 생활 지원 항목) — 이용 시설·이용 비용 지원 미기재', 61),

  -- ── 휴가 (time_off) — 인재상 페이지 복리후생 근속/성과 보상 제도 ──
  (@comp_id, 'long_service_leave', '장기근속자 포상 · 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 포상/휴가 제공 (공식 채용 페이지 인재상 복리후생 근속/성과 보상 제도 항목) — 근속 기준·휴가 일수·포상 내용 미기재', 70),

  -- ── 보상 (compensation) — 인재상 페이지 복리후생 근속/성과 보상 제도 · 2025 사업보고서 ──
  (@comp_id, 'excellence_award', '우수사원 · 공로상 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원, 공로상 포상 (공식 채용 페이지 인재상 복리후생 근속/성과 보상 제도 항목) — 포상 기준·포상 내용 미기재', 80),
  (@comp_id, 'long_service_bonus', '장기근속 급부', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 임직원에게 장기종업원급여를 제공, 급여를 받을 수 있는 권리는 주로 10년 이상의 장기간 근무한 임직원 대상 (2025 사업보고서 재무제표 주석 종업원급여 항목) — 급부 형태·금액 미기재', 82),
  (@comp_id, 'stock_option', '우리사주조합 취득 대금 차입 담보 제공', NULL, 'compensation',
   'est', NULL, TRUE, '직원 우리사주조합 취득 대금 차입금 관련 예수금 담보 제공, 우리사주조합주식 취득 대금 차입금과 관련하여 한국증권금융에 예치보증금 예치 (2026 반기보고서 재무제표 주석 지급보증 · 사용이 제한된 금융자산 항목) — 가입 대상·회사 출연 여부 미기재', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
