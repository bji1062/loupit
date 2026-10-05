-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한화시스템 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.hanwhasystems.com/kr/recruit/recruit2.do
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인 홈페이지 헤더 메뉴 인재채용 → 인사제도 페이지 /kr/recruit/recruit2.do 다.
--   서버 렌더 HTML 에 복리후생 4블록(행복한 일터 · 건강한 일터 · 일家양득 · 자율적 근무환경)과 교육제도가 있다.
--   구본 15행은 이 페이지 문장을 그대로 옮긴 것이었다(구본 귀속 A).
--   보조 출처: 같은 사이트 헤더 메뉴의 영문 인사제도 /en/recruit/recruit2.do Welfare System(개인연금 · 용인 연구소
--     주택 대출 · 구미사업장 기숙사 · 의료비 가족 범위), 같은 사이트 ESG 메뉴의 2026 지속가능경영보고서
--     (국문 PDF, upload/202607/e8971e24…) p.46 대학원 진학 · 전문자격 · p.47 학습조직 · p.48 성과급 · 우리사주 ·
--     p.49 주요 복리후생 프로그램 · p.105 셔틀버스 · p.128 마음건강, 2025 보고서(upload/202607/be34ec54…) p.95 대조.
--     보고서는 종속회사 필리조선소 내용을 함께 싣는다 — 필리조선소 표지가 붙은 구절은 쓰지 않았다.
--   귀속: 법인 자기 도메인 · 법인 발행 보고서. 한화생명 · 한화에어로스페이스 · 한화오션 · ㈜한화 문장은 쓰지 않았다.
--     Global Talent Program 은 원문 주어가 한화(그룹)라 서술에 그룹 운영 프로그램임을 적었다.
--   금액: 원문 금액 없음. 구본 추정 승계 5(meal 432 조 · 중 · 석식 표기 · welfare_point 200 · health_check 100 ·
--     medical 100 · resort 50 — 전부 틀 값, NOTE 끝에 (추정)). 학습조직 월 3만 원은 참가자 한정이라 금액 칸에 넣지 않았다.
--   법정 등록 행: parenting 출산휴가/아빠휴가 → 법정분을 걷고 상회분(배우자 출산 휴가 26일 · 축하금 · 패키지)만 남겨
--     이름이 바뀌었다.
--   제외: 가족돌봄휴가 · 가족돌봄 근로시간 단축 · 임신/육아기 단축 · 육아휴직 · 유급 수유시간 · 난임 휴가 사용 ·
--     법정 휴가 사용 촉진 · 재취업 교육(1,000인 이상 법정) · RSU(임원 · 선별) · 아빠휴가 제도 이름뿐 ·
--     장기근속휴가 이름뿐 · 차세대 리더 육성. (Refresh 휴가 · 사내 교육 플랫폼 채널 H+ 는 2026-10-04 기준 23 · 규칙 8 개정으로 되살렸다.)
--   재코딩: edu_support → mba (구본 학위과정 행의 제도는 재직 중 석사 · 박사과정 지원).
--   SORT 섹션 순서 = 인사제도 복리후생 블록에서 카테고리가 처음 나온 순서, 보조 출처만의 카테고리는 끝
--     (time_off 10 · perks 20 · health 30 · family 40 · leisure 50 · flexibility 60 · growth 70 · compensation 80 · work_env 90).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-5): 채움휴직을 안식휴가에서 떼어 leave_general 로 · 학습조직 MOIM 다과비 걷음 · 어학 학습비(2026 보고서 p.45) · Future Changer 시상(2025 보고서 p.96) 추가 · 최종 30행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(edu_support) · 서술 · 이름 수정 2(refresh_leave · lang) — 최종 31행
-- 후속 정리 4(2026-10-05, R-3): 재택근무제 이름에 대상 한정 「(ICT부문)」 — 2025 · 2026 지속가능경영보고서 유연근무제도 목록 「재택근무제(ICT 부문)」(같은 목록 「파트타임 시간제(헬스키퍼 직원 대상)」과 같은 대상 표기). 근무형태 칩 = 「재택근무 · ICT부문」(SP-SEED-6.2) — 최종 31행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanwha_systems', '한화시스템',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '방산/IT', 'H', 'https://www.hanwhasystems.com/kr/recruit/recruit2.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha_systems');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hanwhasystems.com/kr/recruit/recruit2.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 시간·휴가 (time_off) — 인사제도 행복한 일터 ──
  (@comp_id, 'refresh_leave', '안식휴가·Refresh 휴가·안식월', NULL, 'time_off',
   'est', NULL, TRUE, '일정 주기의 안식휴가 제도 운영 (공식 홈페이지 인재채용 인사제도 복리후생 행복한 일터 항목), Refresh 휴가 및 안식월 제도 (2026 지속가능경영보고서 49쪽 주요 복리후생 프로그램 항목) — 주기·일수·유급 여부 미기재', 10),
  (@comp_id, 'leave_general', '채움휴직(자기계발 휴직)', NULL, 'time_off',
   'est', NULL, TRUE, '직원의 자기계발을 위한 채움휴직 제도 운영 (공식 홈페이지 인재채용 인사제도 복리후생 행복한 일터 항목), Absence of leave for self-development (영문 홈페이지 Welfare System 항목) — 휴직 기간·급여 지급 여부 미기재', 11),

  -- ── 경제적 부가혜택 (perks) — 인사제도 행복한 일터 · 일家양득 / 영문 Welfare System / 2026 보고서 셔틀버스 ──
  (@comp_id, 'meal', '조·중·석식 제공', 432, 'perks',
   'est', '사업장 내 양질의 식사(조·중·석식) 제공 (공식 홈페이지 인재채용 인사제도 복리후생 행복한 일터 항목) — 단가·본인 부담 미기재 (추정)', FALSE, NULL, 20),
  (@comp_id, 'housing_loan', '사업장 이동 근무 시 주택대출', NULL, 'perks',
   'est', NULL, TRUE, '사업장을 이동하여 근무하는 경우 주택대출 등을 통해 주거 안정 지원 (공식 홈페이지 인재채용 인사제도 복리후생 행복한 일터 항목), 용인 R&D 센터 근무자 대상 주택 대출 (영문 홈페이지 Welfare System 항목) — 한도·금리 미기재', 21),
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '직원 가족들의 행복을 위해 복지포인트 운영 (공식 홈페이지 인사제도 일家양득 항목), 선택적 복리후생 복지포인트 (영문 홈페이지) — 배정 금액 미기재 (추정)', FALSE, NULL, 22),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 회사 지원 (영문 홈페이지 인재채용 Welfare System Contribution to personal pension plan 항목) — 지원 비율·금액 미기재', 23),
  (@comp_id, 'commute_subsidy', '셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '각 사업장에서 임직원의 출퇴근 편의를 고려해 셔틀버스 운영, 수요에 기반한 노선 설정 (2026 지속가능경영보고서 환경경영 셔틀버스 지원 항목) — 노선·본인 부담 미기재', 24),

  -- ── 건강·의료 (health) — 인사제도 건강한 일터 / 2026 보고서 임직원 건강 지원 · 마음건강 ──
  (@comp_id, 'health_check', '임직원·배우자 건강검진', 100, 'health',
   'est', '임직원 및 배우자 대상 건강검진 지원 (2026 지속가능경영보고서 주요 복리후생 프로그램 · 공식 홈페이지 인사제도 건강한 일터 항목) — 검진 비용 한도 미기재 (추정)', FALSE, NULL, 30),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '의료비 지원 제도 운영 (공식 홈페이지 인사제도 건강한 일터 항목), 직원·배우자·자녀 의료비 지원 (영문 홈페이지 Welfare System 항목) — 지원 비율·한도 미기재 (추정)', FALSE, NULL, 31),
  (@comp_id, 'mental', '마음 건강 프로그램·해피민트 서비스', NULL, 'health',
   'est', NULL, TRUE, '직원과 가족들의 건강한 마음을 위한 마음 건강 프로그램 (공식 홈페이지 인재채용 인사제도 복리후생 건강한 일터 항목), 외부 전문기관이 제공하는 통합 심리지원 프로그램 해피민트 서비스 — 모바일 애플리케이션으로 24시간 이용, 마음 돌봄 원데이클래스 (2026 지속가능경영보고서 임직원 마음건강 지원 항목)', 32),
  (@comp_id, 'fitness', '사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장 운영 (2026 지속가능경영보고서 주요 복리후생 프로그램 임직원 건강 지원 항목) — 운영 사업장·이용 조건 미기재', 33),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해 보험 (2026 지속가능경영보고서 주요 복리후생 프로그램 임직원 건강 지원 항목) — 보장 범위·가족 포함 여부 미기재', 34),

  -- ── 가족·돌봄 (family) — 인사제도 일家양득 / 2026 보고서 자녀 출산 및 양육 지원 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '집안의 경조사 지원 (공식 홈페이지 인재채용 인사제도 복리후생 일家양득 항목), 경조사 지원 (2026 지속가능경영보고서 주요 복리후생 프로그램 항목) — 경조금·경조휴가 기준 미기재', 40),
  (@comp_id, 'parenting', '배우자 출산휴가 26일·출산 축하금·임신/출산 패키지', NULL, 'family',
   'est', NULL, TRUE, '배우자 출산 휴가 26일(법정 20일에 6일 추가), 자녀 출산 축하금, 임신/출산기 업무 지원품과 축하선물로 구성된 패키지 지급(남/여성 모두) (2026 지속가능경영보고서 자녀 출산 및 양육 지원 항목) — 2025 보고서는 배우자 출산 휴가 26일을 방산 부문 대상으로 기재 · 축하금 금액 미기재', 41),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '유치원부터 대학교까지 자녀의 학자금 지원 (공식 홈페이지 인재채용 인사제도 복리후생 일家양득 항목) — 지원 한도·자녀 수 미기재', 42),
  (@comp_id, 'childcare', '직장어린이집 위탁보육', NULL, 'family',
   'est', NULL, TRUE, '직장어린이집 위탁보육 제도 (2026 지속가능경영보고서 자녀 출산 및 양육 지원 항목) — 어린이집 위치·정원 미기재', 43),
  (@comp_id, 'fertility_support', '난임 시술비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 치료/시술 시 시술비 지원 (2026 지속가능경영보고서 자녀 출산 및 양육 지원 항목) — 지원 한도·횟수 미기재', 44),

  -- ── 여가·라이프 (leisure) — 인사제도 일家양득 / 2026 보고서 가족친화 문화 조성 ──
  (@comp_id, 'resort', '휴양소·워터파크·한화리조트', 50, 'leisure',
   'est', '휴양소, 워터파크 운영 (공식 홈페이지 인사제도 일家양득 항목), 한화리조트·승마장 이용 혜택 (2026 지속가능경영보고서) — 할인율·이용 횟수 미기재 (추정)', FALSE, NULL, 50),

  -- ── 근무 유연성 (flexibility) — 인사제도 자율적 근무환경 / 2026 보고서 유연근무제도 ──
  (@comp_id, 'flex_work', '선택적·탄력적 근로시간제·시차출근제', NULL, 'flexibility',
   'est', NULL, TRUE, '주 단위로 근무시간을 자유롭게 선택하는 선택적 근로시간제, 2주/3개월 단위로 근무시간을 탄력적으로 조정하는 탄력적 근로시간제 (공식 홈페이지 인재채용 인사제도 복리후생 자율적 근무환경 항목), 시차출근제, 재량(간주)근로시간제 (2026 지속가능경영보고서 유연근무제도 항목)', 60),
  (@comp_id, 'remote_work', '재택근무제 (ICT부문)', NULL, 'flexibility',
   'est', NULL, TRUE, '육아와 업무를 병행하는 재택근무제 (공식 홈페이지 인재채용 인사제도 복리후생 자율적 근무환경 항목), 재택근무제 ICT 부문 대상 (2026 지속가능경영보고서 유연근무제도 항목) — 사용 일수 미기재', 61),
  (@comp_id, 'pc_off', 'PC-off 제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-off제도 운영 (2026 지속가능경영보고서 주요 복리후생 프로그램 가족친화 문화 조성 항목) — 적용 시간 미기재', 62),

  -- ── 성장·교육 (growth) — 인사제도 교육제도 / 2026 보고서 대학원 진학 · 전문자격 · 학습조직 ──
  (@comp_id, 'mba', '학술연수·대학원 교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '재직 중 국내 석사/박사과정 지원, 재직 기간 중 학위 취득 (공식 홈페이지 인재채용 인사제도 학술연수 제도 항목), 모든 정규직 임직원 대상 서류 심사와 면접으로 선발해 대학원 교육비 지원, ICT 부문은 등록금·수업료·원우회비 등 학기별 지원 (2026 지속가능경영보고서 대학원 진학 제도 항목)', 70),
  (@comp_id, 'career', 'Global Talent Program (해외 파견)', NULL, 'growth',
   'est', NULL, TRUE, '한화그룹이 운영하는 글로벌 리더 양성 프로그램, 우수 직원의 글로벌 역량강화를 위해 한화그룹 내 해외 법인 및 지사에 파견, 3개월 이상 사전 교육 후 미국·독일·중국·일본 등에서 1~2년간 주재 근무 (공식 홈페이지 인재채용 인사제도 Global Talent Program 항목) — 선발 기준 미기재', 71),
  (@comp_id, 'self_development', '전문자격 취득 지원·학습조직 활동비', NULL, 'growth',
   'est', NULL, TRUE, '모든 정규직 임직원 대상 자격증 등급에 따라 온·오프라인 교육비 및 응시료, 합격 축하금 지원 (2026 지속가능경영보고서 전문자격 취득 지원 제도 항목), ICT 부문 학습조직(Hi.Lite) 참가자에게 매월 1인당 3만 원의 활동비와 도서 구입 비용 지원 (같은 보고서 학습조직 운영 항목)', 72),
  (@comp_id, 'lang', '사외 어학 학습비·전화/화상 어학·OPIc 응시 지원', NULL, 'growth',
   'est', NULL, TRUE, '방산 부문 전 임직원 대상 사외 어학 학습 비용 지원, ICT 부문 전 임직원 대상 전화/화상 어학·이러닝 교육·OPIc 응시 지원 (2026 지속가능경영보고서 45쪽 글로벌 어학 제도 항목) — 지원 한도·대상 어학 미기재', 73),
  (@comp_id, 'edu_support', '사내 교육 플랫폼 (채널 H+)', NULL, 'growth',
   'est', NULL, TRUE, '계약직·정규직을 포함한 전 임직원 대상 자기계발과 자기주도적 학습을 지원하는 사내 교육 플랫폼(채널 H+) 운영 (2026 지속가능경영보고서 47쪽 직무 역량 강화를 위한 교육 제공 항목) — 과정 분야·수강 방식 미기재', 74),

  -- ── 보상·금전 (compensation) — 2026 보고서 성과평가 및 보상 · RSU 및 ESOP ──
  (@comp_id, 'incentive', '현금성 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '계약직을 포함한 전 임직원 대상 성과 수준에 따라 연봉등급과 현금성 성과급 차등 지급, 매년 2월 전년도 개인 업적 성과 기반 지급 (2026 지속가능경영보고서 성과평가 및 보상 제도 항목) — 지급 기준·지급률 미기재', 80),
  (@comp_id, 'stock_option', '우리사주제도(ESOP)', NULL, 'compensation',
   'est', NULL, TRUE, '전사 임직원 대상 우리사주조합을 통한 우리사주제도 운영, 희망 임직원 대상 우리사주청약 기회와 대출이자 지원 (2026 지속가능경영보고서 RSU 및 ESOP 제도 운영 항목)', 81),
  (@comp_id, 'excellence_award', 'Future Changer 시상', NULL, 'compensation',
   'est', NULL, TRUE, '도전적이고 혁신적으로 업무를 수행했거나 우수한 성과를 낸 팀과 직원을 분기별로 선발해 상장과 상금 제공 (2025 지속가능경영보고서 도전적 문화 구축 Future Changer 항목), 연말시상식 Great Challenger (2026 지속가능경영보고서 인재상 항목) — 상금 금액 미기재', 82),

  -- ── 근무환경 (work_env) — 영문 Welfare System / 2026 보고서 자녀 출산 및 양육 지원 ──
  (@comp_id, 'dormitory', '구미사업장 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '구미사업장 근무자 대상 기숙사 (영문 홈페이지 인재채용 Welfare System dormitory 항목) — 입주 조건·비용 부담 미기재', 90),
  (@comp_id, 'nap_room', '수유 시설', NULL, 'work_env',
   'est', NULL, TRUE, '수유 시설 운영 (2026 지속가능경영보고서 자녀 출산 및 양육 지원 항목) — 운영 사업장 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
