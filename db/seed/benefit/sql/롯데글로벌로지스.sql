-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 롯데글로벌로지스 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://www.lotteglogis.com/home/company/recruit/education
-- badge: est
--
-- 참고:
--   정본 = 자기 도메인 인재채용 인사제도 페이지 복리후생 절(SSR · 원본 HTML 에 항목 글 · 발행일 표시 없음).
--   보조 = 자기 도메인 발행 2025 지속가능경영보고서(국문 PDF · 2026년 6월 발행 · 보고 기간 2025-01-01 ~ 2025-12-31 ·
--     비재무 보고 범위 = 별도법인 롯데글로벌로지스 국내 본사 및 전 사업장 · PDF 쪽 = 인쇄 쪽) 52 · 54 · 55 · 56 · 59 · 60 · 66쪽,
--     OpenDART 2025 사업보고서(20260331004385) · 2026 반기보고서(20260814003773) 직원 등 현황 유연근무제도 사용 현황 표.
--   귀속 = 페이지 · 보고서 모두 이 법인 자기 도메인 · 이 법인 주어 문장 — 각주 없음. 롯데그룹 행사 참여 한 구절은 company_event 서술에 그룹 행사로 적음.
--   금액 = 금액 행 0(원문에 연 금액 숫자 없음 — 전 행 정성).
--   제외 = 법정(출산휴가 90일 · 임신기 · 육아기 단축근무 · 육아휴직 연령 요건 · 반일 단위 휴가 · 본인 휴가 사용 독려 공동휴가 · 직책자 지정일 휴가 노리데이 · 휴가 사용 촉진) ·
--     업무 교육(직무교육 · 직무School · 직무자격인증 · Grade · 팀장자격 · 주재원 과정 · 선발형 AI 리더양성) · 조직문화 프로그램 · 택배기사 · 파트너사 · 장애인 선수단 처우.
--   공고 근거 0행 / 전체 28행
--   SORT 섹션 순서 = growth 10 · family 20 · work_env 30 · flexibility 40 · perks 50 · compensation 60 · time_off 70 (정본 페이지 순서) · leisure 80 · health 90 (보고서에만)
-- 검증 · 감사 판정 반영(2026-10-23): 행 조치 없음 · 학자금 대출 이자 self_development 와 다자녀 차량 car_rental 은 같은 웨이브 롯데건설과 한 코드로 맞춤(감사) · 59 · 60 · 66쪽 표 짝 22행 일치 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 28행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lotte_glogis', '롯데글로벌로지스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '물류', 'L', 'https://www.lotteglogis.com/home/company/recruit/education');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_glogis');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lotteglogis.com/home/company/recruit/education'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장·교육 (growth) — 정본 인재육성 체계 · 복리후생 기타 · 보고서 55 · 56 · 59쪽 ──
  (@comp_id, 'lang', '외국어 학습지원 · Speak Up LGL', NULL, 'growth',
   'est', NULL, TRUE, '외국어 학습지원 (공식 채용 페이지 인사제도 인재육성 체계 직무기초 강화 항목), 역량별 어학역량 강화 과정 SPEAK UP LGL 초급·중급 단계 선택, 영어·일어·중국어 언어 프로그램 운영 (2025 지속가능경영보고서 56쪽 자기주도 학습 지원 항목) — 비용 지원 범위 미기재', 10),
  (@comp_id, 'mba', '사외 MBA 과정 (핵심인재 교육)', NULL, 'growth',
   'est', NULL, TRUE, '핵심인재 교육 사외MBA 과정 (공식 채용 페이지 인사제도 인재육성 체계 핵심인재 교육 항목), 핵심인재 과정 LOTTE MBA (2025 지속가능경영보고서 55쪽 직무별 Learning Path 항목) — 선발 기준·비용 지원 범위 미기재', 11),
  (@comp_id, 'self_development', '자기계발비 · 학자금 대출 이자 지원', NULL, 'growth',
   'est', NULL, TRUE, '각종 자기 계발비 지원 (공식 채용 페이지 인사제도 복리후생 기타 복리 후생 항목), 한국장학재단을 통한 학자금 대출금의 최종 상환 시점까지 이자 전액 지원 (2025 지속가능경영보고서 59쪽 학자금 대출 이자 지원 항목) — 자기계발비 지원 한도 미기재', 12),
  -- ── 가족 (family) — 정본 복리후생 여성 친화 · 가족 친화 · 보고서 59 · 60쪽 ──
  (@comp_id, 'parenting', '임신·출산·육아 지원 (육아휴직 최대 2년·남성 육아휴직 의무)', NULL, 'family',
   'est', NULL, TRUE, '육아휴직 의무 사용·최대 2년, 출산 축하금 및 선물 지급 (공식 채용 페이지 인사제도 복리후생 여성 친화 항목), 남성 육아휴직 1개월 의무 (같은 페이지 가족 친화 항목), 임신 축하 선물 임산부용 바디로션 세트, 출산 축하 선물 과일바구니·분유/기저귀, 자녀 초등학교 입학 시 입학 선물, 자녀 초등학교 입학 시 1~12개월까지 휴직 사용이 가능한 자녀입학 돌봄휴가, 수학능력시험 응시 자녀 격려품 (2025 지속가능경영보고서 60쪽 가족 친화 제도 항목) — 출산 축하금 금액 미기재', 20),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금 (공식 채용 페이지 인사제도 복리후생 가족 친화 항목), 직원 및 가족 경조사 발생 시 경조용품, 장례 서비스, 화환, 경조비, 경조 휴가 추가 지급, 배우자 동일 적용 (2025 지속가능경영보고서 59쪽 경조사 지원 항목) — 경조금 금액·휴가 일수 미기재', 21),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금 지원 (공식 채용 페이지 인사제도 복리후생 가족 친화 항목), 대학생 등 자녀 학자금 지원 (2025 지속가능경영보고서 59쪽 자녀 학자금 지원 항목) — 지원 한도 미기재', 22),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '만 3세 미만 자녀 직원 대상 어린이집 운영, 어린이집 이용 직원 대상 월 정기 주차 지원 (2025 지속가능경영보고서 60쪽 가족 친화 제도 직장 어린이집 항목) — 어린이집 위치·정원 미기재', 23),
  -- ── 근무 환경 (work_env) — 정본 복리후생 여성 친화 · 보고서 59쪽 ──
  (@comp_id, 'lounge', '여성 직원 휴게실 (오아시스)', NULL, 'work_env',
   'est', NULL, TRUE, '사내 여성휴게실 운영 (공식 채용 페이지 인사제도 복리후생 여성 친화 항목), 여성 직원 휴게공간 오아시스 운영, 세라젬·1인용 리클라이너·온열팩 등 편의시설 구비 (2025 지속가능경영보고서 59쪽 여성인재 Retention 활동 항목) — 운영 사업장 미기재', 30),
  -- ── 근무 유연성 (flexibility) — 정본 복리후생 가족 친화 · 보고서 59 · 60쪽 · 공시 ──
  (@comp_id, 'flex_work', '유연근무제 (시차출퇴근제)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제, 집중근무제 (공식 채용 페이지 인사제도 복리후생 가족 친화 항목), 총 5가지 유형의 유연 출퇴근 제도 운영, 8시부터 10시까지 30분 단위로 출근시간 조정, 해피런치로 점심시간을 1시간에서 1시간 30분으로 연장 (2025 지속가능경영보고서 59쪽 일과 삶의 균형 항목), 시차출퇴근제 사용자 수 1,215명 (2025 사업보고서 유연근무제도 사용 현황 항목), 1,130명 (2026 반기보고서 같은 항목) — 유형별 근무시간 미기재', 40),
  (@comp_id, 'family_day', '가족사랑의 날 · 행복티켓 (2시간 조기 퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '가족사랑의날 매주 2회 (공식 채용 페이지 인사제도 복리후생 가족 친화 항목), 매주 수요일과 금요일 정시 퇴근 제도, 5시50분 사내 방송과 안내 메일로 정시 퇴근 독려 (2025 지속가능경영보고서 60쪽 가족 친화 제도 가족사랑의 날 항목), 개인 일정에 맞춰 2시간 조기 퇴근을 허용하는 행복티켓, 매월 2회까지 원하는 날짜에 추가 승인 없이 자율 사용 (같은 보고서 59쪽 일과 삶의 균형 항목) — 조기 퇴근 시간 급여 처리 미기재', 41),
  (@comp_id, 'pc_off', 'Mobile-OFF · PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'Mobile-OFF & PC-OFF 제도 (공식 채용 페이지 인사제도 복리후생 가족 친화 항목), 퇴근시간이 임박하면 알림으로 정시 퇴근을 돕고 근무 외 시간에는 PC 사용 제한 (2025 지속가능경영보고서 59쪽 일과 삶의 균형 PC-OFF 제도 항목)', 42),
  -- ── 생활 지원 (perks) — 정본 복리후생 가족 친화 · 기타 · 보고서 59 · 60쪽 ──
  (@comp_id, 'birthday_gift', '생일·결혼기념일 축하 선물', NULL, 'perks',
   'est', NULL, TRUE, '결혼기념일 축하선물 지급 (공식 채용 페이지 인사제도 복리후생 가족 친화 항목), 결혼기념일 기념 선물 케익·꽃다발 (2025 지속가능경영보고서 60쪽 가족 친화 제도 축하 기념품 지급 항목), 생일 축하 선물 지급 (같은 보고서 59쪽 기타 복리후생 항목) — 생일 선물 품목·금액 미기재', 50),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 지급 (공식 채용 페이지 인사제도 복리후생 기타 복리 후생 항목) — 지급 포인트·사용처 미기재', 51),
  (@comp_id, 'car_rental', '다자녀 차량 지원 (3자녀 이상)', NULL, 'perks',
   'est', NULL, TRUE, '3자녀 이상 직원 차량 지원(카니발) (2025 지속가능경영보고서 60쪽 가족 친화 제도 다자녀 지원 항목) — 지원 방식·기간 미기재', 52),
  -- ── 보상 (compensation) — 정본 복리후생 기타 · 보고서 52 · 54 · 59쪽 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 10년 이후 5년단위 (공식 채용 페이지 인사제도 복리후생 기타 복리 후생 항목), 근속 10년~30년 장기근속자 포상, 상패 및 포상금 제공, 여행비 지원 (2025 지속가능경영보고서 59쪽 장기근속자 포상 항목) — 포상금 금액 미기재', 60),
  (@comp_id, 'holiday_gift', '명절 귀향 여비·선물 · 창립기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 귀향 여비 및 선물 지급, 창립기념일 축하 기념 선물 지급 (2025 지속가능경영보고서 59쪽 기타 복리후생 항목) — 여비 금액·선물 품목 미기재', 61),
  (@comp_id, 'incentive', '성과급 차등 보상 · 영업 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '경영실적을 기반으로 우수 성과자에 대한 성과급 차등 보상, 2024년 신설된 영업 인센티브 제도를 통한 개인별 맞춤형 성과 보상 (2025 지속가능경영보고서 54쪽 성과 평가 및 보상 항목), 인센티브 제도 보완 및 포상 규모 확대 (같은 보고서 52쪽 2025 회사발전협의회 주요 활동 영업활성화 Project 항목) — 지급 기준·지급률 미기재', 62),
  (@comp_id, 'excellence_award', '포상 제도', NULL, 'compensation',
   'est', NULL, TRUE, '포상금 상향을 통한 우수 성과에 대한 실질적인 인정 (2025 지속가능경영보고서 54쪽 성과 관리 및 보상 경쟁력 강화 항목) — 포상 종류·포상금 금액 미기재', 63),
  -- ── 휴가 (time_off) — 정본 복리후생 기타 · 보고서 59쪽 ──
  (@comp_id, 'birthday_leave', '기념일 휴가 (생일·결혼기념일 등)', NULL, 'time_off',
   'est', NULL, TRUE, '기념일 휴가 제도 생일, 결혼기념일 등 (공식 채용 페이지 인사제도 복리후생 기타 복리 후생 항목) — 휴가 일수·유급 여부 미기재', 70),
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위로 사용할 수 있는 휴가 제도 시행 (2025 지속가능경영보고서 59쪽 일과 삶의 균형 항목) — 사용 한도 미기재', 71),
  -- ── 여가 (leisure) — 보고서 59 · 60쪽 ──
  (@comp_id, 'resort', '콘도 이용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '성수기, 공휴일 등에 저렴한 가격으로 콘도 이용, 국내 다수 리조트 회원권 보유 (2025 지속가능경영보고서 59쪽 콘도 이용 지원 항목) — 이용 일수·회사 부담 범위 미기재', 80),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '전국 다양한 장르의 31개 동호회 활동 지원, 신규 동호회 개설 시 설립 축하 지원금, 월 1회 동호회 활동을 위한 2시간 조기 퇴근 동호회 티켓 (2025 지속가능경영보고서 59쪽 사내 동호회 항목) — 활동비 지원 금액 미기재', 81),
  (@comp_id, 'summer_vacation_subsidy', '체력단련비 (휴가비)', NULL, 'leisure',
   'est', NULL, TRUE, '매년 1회 임직원 건강증진 및 리프레시를 위한 체력단련비(휴가비) 지원 (2025 지속가능경영보고서 59쪽 기타 복리후생 항목) — 지원 금액 미기재', 82),
  (@comp_id, 'welcome_kit', '신규 입사자 웰컴 키트', NULL, 'leisure',
   'est', NULL, TRUE, '신규 입사자 웰컴 키트 선물 지급 (2025 지속가능경영보고서 59쪽 기타 복리후생 항목) — 구성품 미기재', 83),
  (@comp_id, 'company_event', 'LGL Family Day · 롯데 러브패밀리 페스티벌', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 및 가족 120명이 참석하는 1박2일 임직원 가족 회사 초청 행사 LGL Family Day, 사무실 투어와 임직원 자녀를 위한 행사, 롯데월드 전체를 대관한 롯데그룹 가족 친화 행사 롯데 러브패밀리 페스티벌 참여 (2025 지속가능경영보고서 60쪽 가족친화 문화 조성 항목) — 개최 주기 미기재', 84),
  -- ── 건강 (health) — 보고서 52 · 59 · 66쪽 ──
  (@comp_id, 'health_check', '종합건강검진 (만 35세 이상·가족 1인)', NULL, 'health',
   'est', NULL, TRUE, '만 35세 이상 임직원 대상 종합건강검진 지원, 대상자의 가족 1인 건강검진 추가 지원 (2025 지속가능경영보고서 66쪽 임직원 건강증진 프로그램 항목), 건강검진 비용 지원 만 35세 이상 직원 및 해당 직원 가족 1인 포함 (같은 보고서 59쪽 건강 증진 프로그램 항목), 가족 지원 대상을 기존 배우자에서 배우자, 부모, 형제 1인으로 확대 (같은 보고서 52쪽 2025 회사발전협의회 주요 활동 항목) — 검진 주기 미기재', 90),
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '전 임직원 대상 단체상해보험 가입, 상해 사망, 후유 장애, 입원 통원 실손 의료비 지급, 실손 3대 비급여 및 일반 암 진단비 등 지원 (2025 지속가능경영보고서 66쪽 단체상해보험 가입 항목, 59쪽 건강 증진 프로그램 항목) — 보장 한도 미기재', 91),
  (@comp_id, 'mental', '마음건강 케어 프로그램 (EAP)', NULL, 'health',
   'est', NULL, TRUE, '전문 근로자 지원업체 EAP와 제휴한 임직원 대상 정서관리 및 상담 서비스, 대면·화상·전화 익명 상담, 직장 내 대인관계·업무 스트레스·조직 적응·심리검진·양육 등 상담주제, 이용대상 롯데글로벌로지스 임직원 (2025 지속가능경영보고서 66쪽 마음건강 케어 프로그램 항목) — 이용 횟수 한도 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
