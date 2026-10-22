-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대트랜시스 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://www.hyundai-transys.com/resources/upload/web/esg/report/158886934-0de60008-829e-4abc-993c-682c9b80e3f6.pdf
-- badge: est
--
-- 참고:
--   정본 = 현대트랜시스 자기 도메인 2026 지속가능경영보고서 국문 PDF(2026-07-29 발행 · 보고 기간 2025 회계연도
--     · 일부 정성 성과 2026 상반기까지 · 보고 범위 현대트랜시스 국내 사업장 5개 · 161쪽 · 지속가능경영보고서 목록
--     /ko/sustainability/report.do 의 첫 카드). 99쪽 임직원 근무환경 복리후생 절(선택적 근로시간제 · 일/가정/양립 지원
--     문단 · 건강 · 가정 · 생활 · 금융 · 문화 · 문화 6칸 표)이 중심. 보조 = 같은 보고서 75쪽 금연 프로그램 · 90쪽 임신/임산부의
--     권리 보장 · 94쪽 전 직원 대상 개인개발 교육 · 95쪽 교육 플랫폼 운영 · 96쪽 집중 어학과정 · 해외연수 지원 · 100쪽.
--   렌더 = PDF 텍스트 추출 + 99쪽 표 칸 위치 대조(표 그림 사본으로 칸 귀속 확인). 헤드리스 렌더 없음.
--   공식 채용 사이트 Benefits(hyundai-transys.recruiter.co.kr/career/Benefits)는 원본 HTML 에 항목이 없어(앱 셸) 읽지 않았다.
--   귀속: 보고서 문장 주어가 전부 현대트랜시스 · 법인 단독 발행 보고서라 각주 없음. 현대차그룹 형제 10사 정본 문장 옮기지 않음.
--   금액: 원문 원 단위 금액 0건 → 금액 행 0(이러닝 교육비 100% · 연 2회 교육비 전액은 비율 · 횟수라 NULL).
--   제외: 출산휴가 · 육아휴직 · 근로시간 단축 · 모성보호 3법 적용 · 퇴직연금(법정), 근골격계 · 뇌심혈관 예방 관리(산업보건),
--     신입 · 경력 입문 · OJT · 신임 팀장 · In-HUB · Basic/Advanced MBA · 직무 아카데미(업무 교육), 성과평가 · 생활임금(임금).
--   복합 라벨 가르기: 명절/휴가비 지원 → holiday_gift · summer_vacation_subsidy, 건강검진 및 입원/외래 비용 지원 → health_check · medical.
--   공고 근거 0행 / 전체 29행. SORT 섹션 순서 = 99쪽 복리후생 절에 카테고리가 처음 나온 순서
--     flexibility 10 · family 20 · perks 30 · health 40 · work_env 50 · leisure 60 · compensation 70, 다른 쪽에만 있는 growth 80.
-- 검증 · 감사 판정 반영(2026-10-22): 2026 지속가능경영보고서 48쪽 연구개발 문단의 우수 논문 포상 제도를 excellence_award 로 추가 · 현대트랜시스는 주어라 각주 없음 · 현대차 10사 겹침 0 · 참고 블록의 공고 근거 0행 / 전체 29행과 근거표의 선례 인용(물리치료 행 수 · 해외연수 선례 회사)은 이 판정으로 뒤집힘 — 최종 30행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_transys', '현대트랜시스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '자동차부품', 'H', 'https://www.hyundai-transys.com/resources/upload/web/esg/report/158886934-0de60008-829e-4abc-993c-682c9b80e3f6.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_transys');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hyundai-transys.com/resources/upload/web/esg/report/158886934-0de60008-829e-4abc-993c-682c9b80e3f6.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 유연근무 (flexibility) — 2026 지속가능경영보고서 99쪽 ──
  (@comp_id, 'flex_work', '선택적 근로시간제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '업무 특성을 고려하여 선택적 근로시간제 운영, 제도가 적용되는 직군에서는 의무 근무시간을 제외한 선택 가능 시간대 내에서 출퇴근 시간과 1일 근로시간을 스스로 결정, 일반직(국내)은 월 소정 근로시간을 준수하는 범위에서 몰입 근무 가능 (2026 지속가능경영보고서 99쪽 선택적 근로시간제 항목) — 적용 직군 범위 미기재', 10),

  -- ── 가족 (family) — 2026 지속가능경영보고서 99쪽 · 90쪽 ──
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집을 통해 육아 부담 완화 (2026 지속가능경영보고서 99쪽 일/가정/양립 지원 항목), 직장어린이집 운영 (같은 보고서 99쪽 복리후생 표 가정 항목) — 운영 사업장·정원 미기재', 20),
  (@comp_id, 'fertility_support', '난임시술비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임시술비 지원 (2026 지속가능경영보고서 99쪽 복리후생 표 건강 항목), 난임 시술과 관련해 정부지원금 외 발생 비용에 대한 추가 지원 (같은 보고서 90쪽 임신/임산부의 권리 보장 항목) — 지원 한도·횟수 미기재', 21),

  -- ── 생활 · 금융 (perks) — 2026 지속가능경영보고서 99쪽 ──
  (@comp_id, 'housing_loan', '직원 대출 (주거 · 차량 · 결혼)', NULL, 'perks',
   'est', NULL, TRUE, '주거 및 금융 지원 (2026 지속가능경영보고서 99쪽 일/가정/양립 지원 항목), 직원 대출(주거, 차량, 결혼) (같은 보고서 99쪽 복리후생 표 금융 항목) — 대출 한도·이율 미기재', 30),
  (@comp_id, 'discount', '현대차/기아 차량 구입 시 할인', NULL, 'perks',
   'est', NULL, TRUE, '현대차/기아 차량 구입시 할인 (2026 지속가능경영보고서 99쪽 복리후생 표 금융 항목) — 할인율·대상 차종 미기재', 31),
  (@comp_id, 'meal', '식사 지원', NULL, 'perks',
   'est', NULL, TRUE, '식사지원 (2026 지속가능경영보고서 99쪽 복리후생 표 건강 항목) — 제공 끼니·회사 부담 범위 미기재', 32),
  (@comp_id, 'relocation', '원거리 인사발령 시 부임휴가 · 이사비 지원', NULL, 'perks',
   'est', NULL, TRUE, '원거리 인사발령 시 부임휴가 및 이사비 지원 (2026 지속가능경영보고서 99쪽 복리후생 표 생활 항목) — 휴가 일수·지원 금액 미기재', 33),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 지원 (2026 지속가능경영보고서 99쪽 복리후생 표 생활 항목) — 운행 사업장·노선 미기재', 34),
  (@comp_id, 'welfare_point', '임직원 쇼핑몰 포인트', NULL, 'perks',
   'est', NULL, TRUE, '임직원 쇼핑몰 포인트 제공 (2026 지속가능경영보고서 99쪽 복리후생 표 문화 항목) — 포인트 금액·지급 주기 미기재', 35),
  (@comp_id, 'snack_bar', '간식 지원', NULL, 'perks',
   'est', NULL, TRUE, '간식 지원 (2026 지속가능경영보고서 99쪽 복리후생 표 문화 항목) — 제공 방식·품목 미기재', 36),

  -- ── 건강 (health) — 2026 지속가능경영보고서 99쪽 · 100쪽 · 75쪽 ──
  (@comp_id, 'mental', '심리상담 서비스', NULL, 'health',
   'est', NULL, TRUE, '심리상담 서비스 (2026 지속가능경영보고서 99쪽 일/가정/양립 지원 항목), 상담·치유·예방 중심의 정신건강 지원체계 확대 (같은 보고서 100쪽 임직원 근무환경 항목) — 상담 횟수·이용 대상 미기재', 40),
  (@comp_id, 'clinic', '물리치료 프로그램', NULL, 'health',
   'est', NULL, TRUE, '물리치료 프로그램 (2026 지속가능경영보고서 99쪽 일/가정/양립 지원 항목) — 운영 장소·이용 대상 미기재', 41),
  (@comp_id, 'medical', '입원/외래 비용 · 진료비 지원', NULL, 'health',
   'est', NULL, TRUE, '진료비 지원 (2026 지속가능경영보고서 99쪽 일/가정/양립 지원 항목), 입원/외래 비용 지원 (같은 보고서 99쪽 복리후생 표 건강 항목) — 지원 한도·가족 포함 여부 미기재', 42),
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '건강검진 지원 (2026 지속가능경영보고서 99쪽 복리후생 표 건강 항목) — 검진 주기·비용 지원 범위 미기재', 43),
  (@comp_id, 'insurance', '직원 단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 (2026 지속가능경영보고서 99쪽 일/가정/양립 지원 항목), 직원 단체상해보험 가입 (같은 보고서 99쪽 복리후생 표 건강 항목) — 보장 범위·가족 포함 여부 미기재', 44),
  (@comp_id, 'fitness', '직원 체육시설 지원', NULL, 'health',
   'est', NULL, TRUE, '직원 체육시설 지원 (2026 지속가능경영보고서 99쪽 복리후생 표 건강 항목) — 시설 형태·이용 조건 미기재', 45),
  (@comp_id, 'smoking_cessation', '금연클리닉 프로그램', NULL, 'health',
   'est', NULL, TRUE, '흡연자를 대상으로 1:1 금연클리닉 프로그램 운영, 지곡·성연공장 중심 연 2회 기수별 100일간 금연 관리, 필요 시 금연보조제 제공 및 전문 상담, 금연 유지 확인 뒤 성공자에게 인센티브 지급 (2026 지속가능경영보고서 75쪽 금연 프로그램 항목) — 인센티브 금액 미기재', 46),

  -- ── 근무 환경 (work_env) — 2026 지속가능경영보고서 99쪽 · 90쪽 ──
  (@comp_id, 'dormitory', '숙소(사택) 제공', NULL, 'work_env',
   'est', NULL, TRUE, '숙소(사택)제공 (2026 지속가능경영보고서 99쪽 복리후생 표 생활 항목) — 입주 대상·조건 미기재', 50),
  (@comp_id, 'uniform', '제조 근무자 피복 지원', NULL, 'work_env',
   'est', NULL, TRUE, '제조 근무자 대상 피복 지원 (2026 지속가능경영보고서 99쪽 복리후생 표 생활 항목) — 지급 품목·주기 미기재', 51),
  (@comp_id, 'nap_room', '수유 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '임산부를 위한 수유 휴게실 제공 (2026 지속가능경영보고서 90쪽 임신/임산부의 권리 보장 항목) — 설치 사업장 미기재', 52),
  (@comp_id, 'parking', '임산부 전용 주차공간', NULL, 'work_env',
   'est', NULL, TRUE, '임산부를 위한 전용 주차공간 제공 (2026 지속가능경영보고서 90쪽 임신/임산부의 권리 보장 항목) — 설치 사업장 미기재', 53),

  -- ── 여가 (leisure) — 2026 지속가능경영보고서 99쪽 ──
  (@comp_id, 'resort', '호텔/리조트 회원권 연계 지원', NULL, 'leisure',
   'est', NULL, TRUE, '호텔/리조트 회원권 연계 지원 (2026 지속가능경영보고서 99쪽 복리후생 표 문화 항목) — 이용 시설·이용 횟수 미기재', 60),
  (@comp_id, 'club', '동호회 활동비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동비 지원 (2026 지속가능경영보고서 99쪽 복리후생 표 문화 항목) — 지원 금액·지원 기준 미기재', 61),
  (@comp_id, 'leisure_ticket', '문화행사 관람비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '문화행사 관람비 지원 (2026 지속가능경영보고서 99쪽 복리후생 표 문화 항목) — 지원 금액·대상 행사 미기재', 62),
  (@comp_id, 'summer_vacation_subsidy', '휴가비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비 지원 (2026 지속가능경영보고서 99쪽 복리후생 표 문화 항목) — 지급 금액·지급 시기 미기재', 63),

  -- ── 보상 (compensation) — 2026 지속가능경영보고서 99쪽 ──
  (@comp_id, 'holiday_gift', '명절 지원', NULL, 'compensation',
   'est', NULL, TRUE, '명절 지원 (2026 지속가능경영보고서 99쪽 복리후생 표 문화 항목) — 지원 형태·금액 미기재', 70),
  (@comp_id, 'excellence_award', '우수 논문 포상 제도', NULL, 'compensation',
   'est', NULL, TRUE, '창의적 연구문화 조성 및 기술 경쟁력 강화를 위한 우수 논문 포상 제도 운영 (2026 지속가능경영보고서 48쪽 연구개발 항목) — 포상 대상·포상 내용 미기재', 71),

  -- ── 성장 · 교육 (growth) — 2026 지속가능경영보고서 94쪽 · 95쪽 · 96쪽 ──
  (@comp_id, 'edu_support', '이러닝 플랫폼 · 사외 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '매월 직무 분야 이러닝 콘텐츠 수강, 이러닝만으로 충족하기 어려운 심화 과정은 외부 교육기관의 전문 교육 과정 수강 기회 제공, 회사가 연 2회 교육비 전액 지원 (2026 지속가능경영보고서 94쪽 전 직원 대상 개인개발 교육 항목), 직무 이러닝 과정 수료 시 회사가 교육비 100% 지원 (같은 보고서 95쪽 교육 플랫폼 운영 항목) — 1회 지원 한도 미기재', 80),
  (@comp_id, 'lang', '외국어 이러닝 · 집중 어학과정', NULL, 'growth',
   'est', NULL, TRUE, '외국어 과정 · 전화·화상 외국어 과정 운영, 어학 이러닝 과정 수료 시 회사가 교육비 100% 지원 (2026 지속가능경영보고서 95쪽 교육 플랫폼 운영 항목), 영어/중국어 집중 어학 과정 상/하반기 운영, 입과 기준 충족자 대상 (같은 보고서 96쪽 집중 어학과정 항목) — 입과 기준 미기재', 81),
  (@comp_id, 'conference', '해외연수 지원 (지곡·성연공장)', NULL, 'growth',
   'est', NULL, TRUE, '지곡공장 및 성연공장 근무 임직원 중 대상자를 선정하여 해외 사업장 견학과 이문화 체험으로 구성된 해외연수 프로그램 운영 (2026 지속가능경영보고서 96쪽 해외연수 지원 항목) — 선정 기준·연수 기간 미기재', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
