-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한화에어로스페이스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://hanwhaaerospace-recruit.com/
-- badge: est
--
-- 참고:
--   정본은 한화에어로스페이스 채용 마이크로페이지(법인 공식 홈 /kor/careers/recruit.do 의 「채용 마이크로페이지 —
--   한화에어로스페이스 채용 홍보」 배너가 링크) 첫 화면의 복리후생 절이다. 서버 렌더 HTML(Astro), 라벨 16개 + FAQ 주거지원 문항.
--   ⚠ 정본은 공채 홍보 도메인이다 — 도메인 등록 2023-08-29 · 만료 2027-08-29(RDAP). 공채가 바뀌면 화면이 바뀔 수 있다.
--   보조 출처: 같은 법인 홈 ESG 지속가능경영 메뉴의 2026 지속가능경영보고서(국문 PDF, files/down.do 506d56b7)
--     p.38 건강증진 프로그램 · p.49 평가 및 보상 · 사내공모 제도 · 일과 삶의 균형 지원제도 표,
--     2025 지속가능경영보고서(국문 PDF, 6dbe86fc) 지속가능발전목표 5.1 항목. 보고서 근거 구절은 서술 괄호에 보고서 이름을 적어 구분했다.
--   귀속: 법인 자기 도메인 · 법인 발행 보고서 · 법인 홈이 링크한 법인 채용 페이지라 그룹 각주 없음.
--     ㈜한화 · 한화시스템 · 한화오션 · 한화생명 페이지 문장은 쓰지 않았다. 구본의 한화리조트 · 더플라자호텔 · 한화갤러리아 ·
--     63빌딩 할인 문구는 이 법인 원문에 없어 걷었다.
--   직군 · 사업장: 자율출퇴근제는 본사 및 연구소, 시차출퇴근제는 사업장 일반직(보고서 표), 주거 지원은 사업장별 상이 ·
--     서울/판교 미운영(FAQ)을 서술에 적었다.
--   금액: 원문 명시 금액 0. 구본 추정 승계 3(health_check 100 · medical 100 · resort 50 — 전부 틀 값, NOTE 끝에 (추정)).
--   법정 등록 행 parenting 아빠휴가: 원문이 근무일 기준 총 30일을 밝혀 상회분(법정 20일에 10일 추가)만 남겼다 — 이름이 바뀐다.
--   제외: 가족돌봄휴가 · 육아휴직 · 난임휴가(일수 없음) · 근무시간 조정 및 단축근무 · 재취업 지원 서비스(정년퇴직 대상자 —
--     1,000인 이상 법정) · 정기 상여 · 사내 MBA · 온보딩 등 회사 주도 교육(어학 과정은 2026-10-04 규칙 8 개정으로 lang 서술에 되살림) · 문화 교양 프로그램(내용 없음) ·
--     건강 프로그램(운동 · 금연 · 특강 — 맞는 코드 없음).
--   구본에서 뺀 행: event · books · club · discount (이 법인 현행 원문에 없음).
--   SORT 섹션 순서 = 정본 복리후생 절에서 카테고리가 처음 나온 순서, 보고서에만 있는 카테고리는 보고서 순서로 뒤에
--     (flexibility 10 · perks 20 · health 30 · time_off 40 · growth 50 · family 60 · compensation 70 · leisure 80 · work_env 90).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-5): 20행 전부 원문 확인 · parenting 아빠휴가는 상회분(근무일 기준 총 30일)만 남아 법정 등록 해제 · 행 조치 없음 — 최종 20행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 서술 · 이름 수정 1(lang) — 최종 20행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanwha_aerospace', '한화에어로스페이스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '항공/방산', 'H', 'https://hanwhaaerospace-recruit.com/');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha_aerospace');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://hanwhaaerospace-recruit.com/'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 복리후생 유연근무제 / 2026 보고서 근무 형태 ──
  (@comp_id, 'flex_work', '유연근무제 (자율출퇴근·시차출퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제(자율출퇴근/시차출퇴근) (공식 채용 사이트 복리후생 항목), 자율출퇴근제는 본사 및 연구소, 시차출퇴근제는 사업장 일반직 대상 (2026 지속가능경영보고서 일과 삶의 균형 지원제도 표) — 코어타임·사용 조건 미기재', 10),

  -- ── 경제적 부가혜택 (perks) — 복리후생 복지포인트 · 개인연금 · 주거 · 귀가 교통비 ──
  (@comp_id, 'welfare_point', '복지포인트·Refresh 포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트/Refresh 포인트 (공식 채용 사이트 복리후생 항목) — 연간 포인트 금액·사용처 미기재', 20),
  (@comp_id, 'pension_support', '개인연금제도', NULL, 'perks',
   'est', NULL, TRUE, '개인연금제도 (공식 채용 사이트 복리후생 항목) — 회사 부담률·가입 조건 미기재', 21),
  (@comp_id, 'housing_support', '주거지원금·주택보조금', NULL, 'perks',
   'est', NULL, TRUE, '무연고자 주거지원제도, 주거지원금/주택보조금 (공식 채용 사이트 복리후생 항목), 주거지원금 및 주택보조금 제도로 주거 관련 지원, 사업장별 상이, 서울/판교는 주거지원 관련 제도 미운영 (공식 채용 사이트 FAQ 주거지원 문항), 주택 지원금 및 보조금 제도 (2026 지속가능경영보고서 일과 삶의 균형 지원제도 표) — 지원 금액·지급 형태 미기재', 22),
  (@comp_id, 'transport', '귀가 교통비 (월 2회 왕복 KTX)', NULL, 'perks',
   'est', NULL, TRUE, '월 2회 귀가 교통비(왕복 KTX 비용 지원) (공식 채용 사이트 복리후생 항목) — 대상·적용 사업장 미기재', 23),

  -- ── 건강·의료 (health) — 복리후생 심리상담 · 보험 · 건강검진 / 2026 보고서 건강증진 프로그램 · 의료 ──
  (@comp_id, 'mental', '전문 심리상담 서비스', NULL, 'health',
   'est', NULL, TRUE, '전문 심리상담 서비스 (공식 채용 사이트 복리후생 항목), 임직원의 정신건강을 위해 전문 심리상담사를 채용하여 상담 및 다양한 심리 프로그램 제공 (2026 지속가능경영보고서 건강증진 프로그램 항목) — 상담 횟수·가족 이용 여부 미기재', 30),
  (@comp_id, 'insurance', '단체상해보험·단체 의료 실손보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험/가족실손보험 (공식 채용 사이트 복리후생 항목), 임직원에게 단체 의료 실손 보험 제공 (2026 지속가능경영보고서 건강증진 프로그램 항목) — 보장 범위·보험료 부담 미기재', 31),
  (@comp_id, 'health_check', '종합건강검진 (임직원·가족)', 100, 'health',
   'est', '건강검진 (공식 채용 사이트 복리후생 항목), 임직원과 그 가족 대상 종합 건강 검진 지원, 정기적인 사원 건강진단 (2026 지속가능경영보고서) — 검진 비용 한도 미기재 (추정)', FALSE, NULL, 32),
  (@comp_id, 'medical', '의료비 지원 (본인·가족)', 100, 'health',
   'est', '의료 지원 및 의료비 지원, 선택에 따라 가족 의료비 지원 또는 가족 실손 의료보험 제공 (2026 지속가능경영보고서 일과 삶의 균형 지원제도 표 · 건강증진 프로그램 항목) — 지원 비율·한도 미기재 (추정)', FALSE, NULL, 33),

  -- ── 시간·휴가 (time_off) — 복리후생 안식월 제도 ──
  (@comp_id, 'leave_general', '안식월 (승진자 대상)', NULL, 'time_off',
   'est', NULL, TRUE, '안식월 제도(승진자 대상) (공식 채용 사이트 복리후생 항목) — 기간·유급 여부·사용 시기 미기재', 40),

  -- ── 성장·교육 (growth) — 복리후생 잡포스팅 · 사외직무/어학교육 · 오픽 / 2026 보고서 사내공모 제도 ──
  (@comp_id, 'career', '사내 잡포스팅 (Job Market)', NULL, 'growth',
   'est', NULL, TRUE, '사내 잡포스팅 제도 (공식 채용 사이트 복리후생 항목), 정기적인 Job Market 제도로 직원이 희망 부서 및 직무에 지원, 서류 검토 및 인터뷰 절차로 선정 (2026 지속가능경영보고서 사내공모 제도 항목)', 50),
  (@comp_id, 'edu_support', '사외 직무교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '사외직무 교육 지원 (공식 채용 사이트 복리후생 사외직무/어학교육 지원 항목) — 지원 한도·대상 과정 미기재', 51),
  (@comp_id, 'lang', '어학교육·OPIc 평가 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학교육 지원, 오픽(OPIc) 평가 지원 연 2회 (공식 채용 사이트 복리후생 사외직무/어학교육 지원 · 오픽 평가 지원 항목), 희망 임직원 대상 1:1 화상 전화 어학 교육·사업장별 대면/비대면 집합 사내 어학 교육 (2026 지속가능경영보고서 48쪽 인재육성 프로그램 글로벌 항목) — 응시료 부담 범위 미기재', 52),

  -- ── 가족·돌봄 (family) — 복리후생 맘스패키지 · 직장 어린이집 · 학자금 · 아빠휴가 / 2026 보고서 가족 ──
  (@comp_id, 'parenting', '맘스패키지·출산축하금·아빠휴가 총 30일', NULL, 'family',
   'est', NULL, TRUE, '맘스패키지(임신축하선물), 아빠휴가 근무일 기준 총 30일(법정 배우자 출산휴가 20일에 10일 추가) (공식 채용 사이트 복리후생 항목), 출산축하금 및 출산 축하 선물, 일과 가정의 균형을 위해 맘스패키지 및 상품권 제공 (2026 지속가능경영보고서 일과 삶의 균형 지원제도) — 축하금 금액 미기재', 60),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 (공식 채용 사이트 복리후생 항목), 직장 어린이집 운영 (2026 지속가능경영보고서 일과 삶의 균형 지원제도 표) — 운영 사업장·정원 미기재', 61),
  (@comp_id, 'child_edu', '자녀 학자금 (미취학·중/고/대학교)', NULL, 'family',
   'est', NULL, TRUE, '미취학 자녀 및 중/고/대학교 학자금 (공식 채용 사이트 복리후생 항목), 장학 제도(자녀 학비 지원 및 양질 교육 제공 등) (2026 지속가능경영보고서 일과 삶의 균형 지원제도 표) — 지원 한도·자녀 수 제한 미기재', 62),

  -- ── 보상·금전 (compensation) — 2026 보고서 평가 및 보상 ──
  (@comp_id, 'incentive', '경영성과급·수시 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '개인의 업무 성과와 회사의 재무 및 전략적 성과를 반영한 변동급 제도를 전 직원에게 적용, 경영성과 및 전략 목표 달성에 연계된 경영성과급과 CEO 재량의 수시 인센티브 (2026 지속가능경영보고서 합리적인 보상 제도 항목) — 지급 기준·지급률 미기재', 70),
  (@comp_id, 'stock_option', '우리사주제도', NULL, 'compensation',
   'est', NULL, TRUE, '전 임직원 대상 우리사주 조합을 통한 우리사주제도 운영, 희망 임직원에게 우리사주청약 기회와 대출이자 지원 (2026 지속가능경영보고서 합리적인 보상 제도 항목) — 지원 한도 미기재', 71),

  -- ── 여가·라이프 (leisure) — 2026 보고서 여가 ──
  (@comp_id, 'resort', '휴양시설·레저 활동 지원', 50, 'leisure',
   'est', '휴양시설, 레저 활동 등 비용 및 시설 지원 (2026 지속가능경영보고서 일과 삶의 균형 지원제도 표 여가 항목) — 시설명·이용 횟수 미기재 (추정)', FALSE, NULL, 80),

  -- ── 근무환경 (work_env) — 2026 보고서 모성보호 휴게실 ──
  (@comp_id, 'nap_room', '모성보호 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '모성보호 휴게실 구비 (2026 지속가능경영보고서 일과 삶의 균형 지원제도 표 가족 항목), 직장 내 모성보호와 모유수유 친화적 공간 제공 (2025 지속가능경영보고서 지속가능발전목표 5.1 항목) — 운영 사업장 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
