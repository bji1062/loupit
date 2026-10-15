-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 두산퓨얼셀 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.doosanfuelcell.com/kr/sustainability/sust-0103/
-- badge: est
--
-- 참고:
--   정본 = 자기 도메인 지속가능경영 보고서 목록(SSR). 근거 = 그 목록의 2026 두산퓨얼셀 지속가능경영보고서 국문 PDF
--   (PDF 생성 2026-08, 보고 기간 2025-01-01~2025-12-31, 비재무 데이터 별도 기준 = 법인 단독) 52 · 73 · 79 · 80 · 81 · 89쪽.
--   보조 = 2025 지속가능경영보고서 59쪽(군산공장 휴게실 실재만 받침) · 2026 반기보고서 유연근무제도 사용 현황 표(flex_work · remote_work 받침).
--   자기 도메인 채용 메뉴는 HTML 주석으로 막혀 있고 링크는 그룹 채용 사이트뿐 — 그룹 채용 문장은 쓰지 않았다.
--   귀속: 법인 자기 발행 단독 보고서 · 주어가 두산퓨얼셀인 문장 — 각주 없음. 형제(두산 · 두산에너빌리티 · 두산테스나) 문장 복사 없음.
--   금액: 전 행 NULL(일회성 축하금 · 상품권 · 한도 · 조건부 급부뿐). stated 0 · 추정 0.
--   제외: 법정(출산휴가 90일 · 임신기 · 육아기 근로시간 단축 · 태아검진휴가 · 가족돌봄휴직 90일 · 보상휴가 · 연차 촉진 · 동일 직무 복귀) ·
--   권장 휴가(12월 마지막 주 휴가 사용 권장) · 업무 교육(입문 · 멘토링 · OJT · 직무 공통 과정 · AI BASIC 360 · 리더십 진단) ·
--   임원 · 재량 주식보상(RSU · PSP) · 안전 EHS 포상 · 에너지 절감 내부 포상 · 장애인 체육선수 훈련복 · 출전 수당 · 여비(직무 경비) ·
--   혹서기 쿨론 티셔츠(작업자 혹서기 대책) · 우리사주조합(주주 표 한 칸뿐).
--   공고 근거 0행 / 전체 23행. SORT 섹션 순서 = 보고서 쪽 순서(health · flexibility · compensation · growth · work_env · perks · family · leisure · time_off).
-- 검증 · 감사 판정 반영(2026-10-15): 80쪽 노사협의회 혹서기 쿨론소재 티셔츠 uniform 추가(참고 블록 제외 줄의 쿨론 티셔츠는 이 판정으로 뒤집힘) · 정본 목록 페이지 유지 — 최종 24행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('doosan_fuelcell', '두산퓨얼셀',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '에너지/발전', 'D', 'https://www.doosanfuelcell.com/kr/sustainability/sust-0103/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'doosan_fuelcell');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.doosanfuelcell.com/kr/sustainability/sust-0103/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 2026 지속가능경영보고서 52 · 73 · 81쪽 ──
  (@comp_id, 'clinic', '사내 간호사 상주 (서울사무소)', NULL, 'health',
   'est', NULL, TRUE, '서울사무소 간호사 상주, 혈압·공복혈당·인바디 측정 및 직무스트레스 검사, 금연프로그램 등 건강증진 프로그램 제공 (2026 지속가능경영보고서 52쪽 사업장 안전보건관리 항목) — 운영 시간·이용 대상 미기재', 10),
  (@comp_id, 'health_check', '종합건강검진 (본인·배우자)', NULL, 'health',
   'est', NULL, TRUE, '임직원과 배우자 대상 종합건강검진 실시, 정규직·계약직 직원 대상 (2026 지속가능경영보고서 81쪽 건강검진 및 의료비 지원 항목), 법적 의무 이상의 선택적 건강검진 운영 (같은 보고서 73쪽 인권경영 프로그램 항목) — 검진 주기·비용 지원 범위 미기재', 11),
  (@comp_id, 'medical', '의료비 지원 (본인·가족)', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 가족의 의료비 지원, 정규직·계약직 직원 대상 (2026 지속가능경영보고서 81쪽 건강검진 및 의료비 지원 항목) — 지원 범위·한도 미기재', 12),
  (@comp_id, 'insurance', '단체 보험', NULL, 'health',
   'est', NULL, TRUE, '사고나 질병 발생 시 치료에 전념할 수 있도록 단체 보험을 통한 보장, 정규직·계약직 직원 대상 (2026 지속가능경영보고서 81쪽 건강검진 및 의료비 지원 항목) — 보험 종류·보장 범위 미기재', 13),

  -- ── 근무 유연성 (flexibility) — 2026 지속가능경영보고서 73 · 81쪽 ──
  (@comp_id, 'pc_off', 'PC-Off 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '초과 근로시간을 관리하기 위한 PC-Off제도 운영 (2026 지속가능경영보고서 73쪽 인권경영 프로그램 항목) — 적용 시간·대상 미기재', 20),
  (@comp_id, 'flex_work', '선택적 근로시간제·시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '2025년 1월부터 선택적 근로시간제 도입, 총 근로시간 범위 내에서 직원이 자율적으로 업무 시간 설계 (2026 지속가능경영보고서 81쪽 임직원 복지제도 선택적 근로시간제 항목), 선택적근로시간제·시차출퇴근제 운영 (같은 보고서 81쪽 유연근무제 항목) — 의무 근무시간대·정산 기간 미기재', 21),
  (@comp_id, 'remote_work', 'Remote Work·재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, 'Remote Work 및 재택근무 운영 (2026 지속가능경영보고서 81쪽 유연근무제 항목), 원격근무제(재택근무 포함) (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 22),

  -- ── 보상 (compensation) — 2026 지속가능경영보고서 79 · 89쪽 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '개인 평가결과를 반영한 성과급 지급 (2026 지속가능경영보고서 79쪽 평가 및 보상 · 평가 프로세스 항목) — 지급 기준·지급률 미기재', 30),
  (@comp_id, 'excellence_award', '우수봉사자 포상 제도', NULL, 'compensation',
   'est', NULL, TRUE, '임직원 배식 봉사와 함께 우수봉사자 포상 제도로 사내 봉사 문화 장려 (2026 지속가능경영보고서 89쪽 다이로움 밥차 후원 및 정기 봉사활동 항목) — 포상 기준·포상 내용 미기재', 31),

  -- ── 성장 (growth) — 2026 지속가능경영보고서 79쪽 ──
  (@comp_id, 'career', '경력개발제도', NULL, 'growth',
   'est', NULL, TRUE, '직원이 경력 목표와 역량 개발 계획을 수립하고 희망하는 직무로 이동하도록 지원하는 경력개발제도, 2026년 5월 첫 시행 (2026 지속가능경영보고서 79쪽 경력개발제도 신설 항목) — 신청 자격·이동 절차 미기재', 40),
  (@comp_id, 'retirement_support', '은퇴 후 생애 설계 과정 (만 55세 이상)', NULL, 'growth',
   'est', NULL, TRUE, '만 55세 이상 직원 대상 은퇴 이후의 삶을 준비할 수 있도록 생애 설계 과정 제도화 (2026 지속가능경영보고서 79쪽 은퇴 후 생애 설계 지원 항목) — 과정 내용·운영 주기 미기재', 41),

  -- ── 근무 환경 (work_env) — 2026 지속가능경영보고서 80 · 81쪽 ──
  (@comp_id, 'lounge', '휴게실 (군산공장)', NULL, 'work_env',
   'est', NULL, TRUE, '군산공장 휴게실 환경 개선 (2026 지속가능경영보고서 80쪽 노사협의회 2025년 2분기 주요안건 항목), 군산공장 비즈니스 라운지와 휴게실 조성 (2025 지속가능경영보고서 59쪽 쾌적한 근무환경 조성 항목) — 휴게실 규모·설비 미기재', 50),
  (@comp_id, 'parking', '임신부 주차권 부여', NULL, 'work_env',
   'est', NULL, TRUE, '임신 중인 직원에게 출산휴가 또는 육아휴직 시작 전까지 주차권 지원 (2026 지속가능경영보고서 81쪽 자녀 양육 지원 프로그램 임신부 주차권 부여 항목) — 주차 장소·사업장 범위 미기재', 51),
  (@comp_id, 'nap_room', '수유실', NULL, 'work_env',
   'est', NULL, TRUE, '본사 내 수유실, 임산부의 휴식 및 수유 공간으로 운영 (2026 지속가능경영보고서 81쪽 수유실 항목) — 시설 규모·설비 미기재', 52),
  (@comp_id, 'uniform', '혹서기 쿨론소재 티셔츠 (항온 공정 이외 작업자)', NULL, 'work_env',
   'est', NULL, TRUE, '항온 공정 이외 작업자 대상 혹서기 쿨론소재 티셔츠 지급 (2026 지속가능경영보고서 80쪽 노사협의회 2025년 1분기 주요안건 항목) — 지급 주기·지급 수량 미기재', 53),

  -- ── 생활 지원 (perks) — 2026 지속가능경영보고서 80 · 81 · 89쪽 ──
  (@comp_id, 'transport', '출퇴근 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 교통비 지원 연한 2년에서 5년으로 확대 (2026 지속가능경영보고서 80쪽 노사협의회 2025년 3분기 주요안건 항목) — 지원 대상·금액 미기재', 60),
  (@comp_id, 'snack_bar', '사무실 커피머신·간식', NULL, 'perks',
   'est', NULL, TRUE, '사무실 내 직원 복지를 위해 사용되는 커피머신 (2026 지속가능경영보고서 89쪽 커피박 재활용 항목), 노사협의회 안건으로 간식 납품 내역 조정 (같은 보고서 80쪽 노사협의회 2025년 4분기 주요안건 항목) — 제공 사업장·품목 미기재', 61),
  (@comp_id, 'housing_loan', '주택자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택 마련 자금 지원 제도 운영, 주택 매매 또는 임차 시 일부 자금 지원, 정규직·계약직 직원 대상 (2026 지속가능경영보고서 81쪽 주택자금 지원 항목) — 지원 방식·한도 미기재', 62),

  -- ── 가족 (family) — 2026 지속가능경영보고서 81쪽 ──
  (@comp_id, 'parenting', '임신·출산·육아 지원', NULL, 'family',
   'est', NULL, TRUE, '약정 육아휴직 제도로 육아휴직 최대 1년 별도 부여(법정 1년에 1년 추가), 6개월 이상 육아휴직 후 복직 시 육아휴직 리보딩 프로그램(팀장 Caring 면담 3회·심리상담서비스·긴급 돌봄 육아지원서비스), 육아휴직 서포터즈 지원(6개월 이상 육아휴직 신청 직원의 팀장 및 팀원에게 인당 최대 50만원), 임신축하선물 50만원 상당 상품권, 출산경조금 첫째 300만원·둘째 500만원·셋째 이상 1,000만원, 미래나무어린이집 이용이 여의치 않은 만 1~2세 자녀 보육 지원금(정규직·계약직 직원 대상), 중·고등학교 및 대학교 진학 자녀 입학 축하금 (2026 지속가능경영보고서 81쪽 일과 가정의 양립 자녀 양육 지원 프로그램·어린이집·자녀학자금 항목) — 보육 지원금·입학 축하금 금액 미기재', 70),
  (@comp_id, 'childcare', '어린이집 (미래나무 어린이집)', NULL, 'family',
   'est', NULL, TRUE, '만 1세부터 만 5세 임직원 자녀 대상 어린이집(미래나무 어린이집) 제공 및 지원, 정규직·계약직 직원 대상 (2026 지속가능경영보고서 81쪽 어린이집 항목) — 어린이집 위치·정원 미기재', 71),
  (@comp_id, 'child_edu', '자녀학자금', NULL, 'family',
   'est', NULL, TRUE, '중·고등학교 및 대학교 진학 자녀 학자금, 고등학교 입학 자녀 교육 구입비 지원 (2026 지속가능경영보고서 81쪽 자녀학자금 항목) — 지원 한도·지급 기준 미기재', 72),

  -- ── 여가 · 행사 (leisure) — 2026 지속가능경영보고서 81쪽 ──
  (@comp_id, 'company_event', '어린이날 행사', NULL, 'leisure',
   'est', NULL, TRUE, '어린이날을 맞아 DLI 연강원과 야구장에서 임직원과 자녀가 함께 즐기는 행사 마련 (2026 지속가능경영보고서 81쪽 어린이날 행사 항목) — 참가 대상·비용 지원 범위 미기재', 80),

  -- ── 휴가 (time_off) — 2026 지속가능경영보고서 81쪽 ──
  (@comp_id, 'summer_leave', '하계휴가 (유급 5일)', NULL, 'time_off',
   'est', NULL, TRUE, '여름철 5일의 유급 하계휴가 제공 (2026 지속가능경영보고서 81쪽 임직원 복지제도 휴가제도 항목) — 연차 사용일인지 미기재', 90),
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위로 사용할 수 있는 휴가 제도 도입 (2026 지속가능경영보고서 81쪽 임직원 복지제도 휴가제도 항목) — 사용 한도·신청 방식 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
