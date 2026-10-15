-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 이수스페셜티케미컬 복리후생 데이터 (신규 회사 — 웨이브 6)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.isuspecialtychemical.com/kor/recruit/getRec4001Html.do
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인 www.isuspecialtychemical.com 채용정보 > 복리후생 페이지(서버렌더 HTML,
--   ul > li 라벨 18개 · 3묶음). 리드 문장 주어가 이수스페셜티케미컬 단수라 귀속이 확정되고
--   그룹 통합 채용 페이지가 아니므로 그룹 각주를 달지 않는다. apex 도메인은 A 레코드가 없어 www 고정.
--   보조 출처: 같은 도메인 인사제도 getRec2001Html.do(보상체계 · 기타 포상제도) ·
--   교육제도 getRec3001Html.do(역량개발교육체계 자기개발) · 헤더 ENG 메뉴 영문 복리후생
--   /eng/recruit/getRec4001Html.do(복지카드 주석) · OpenDART 2025 사업보고서(접수 20260319001027) ·
--   2026 반기보고서(접수 20260814002108)의 직원 등 현황 유연근무제도 사용 현황 항목.
--   별개 법인 이수화학(isuchemical.com) · 이수페타시스 · 그룹 isu.co.kr 문장은 쓰지 않았다.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 정성(금액 NULL). 금 10돈은 현물 수량이다.
--   제외: 의료보험 / 국민연금 / 건강진단(4대 보험 · 법정 검진) · 상여금 250%(임금 구성) ·
--   무재해 목표 달성 유공자 포상(안전 포상) · 기본소양 · 리더십 · 직무일반 교육(업무 교육) ·
--   사업보고서 임원 보수 산정 칸의 복지 금액(임원 전용 칸).
--   공고 근거 0행 / 전체 19행.
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서
--   (perks 10 · work_env 20 · family 30 · leisure 40 · compensation 50 · growth 60 · health 70),
--   공시에만 있는 flexibility 80 은 끝.
-- 검증 · 감사 판정 반영(2026-10-14): 휴양소 행에 2026 반기보고서 복지용 휴양소 구절 보탬 · 자기개발 과정 행을 OA 과정만 남김(리더십 묶음 걷기) — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('isu_specialty_chemical', '이수스페셜티케미컬',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '화학', 'I', 'https://www.isuspecialtychemical.com/kor/recruit/getRec4001Html.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'isu_specialty_chemical');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.isuspecialtychemical.com/kor/recruit/getRec4001Html.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 복리후생 주택지원 · 생활편의 / 경조사 지원 ──
  (@comp_id, 'housing_loan', '주택자금 대부', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 대부 (공식 채용 페이지 복리후생 주택지원 항목) — 대부 한도·이율·근속 요건 미기재', 10),
  (@comp_id, 'transport', '자가운전보조 (차장급 이상)', NULL, 'perks',
   'est', NULL, TRUE, '자가운전보조(차장급 이상) (공식 채용 페이지 복리후생 생활편의 / 경조사 지원 항목) — 지급액·지급 주기 미기재', 11),
  (@comp_id, 'commute_subsidy', '공장 통근버스', NULL, 'perks',
   'est', NULL, TRUE, '공장통근버스 운행 (공식 채용 페이지 복리후생 생활편의 / 경조사 지원 항목) — 노선·운행 공장·이용 대상 미기재', 12),
  (@comp_id, 'meal', '구내식당', NULL, 'perks',
   'est', NULL, TRUE, '구내식당 운영 (공식 채용 페이지 복리후생 생활편의 / 경조사 지원 항목) — 제공 끼니·식대·본인 부담 미기재', 13),
  (@comp_id, 'welfare_point', '복지카드', NULL, 'perks',
   'est', NULL, TRUE, '복지카드 지급 (공식 채용 페이지 복리후생 생활편의 / 경조사 지원 항목), 각 직원에게 제공되는 복지카드는 운동·지식 습득·취미 등 원하는 용도에 자유롭게 사용 (공식 영문 채용 페이지 Employee Benefits Package 주석) — 연간 지급 금액 미기재', 14),

  -- ── 근무환경 (work_env) — 복리후생 주택지원 ──
  (@comp_id, 'dormitory', '공장 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '공장 기숙사 운영 (공식 채용 페이지 복리후생 주택지원 항목) — 소재 공장·입주 자격·본인 부담 미기재', 20),

  -- ── 가족·돌봄 (family) — 복리후생 여가활용, 가족지원 · 생활편의 / 경조사 지원 ──
  (@comp_id, 'child_edu', '고등학교·대학교 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '고등학교 및 대학교 학자금 지원 (공식 채용 페이지 복리후생 여가활용, 가족지원 항목) — 지원 대상·지원 한도 미기재', 30),
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금 지급, 경조휴가 (공식 채용 페이지 복리후생 생활편의 / 경조사 지원 항목) — 경조 사유별 금액·휴가 일수 미기재', 31),

  -- ── 여가·라이프 (leisure) — 복리후생 여가활용, 가족지원 ──
  (@comp_id, 'resort', '콘도·하계 휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '콘도 및 하계 휴양소 운영 (공식 채용 페이지 복리후생 여가활용, 가족지원 항목), 복지용 휴양소를 매입하여 임직원 복지로 활용 (2026 반기보고서 신규사업 부동산 매매 및 임대업 항목) — 이용 조건·지원 범위 미기재', 40),
  (@comp_id, 'club', '취미써클 지원', NULL, 'leisure',
   'est', NULL, TRUE, '취미써클지원 (공식 채용 페이지 복리후생 여가활용, 가족지원 항목) — 지원 내용·활동비 규모 미기재', 41),

  -- ── 보상·금전 (compensation) — 복리후생 여가활용, 가족지원 · 인사제도 ──
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (공식 채용 페이지 복리후생 여가활용, 가족지원 항목), 장기근속자(10, 15, 20, 25년 주기) 포상 (공식 채용 페이지 인사제도 기타 포상제도 항목) — 포상 내용·금액 미기재', 50),
  (@comp_id, 'excellence_award', '모범사원 국내외연수·포상제도', NULL, 'compensation',
   'est', NULL, TRUE, '모범사원 국내외연수 (공식 채용 페이지 복리후생 여가활용, 가족지원 항목), 전년도 목표달성에 공이 큰 직원을 창립기념일에 포상, 회사의 경영성과 달성 유공자 · 제안우수부서 및 직원 · 공장 분임조활동 유공자 포상 (공식 채용 페이지 인사제도 기타 포상제도 항목) — 선발 기준·포상 금액·연수 지역 미기재', 51),
  (@comp_id, 'incentive', '연말 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '연말 성과급(총 연봉과 별도), 연말에 당해년도 목표의 달성도 평가에 근거하여 차등 지급 (공식 채용 페이지 인사제도 보상체계 항목) — 지급률·평가 등급별 차등 폭 미기재', 52),

  -- ── 성장·커리어 (growth) — 복리후생 여가활용, 가족지원 · 교육제도 ──
  (@comp_id, 'retirement_support', '정년기념 금 10돈·행운의 열쇠 선물', NULL, 'growth',
   'est', NULL, TRUE, '정년퇴직자 정년기념 금10돈, 「행운의 열쇠」 선물 (공식 채용 페이지 복리후생 여가활용, 가족지원 항목) — 행운의 열쇠 선물의 지급 계기·대상 미기재', 60),
  (@comp_id, 'lang', '어학 과정 (영어·일어·중국어)', NULL, 'growth',
   'est', NULL, TRUE, '역량개발교육체계 자기개발 과정의 영어(General English · Biz English · TOEIC), 일어(Biz & Life · General Japanese · JPT), 중국어(General Chinese · Biz Chinese · HSK) 과정 (공식 채용 페이지 교육제도 항목) — 운영 방식·수강 대상·비용 부담 미기재', 61),
  (@comp_id, 'edu_support', 'OA 과정 (Excel·Power Point·Word)', NULL, 'growth',
   'est', NULL, TRUE, '역량개발교육체계 자기개발 과정의 OA(Excel · Power Point · Word / 한글) 과정 (공식 채용 페이지 교육제도 항목) — 운영 방식·수강 대상·비용 부담 미기재', 62),

  -- ── 건강·의료 (health) — 복리후생 생활편의 / 경조사 지원 ──
  (@comp_id, 'insurance', '상해보험', NULL, 'health',
   'est', NULL, TRUE, '상해보험 가입 (공식 채용 페이지 복리후생 생활편의 / 경조사 지원 항목) — 보장 범위·가족 포함 여부·보험료 부담 미기재', 70),
  (@comp_id, 'health_check', '종합검진 (직원·배우자)', NULL, 'health',
   'est', NULL, TRUE, '종합검진(직원 및 배우자) (공식 채용 페이지 복리후생 생활편의 / 경조사 지원 항목) — 검진 주기·비용 지원 범위 미기재', 71),

  -- ── 근무 유연성 (flexibility) — 사업보고서 · 반기보고서 직원 등 현황 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제로 시차출퇴근제 활용, 사용자 2025년 30명 · 2026년 상반기 34명 (2025 사업보고서 · 2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 적용 대상·출퇴근 시간대 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
