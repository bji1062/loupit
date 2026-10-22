
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 동원F&B 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://www.dongwonfnb.com/services/Company/Sustainable_Manage01
-- badge: est
--
-- 참고:
--   정본 = 동원F&B 자기 도메인(DART 홈 주소 www.dongwonfnb.com) 회사소개 지속가능경영 페이지(SSR) — 이 페이지가
--     2024년 지속가능경영보고서 국문 PDF(/Company/2024_Sustainable_kor.pdf)를 링크한다. 렌더 없음.
--   근거 = 동원F&B 지속가능경영보고서 2024(법인 단독 발행 · 보고 기간 2024-01 ~ 2024-12 · 일부 2025 상반기 ·
--     보고 범위 동원F&B 국내 전 사업장 · PDF 작성 2025-06) 43 · 44 · 45 · 47 · 48 · 54 · 91쪽.
--   보조 = 2026 반기보고서(접수 20260813000741) 직원 등 현황 유연근무제도 사용 현황 표 — 2025 사업보고서
--     (접수 20260319000629) 같은 표도 열어 세 기간 숫자를 근거표에 옮겼다.
--   귀속: 법인 자기 발행 보고서 · 법인 공시 근거라 각주 없음. 기등록 형제 동원산업(동원그룹 포털 기업 문화 페이지 ·
--     동원그룹 공통 문구 각주)과 문장이 비슷한 항목이 있으나 이 행들은 이 법인 보고서 문장만 인용했다.
--     그룹 채용 사이트(careers.dongwon.com)는 보안 확인 화면(429)이라 읽지 않았다.
--   금액: 금액 행 0(stated 0 · 추정 0) — 출산축하금 · 자격증 인센티브는 1회성, 나머지는 원문 숫자 없음. 식대 원문 없음.
--   제외: 육아휴직 · 배우자 출산휴가 · 임신기 단축근무(법정) · 일반 · 특수건강검진(법정 이름) · 퇴직자 재취업 지원
--     (직원 3,165명 · 비자발적 이직자 재취업 지원 = 법정) · 연말 휴가 권장(본인 휴가 사용 권장) · 신입 · 직급별 ·
--     리더십 · 멘토링 · 스마트캠퍼스 직무 이러닝 · GLOBAL FRONTIER(업무 교육) · 사외 보건대행(법정 보건관리) ·
--     우리사주조합 지분 0.00 표 한 칸 · 협력사 복지 지원(다른 법인).
--   공고 근거 0행 / 전체 30행.
--   SORT 섹션 순서(보고서에 처음 나온 순서): family 10 · growth 20 · compensation 30 · flexibility 40 ·
--     time_off 50 · health 60 · leisure 70 · perks 80 · work_env 90.
-- 검증 · 감사 판정 반영(2026-10-22): 시간단위 연차 확대 행을 법정 반차 몫을 걷은 2시간 단위 휴가 꼴로 · 정기 건강검진 health_check 행 삭제(리드 판정 172 · 같은 보고서 54쪽이 일반 · 특수건강검진으로 밝힘) · 2024 판 보고서가 자기 도메인 최신 판(2025 판 주소 404) · 참고 블록의 반반차 4분의 1일 표기와 행 수는 이 판정으로 뒤집힘 — 최종 29행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('dongwon_fnb', '동원F&B',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품', 'D', 'https://www.dongwonfnb.com/services/Company/Sustainable_Manage01');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'dongwon_fnb');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.dongwonfnb.com/services/Company/Sustainable_Manage01'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — 2024 지속가능경영보고서 48쪽 임직원 복지 ──
  (@comp_id, 'parenting', '다자녀 출산축하금 · 세자녀가구 부양수당 · 초등 입학축하금', NULL, 'family',
   'est', NULL, TRUE, '임직원 출산 지원 제도로서, 자녀 2명 이상 출산 시 둘째 100 만원, 셋째 이상 1,000 만원의 출산축하금 제공, 만 20세 이하 자녀 3명 이상인 임직원 지원 제도로서 세자녀가구 부양수당 제공 (2024 지속가능경영보고서 48쪽 임직원 복지 다자녀 출산축하금 · 세자녀가구 부양수당 항목), 초등 입학축하금 (같은 쪽 주요 복지제도 자녀 학자금 항목) — 부양수당 금액·입학축하금 금액 미기재', 10),
  (@comp_id, 'child_edu', '자녀 학자금 (고등~대학)', NULL, 'family',
   'est', NULL, TRUE, '고등~대학 학자금 지원 (2024 지속가능경영보고서 48쪽 주요 복지제도 자녀 학자금 항목) — 지원 금액·지원 한도 미기재', 11),
  (@comp_id, 'childcare', '사내 어린이집 (동원 어린이집)', NULL, 'family',
   'est', NULL, TRUE, '임직원들의 일과 가정의 양립을 지원하고, 육아에 대해 부담을 느끼는 임직원을 위해 동원 어린이집 운영, 임직원 자녀 대상 동원 어린이집 운영 (2024 지속가능경영보고서 48쪽 사내 어린이집 운영 · 주요 복지제도 육아지원 항목) — 어린이집 위치·정원 미기재', 12),

  -- ── 성장 · 교육 (growth) — 2024 지속가능경영보고서 43 · 44 · 91쪽 ──
  (@comp_id, 'mba', '동원 MBA · 글로벌 지역전문가', NULL, 'growth',
   'est', NULL, TRUE, '동원 MBA: 실무 위주의 경영지식과 현업사례 적용 학습을 진행하는 사내MBA 프로그램, 글로벌 지역전문가 제도: 1년간 현지생활을 통해 언어, 문화, 산업 등을 이해하기 위한 다양한 활동을 진행하는 글로벌 지역전문가 육성 제도 (2024 지속가능경영보고서 43쪽 직급별 육성과정 Professional 육성과정 항목) — 선발 기준·파견 지역·비용 부담 미기재', 20),
  (@comp_id, 'edu_support', '목요세미나', NULL, 'growth',
   'est', NULL, TRUE, '상시 성장을 위한 목요세미나 (2024 지속가능경영보고서 44쪽 인재육성 기타 교육 항목) — 강의 주기·참여 방식 미기재', 21),
  (@comp_id, 'lang', '사이버 · 모바일 · 전화외국어교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '사이버/모바일/전화외국어교육 지원 (2024 지속가능경영보고서 44쪽 인재육성 기타 교육 항목) — 지원 대상·비용 부담 범위 미기재', 22),
  (@comp_id, 'books', '도서구입비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서구입비 지원 (2024 지속가능경영보고서 44쪽 인재육성 기타 교육 항목) — 지원 금액·한도 미기재', 23),
  (@comp_id, 'conference', '사내 · 사외 전문교육 참여 지원', NULL, 'growth',
   'est', NULL, TRUE, '사내/사외 전문교육 참여 지원 (2024 지속가능경영보고서 44쪽 인재육성 기타 교육 항목) — 지원 대상·비용 부담 범위 미기재', 24),
  (@comp_id, 'self_development', 'AI 자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, 'AI 관련 자격증 취득 지원금 제공, 취득 시 인센티브 지급, 강의료, 교재비, 자격증 취득 비용을 지원, 빅데이터분석기사 · ADsP · AICE · AIPD 도서비 · 전형료 실비, 취득 인센티브 정액 빅데이터분석기사 150,000원 · ADsP와 AICE 100,000원 · AIPD 50,000원 (2024 지속가능경영보고서 91쪽 AI 관련 자격증 취득 지원 항목) — AI 외 자격증 지원 여부 미기재', 25),

  -- ── 보상 (compensation) — 2024 지속가능경영보고서 45 · 47 · 48쪽 ──
  (@comp_id, 'incentive', '성과 인센티브 (평가 차등)', NULL, 'compensation',
   'est', NULL, TRUE, '조직평가제도를 운영하여 인센티브 재원 배분에 대한 공정성을 높이고, 회사평가와 조직평가, 개인평가가 종합된 배분율에 따라 인센티브 등의 보상을 차등적으로 지급 (2024 지속가능경영보고서 45쪽 성과평가 및 보상 임직원 평가 제도 항목) — 지급 기준·지급률 미기재', 30),
  (@comp_id, 'excellence_award', '우수인재 · 우수팀 시상', NULL, 'compensation',
   'est', NULL, TRUE, '사내 우수인재 선발 정기 시상, 연말 성과 우수상 재편, 우수팀/개인 분기 시상 공모 (2024 지속가능경영보고서 47쪽 조직문화 개선 실행방안 보상경쟁력 강화 항목) — 시상 기준·포상 내용 미기재', 31),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '10/20/25년 장기근속자 포상 및 국내외 여행 상품권 제공 (2024 지속가능경영보고서 48쪽 주요 복지제도 장기근속포상 항목) — 포상 금액·상품권 금액 미기재', 32),

  -- ── 근무 유연성 (flexibility) — 2024 지속가능경영보고서 47 · 48쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제 · 선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출근제 유연근무 (2024 지속가능경영보고서 47쪽 조직문화 개선 실행방안 인사제도 개선 항목), 유연근무제 활용 여부 활용 · 시차출퇴근제 사용자 2024년 44명 · 2025년 52명 · 2026년 상반기 44명 · 선택근무제 사용자 2024년 8명 · 2025년 3명 · 2026년 상반기 3명 (2026 반기보고서 유연근무제도 사용 현황 표 항목) — 출퇴근 시간대·대상 직무 미기재', 40),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용 여부 활용 · 원격근무제(재택근무 포함) 사용자 2024년 10명 · 2025년 10명 · 2026년 상반기 2명 (2026 반기보고서 유연근무제도 사용 현황 표 항목) — 대상 직무·사용 조건 미기재', 41),
  (@comp_id, 'pc_off', 'PC-OFF 시스템', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF 도입, 눈치보기, 습관적 지연퇴근 및 야근 축소 유도, 근무시간 내 업무몰입 (2024 지속가능경영보고서 47쪽 조직문화 개선 실행방안 시스템 개선 항목) — 종료 시각·예외 신청 절차 미기재', 42),
  (@comp_id, 'family_day', '가정의 날 (매주 수요일)', NULL, 'flexibility',
   'est', NULL, TRUE, '매주 수요일을 가정의 날로 지정하여 퇴근 독려 사내방송을 실시, 임원과 부서장이 먼저 퇴근하는 문화 (2024 지속가능경영보고서 48쪽 임직원 복지정책 항목) — 퇴근 시각 미기재', 43),

  -- ── 휴가 (time_off) — 2024 지속가능경영보고서 47 · 48쪽 ──
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, 'Refresh 휴가, 연중 4일 유급휴가 부여 (2024 지속가능경영보고서 48쪽 주요 복지제도 Refresh 휴가 항목) — 부여 조건·사용 시기 미기재', 50),
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '시간단위 휴가 확대(2시간 단위 등) (2024 지속가능경영보고서 47쪽 조직문화 개선 실행방안 인사제도 개선 항목) — 사용 절차 미기재', 51),

  -- ── 건강 (health) — 2024 지속가능경영보고서 47 · 48 · 54쪽 ──
  (@comp_id, 'mental', '임직원 EAP 심리상담', NULL, 'health',
   'est', NULL, TRUE, '임직원 EAP(Employee assistance program) 멘탈심리케어(우울, 스트레스), 심리전문가 연결(ON/OFF) 채팅, 전화, 화상, 대면 (2024 지속가능경영보고서 47쪽 조직문화 개선 실행방안 항목), 전문 심리/건강 상담 (48쪽 주요 복지제도 건강검진 및 심리상담 항목) — 이용 횟수·비용 부담 미기재', 60),
  (@comp_id, 'clinic', '간호사 방문 건강상담 (본사)', NULL, 'health',
   'est', NULL, TRUE, '본사: 매월 간호사 방문을 통해 추가 건강상담 제공 (2024 지속가능경영보고서 54쪽 임직원 건강 관리 항목) — 상담 시간·이용 방식 미기재', 62),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '임직원 질병 및 상해 보장 보험 지원 (2024 지속가능경영보고서 48쪽 주요 복지제도 단체상해보험 항목) — 보장 한도·가족 포함 여부 미기재', 63),
  (@comp_id, 'fitness', '피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '본사, 사업장 피트니스 센터 운영 (2024 지속가능경영보고서 48쪽 주요 복지제도 피트니스 항목) — 사업장별 운영 여부 미기재', 64),

  -- ── 여가 (leisure) — 2024 지속가능경영보고서 48쪽 ──
  (@comp_id, 'company_event', '가족 참여 프로그램 (부모의 직장 견학 등)', NULL, 'leisure',
   'est', NULL, TRUE, '임직원이 개인 여가시간을 가족과 함께할 수 있도록 부모의 직장 견학, 아빠와 쿠킹 클래스, 자녀 소통법 강좌 등과 같은 프로그램 실시 (2024 지속가능경영보고서 48쪽 임직원 복지정책 항목) — 실시 주기·참여 대상 미기재', 70),
  (@comp_id, 'resort', '휴양시설 지원', NULL, 'leisure',
   'est', NULL, TRUE, '전국 주요 관광지 25개 유명 리조트 이용 지원 (2024 지속가능경영보고서 48쪽 주요 복지제도 휴양시설 항목) — 이용 일수·비용 지원 범위 미기재', 71),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 지원 (2024 지속가능경영보고서 48쪽 주요 복지제도 사내 동호회 항목) — 지원 금액·지원 방식 미기재', 72),

  -- ── 생활 · 금융 · 주거 (perks) — 2024 지속가능경영보고서 48쪽 ──
  (@comp_id, 'housing_loan', '주택자금대출 (신협)', NULL, 'perks',
   'est', NULL, TRUE, '주택자금대출(신협) 운영 (2024 지속가능경영보고서 48쪽 주요 복지제도 주거지원 항목) — 대출 한도·이율 미기재', 80),
  (@comp_id, 'welfare_point', '복지포인트 (자사몰 · 임직원 할인 포인트)', NULL, 'perks',
   'est', NULL, TRUE, '자사몰 포인트 및 임직원 할인 포인트 지원 (2024 지속가능경영보고서 48쪽 주요 복지제도 복지포인트 항목) — 포인트 금액·지급 주기 미기재', 81),
  (@comp_id, 'commute_subsidy', '출퇴근 셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '본사, 사업장 셔틀버스 운영 (2024 지속가능경영보고서 48쪽 주요 복지제도 출퇴근 셔틀버스 항목) — 운행 노선·사업장별 운행 여부 미기재', 82),

  -- ── 근무 환경 (work_env) — 2024 지속가능경영보고서 48쪽 ──
  (@comp_id, 'lounge', '여성 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '여성 휴게실 (2024 지속가능경영보고서 48쪽 주요 복지제도 휴게공간 항목) — 설치 사업장·이용 방식 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
