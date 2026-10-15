-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 후성 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.foosungchem.com/esg/esg02.asp
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)후성 자기 도메인 www.foosungchem.com 의 ESG 정보공개 > 사회적 가치 (S) 목록 페이지(SSR)다.
--   이 목록에 올라 있는 법인 단독 발행 2026 ESG 경영보고서(PDF 103쪽 · 파일 생성 2026-06-30 · 목록 등록일 2026-06-30 ·
--   보고 기간 2025년 · 주어 (주)후성)가 복지 원문이다 — 40쪽 401-2 표(임직원 복지제도 업무환경 · 개인성장 · 복리후생),
--   45쪽 403-3 건강관리실, 47~48쪽 403-6 근로자 건강 증진 활동 표. PDF 주소는
--   /common/download.asp?filename=(주)후성_2026_ESG_경영보고서_0.pdf (파일 이름에 연도가 있어 정본으로 쓰지 않았다).
--   옛 판 2025 지속가능경영보고서(같은 목록 · 2025-12-30) 57쪽 · 64쪽은 최신 판 낱말의 뜻을 받치는 데만 썼다
--   (가족의료비 연 400만원까지 · 마음버스 상담 · 모션데스크 · 체력단련비 표기).
--   보조 출처는 후성그룹 사이트 www.foosung.com 인재채용 > 복리후생(careers03.asp, SSR) — 그룹 통합 채용 페이지라
--   법인 구분이 없다. 보고서에 없는 항목 6개만 이 페이지로 세우고 서술 끝에 (그룹 통합 채용 기준) 각주를 단다.
--   코퍼스와 대기 폴더에 후성그룹 형제 법인이 없다.
--   공시 보조: OpenDART 2025 사업보고서(접수 20260318001491) 재무제표 주석 기타장기종업원급여 ·
--   2026 반기보고서(접수 20260814003359) 직원 등 현황(직원 382명 · 유연근무제도 사용 현황 전부 -).
--   금액: 원 단위 숫자는 가족의료비 연 400만원(한도) 하나라 전 행 BENEFIT_AMT NULL.
--   제외: 법정(주 5일 근무 · 4대 보험 · 육아휴직 · 배우자 출산휴가 · 육아기 단축근무 · 일반 · 특수검진 · 퇴직연금 DB/DC) ·
--     자유로운 휴가사용(본인 휴가 사용 · 더 주는 날 없음 — 판단 요청) · 업무 교육(직무 · 리더십 · 법정 의무 교육) ·
--     안전 포상(아차사고 · 잠재위험 발굴) · 직무스트레스 자체 조사 · 건강증진체험관 부스(맞는 코드 없음 — 판단 요청) ·
--     연봉제(임금 제도) · 지역사회 장학금(직원 대상 아님).
--   공고 근거 0행 / 전체 26행.
--   SORT 섹션 순서 = 보고서 40쪽 표 등장 순(열 단위) work_env 10 · growth 20 · time_off 30 · family 40 · health 50 ·
--     leisure 60 · perks 70 · compensation 80. 섹션 안은 보고서 행 다음 그룹 페이지 행.
-- 검증 · 감사 판정 반영(2026-10-15): 장기근속자 선물 행에서 정년퇴직자 몫을 retirement_support 로 분리 추가 — 최종 27행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('foosung', '후성',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '화학', 'F', 'https://www.foosungchem.com/esg/esg02.asp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'foosung');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.foosungchem.com/esg/esg02.asp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 업무환경 (work_env) — 보고서 40쪽 업무환경 · 그룹 채용 페이지 ──
  (@comp_id, 'office_furniture', '모션데스크 제공', NULL, 'work_env',
   'est', NULL, TRUE, '모션데스크 제공 (2026 ESG 경영보고서 40쪽 임직원 복지제도 업무환경 항목) — 제공 대상·사업장 미기재', 10),
  (@comp_id, 'uniform', '운동복 및 근무복 지급', NULL, 'work_env',
   'est', NULL, TRUE, '운동복 및 근무복 지급 (후성그룹 채용 페이지 복리후생 항목) — 지급 주기·지급 대상 미기재 (그룹 통합 채용 기준)', 11),
  -- ── 성장 · 교육 (growth) — 보고서 40쪽 개인성장 · 그룹 채용 페이지 ──
  (@comp_id, 'lang', '외국어 학원비 및 시험 응시료 지원', NULL, 'growth',
   'est', NULL, TRUE, '외국어 학원비 및 시험 응시료 지원 (2026 ESG 경영보고서 40쪽 임직원 복지제도 개인성장 항목) — 지원 한도·지원 비율 미기재', 20),
  (@comp_id, 'edu_support', '사내외 교육지원', NULL, 'growth',
   'est', NULL, TRUE, '사내외 교육지원 (2026 ESG 경영보고서 40쪽 임직원 복지제도 개인성장 항목) — 지원 대상 교육 범위·지원 한도 미기재', 21),
  (@comp_id, 'books', '업무용 도서 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무용 도서 지원 (2026 ESG 경영보고서 40쪽 임직원 복지제도 개인성장 항목) — 지원 한도·지원 방식 미기재', 22),
  (@comp_id, 'self_development', '자기개발비 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기개발비 지원 (후성그룹 채용 페이지 복리후생 항목) — 지원 금액·사용 범위 미기재 (그룹 통합 채용 기준)', 23),
  (@comp_id, 'retirement_support', '정년퇴직자 선물', NULL, 'growth',
   'est', NULL, TRUE, '장기근속자 선물 대상 중 정년퇴직자 (2026 ESG 경영보고서 40쪽 복리후생 항목) — 선물 품목·금액 미기재', 24),
  -- ── 휴가 (time_off) — 보고서 40쪽 개인성장 ──
  (@comp_id, 'long_service_leave', '장기근속 휴가 및 휴가비 지원', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 휴가(13년, 20년, 30년) 및 휴가비 지원 (2026 ESG 경영보고서 40쪽 임직원 복지제도 개인성장 항목) — 휴가 일수·휴가비 금액 미기재', 30),
  -- ── 가족 (family) — 보고서 40쪽 복리후생 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (2026 ESG 경영보고서 40쪽 복리후생 항목) — 지원 학령·지원 한도 미기재', 40),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원(결혼·상례 등) (2026 ESG 경영보고서 40쪽 복리후생 항목) — 지원 내용·금액 미기재', 41),
  -- ── 건강 (health) — 보고서 40쪽 복리후생 · 45쪽 산업보건 서비스 · 47~48쪽 건강 증진 활동 ──
  (@comp_id, 'health_check', '종합건강검진 지원 (배우자 포함)', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진 지원(배우자포함) (2026 ESG 경영보고서 40쪽 복리후생 항목), 임직원&배우자 종합검진비 지원(1회/2년) (같은 보고서 48쪽 근로자 건강 증진 활동 항목) — 검진 비용 한도 미기재', 50),
  (@comp_id, 'fitness', '체력단련비 지원·바르게 걷기 프로그램', NULL, 'health',
   'est', NULL, TRUE, '체력단련비 지원 (2026 ESG 경영보고서 40쪽 복리후생 항목), 심뇌혈관질환 예방 관련 전문 강사를 초빙하여 올바르게 걷기 강의 및 체험을 하는 바르게 걷기 프로그램 (같은 보고서 48쪽 근로자 건강 증진 활동 항목) — 체력단련비 금액·지급 주기 미기재', 51),
  (@comp_id, 'insurance', '단체상해보험 가입 (실비 포함)', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 가입(실비포함) (2026 ESG 경영보고서 40쪽 복리후생 항목) — 보장 범위·가족 포함 여부 미기재', 52),
  (@comp_id, 'medical', '가족의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 가족의료비 지원(400만원/년) (2026 ESG 경영보고서 48쪽 근로자 건강 증진 활동 항목), 임직원의 가족 의료비 지원을 연간 400만원까지 신청 건에 한하여 지급 (2025 지속가능경영보고서 57쪽 종합 건강검진 지원 항목) — 지원 대상 가족 범위·지원 비율 미기재', 53),
  (@comp_id, 'smoking_cessation', '찾아가는 금연클리닉', NULL, 'health',
   'est', NULL, TRUE, '금연 프로그램 「찾아가는 금연클리닉」(남부보건소 연계) (2026 ESG 경영보고서 48쪽 근로자 건강 증진 활동 항목) — 운영 주기·참여 혜택 미기재', 54),
  (@comp_id, 'mental', '찾아가는 마음버스 (마음챙김 프로그램)', NULL, 'health',
   'est', NULL, TRUE, '마음챙김 프로그램 「찾아가는 마음버스」(울산정신건강복지센터 연계) (2026 ESG 경영보고서 48쪽 근로자 건강 증진 활동 항목), 프로그램에 신청한 임직원의 전문 상담사 면담 (2025 지속가능경영보고서 57쪽 찾아가는 금연 클리닉 항목) — 상담 횟수·운영 주기 미기재', 55),
  (@comp_id, 'clinic', '건강관리실 운영', NULL, 'health',
   'est', NULL, TRUE, '울산 제1캠퍼스 내 건강관리실 운영, 당사 소속 간호사가 항시 상주하여 임직원 및 협력사 직원에게 전문적인 건강 상담 및 응급 처치 제공 (2026 ESG 경영보고서 45쪽 산업보건 서비스 제공 항목) — 운영 시간·다른 사업장 설치 여부 미기재', 56),
  -- ── 여가 (leisure) — 보고서 40쪽 복리후생 · 그룹 채용 페이지 ──
  (@comp_id, 'resort', '리조트 지원', NULL, 'leisure',
   'est', NULL, TRUE, '리조트 지원 (2026 ESG 경영보고서 40쪽 복리후생 항목) — 이용 방식·지원 범위 미기재', 60),
  (@comp_id, 'summer_vacation_subsidy', '하계휴가비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '하계휴가비 지원 (2026 ESG 경영보고서 40쪽 복리후생 항목) — 지원 금액·지급 시기 미기재', 61),
  (@comp_id, 'club', '사내동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 지원 (후성그룹 채용 페이지 복리후생 항목) — 지원 금액·동호회 종류 미기재 (그룹 통합 채용 기준)', 62),
  -- ── 생활 · 금융 (perks) — 보고서 40쪽 복리후생 · 그룹 채용 페이지 ──
  (@comp_id, 'welfare_point', '복지포인트 지원', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 지원 (2026 ESG 경영보고서 40쪽 복리후생 항목) — 포인트 금액·사용처 미기재', 70),
  (@comp_id, 'birthday_gift', '생일축하금 지원', NULL, 'perks',
   'est', NULL, TRUE, '생일축하금 지원 (2026 ESG 경영보고서 40쪽 복리후생 항목) — 지급 금액 미기재', 71),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 지원 (2026 ESG 경영보고서 40쪽 복리후생 항목) — 회사 부담 비율·금액 미기재', 72),
  (@comp_id, 'meal', '사원 식당 운영', NULL, 'perks',
   'est', NULL, TRUE, '사원 식당 운영 (후성그룹 채용 페이지 복리후생 항목) — 제공 끼니·식대 지원 범위 미기재 (그룹 통합 채용 기준)', 73),
  -- ── 보상 (compensation) — 보고서 40쪽 복리후생 · 2025 사업보고서 · 그룹 채용 페이지 ──
  (@comp_id, 'long_service_bonus', '장기근속자 선물', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 선물(10년, 30년) (2026 ESG 경영보고서 40쪽 복리후생 항목), 장기 근속 임직원에게 장기종업원급여 제공 (2025 사업보고서 재무제표 주석 종업원급여 항목) — 선물 품목·금액 미기재', 80),
  (@comp_id, 'excellence_award', '우수사원 표창 및 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 표창 및 포상 (후성그룹 채용 페이지 복리후생 항목) — 포상 기준·포상 내용 미기재 (그룹 통합 채용 기준)', 81),
  (@comp_id, 'incentive', '성과급제', NULL, 'compensation',
   'est', NULL, TRUE, '개인별 종합능력과 부서(팀) 중심의 단체 업무 성과를 지속적으로 평가하여 합당한 대우를 하는 성과급제 (후성그룹 채용 페이지 복리후생 성과급제 항목) — 지급 기준·지급률 미기재 (그룹 통합 채용 기준)', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
