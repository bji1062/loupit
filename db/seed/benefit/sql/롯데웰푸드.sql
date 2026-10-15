-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 롯데웰푸드 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.lottewellfood.com/careers/hire/welfare
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 채용 > 채용정보 > 복리후생 페이지(SSR · 법정 외 복리후생 15항목 이름 목록 · 설명 없음).
--   보조 1 = 롯데웰푸드 발행 2025 지속가능경영보고서(PDF 메타 2026-06-26 · 자기 도메인 ESG경영 페이지 국문 다운로드)
--     97 · 98 · 100 · 101 · 108 · 114쪽.
--   보조 2 = 2026 반기보고서(OpenDART 20260813000921) 직원 등 현황 유연근무제도 사용 현황 표.
--   귀속: 전부 롯데웰푸드 자기 도메인 · 자기 발행 보고서 · 자기 공시 — 그룹 각주 없음. 채용 페이지 항목 이름이
--     롯데칠성음료 채용 페이지 목록과 많이 겹치나(같은 계열 양식) 각자 자기 도메인 원문이라 그대로 싣고 설명은 이 법인 원문만 썼다.
--   금액: 금액 행 0(원문 숫자는 1회성 축하금 · 기간 상한 보육수당 · 횟수뿐 — 서술에만).
--   제외: 법정(4대 보험 · 퇴직금 제도 · 남성 육아휴직 기회 · 생애설계 및 재취업 교육 — 직원 5,464명) ·
--     본인 휴가 사용 권장(힐링데이) · 업무 교육(입문 · 멘토링 · 버디 · 직무 · 리더십 · Fit 특강 · 이지러닝 · 주재원 과정) ·
--     선발형 핵심인재 과정(사외MBA/대학원 · 롯데 MBA) · 사내벤처 · 해외연수제도(이름뿐이라 코드 미정 — 근거표 판단 요청).
--   공고 근거 0행 / 전체 26행
--   SORT 섹션: family 10 · leisure 20 · time_off 30 · compensation 40 · perks 50 · health 60 ·
--     growth 70(보조 출처) · flexibility 80(보조 출처) · work_env 90(보조 출처)
-- 검증 · 감사 판정 반영(2026-10-15): 유연근무 행의 시차출근제를 원문 시차출퇴근제로 · 정본 목록 해외연수제도를 장기근속 포상 행에 병합 · 115쪽 전사 소통 행사 company_event · 116쪽 우수 상담사 포상 excellence_award · 112쪽 공장 간호사 clinic · 98쪽 사외 MBA 대학원 mba 추가(리드 판정 132 — 참고 블록 제외 줄의 해외연수제도 · 사외MBA는 이 판정으로 뒤집힘) — 최종 30행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lotte_wellfood', '롯데웰푸드',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품', 'L', 'https://www.lottewellfood.com/careers/hire/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_wellfood');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lottewellfood.com/careers/hire/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금 지원 (공식 채용 페이지 복리후생 항목), 대학학자금 (2025 지속가능경영보고서 100쪽 직원과 가족을 위한 복지 제도 학자금 항목) — 지원 금액·자녀 수 제한 미기재', 10),
  (@comp_id, 'parenting', '출산축하금·보육수당·육아 지원', NULL, 'family',
   'est', NULL, TRUE, '출산축하금 및 보육수당 지급 (공식 채용 페이지 복리후생 항목), 둘째 이상 자녀 출산 시 100만 원 출산축하금 · 1년 48캔 분유 출산 축하 선물 · 월 10만 원 24개월 지급 미취학 자녀 보육수당 · 초중고 입학축하금 · 남성 육아휴직 의무 사용 · 1년 추가 육아휴직 · 자녀 입학돌봄 (2025 지속가능경영보고서 100쪽 직원과 가족을 위한 복지 제도 항목) — 입학축하금 금액·자녀 입학돌봄 기간 미기재', 11),
  (@comp_id, 'event', '경조 제도·상조서비스 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조 제도 · 상조서비스 지원 (공식 채용 페이지 복리후생 항목), 경조금 · 경조휴가 등 지원 (2025 지속가능경영보고서 100쪽 직원과 가족을 위한 복지 제도 경조사 항목) — 경조 유형별 금액·휴가 일수 미기재', 12),
  (@comp_id, 'childcare', '직장어린이집 운영', NULL, 'family',
   'est', NULL, TRUE, '직장어린이집 운영 (공식 채용 페이지 복리후생 항목) — 운영 사업장·정원 미기재', 13),
  -- ── 여가 (leisure) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'resort', '콘도미니엄 운영', NULL, 'leisure',
   'est', NULL, TRUE, '콘도미니엄 운영 (공식 채용 페이지 복리후생 항목) — 이용 조건·회사 부담 범위 미기재', 20),
  (@comp_id, 'summer_vacation_subsidy', '휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비 (공식 채용 페이지 복리후생 하기휴가 및 휴가비 항목) — 지급 금액·지급 시기 미기재', 21),
  (@comp_id, 'club', '사내 동호회 운영', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 운영 (공식 채용 페이지 복리후생 항목), 교양 · 체육 · 취미 등 사내동호회 활동 지원, 2025년 말 기준 총 50개 이상 단체 운영 (2025 지속가능경영보고서 100쪽 일하고 싶은 근무환경 항목) — 지원 금액 미기재', 22),
  (@comp_id, 'company_event', '전사 소통 행사·출근길 빼빼로 나눔', NULL, 'leisure',
   'est', NULL, TRUE, '주니어보드와 GWP위원회가 협력한 전사적 소통 행사, 웰푸드 게임 전사 소통 활성화 행사 진행 · 빼빼로데이 진행에 맞춰 출근하는 임직원 격려 출근길 빼빼로 나눔 행사 (2025 지속가능경영보고서 115쪽 주니어 보드 항목) — 개최 주기·참여 대상 미기재', 23),
  -- ── 휴가 (time_off) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'summer_leave', '하기휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하기휴가 (공식 채용 페이지 복리후생 하기휴가 및 휴가비 항목) — 연차 사용일인지·일수·유급 여부 미기재', 30),
  (@comp_id, 'leave_general', '정기휴가 4일', NULL, 'time_off',
   'est', NULL, TRUE, '정기휴가 4일 (2025 지속가능경영보고서 100쪽 직원을 위한 복지 제도 정기휴가 항목) — 연차 사용일인지·유급 여부 미기재', 31),
  (@comp_id, 'refresh_leave', '안식휴가', NULL, 'time_off',
   'est', NULL, TRUE, '안식휴가 (공식 채용 페이지 복리후생 항목) — 휴가 일수·부여 조건 미기재', 32),
  -- ── 보상 (compensation) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'holiday_gift', '귀향여비 지급', NULL, 'compensation',
   'est', NULL, TRUE, '귀향여비 지급 (공식 채용 페이지 복리후생 항목) — 지급 금액·지급 시기 미기재', 40),
  (@comp_id, 'long_service_bonus', '장기근속자 포상·장기근속 해외연수', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 · 해외연수제도 (공식 채용 페이지 복리후생 항목), 장기근속포상 근속 해당 시 금 또는 현금 지급 · 장기근속해외연수 근속 해당 시 선정 인원 동남아 해외연수 또는 상품권 (2025 지속가능경영보고서 100쪽 직원을 위한 복지 제도 항목) — 근속 기준·포상 금액·선정 인원 미기재', 41),
  (@comp_id, 'excellence_award', '우수 상담사 포상 (고객지원센터 상담 직원)', NULL, 'compensation',
   'est', NULL, TRUE, '상담 직원의 사기 진작을 위해 반기 단위로 우수 상담사를 선정·포상할 수 있는 체계 구축 (2025 지속가능경영보고서 116쪽 고객 응대 근로자 보호 항목) — 포상 내용·선정 인원 미기재', 42),
  -- ── 생활 (perks) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'welfare_fund', '사내근로복지기금 운영', NULL, 'perks',
   'est', NULL, TRUE, '사내근로복지기금 운영 (공식 채용 페이지 복리후생 항목) — 기금 지원 사업 내용 미기재', 50),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '단체협약에 복지포인트 등 복지제도 규정 (2025 지속가능경영보고서 114쪽 단체협약 항목) — 배정 금액·사용처·비조합원 적용 방식 미기재', 51),
  -- ── 건강 (health) — 채용 페이지 복리후생 · 2025 지속가능경영보고서 ──
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '단체보험 (공식 채용 페이지 복리후생 항목), 질병 진단금 및 후유장해 보상금 등 보험 가입 (2025 지속가능경영보고서 100쪽 직원을 위한 복지 제도 단체보험 항목) — 보장 금액·가족 포함 여부 미기재', 60),
  (@comp_id, 'health_check', '건강검진 비용 지원', NULL, 'health',
   'est', NULL, TRUE, '검진 플랫폼 통한 기준별 검진 비용 지원 (2025 지속가능경영보고서 100쪽 직원과 가족을 위한 복지 제도 건강검진 항목) — 검진 주기·지원 금액·가족 포함 여부 미기재', 61),
  (@comp_id, 'mental', '심리상담 지원 프로그램 (가족 포함)', NULL, 'health',
   'est', NULL, TRUE, '외부 전문기관과 연계한 심리상담 프로그램 운영, 2022년부터 지원 대상을 임직원 가족까지 확대, 2025년 참여 126명 · 상담 1,056회 (2025 지속가능경영보고서 101쪽 임직원 정서 관리 항목) — 1인당 상담 횟수 한도 미기재', 62),
  (@comp_id, 'fitness', '본사 임직원 건강증진 프로그램', NULL, 'health',
   'est', NULL, TRUE, '오피스 스트레칭 · 명상 및 스트레칭 · 교정 테라피 운영 1:1 맞춤 물리치료 · 본사 몸짱대회 운영 인바디 및 3D체형분석기 측정 후 맞춤운동 홍보 (2025 지속가능경영보고서 108쪽 안전보건 주요 활동 본사 임직원 건강증진 프로그램 항목) — 운영 주기·본사 외 사업장 적용 여부 미기재', 63),
  (@comp_id, 'clinic', '공장 간호사', NULL, 'health',
   'est', NULL, TRUE, '각 공장 간호사 (2025 지속가능경영보고서 112쪽 인권고충처리 소통 채널 공장 항목) — 간호사 상주 여부·건강관리 업무 범위 미기재', 64),
  -- ── 성장 (growth) — 2025 지속가능경영보고서 ──
  (@comp_id, 'lang', '임직원 어학교육', NULL, 'growth',
   'est', NULL, TRUE, '임직원 어학교육 · 사외위탁교육 어학 (2025 지속가능경영보고서 98쪽 교육체계도 글로벌 항목), 2025년 구성원들의 관심과 접근성을 높이는 방향으로 어학 교육 프로그램 개편, 글로벌 및 어학 교육 수료 208명 (같은 보고서 97쪽 우수 인재 확보 및 육성 항목) — 대상 언어·비용 지원 범위 미기재', 70),
  (@comp_id, 'career', '사내 공모 제도·인커리어', NULL, 'growth',
   'est', NULL, TRUE, '임직원이 자신의 CDP 목표와 역량에 맞는 직무를 선택할 수 있도록 사내 공모제도와 그룹 통합 경력관리 플랫폼 인커리어(INCareer) 운영 (2025 지속가능경영보고서 98쪽 인재 육성 체계 항목) — 지원 자격·공모 주기 미기재', 71),
  (@comp_id, 'mba', '사외 MBA·대학원 과정', NULL, 'growth',
   'est', NULL, TRUE, '핵심인재(Hi-Po) 대상 사외MBA/대학원 (2025 지속가능경영보고서 98쪽 교육체계도 핵심인재 항목), 최신 트렌드와 산업 지식을 반영한 사외 MBA 등 맞춤형 교육 운영 (같은 쪽 임직원 육성 및 복지 항목) — 선발 기준·학비 지원 범위 미기재', 72),
  -- ── 근무 유연성 (flexibility) — 2025 지속가능경영보고서 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제·시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무 필요에 따라 출근시간 조정 가능, 시차출퇴근제 운영 (2025 지속가능경영보고서 100쪽 직원을 위한 복지 제도 유연근무 항목), 유연근무제 활용 · 2026년 반기 시차출퇴근제 사용자 787명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 출근 시간대·적용 직군 미기재', 80),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '사내 보안망 접속 후 재택 근무 가능 (2025 지속가능경영보고서 100쪽 직원을 위한 복지 제도 재택근무 항목), 원격근무제 재택근무 포함 2026년 반기 사용자 64명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 81),
  (@comp_id, 'satellite_office', '거점오피스·공유오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '거점오피스근무제 운영, 수도권 전역에 분포한 30개 이상의 공유오피스 네트워크 운영 (2025 지속가능경영보고서 100쪽 생활 편리 및 일하고 싶은 근무환경 항목) — 이용 대상·이용 조건 미기재', 82),
  (@comp_id, 'pc_off', 'PC On/Off 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '정해진 근로시간 외 업무용 PC 자동 종료 (2025 지속가능경영보고서 100쪽 직원을 위한 복지 제도 PC on/off제도 항목) — 예외 기준 미기재', 83),
  (@comp_id, 'family_day', '금요일 1시간 조기 퇴근 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '금요일 1시간 조기 퇴근 제도 (2025 지속가능경영보고서 100쪽 생활 편리 항목) — 시행 대상 사업장·예외 기준 미기재', 84),
  -- ── 근무 환경 (work_env) — 2025 지속가능경영보고서 ──
  (@comp_id, 'free_seating', '자율좌석제', NULL, 'work_env',
   'est', NULL, TRUE, '자율좌석제와 원격근무 체계 강화를 통한 유연한 근무환경 조성 (2025 지속가능경영보고서 100쪽 일하고 싶은 근무환경 항목) — 적용 사업장 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
