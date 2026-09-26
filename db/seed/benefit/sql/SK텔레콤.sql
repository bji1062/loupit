-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK텔레콤 복리후생 데이터
-- 출처: AI 파싱 (2026-09-26)
-- URL: https://careers.sktelecom.com/skEnjoy/support
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
--
-- 참고:
--   정본은 상장 법인 SK텔레콤(KOSPI 017670) 자기 채용 사이트 careers.sktelecom.com 의 복리후생 페이지다
--   (GNB 복리후생 → 탭 3개 행복지원 8 · 생활지원 7 · 업무지원 3 = 18항목). 정적 HTML 이라 탭 3개가
--   원본에 모두 들어 있다 — 헤드리스 불필요. robots 는 Allow: /skEnjoy/ (나머지 Disallow: /).
--   게시일 표기 없음(자산 sub.css?v=20240726). 그룹 통합 채용 포털(SK Careers)이 아니라 법인 전용
--   사이트라 그룹 각주를 달지 않는다(푸터 주소·대표이사·저작권 SK TELECOM CO., LTD.).
--   보조 공식 출처(전부 자기 도메인):
--     ① SK텔레콤 지속가능경영보고서 2025 (www.sktelecom.com PDF, 경로상 2026-07-15 게시 — 가장 새 공식 문서)
--        p.76·79 교육·학위·정년퇴직 지원, p.81 DYWT·거점 오피스, p.85 건강 관리, p.91 출산·육아, p.213 웰빙 프로그램 표
--     ② www.sktelecom.com/view/safety-health/employee-health.do (임직원 건강증진, CSR 렌더)
--     ③ news.sktelecom.com 공식 뉴스룸 기사(2020~2026) · ④ careers.sktelecom.com/skEnjoy/thumbUpDetail 구성원 이야기
--        (저작권 SK텔레콤 표기 글만 채택. thumbUpDetail/80 은 잡플래닛 어워드 기사체 글이라 금액 근거에서 뺐다)
--   금액: 원문 명시값 0건. 금액 4행은 구본 추정치 승계(건강검진 100·의료비 200·자녀학자금 300·휴양시설 50,
--     NOTE 말미 (추정)). 복리후생비 400(구본 stated)은 유일한 숫자 근거가 3자 작성 기사라 승계하지 않았다.
--   코드: 구본 discount(자사 서비스 할인) → sports_ticket + car_rental 분리 재코딩 ·
--     구본 long_service_leave 의 포인트 선택분 → long_service_bonus 분리 · 신규 코드 0.
--   구본에서 뺀 행: excellence_award(IDEATHON) · refresh_leave(체력단련 휴가) · club(소모임) ·
--     edu_support(사내 교육 과정 — 비용 지원 아님) · snack_bar(더 라운지와 같은 시설 — lounge 로 합침).
--   SORT 섹션 순서는 정본 페이지에서 그 카테고리가 처음 나온 순서다
--     (flexibility 10 · time_off 20 · perks 30 · health 40 · leisure 50 · family 60 · work_env 70 ·
--      growth 80 · compensation 90).
-- 재수집(2026-09-26): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다 — 대조 보고서 2026-09-25-official-compare
-- 감사(RA-1 2026-09-26) 반영: 더 라운지 카페 snack_bar 분리(추정 50 승계) · 사내공모제도 career · 성과급 incentive · SUPEX 추구상 excellence_award 추가 · 정년퇴직 지원에서 법정 재취업지원 프로그램 문구 제거
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op, 3) 의 UPDATE 가 URL 을 채운다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('skt', 'SK텔레콤',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '통신', 'S', 'https://careers.sktelecom.com/skEnjoy/support');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'skt');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://careers.sktelecom.com/skEnjoy/support'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', 'Work Planner·DYWT 선택근무제·Focus Day', NULL, 'flexibility',
   'est', NULL, TRUE, 'Work Planner — 1개월 단위 근무시간을 자율적으로 계획하고 매일 스스로 근무시간 설정 (공식 채용 페이지 업무지원 항목). DYWT(Design Your Work & Time) 선택근무제 — 월 단위 소정근로시간 범위 안에서 업무 시간과 스케줄 설계, 출퇴근 시간 자율 결정 (2025 지속가능경영보고서), 근무 계획 10분 단위 설정 (공식 뉴스룸 2021년 기사). 매달 둘째·넷째 주 금요일 Focus Day — 일과 휴식, 자기개발 모두에 집중하는 날 (공식 채용 페이지 행복지원 항목. 2025 지속가능경영보고서에는 Happy Friday 제도, 공식 뉴스룸 2024년 기사에는 쉴 수 있는 날로 기재)', 10),
  (@comp_id, 'remote_work', '재택근무 (WFA)', NULL, 'flexibility',
   'est', NULL, TRUE, '더 몰입할 수 있는 장소를 스스로 선택해 근무하는 재택근무 제도 운영 (2025 지속가능경영보고서). 공식 채용 사이트 거점오피스 소개 글에는 메인 오피스, 재택, 거점오피스 스피어 3가지 중 일하는 장소를 고르는 WFA(Work from Anywhere)로 기재 — 재택 허용 일수·신청 조건 미기재', 11),
  (@comp_id, 'satellite_office', '거점오피스 Sphere', NULL, 'flexibility',
   'est', NULL, TRUE, '거점 오피스 Sphere 운영, 2025년 기준 보라매·성수·분당·판교 4개소 (2025 지속가능경영보고서). 앱 좌석 예약과 얼굴 인식 출입, 개인 PC 없이 쓰는 iDesk 좌석 (공식 뉴스룸 2022년 기사)', 12),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', 'Refresh 휴가 (근속 5년마다)', NULL, 'time_off',
   'est', NULL, TRUE, '근속 만 5년마다 Refresh 휴가 제공 (공식 채용 페이지 행복지원 항목 Refresh 제도). 입사 후 5년에 한 번씩 10일에서 30일의 장기 휴가 부여 (2025 지속가능경영보고서 구성원 행복 제고 프로그램 표). 공식 채용 사이트 구성원 인터뷰에는 유급 안식 휴가로 소개', 20),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'car_rental', '해피쉐어카', NULL, 'perks',
   'est', NULL, TRUE, '회사 차를 업무시간 전후 또는 휴일에 개인용으로 이용, 최소 실비만 부담 (공식 채용 페이지 행복지원 항목 해피쉐어카). 공식 채용 사이트 구성원 인터뷰에는 전국 지사 차량 이용으로 소개 — 이용 요금·차종·신청 방법 미기재', 30),
  (@comp_id, 'welfare_point', '복리후생비 (선택적 복리후생)', NULL, 'perks',
   'est', NULL, TRUE, '여행, 자기계발, 가족건강검진, 연휴 귀성비용 등 구성원의 삶의 질을 높이는 데 필요한 비용 지원 (공식 채용 페이지 생활지원 항목 복리후생비. 공식 뉴스룸 2022년 기사에는 선택적 복리 후생비로 기재) — 연간 지급 금액 미기재', 31),
  (@comp_id, 'housing_loan', '주거안정 자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '구성원의 안정된 생활 터전 마련을 위한 주거안정 자금 지원 (공식 채용 페이지 생활지원 항목 주거안정 — 대출 여부·한도·이율 미기재)', 32),
  (@comp_id, 'telecom', '통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '매달 통신비 지원 (공식 채용 페이지 생활지원 항목 통신비지원). 공식 채용 사이트 구성원 인터뷰에는 구성원 명의 1회선의 통신 서비스 이용료와 단말기 할부금 지원으로 소개 — 월 지원 한도 미기재', 33),
  (@comp_id, 'meal', '사내식당 더 테이블·EBB 아침식사', NULL, 'perks',
   'est', NULL, TRUE, 'T타워 지하 2층 사내식당 겸 복합 문화 공간 더 테이블 운영 (공식 뉴스룸 2022년 기사·공식 홈페이지 임직원 건강증진 페이지). 아침 일찍 출근한 구성원에게 아침식사를 무료로 제공하는 EBB(Early Bird Breakfast) (공식 뉴스룸 2022년·2026년 기사) — 중식 식대 지원 여부·본인 부담 미기재', 34),
  (@comp_id, 'snack_bar', '더 라운지 카페', 50, 'perks',
   'est', 'T타워 31층 더 라운지에서 바리스타가 내려주는 드립 커피와 차·음료·간단한 스낵 제공 (공식 뉴스룸·공식 채용 사이트 2022년 소개 글 — 이용 요금 미기재) (추정)', FALSE, NULL, 35),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'massage', '네일케어·안마 서비스', NULL, 'health',
   'est', NULL, TRUE, '사내에 행복한울 소속 네일케어·안마사 상주, 휴게시간에 네일케어와 안마 서비스 이용 (공식 채용 페이지 행복지원 항목 네일케어/안마. 2025 지속가능경영보고서에는 사내 안마 서비스 헬스케어로 기재) — 이용 횟수·본인 부담 미기재', 40),
  (@comp_id, 'fitness', '사내 헬스센터 액티움(Actium)', NULL, 'health',
   'est', NULL, TRUE, '월 1만원에 300평이 넘는 사내 헬스 센터 이용, 근력·유산소 운동 기구 구비 (공식 채용 페이지 행복지원 항목 Actium). 공식 채용 사이트 구성원 인터뷰에는 헬스·요가·골프·탁구·배드민턴·농구와 트레이너·골프 레슨으로 소개. 원격 피트니스·식단/운동 코칭 등 비대면 건강증진 프로그램 (공식 홈페이지 임직원 건강증진 페이지)', 41),
  (@comp_id, 'medical', '의료비 지원 (본인·가족)', 200, 'health',
   'est', '구성원 의료비 100% 지원, 가족(부모·배우자·자녀·배우자의 부모) 의료비 지원 (공식 채용 페이지 생활지원 항목 의료비/건강검진). 건강진료 HOT-LINE — 본인·배우자·자녀·부모 진료 상담·예약과 비급여 항목 일부 할인 (공식 홈페이지 임직원 건강증진 페이지) (추정)', FALSE, NULL, 42),
  (@comp_id, 'health_check', '종합건강검진 (가족 포함)', 100, 'health',
   'est', '최고 수준의 건강검진 전액 지원 (공식 채용 페이지 생활지원 항목 의료비/건강검진). 전 임직원 종합 검진과 구성원 가족(배우자, 자녀, 본인 및 배우자의 직계 존속 중 1인) 검진 지원 (공식 홈페이지 임직원 건강증진 페이지). 격년 선택적 건강검진, 독감·B형 간염·대상포진 예방접종 지원 (2025 지속가능경영보고서) (추정)', FALSE, NULL, 43),
  (@comp_id, 'mental', '심리상담 마음의 숲', NULL, 'health',
   'est', NULL, TRUE, '외부 상담전문기관 위탁 개인 전문 상담 마음의 숲 — 업무 스트레스·애로사항·건강·개인 상담, 365일 수시 상담 (2025 지속가능경영보고서). 마음건강 레터·건강강좌·웃음운동·힐링요가 등 액티움 정신건강 프로그램과 개인별 맞춤형 Class 101 강의 제공 (2025 지속가능경영보고서·공식 홈페이지 임직원 건강증진 페이지) — 이용 횟수 한도 미기재', 44),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'sports_ticket', 'SK Knights 농구 관람 지원', NULL, 'leisure',
   'est', NULL, TRUE, 'SK Knights 농구 경기 티켓 지원, 친구·가족과 함께 경기 관람 (공식 채용 페이지 행복지원 항목 스포츠 관람 지원 — 지급 매수·신청 방법 미기재)', 50),
  (@comp_id, 'company_event', '가족·자녀캠프', NULL, 'leisure',
   'est', NULL, TRUE, '영어캠프·코딩캠프·글램핑·SK Knights 농구교실 등 가족과 함께하는 체험 프로그램, 구성원 누구나 이용 (공식 채용 페이지 행복지원 항목 가족/자녀캠프 — 개최 주기·본인 부담 미기재)', 51),
  (@comp_id, 'resort', '휴양시설 (임직원가)', 50, 'leisure',
   'est', '전국 휴양시설을 임직원가로 저렴하게 이용 (공식 채용 페이지 행복지원 항목 휴양시설 — 제휴 시설 목록 미기재) (추정)', FALSE, NULL, 52),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '푸르니 재단 행복날개 어린이집 사내 운영, 매일 아침 자녀와 함께 출근 (공식 채용 페이지 생활지원 항목 어린이집 — 입소 정원·보육료 부담 미기재)', 60),
  (@comp_id, 'child_edu', '자녀 학자금 (유치원~대학교)', 300, 'family',
   'est', '유치원부터 대학교까지 자녀 학자금 모두 지원 (공식 채용 페이지 생활지원 항목 육아/자녀 교육). 미취학아동 3년, 초등학교 6년, 중학교 3년, 고등학교 3년, 대학교 4년 (공식 뉴스룸 2024년 기사) (추정)', FALSE, NULL, 61),
  (@comp_id, 'parenting', '육아휴직 추가 1년·입학자녀 돌봄휴직·임신기 지원', NULL, 'family',
   'est', NULL, TRUE, '회사 자체 추가 육아휴직 1년으로 자녀당 최대 2년(남녀 모두, 추가 1년에도 육아휴직급여 지급, 계약직은 추가분 제외), 휴직 전 기간 의료비 등 주요 복리후생 유지, 초등학교 입학년도 입학자녀 돌봄휴직 연 1회 90일, 임신 전 기간 1일 2시간 단축근무, 사내 수유시설 (2025 지속가능경영보고서 구성원 행복 제고 프로그램 표). 출산 경조금 첫째 50만원·둘째 100만원·셋째 500만원, 제왕절개 수술비 본인 100%·배우자 50만원 초과분 50%, 임신 확인부터 산후 1년까지 필요시 재택근무, 임신 구성원 전용 휴게 공간 (공식 뉴스룸 2024년 기사)', 62),
  (@comp_id, 'event', '경조사비 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사비 지원, 본인뿐 아니라 본인과 배우자의 형제자매까지 지원 (공식 채용 페이지 생활지원 항목 경조사 — 경조 종류별 금액 미기재)', 63),
  (@comp_id, 'fertility_support', '난임 지원', NULL, 'family',
   'est', NULL, TRUE, '난임치료 휴가 연 6일 전 일수 유급 (2025 지속가능경영보고서). 난임 의료비 본인 100%·배우자 50만원 초과분 50%, 통상급 50%를 지원하는 최대 10개월 난임 휴직 (공식 뉴스룸 2024년 기사)', 64),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'work_tools', '최고의 근무환경 (노트북 교체·인체공학 의자)', NULL, 'work_env',
   'est', NULL, TRUE, '3년마다 최신형 노트북 교체 지원, 편안한 자세를 위한 인체공학적 의자 제공 (공식 채용 페이지 업무지원 항목 최고의 근무환경)', 70),
  (@comp_id, 'lounge', '더 라운지·리프레시 존', NULL, 'work_env',
   'est', NULL, TRUE, 'T타워 31층 소통·휴식 공간 더 라운지 — 리클라이너·빈백 소파 (공식 뉴스룸·공식 채용 사이트 2022년 소개 글). 각 층 1인실 구조의 리프레시 존에서 휴게시간 휴식 (2025 지속가능경영보고서) — 공식 채용 사이트 구성원 인터뷰에는 리클라이너·안마의자 설치로 소개', 71),

  -- ── 성장·교육 (growth) ──
  (@comp_id, 'books', '사내 도서관 T-Library', NULL, 'growth',
   'est', NULL, TRUE, '업무 관련과 다양한 분야의 최신 도서, 일반 도서·e-book·기술 트렌드 잡지 제공 (공식 채용 페이지 업무지원 항목 T-Library). 을지로 SKT타워 18층, 24시간 개방·무인 대출반납 (공식 뉴스룸 2020년 기사)', 80),
  (@comp_id, 'mba', '석사과정 지원 (OJD)', NULL, 'growth',
   'est', NULL, TRUE, 'AI 분야 석사 학위 취득 프로그램 OJD(On the Job Degree) — On Duty 형태의 온/오프라인 석사과정 지원, 정규직 대상 (2025 지속가능경영보고서). 공식 채용 사이트 구성원 인터뷰에는 후보 선발 시 근속 기간 제한 없음, 최종 합격자에게 주 1일 학업 시간 배려로 소개 — 선발 인원·학비 부담 범위 미기재', 81),
  (@comp_id, 'retirement_support', '정년퇴직·Next Career 지원', NULL, 'growth',
   'est', NULL, TRUE, '정년퇴직 예정 구성원에게 퇴직일 3개월 전부터 쓰는 1개월 유급 정년퇴직 특별휴가, 3년간 이동전화 요금·경조사 물품·협약가 건강검진 지원. 25년 이상 장기근속자 또는 만 50세 이상 구성원 대상 유급 Next Career 휴직과 창업 지원 프로그램 (2025 지속가능경영보고서 정년퇴직 구성원 지원)', 82),
  (@comp_id, 'career', '사내공모제도', NULL, 'growth',
   'est', NULL, TRUE, '구성원이 전문성과 역량, 커리어 비전에 따라 하고 싶은 일에 스스로 도전하는 사내공모제도 (2025 지속가능경영보고서 행복한 조직문화 형성 — 공모 주기·지원 자격 미기재)', 83),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'long_service_bonus', 'Refresh 복리후생 포인트 (근속 5년마다)', NULL, 'compensation',
   'est', NULL, TRUE, '근속 5년 주기 Refresh 휴가와 함께 복리후생 포인트 부여 (공식 뉴스룸 2022년 기사). 공식 채용 사이트 구성원 인터뷰에는 휴가 10일과 복지포인트 1,000만 포인트 또는 휴가 30일과 200만 포인트 중 선택으로 소개 — 현행 포인트 금액은 2025 지속가능경영보고서에 미기재', 90),
  (@comp_id, 'incentive', '성과급 (TI·PS)', NULL, 'compensation',
   'est', NULL, TRUE, 'KPI 달성에 따라 지급하는 TI(Target Incentive)와 경영실적 기반의 PS(Profit Sharing) 제도 운영, PS 는 개인별 평가 결과에 따라 차등 지급 (2025 지속가능경영보고서 구성원 보상제도 — 지급률·지급 기준 미기재)', 91),
  (@comp_id, 'excellence_award', 'SUPEX 추구상', NULL, 'compensation',
   'est', NULL, TRUE, '각 영역에서 SKMS 정신을 발휘해 높은 목표에 도전하고 탁월한 성과를 낸 우수 사례를 발굴해 포상하는 전사 포상제도 (2025 지속가능경영보고서 구성원 보상제도 — 포상 내용·규모 미기재)', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
