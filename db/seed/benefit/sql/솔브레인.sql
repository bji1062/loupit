-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 솔브레인 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.soulbrain.co.kr/m62.php
-- badge: est
--
-- 참고:
--   정본은 솔브레인 공식 홈페이지 www.soulbrain.co.kr 헤더 메뉴 채용정보 → 복리후생(/m62.php)이다. 서버 렌더 HTML 에
--   항목 26개가 라벨로만 있다(꼬리말 Soulbrain Co., Ltd.). 같은 목록이 솔브레인홀딩스 홈페이지 /m62.php 에도 글자까지
--   같게 있다(머리 문장의 회사명만 다름) — 솔브레인 고유 근거는 아래 보고서 표로 확인했다.
--   보조 출처 1: 같은 사이트 ESG → 지속가능경영 페이지에서 받는 2025 지속가능경영보고서(솔브레인 그룹 발행) 61쪽 표
--     솔브레인 복리후생 프로그램(솔브레인홀딩스 표와 나란히 따로 실림). 홀딩스 표의 문장은 쓰지 않았다.
--   보조 출처 2: 같은 페이지의 솔브레인 2023 지속가능경영보고서(솔브레인 단독 발행) 28쪽 복리후생 프로그램 · 유연한 근무환경 조성.
--   채용 사이트 career.soulbrain.co.kr(그룹 공용 ATS) 공고 본문에는 복리후생 블록이 없다.
--   robots: www.soulbrain.co.kr · career.soulbrain.co.kr · www.soulbrainholdings.co.kr 모두 robots.txt 404(제한 없음).
--   금액: 구본 추정 승계 5(commute_subsidy 120 · health_check 100 · insurance 30 · child_edu 200 · resort 50 — 전부 틀 값,
--     NOTE 끝에 (추정)). event 50 은 경조금이라, excellence_award 50 은 선별 포상이라, holiday_gift 30 은 원문이
--     명절 상여금(구조가 다름)이라 승계하지 않았다.
--   제외 항목: 외국어 인텐시브 과정 · 맞춤형 교육프로그램 · 인문학특강(회사 주도 교육 과정) · 조직문화활성화 행사(혜택 미기재) ·
--     법정 복리후생(4대 보험 · 퇴직연금) · 근속수당 · 가족수당(호봉제 한정 급여성 수당) · 육아휴직 등 법정 제도.
--   구본에서 뺀 행: lang(외국어 인텐시브 과정 — 회사 주도 어학 과정). 재코딩 없음.
--   SORT 섹션 순서 = 홈페이지 목록에서 카테고리가 처음 나온 순서, 보고서에만 있는 카테고리는 끝
--     (perks 10 · compensation 20 · time_off 30 · leisure 40 · family 50 · growth 60 · health 70 ·
--     flexibility 80 · work_env 90).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-5): 자기 도메인 원문이라 excellence_award · mba 의 그룹 공통 각주를 뺌 · 명절 복지포인트를 holiday_gift 에 합치고 welfare_point 행을 뺌 · 2023 보고서의 사내근로복지기금 · 정신건강 상담과 홈페이지의 조직문화활성화 행사를 행으로 보탬 · parenting 에 육아기 단축 사용기간 무제한 · dormitory 에 공주·파주 기숙사 보탬 — 최종 30행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('soulbrain', '솔브레인',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체소재', 'S', 'https://www.soulbrain.co.kr/m62.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'soulbrain');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.soulbrain.co.kr/m62.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 홈페이지 주택구입 및 전세자금 대출 · 생일선물 · 사내식당 · 사내카페 · 통근버스 / 2023 보고서 사내근로복지기금 ──
  (@comp_id, 'housing_loan', '주택구입·전세자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택구입 및 전세자금 대출 (공식 홈페이지 복리후생 항목), 주거안정을 위한 주택자금 대출 지원 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램) — 대출 한도·이율 미기재', 10),
  (@comp_id, 'birthday_gift', '생일선물·생일 축하금', NULL, 'perks',
   'est', NULL, TRUE, '생일선물 지급 (공식 홈페이지 복리후생 항목), 생일 축하금 지원 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램 경조지원) — 선물·축하금 금액 미기재', 11),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 운영 (공식 홈페이지 복리후생 항목), 사내 식당 식사 지원 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램), 전 사업장 직원 식사 제공 (2023 지속가능경영보고서 복리후생 프로그램) — 제공 끼니·단가 미기재', 12),
  (@comp_id, 'snack_bar', '사내카페', NULL, 'perks',
   'est', NULL, TRUE, '사내카페 운영 (공식 홈페이지 복리후생 항목), 공주 공장 및 판교 사내 카페 운영 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램)', 13),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '통근버스 운영 (공식 홈페이지 복리후생 항목 · 2023 지속가능경영보고서 복리후생 프로그램) — 노선·운행 사업장 미기재 (추정)', FALSE, NULL, 14),
  (@comp_id, 'welfare_fund', '사내근로복지기금', NULL, 'perks',
   'est', NULL, TRUE, '사내근로복지기금 운영, 2023년 노사협의회(한마음협의회)를 통해 기금 확대 (2023 지속가능경영보고서 노사협의회 운영 항목) — 기금 지원 내용·대상·한도 미기재', 15),

  -- ── 보상·금전 (compensation) — 홈페이지 명절선물 · 창립기념일선물 · 연구개발/특허 포상 · 우수사원 포상 / 2025 보고서 명절 상여금 ──
  (@comp_id, 'holiday_gift', '명절 상여금·명절/창립기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '설, 추석 명절상여금 지급 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램), 명절선물·창립기념일선물 지급 (공식 홈페이지 복리후생 항목), 창립기념일 및 명절 복지포인트 지급 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램 기타) — 상여금 지급 기준·선물과 포인트 금액 미기재', 20),
  (@comp_id, 'excellence_award', '우수사원·연구개발·특허 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상제도 운영, 연구개발포상·특허관련 포상제도 운영 (공식 홈페이지 복리후생 항목) — 포상 기준·금액 미기재', 21),

  -- ── 시간·휴가 (time_off) — 홈페이지 하계 유급휴가 · 장기근속자 포상 / 2025 보고서 리프레쉬 휴가 · 생일휴가 ──
  (@comp_id, 'summer_leave', '하계 유급휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계 유급휴가 (공식 홈페이지 복리후생 항목), 별도로 부여하는 하계 휴가 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램 휴식지원) — 휴가 일수 미기재', 30),
  (@comp_id, 'long_service_leave', '장기근속 휴가·축하격려금', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 시 5~7일 휴가 및 축하격려금 지원 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램), 근속 3·5·7·10·15·20·25·30년 도달 시 휴가 및 축하격려금 지급 (2023 지속가능경영보고서 복리후생 프로그램), 장기근속자 포상제도 운영 (공식 홈페이지 복리후생 항목) — 근속연수별 휴가 일수·격려금 금액 미기재', 31),
  (@comp_id, 'refresh_leave', '리프레쉬 휴가 3일', NULL, 'time_off',
   'est', NULL, TRUE, '리프레쉬 휴가 3일 지원 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램) — 부여 주기·유급 여부 미기재', 32),
  (@comp_id, 'birthday_leave', '생일휴가', NULL, 'time_off',
   'est', NULL, TRUE, '생일휴가 지원 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램 경조지원 · 2023 지속가능경영보고서 생일축하 항목) — 휴가 일수 미기재', 33),

  -- ── 여가·라이프 (leisure) — 홈페이지 휴가비 · 사내동호회 운영비 · 휴양지 운영 ──
  (@comp_id, 'summer_vacation_subsidy', '하계 휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '하계 휴가비 지원 (공식 홈페이지 복리후생 항목 · 2025 지속가능경영보고서 솔브레인 복리후생 프로그램 휴식지원) — 지급액 미기재', 40),
  (@comp_id, 'club', '사내동호회 활동비', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 운영비 지원 (공식 홈페이지 복리후생 항목), 동호회 활동비 지원 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램) — 지원 금액 미기재', 41),
  (@comp_id, 'resort', '휴양지·제휴 콘도', 50, 'leisure',
   'est', '휴양지 운영 (공식 홈페이지 복리후생 항목), 제휴 콘도 및 휴양소 이용 지원 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램) — 이용 일수·비용 부담 미기재 (추정)', FALSE, NULL, 42),
  (@comp_id, 'company_event', '조직문화활성화 행사', NULL, 'leisure',
   'est', NULL, TRUE, '조직문화활성화 행사 (공식 홈페이지 복리후생 항목) — 행사 내용·개최 주기·참가 대상 미기재', 43),

  -- ── 가족·돌봄 (family) — 홈페이지 입학축하금 · 고등학교 수업료 · 대학등록금 · 경조사 · 사내 상조회 / 2023 보고서 위탁 어린이집 ──
  (@comp_id, 'parenting', '자녀 입학축하금·위탁 어린이집 비용', NULL, 'family',
   'est', NULL, TRUE, '유치원·초등학교·중학교 입학축하금 지급 (공식 홈페이지 복리후생 항목 · 2025 지속가능경영보고서 솔브레인 복리후생 프로그램 학자금), 위탁 어린이집 비용 지원·사용기간에 제한이 없는 육아기 근로시간 단축 (2023 지속가능경영보고서 유연한 근무환경 조성) — 축하금·지원 금액 미기재', 50),
  (@comp_id, 'child_edu', '자녀 학자금', 200, 'family',
   'est', '자녀 유치원, 초중등, 대학등록금 지원 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램), 고등학교 수업료·대학등록금 지원 (공식 홈페이지 복리후생 항목) — 지원 한도·자녀 수 미기재 (추정)', FALSE, NULL, 51),
  (@comp_id, 'event', '경조사 지원·사내 상조회', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 발생 시 경조금 및 휴가, 화환 등 지원 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램), 경조사 지원·사내 상조회 운영 (공식 홈페이지 복리후생 항목) — 경조 종류별 금액·휴가 일수 미기재', 52),

  -- ── 성장·교육 (growth) — 홈페이지 학위지원제도 / 2025 보고서 정년퇴직자 ──
  (@comp_id, 'mba', '학위지원제도', NULL, 'growth',
   'est', NULL, TRUE, '학위지원제도 운영 (공식 홈페이지 복리후생 항목) — 지원 학위·비용 범위 미기재', 60),
  (@comp_id, 'retirement_support', '정년퇴직자 공로휴직·포상금', NULL, 'growth',
   'est', NULL, TRUE, '정년퇴직자 근속연수별 공로휴직 및 포상금 지급 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램) — 휴직 기간·포상금 금액 미기재', 61),

  -- ── 건강·의료 (health) — 홈페이지 종합건강검진 · 단체상해보험 / 2025 보고서 의료비 · 건강관리실 · 피트니스 ──
  (@comp_id, 'health_check', '종합건강검진 (본인·가족 1인)', 100, 'health',
   'est', '임직원 및 가족(1인)에 대한 종합건강검진 지원 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램 · 공식 홈페이지 복리후생 항목) — 지원 한도 미기재 (추정)', FALSE, NULL, 70),
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '단체상해보험 가입 (공식 홈페이지 복리후생 항목 · 2025 지속가능경영보고서 솔브레인 복리후생 프로그램) — 보장 내용 미기재 (추정)', FALSE, NULL, 71),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '질병, 상해에 대해 의료비 지원 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램) — 지원 대상·한도 미기재', 72),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '전담 간호사 배치(공주, 파주) 및 임직원 건강 관리 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램 건강관리실)', 73),
  (@comp_id, 'fitness', '헬스장·운동장', NULL, 'health',
   'est', NULL, TRUE, '실내 헬스장, 실외 운동장 운영 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램 피트니스), 판교 요가교실 (2023 지속가능경영보고서 복리후생 프로그램) — 운영 사업장·이용 시간 미기재', 74),
  (@comp_id, 'mental', '정신건강 상담', NULL, 'health',
   'est', NULL, TRUE, '공주시 정신건강 복지센터와 협약을 맺고 도움이 필요한 임직원 대상 정기 상담 및 예방교육 실시 (2023 지속가능경영보고서 구성원 건강 증진 프로그램 항목) — 상담 횟수·대상 사업장 미기재', 75),

  -- ── 근무 유연성 (flexibility) — 2023 보고서 탄력적 근로시간제 ──
  (@comp_id, 'flex_work', '탄력적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '임직원의 상황을 고려해 근무할 수 있도록 탄력적 근로시간제 도입 (2023 지속가능경영보고서 유연한 근무환경 조성) — 단위 기간·적용 대상 미기재', 80),

  -- ── 근무환경 (work_env) — 2025 보고서 기숙사 / 2023 보고서 근무복 ──
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '타 지역 거주자 대상 기숙사 운영 (2025 지속가능경영보고서 솔브레인 복리후생 프로그램 · 2023 지속가능경영보고서 복리후생 프로그램), 공주·파주 사업장 기숙사 지원 (공식 홈페이지 채용소식 자주하는 질문) — 비용 부담·입주 조건 미기재', 90),
  (@comp_id, 'uniform', '근무복 지급', NULL, 'work_env',
   'est', NULL, TRUE, '근무복 지급 (2023 지속가능경영보고서 복리후생 프로그램 기타) — 지급 주기·대상 직군 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
