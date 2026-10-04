-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG디스플레이 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.lgdisplay.com/kor/company/employ/pms-benefit
-- badge: est
--
-- 참고:
--   정본은 LG디스플레이 법인 자기 도메인 www.lgdisplay.com 의 COMPANY > 채용 > 복지제도 > 복리후생 페이지
--   (/kor/company/employ/pms-benefit)다. 생활 지원 · 자기 계발 · 모 부성보호 · 여가 · 건강 다섯 묶음 29항목을 담은
--   서버 렌더 HTML 이다. 헤드리스 렌더 불필요. robots 는 전 경로 허용(User-agent * Allow /).
--   같은 메뉴의 인사제도 > 인사원칙(/kor/company/employ/pms-principle) · 인재육성(/kor/company/employ/pms-develop)
--   페이지가 보상 · 근무시간 · 휴가 · 학위 파견 항목을 싣는다.
--   보조 출처: 2026 LG디스플레이 ESG Report 국문 PDF(같은 도메인 /attachment/esg/csm/LGD_ESG_report_2026_kor.pdf)
--     36 · 50 · 54 · 55 · 56쪽 — 복리후생 제도 표 · 모성 보호 제도 · 건강관리 · 보상 · 포상.
--   그룹 통합 채용 careers.lg.com 은 근거로 쓰지 않았다 — 법인 자기 도메인에 정본이 있다. 다른 LG 계열사 문구는 옮기지 않았다.
--   ESG 인적자본 페이지의 복지 제도 절은 자회사 나눔누리 제도라 쓰지 않았다.
--   금액: 원문 명시 연 환산 금액 0건. 승계 추정치 8행(incentive 500 · commute_subsidy 120 · welfare_point 200 ·
--     child_edu 300 · resort 50 · medical 100 · health_check 100 · insurance 30 — 모두 같은 값을 추정치로 쓴 다른 회사가
--     3곳 이상, NOTE 끝에 (추정)). event 50 은 1회성 경조금이라 NULL.
--   재코딩 1: summer_leave → refresh_leave (구본 유급하계휴가 4일 = 현행 원문 Refresh 휴가 4일, 연중 사용 · 별도 부여).
--   구본에서 뺀 행: edu_support(회사 주도 직무 · 리더십 교육 과정). 구본 housing_loan 의 사택 · 기숙사 서술은 dormitory 로 나눴다.
--   법정 제도 제외: 임신기 · 육아기 근로시간 단축 · 배우자 출산휴가 · 출산 전후 휴가 · 난임치료 휴가 기본 일수 ·
--     가족 돌봄 휴가 휴직 · 휴가 사용 촉진(LGD 휴가일) · 특수건강검진 · 재취업 지원 서비스(1,000인 이상 의무).
--   SORT 섹션 순서 = 정본 복리후생 페이지에서 카테고리가 처음 나온 순서(perks 10 · work_env 20 · family 30 · leisure 40 ·
--     growth 50 · time_off 60 · health 70), 이어서 인사원칙 페이지(compensation 80 · flexibility 90).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-4): ESG Report 55쪽 통근 지원의 교통비 지급을 transport 행으로 나눔 · 인사원칙 Turn Off 휴가를 leave_general 행에 보탬 · fitness 서술에서 보고서 동일시 구절 뺌 — 최종 34행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 서술 · 이름 수정 2(fertility_support · lang) — 최종 34행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_display', 'LG디스플레이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '디스플레이', 'L', 'https://www.lgdisplay.com/kor/company/employ/pms-benefit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_display');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lgdisplay.com/kor/company/employ/pms-benefit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'commute_subsidy', '통근버스·주말 귀향버스', 120, 'perks',
   'est', '전 사업장 통근버스 운영 (공식 채용 페이지 복리후생 생활 지원 항목), 출퇴근 통근버스·주말 귀향버스 운영 (2026 ESG Report 55쪽) — 노선·운행 사업장 미기재 (추정)', FALSE, NULL, 10),
  (@comp_id, 'housing_loan', '주택 융자금 이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택 융자금 이자 지원 (공식 채용 페이지 복리후생 생활 지원 항목). 2026 ESG Report 55쪽에는 구성원의 주거안정을 위한 주택 구입·임차 자금 지원으로 기재 — 융자 한도·이율 미기재', 11),
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '개인별 다양한 Needs를 충족시키기 위한 복지 포인트 지급 (공식 채용 페이지 복리후생 생활 지원 항목 · 2026 ESG Report 55쪽 — 연간 포인트 금액 미기재) (추정)', FALSE, NULL, 12),
  (@comp_id, 'discount', 'LG전자 제품 할인·제휴 할인', NULL, 'perks',
   'est', NULL, TRUE, '호텔·항공 등 다양한 제휴 할인 (공식 채용 페이지 복리후생 여가 항목), LG전자 제품 구매 시 할인 지원 (2026 ESG Report 55쪽) — 할인율 미기재', 13),
  (@comp_id, 'team_dinner', '조직행사 비용 지원', NULL, 'perks',
   'est', NULL, TRUE, '야유회·팀워크 행사 등 조직행사 비용 지원 (2026 ESG Report 55쪽 복리후생 제도) — 지원 금액·횟수 미기재', 14),
  (@comp_id, 'transport', '교통비 지급', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근을 위한 교통비 지급 (2026 ESG Report 55쪽 복리후생 제도 통근 지원 항목) — 지급 대상·금액 미기재', 15),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '구미·파주 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '구미·파주 사업장 기숙사 운영 (공식 채용 페이지 복리후생 생활 지원 항목 — 입주 조건·비용 부담 미기재)', 20),
  (@comp_id, 'nap_room', '임산부 전용 휴게실·수유시설', NULL, 'work_env',
   'est', NULL, TRUE, '임산부를 위한 전용 휴게실과 사업장 내 수유 시설 운영 (2026 ESG Report 56쪽 국내 임산부 직원 지원) — 설치 사업장 미기재', 21),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '임신·육아기 휴직 최대 2년 6개월·임산부 출퇴근 지원·입학 선물', NULL, 'family',
   'est', NULL, TRUE, '임신·육아기 휴직 자녀 1인당 최대 2년 6개월, 임산부 출퇴근 지원(통근버스 전용 좌석·전용 주차장 등), 임신·출산 선물, 자녀 입학 시 노트북 지급 (공식 채용 페이지 복리후생 생활 지원·모·부성보호 항목). 2026 ESG Report 54~56쪽에는 육아휴직 기본 2년, 초·중·고 입학 자녀 전자제품 선물과 초등학교 입학 자녀 학용품 선물, 본인 또는 배우자가 출산할 때와 직계 가족 수능 때 축하 선물, 초등학교 6학년(만 12세 이하) 자녀를 둔 구성원이 조기퇴근 뒤 재출근해 자율적으로 근무하는 육아기 자율근무제로 기재 — 휴직 중 급여·선물 금액 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', 300, 'family',
   'est', '중·고·대학생 자녀 학자금 지원 (공식 채용 페이지 복리후생 생활 지원 항목 · 2026 ESG Report 55쪽 — 지원 한도·자녀 수 미기재) (추정)', FALSE, NULL, 31),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '본인·가족 경조사 지원 (공식 채용 페이지 복리후생 생활 지원 항목). 2026 ESG Report 55쪽에는 경조사 발생 시 경조금과 경조 물품 지원, 구성원 사망사고 발생 시 상호 부조금 지원으로 기재 — 경조 종류별 금액 미기재', 32),
  (@comp_id, 'fertility_support', '난임 휴가·휴직', NULL, 'family',
   'est', NULL, TRUE, '난임 치료 휴가 유급 3일(법정 유급 2일에 1일 추가), 난임 휴직 180일 이하 무급 (공식 채용 페이지 복리후생 모·부성보호 항목) — 난임 시술비 지원 여부 미기재', 33),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '전 사업장 사내 어린이집 운영 (공식 채용 페이지 복리후생 모·부성보호 항목). 2026 ESG Report 56쪽에는 사업장 내 보육시설 운영으로 기재 — 정원·보육료 부담 미기재', 34),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양소 지원금', 50, 'leisure',
   'est', '휴양소 지원금 지급 (공식 채용 페이지 복리후생 생활 지원 항목), 휴양시설 회원권과 이용 비용 지원 (2026 ESG Report 55쪽 — 지원 금액 미기재) (추정)', FALSE, NULL, 40),
  (@comp_id, 'library', '전자책 도서관', NULL, 'leisure',
   'est', NULL, TRUE, '전자책 도서관 운영 (공식 채용 페이지 복리후생 자기 계발 항목 — 이용 범위 미기재)', 41),
  (@comp_id, 'sports_ticket', 'LG트윈스·FC 서울 스포츠 티켓', NULL, 'leisure',
   'est', NULL, TRUE, 'LG트윈스·FC 서울 스포츠 티켓 지급 (공식 채용 페이지 복리후생 여가 항목 — 지급 횟수·좌석 미기재)', 42),
  (@comp_id, 'club', '사내 동호회 (Informal Group)', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회(Informal Group) 운영 (공식 채용 페이지 복리후생 여가 항목). 2026 ESG Report 54~55쪽에는 휴식과 여가 활동을 위한 동호회 활동 지원과 다양한 사내 스포츠 동호회로 기재 — 활동비 지원 금액 미기재', 43),
  (@comp_id, 'company_event', '가족 초청 행사', NULL, 'leisure',
   'est', NULL, TRUE, '구성원 부모님·자녀와 함께 참여하는 다양한 사내 초청 행사 (2026 ESG Report 54쪽 가족 친화 프로그램) — 행사 횟수 미기재', 44),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', 'YBM 어학 할인·사내 어학', NULL, 'growth',
   'est', NULL, TRUE, 'YBM 어학 할인 지원 (공식 채용 페이지 복리후생 자기 계발 항목), 사내 어학 교육 (2026 ESG Report 51쪽 교육 체계 글로벌 항목) — 할인율·대상 과정·사내 과정 운영 방식 미기재', 50),
  (@comp_id, 'mba', '국내외 석·박사 학위 파견', NULL, 'growth',
   'est', NULL, TRUE, '신기술 학습과 역량 개발을 위한 국내외 석·박사 학위 파견 (공식 채용 페이지 인재육성 항목 — 선발 기준·비용 부담 범위 미기재)', 51),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '자기 계발 휴직·Turn Off 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '근속 5년 이상 구성원 대상 최대 1년 자기 계발 휴직 (공식 채용 페이지 복리후생 자기 계발 항목, 2026 ESG Report 55쪽 자기계발·재충전 휴직), 연 1회 이상 1주 이상 장기 휴가를 쓰는 Turn Off 휴가 (같은 채용 페이지 인사원칙 항목) — 휴직 중 급여·Turn Off 별도 부여 일수 미기재', 60),
  (@comp_id, 'long_service_leave', '장기근속 포상 (휴가·포상금·해외여행)', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상 제도로 휴가·포상금·기념패·해외여행 제공 (공식 채용 페이지 복리후생 여가 항목 · 2026 ESG Report 55쪽) — 근속 구간·휴가 일수·포상 금액 미기재', 61),
  (@comp_id, 'refresh_leave', 'Refresh 휴가 4일', NULL, 'time_off',
   'est', NULL, TRUE, '연중 언제든 사용 가능한 4일 휴가를 별도로 제공 (공식 채용 페이지 인사원칙 스마트하게 일하고 쉽니다 항목)', 62),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'fitness', '사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장 운영 (공식 채용 페이지 복리후생 여가 항목) — 운영 사업장·이용료 미기재', 70),
  (@comp_id, 'clinic', '사내 병원', NULL, 'health',
   'est', NULL, TRUE, '사내 병원 운영 (공식 채용 페이지 복리후생 건강 항목). 2026 ESG Report 36쪽에는 사내 부속의원과 건강관리실에서 일반 진료와 만성질환 관리 등 의료 서비스 제공으로 기재 — 설치 사업장·진료 과목 미기재', 71),
  (@comp_id, 'mental', '사내 심리상담실', NULL, 'health',
   'est', NULL, TRUE, '사내 심리상담실 운영 (공식 채용 페이지 복리후생 건강 항목). 2026 ESG Report 36쪽·54쪽에는 마음사랑상담실과 지역별 심리 상담실에서 정신건강 상담 제공으로 기재 — 상담 횟수·가족 포함 여부 미기재', 72),
  (@comp_id, 'medical', '본인·가족 의료비 지원', 100, 'health',
   'est', '본인·가족 의료비 지원, 질병 휴직 중 임금 일부 지원 (공식 채용 페이지 복리후생 건강 항목), 암·희귀질환 등 중증 질환 발생 시 의료 지원과 보상 (2026 ESG Report 36쪽) — 한도 미기재 (추정)', FALSE, NULL, 73),
  (@comp_id, 'health_check', '종합 건강검진 (본인·배우자)', 100, 'health',
   'est', '본인·배우자 종합 건강검진 제공 (공식 채용 페이지 복리후생 건강 항목), 검진일 유급휴가 부여 (2026 ESG Report 55쪽) — 검진 주기·비용 한도 미기재 (추정)', FALSE, NULL, 74),
  (@comp_id, 'insurance', '임직원 단체 보험', 30, 'health',
   'est', '임직원 단체 보험 가입 (공식 채용 페이지 복리후생 건강 항목 · 2026 ESG Report 55쪽 — 보장 내용 미기재) (추정)', FALSE, NULL, 75),
  (@comp_id, 'massage', '사내 마사지 서비스', NULL, 'health',
   'est', NULL, TRUE, '사내 마사지 서비스 운영 (공식 채용 페이지 복리후생 건강 항목). 2026 ESG Report 54쪽에는 사내 마사지실 운영으로 기재 — 이용 횟수 미기재', 76),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', 'Incentive (개인·조직 성과 보상)', 500, 'compensation',
   'est', '개인과 조직 성과에 따른 보상 (공식 채용 페이지 인사원칙 연봉 구조 항목), 전 구성원 대상 다양한 인센티브 제공 (2026 ESG Report 50쪽) — 지급 기준·지급률 미기재 (추정)', FALSE, NULL, 80),
  (@comp_id, 'excellence_award', '부문 포상·LG디스플레이 Award', NULL, 'compensation',
   'est', NULL, TRUE, '팀 단위 부문 포상, 혁신과제 우수 단체·개인 포상, 전사 우수 성과에 대한 LG디스플레이 Award 운영 (2026 ESG Report 50쪽 성장 지원 프로그램) — 포상 금액 미기재', 81),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '개인 일정을 고려해 자율적으로 출퇴근 시간을 조정하는 선택적 근로시간제 (공식 채용 페이지 인사원칙 항목). 2026 ESG Report 55쪽에는 일정 범위 내에서 근무시간이나 업무량을 조정하는 탄력적 근로시간제도 함께 운영한다고 기재 — 코어 타임·정산 기간 미기재', 90),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 등 원격근무제 운영 (2026 ESG Report 55쪽 유연한 근무제도) — 대상 직무·사용 일수 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
