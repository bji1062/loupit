-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 세방전지 복리후생 데이터 (신규 회사 — 웨이브 6)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.gbattery.com/company/recruit
-- badge: est
--
-- 참고:
--   정본은 상장 법인 세방전지(주)의 자기 도메인 www.gbattery.com 기업정보 > 채용정보 페이지다.
--   SSR 이라 원본 HTML 에 복리후생 6블록(div.recruit06)과 인사제도 > 보상제도(div.recruit05) 텍스트가 다 있다.
--   헤드리스 렌더 · 이미지 판독 불필요.
--   보조 출처는 같은 도메인 지속가능경영 목록에 올라 있는 법인 단독 발행 2025 세방전지 지속가능경영보고서
--   (발행 2026-06-23 · 보고 기간 2025-01-01~2025-12-31 · 보고 범위 세방전지(주) 별도 · 국내 전 사업장)
--   36쪽 표 두 개(임직원 복리후생 및 근무환경 · 임직원 복지 및 지원제도) + 34쪽 인재육성 + 35쪽 보상 + 42쪽 의료 지원.
--   공시 보조: OpenDART 2025 사업보고서(접수 20260319001105) 자기주식 처분 항목(임직원 성과급 일부 자사주 지급)과
--   직원 등의 현황 유연근무제도 사용 현황(시차출퇴근 · 원격근무 사용자 수). 직원 1,284명.
--   목록 Referer 없이 받으면 200 으로 136바이트 경고문이 온다 — 사본은 PDF 1.7 87쪽 실물을 확인했다.
--   귀속: 페이지 문구가 세방전지의 다양한 복리후생을 소개합니다 로 법인 단수 주어이고
--   계열사 · 그룹 공통 단서가 없다. 보고서는 자기 발행이라 각주 없음. 그룹 각주 불필요.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL. 리프레시 휴가 5일만 숫자다.
--   제외: 법정(출산 전후 휴가 · 임신 중 휴직 · 남녀 동일 유급 육아휴직 · 임신기 육아기 근로시간 단축 ·
--     가족돌봄휴직 · 특수건강검진 · 재취업지원교육 커리어 플러스 — 2025 총 임직원 1,291명) ·
--     업무 교육(버디 온보딩 · 승진자 · 리더십 · 생산 노하우 컨텐츠 · 법정의무교육) · 정기상여금(보상 문장) ·
--     안전 포상(SCC 제도) · 임원 보수 표(55쪽 · 사업보고서 임원 보수) · 사내 대출제도 언급(44쪽 인권실사) ·
--     장기 근속 임직원 기타장기종업원급여(사업보고서 주석 — 휴가인지 포상인지 미상, 근거표 판단 요청).
--   공고 근거 0행 / 전체 22행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(compensation 10 · perks 20 · time_off 30 · leisure 40 ·
--     flexibility 50 · health 60 · growth 70 · family 80), 보고서에만 있는 work_env 90.
-- 검증 · 감사 판정 반영(2026-10-14): 포상제도 행에 착한동료상 보탬 · 사내 대출제도 welfare_fund_loan · 체육대회와 원팀데이 company_event · 기타장기종업원급여 long_service_bonus 추가(참고 블록 제외 목록의 해당 줄은 이 판정으로 뒤집힘) — 최종 25행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sebang_battery', '세방전지',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '배터리', 'S', 'https://www.gbattery.com/company/recruit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sebang_battery');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.gbattery.com/company/recruit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 채용정보 인사제도 보상제도 · 보고서 35 · 36쪽 · 2025 사업보고서 ──
  (@comp_id, 'profit_sharing', '경영성과급', NULL, 'compensation',
   'est', NULL, TRUE, '회사의 성과를 다 함께 공유할 수 있는 경영성과급제도 운영 (공식 채용정보 페이지 인사제도 보상제도 항목), 경영성과급 등 성과 기반 보상 제도 운영 (2025 지속가능경영보고서 35쪽 공정한 성과관리 및 보상 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'excellence_award', '포상제도', NULL, 'compensation',
   'est', NULL, TRUE, '우수한 성과를 인정하는 다양한 포상제도 운영 (공식 채용정보 페이지 인사제도 보상제도 항목), 모범적인 협업 사례와 긍정적 행동을 발굴·포상하는 착한동료상 상·하반기 연 2회 운영 (2025 지속가능경영보고서 46쪽 조직문화 확산 캠페인 항목) — 포상 금액·포상 내용 미기재', 11),
  (@comp_id, 'holiday_gift', '명절·기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '설·추석·창립기념일·근로자의 날 선물 지급 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 기념일 지원 항목) — 선물 품목·금액 미기재', 12),
  (@comp_id, 'stock_grant', '자사주 지급 (성과급 일부)', NULL, 'compensation',
   'est', NULL, TRUE, '임직원 성과급 중 일부를 자기주식으로 지급 (2025 사업보고서 자기주식 취득 및 처분 현황 항목) — 지급 대상·지급 비율·1인당 주식 수 미기재', 13),
  (@comp_id, 'long_service_bonus', '장기근속 급부', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 임직원에게 기타장기종업원급여 제공 (2025 사업보고서 재무제표 주석 종업원급여 항목) — 근속 기준·급부 형태·금액 미기재', 14),
  -- ── 경제적 부가혜택 (perks) — 채용정보 복리후생 · 보고서 36쪽 ──
  (@comp_id, 'welfare_point', '복지포인트 (복지몰·복지카드)', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 (복지몰 및 복지카드) (공식 채용정보 페이지 복리후생 항목), 여가생활 지원, 복지몰 운영 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 선택적 복리후생 항목) — 포인트 배정액·사용처 미기재', 20),
  (@comp_id, 'housing_loan', '전세자금·주택구입자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '전세자금 및 주택구입자금 지원 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 주거 지원 항목) — 지원 방식·한도·이율·대상 미기재', 21),
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일 선물 지급 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 기념일 지원 항목) — 선물 품목·금액 미기재', 22),
  (@comp_id, 'welfare_fund_loan', '사내 대출제도', NULL, 'perks',
   'est', NULL, TRUE, '사내 대출제도, 신청 및 상환 과정의 자발성·투명성 강화 (2025 지속가능경영보고서 44쪽 인권실사 인권 리스크 식별 및 개선 활동 항목) — 대출 용도·한도·이율 미기재', 23),
  -- ── 휴가 (time_off) — 채용정보 복리후생 · 보고서 36쪽 ──
  (@comp_id, 'refresh_leave', '리프레시 휴가 (5일)', NULL, 'time_off',
   'est', NULL, TRUE, 'Refresh 휴가 (공식 채용정보 페이지 복리후생 Refresh 휴가 및 휴가비 항목), 리프레시 휴가(5일) 제공 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 휴가 제도 항목) — 부여 주기·부여 조건·유급 여부 미기재', 30),
  -- ── 여가 (leisure) — 채용정보 복리후생 ──
  (@comp_id, 'summer_vacation_subsidy', '휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비 (공식 채용정보 페이지 복리후생 Refresh 휴가 및 휴가비 항목) — 지급 금액·지급 시기·지급 조건 미기재', 40),
  (@comp_id, 'company_event', '체육대회·원팀데이·에너지충전소', NULL, 'leisure',
   'est', NULL, TRUE, '노사 간 화합과 상호 이해 증진을 위해 매년 체육대회 등 화합 프로그램 개최 (2025 지속가능경영보고서 45쪽 노사 화합 프로그램 항목), 협업 미션 · 소통 프로그램 · 취미·문화 공유 프로그램으로 구성된 분기별 전사 원팀데이 · 임직원 사기 진작을 위한 에너지충전소 오프라인 이벤트 (2025 지속가능경영보고서 46쪽 전사 참여 프로그램 항목) — 참가 대상·비용 지원 범위 미기재', 41),
  -- ── 근무 유연성 (flexibility) — 채용정보 복리후생 · 보고서 36쪽 ──
  (@comp_id, 'flex_work', '유연근무제 (시차출근제)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제도 (공식 채용정보 페이지 복리후생 항목), 시차출근제 운영 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 근무 유연성 항목), 시차출퇴근제 사용자 수 62명 (2025 사업보고서 유연근무제도 사용 현황 항목) — 출퇴근 시간대·적용 대상 미기재', 50),
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF 시스템 (공식 채용정보 페이지 복리후생 유연근무제도 항목), PC-OFF 제도 운영 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 근무환경 개선 항목) — 종료 시각·적용 대상 미기재', 51),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 운영 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 근무 유연성 항목), 원격근무제(재택근무 포함) 사용자 수 24명 (2025 사업보고서 유연근무제도 사용 현황 항목) — 대상·횟수·운영 방식 미기재', 52),
  -- ── 건강 (health) — 채용정보 복리후생 · 보고서 36 · 42쪽 ──
  (@comp_id, 'health_check', '본인·배우자 종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '건강검진 (공식 채용정보 페이지 복리후생 건강검진 및 의료비 지원 항목), 본인 및 배우자 종합건강검진 제공 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 건강관리 항목), 임직원 본인 및 배우자 대상 건강검진 지원 (2025 지속가능경영보고서 42쪽 의료 지원 제도 항목) — 검진 주기·지원 금액 미기재', 60),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (공식 채용정보 페이지 복리후생 건강검진 및 의료비 지원 항목, 2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 의료 지원 항목) — 지원 대상·지원 범위·한도 미기재', 61),
  (@comp_id, 'clinic', '사내 의무실·주치의·간호사 상주', NULL, 'health',
   'est', NULL, TRUE, '사업장 내 간호사 상주 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 사내 보건 항목), 사업장 내 주치의 제도 운영(월 1회 전문의 방문진료) · 사내 의무실 운영(임직원·협력회사·방문객 대상 의료 서비스 제공) (2025 지속가능경영보고서 42쪽 의료 지원 제도 항목) — 운영 사업장·진료 과목 미기재', 62),
  -- ── 성장 (growth) — 채용정보 복리후생 · 보고서 34 · 36쪽 ──
  (@comp_id, 'edu_support', '교육 프로그램 (세바시 특강·리더의 서재)', NULL, 'growth',
   'est', NULL, TRUE, '교육 프로그램 제공 (공식 채용정보 페이지 복리후생 항목), 금융시장, 디지털 트윈, 휴머노이드 등 다양한 주제로 산업 및 기술 트렌드에 대한 인사이트를 얻을 수 있도록 하는 세바시(세상을 바꾸는 시간) 특강 · 경영진의 인사이트가 담긴 추천 도서를 직원들과 공유하고 함께 읽는 리더의 서재 (2025 지속가능경영보고서 34쪽 주요 인재육성 프로그램 표), 이러닝 등 직무 외 상시 역량 교육 (2025 지속가능경영보고서 34쪽 교육 운영체계 표 어학·기타 항목) — 수강 비용·대상·운영 주기 미기재', 70),
  (@comp_id, 'lang', '어학 교육', NULL, 'growth',
   'est', NULL, TRUE, '어학 등 직무 외 상시 역량 교육 (2025 지속가능경영보고서 34쪽 교육 운영체계 표 어학·기타 항목) — 언어·운영 방식·비용 지원 범위 미기재', 71),
  (@comp_id, 'mba', '석·박사 학위 취득 지원 (직무 관련)', NULL, 'growth',
   'est', NULL, TRUE, '직무 관련 석·박사 학위 취득 지원 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 교육 지원 항목) — 지원 범위·선발 기준 미기재', 72),
  -- ── 가족 (family) — 채용정보 복리후생 · 보고서 36쪽 ──
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조금 지급 (공식 채용정보 페이지 복리후생 경조금 지급 및 학자금 지원 항목), 결혼·회갑 등 경조금 및 경조휴가 제공 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 경조 지원 항목) — 경조 종류별 금액·휴가 일수 미기재', 80),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원 (공식 채용정보 페이지 복리후생 경조금 지급 및 학자금 지원 항목), 자녀 학자금 지원 (2025 지속가능경영보고서 36쪽 임직원 복지 및 지원제도 표 교육 지원 항목) — 지원 학령·한도 미기재', 81),
  (@comp_id, 'childcare', '사내 보육시설 (광주사업장)', NULL, 'family',
   'est', NULL, TRUE, '광주사업장 내 보육시설 운영 (2025 지속가능경영보고서 36쪽 임직원 복지 및 지원제도 표 보육 지원 항목) — 정원·이용 대상·이용료 미기재', 82),
  -- ── 근무환경 (work_env) — 보고서 36쪽 ──
  (@comp_id, 'dormitory', '사택', NULL, 'work_env',
   'est', NULL, TRUE, '사택 제공 (2025 지속가능경영보고서 36쪽 임직원 복리후생 및 근무환경 표 주거 지원 항목) — 입주 대상·위치·이용료 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
