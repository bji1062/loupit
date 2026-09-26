-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK하이닉스 복리후생 데이터
-- 출처: AI 파싱 (2026-09-26)
-- URL: https://talent.skhynix.com/hub/ko/culture/welfare
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 정본은 SK하이닉스 자기 도메인 채용 허브(SK hynix Talent Hub, 2026-03 신설)의 국문 복지 제도 페이지다.
--       robots Allow: /hub/ · 정적 HTML(curl) · 같은 항목이 모바일/PC 두 블록으로 반복돼 한 벌만 셌다.
--       2026-09-26 재수신 sha256 da17bc1e…3a66770 = 2026-09-25 대조 사본과 동일.
--       보조 출처 = 회사 발간 SK하이닉스 지속가능경영보고서 2026(국문 PDF, sustainability.skhynix.com 데이터센터)
--       p.44 글로벌 인재 육성 · p.48 구성원 행복과 복리후생 · p.49 The Series · p.51 일·생활 균형 ·
--       p.54 구성원 평가·보상 · p.59 하이헬스 앱. 영문 본사 Benefits 페이지(skhynix.com/careers/UI-FR-CR0204)는
--       정본의 영문판이라 fitness 행의 사진 설명 On-site fitness facilities 에만 썼다.
--       자기 법인 도메인·자기 법인 보고서라 그룹 통합 채용 기준 각주는 달지 않았다.
--       금액: 공식 원문에 연 환산 가능한 금액 0건. 금액 정책 (a)로 추정치 8행을 승계했다(NOTE 에 추정 표기).
--       성과급 금액은 승계하지 않았다 — 연봉의 0~50% 는 보고서 p.95 이사 보수표의 TI 상한이다.
--       시설 나열형 구본 행(편의시설·부속의원·경조사·동아리·카페·문화시설)은 정본·보고서·영문 페이지·FAQ 에 근거가 없어 뺐다.
--       법정 제도(난임휴가 6일·유산사산휴가·태아 검진 휴가·퇴직연금·연차)는 행과 서술 어디에도 넣지 않았다.
-- 재수집(2026-09-26): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다 — 대조 보고서 2026-09-25-official-compare
-- 감사(RA-1 2026-09-26) 반영: incentive 500 추정 승계(9사 공통 앵커) · welfare_point 조건 서술의 연차를 휴가로 · meal 432 미승계(원문에 3식 표기가 없다 — 조식부터 야식까지는 범위라 SI-9 기준 미달, 리드 판정)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sk_hynix', 'SK하이닉스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '반도체', 'S', 'https://talent.skhynix.com/hub/ko/culture/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_hynix');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://talent.skhynix.com/hub/ko/culture/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제·Happy Friday', NULL, 'flexibility',
   'est', NULL, TRUE, '구성원이 직접 일하는 시간을 설계하는 유연근무제. 1~4주 단위 선택적 근로시간제(1일 최소 근로시간 1시간, 오전 6시~오후 10시 사이 자율 근무), 매월 두 번째 금요일 Happy Friday(의무 근로시간 충족 시 휴무) (공식 채용 페이지 복지 제도 업무 항목·지속가능경영보고서 2026)', 10),
  (@comp_id, 'satellite_office', '거점오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '캠퍼스 외 업무 공간이 필요한 구성원이 자택 근처에서 일할 수 있는 거점오피스. 서울 을지로·고려대·서강대·분당 4개소와 이천·청주·분당 사업장 내 공유 오피스 (공식 채용 페이지 복지 제도 업무 항목·지속가능경영보고서 2026)', 11),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'office_furniture', '허먼밀러 의자', NULL, 'work_env',
   'est', NULL, TRUE, '전 구성원 허먼밀러 의자 지원 (공식 채용 페이지 복지 제도 업무 항목)', 20),
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 운영. 기숙사에서 생활하는 구성원 대상 기숙사 내 고담극장 공연과 The Studio 문화강좌 (지속가능경영보고서 2026 — 입주 자격·비용·호실 구성 미기재)', 21),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '사내식당 및 편의식', NULL, 'perks',
   'est', NULL, TRUE, '조식부터 야식까지 모든 캠퍼스에서 식사 또는 편의식 제공, 균형 잡힌 영양 식단의 건강한 밥상 운영 (본인 부담 여부 미기재)', 30),
  (@comp_id, 'commute_subsidy', '리무진 통근 버스', 120, 'perks',
   'est', '리무진 통근 버스 운영, 자율 출퇴근 셔틀 확장 (연 120만원 추정)', FALSE, NULL, 31),
  (@comp_id, 'housing_loan', '주택 및 결혼자금 융자', NULL, 'perks',
   'est', NULL, TRUE, '주택 임대·구매 시 필요 자금과 결혼 자금 저금리 융자, 자녀 3명 이상 구성원 최대 2억원 특별 주택 융자 (공식 채용 페이지 복지 제도 생활 항목·지속가능경영보고서 2026 — 일반 융자 한도·금리 미기재)', 32),
  (@comp_id, 'pension_support', '개인연금 지원', 50, 'perks',
   'est', '회사가 마련한 개인연금 상품 가입 시 재직 중 보험 납입 기간 동안 보험료 절반 회사 지원 (연 50만원 추정)', FALSE, NULL, 33),
  (@comp_id, 'telecom', '통신비', NULL, 'perks',
   'est', NULL, TRUE, '원활한 업무 수행을 위한 소정의 통신비 지원 (공식 채용 페이지 복지 제도 생활 항목 — 지원 금액 미기재)', 34),
  (@comp_id, 'welfare_point', 'SK hywel Point', 200, 'perks',
   'est', '매년 SK hywel Point 지급 — 복지 콘텐츠·외부 제휴 서비스 이용, 휴가 사용 리워드로 휴가 사용률에 따라 최대 60만 복지 포인트 (연 200만원 추정)', FALSE, NULL, 35),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'fertility_support', '난임 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 컨시어지 서비스(치료 정보·행정 지원·지역별 제도 안내), 난임휴직 최대 1년, 난임 치료비 횟수 제한 없이 100% 지원 (공식 채용 페이지 복지 제도 난임&임신 지원 항목·지속가능경영보고서 2026)', 40),
  (@comp_id, 'parenting', '임신·출산·육아 지원', NULL, 'family',
   'est', NULL, TRUE, '임신 전 기간 근로시간 단축, 임신 중 영양제 지원, 임신·출산 쉼터 도담이방 41곳, 출산 의료비·분만 비용 100% 지원, 배우자 출산휴가 25일(자녀 수 무관), 임산부·신생아 축하 패키지, 자녀 수에 따라 늘어나는 출생 축하금, 산후 1년 미만 유연 출근제, 특별 육아휴직 1년 추가, 초등 입학 자녀 돌봄휴직, 복직자·부모 구성원 소프트랜딩 프로그램과 심리 상담·코칭, 유아교육기관부터 초·중·고 진학 자녀 입학 축하금, 다자녀 양육 저축 상품 보험료 50% 지원 (공식 채용 페이지 복지 제도 출산&육아 지원·입학 축하금 및 학자금 항목, 지속가능경영보고서 2026 — 축하금 금액·돌봄휴직 기간 미기재)', 41),
  (@comp_id, 'child_edu', '자녀 학자금', 300, 'family',
   'est', '중·고등학교와 대학교 재학 자녀 등록금 지원, 중증장애 자녀 교육비 지원 (연 300만원 추정)', FALSE, NULL, 42),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사업장별 직장 어린이집, 수유 시설, 산모 휴게실 운영 (지속가능경영보고서 2026 — 운영 사업장·입소 연령·정원 미기재)', 43),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합검진', 100, 'health',
   'est', '전 구성원 종합검진 제도 운영, 일부 검진 항목은 직계 가족에게도 제공 (연 100만원 추정)', FALSE, NULL, 50),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '본인 연간 1억원, 배우자와 자녀 연간 5,000만원 한도 의료비 지원, 동의한 본인은 별도 신청 없이 건강보험공단 자료 기반 자동 지원 (연 100만원 추정)', FALSE, NULL, 51),
  (@comp_id, 'fitness', '사내 헬스장', NULL, 'health',
   'est', NULL, TRUE, '사내 헬스장 운영, 건강관리 앱 하이헬스와 이용 내역 연동 (지속가능경영보고서 2026·공식 영문 채용 페이지 Benefits — 운영 사업장·이용 조건 미기재)', 52),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', 'Refresh 휴양 시설', 50, 'leisure',
   'est', '전국 호텔·콘도·리조트·놀이터·하계 휴양소 등 제휴 지점 저렴한 가격 이용, SK아카데미 유휴 일정을 활용한 1박 2일 구성원 휴양소 The Camp (연 50만원 추정)', FALSE, NULL, 60),
  (@comp_id, 'company_event', '캠퍼스 공연·가족 초청 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '초대 가수·구성원 공연이 캠퍼스에서 열리는 캠퍼스 비긴어게인, 캠퍼스 내 오페라·클래식·재즈 공연 The Concert, 이천·청주 캠퍼스 가족·지인 초청 투어 The Open, 매년 어린이날 놀이공원 이용권 등 가족 선물 (공식 채용 페이지 복지 제도 소통 항목·지속가능경영보고서 2026 — 개최 주기 미기재)', 61),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'mba', '대학 학위 과정 및 Global Program', NULL, 'growth',
   'est', NULL, TRUE, '국내외 학위과정 지원과 Global Program 운영, GIP 해외 대학 연구기관 기술 교류·해외 대학 교육과정 참여 최대 1년 단기 해외 연수 (공식 채용 페이지 복지 제도 성장 항목·지속가능경영보고서 2026 — 선발 기준·비용 지원 범위 미기재)', 70),
  (@comp_id, 'career', 'Career Growth Program', NULL, 'growth',
   'est', NULL, TRUE, '원하는 직무로 전환하거나 경력을 재설계하도록 지원하는 사내 경력 개발 프로그램 CGP(사내 공모)와 희망 조직 사전 등록 CGP-Up, 해외법인·해외 협력사에서 최대 5주 현지 업무를 수행하는 GXP (공식 채용 페이지 복지 제도 성장 항목·지속가능경영보고서 2026)', 71),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 휴가 5년마다 10일, 10년마다 최대 3주 (지속가능경영보고서 2026 — 휴가비 지급 여부 미기재)', 80),
  (@comp_id, 'leave_general', '시간 단위 휴가·휴가 자가 승인', NULL, 'time_off',
   'est', NULL, TRUE, '시간 단위 단기 휴가, 휴가 자가 승인 제도, 교대근무 구성원 대상 야간 근무 Care 휴가 연간 최대 6일 (지속가능경영보고서 2026 — 최소 사용 시간 단위 미기재)', 81),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '인센티브(PI/PS)', 500, 'compensation',
   'est', 'PI(Productivity Incentive)·PS(Profit Sharing) 등 경영 성과와 연계한 인센티브 제도 운영, 지급률·지급 기준 미기재 (연 500만원 추정)', FALSE, NULL, 90),
  (@comp_id, 'stock_option', '우리사주·PS 자사주 선택 수령', NULL, 'compensation',
   'est', NULL, TRUE, '전 구성원 대상 우리사주 매수 선택권 부여(2007년·2021년), 2025년 말 기준 1만 2,481명 가입. 2023년부터 PS 일부를 자사주로 선택 수령하고 일정 기간 보유 시 추가 현금 인센티브 제공 (지속가능경영보고서 2026 — 향후 배정 계획·가입 조건 미기재)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
