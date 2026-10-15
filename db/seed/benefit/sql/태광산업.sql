-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 태광산업 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: http://www.taekwang.co.kr/employment/employment_04.asp
-- badge: est
--
-- 참고:
--   정본은 상장 법인 태광산업(주)의 자기 도메인 www.taekwang.co.kr 인사채용 > 복리후생 페이지다(https 는 접속 거부 · http 만 응답).
--   SSR 이지만 보이는 항목은 이미지 img_04_01.gif(705x350 · 판독 가능) 안에만 있다. 같은 HTML 의 dl.hidden(화면 밖 -10000px)
--   대체 텍스트는 이미지와 항목이 다른 옛 문구라 행 근거로 쓰지 않았다(이미지에 없는 창립기념일 휴무 · 노동절 휴무 · 교육비 지원 ·
--   우수사원포상 · 종합검진 만 40세 이상 단서 — 근거표 판단 요청).
--   보조 출처: 같은 도메인 지속가능경영 > 보고서 및 규정 목록의 법인 단독 발행 2026년 태광산업 지속가능경영보고서(FY2025 ·
--   PDF 작성 2026-07-01 · 보고 기간 2025-01-01~2025-12-31 · 보고 범위 태광산업 별도) 22~26쪽 ·
--   같은 도메인 지속가능경영 > 사회 > 노동관행 페이지(2023~2025 지표) · 인사채용 > 인사제도 페이지 평가/보상 이미지 ·
--   OpenDART 2026 반기보고서(접수 20260814003951) 유연근무제도 사용 현황. 직원 2025 사업보고서 기준 남 721 · 여 약 105.
--   귀속: 페이지 · 보고서 모두 태광산업 단수 주어 또는 주어 없음 · 계열사별 상이 단서 없음 · 자기 발행 보고서라 각주 없음.
--   태광그룹 형제(대한화섬 · 흥국생명 · 흥국화재 등)는 코퍼스 · 대기 폴더에 없다. 그룹 채용 ATS 는 쓰지 않았다.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL.
--   제외: 법정(연차 · 반차 · 정기 건강검진 국민건강보험공단 · 육아기 단축근무 · 육아휴직 1년 · 배우자 출산휴가 20일 ·
--     난임치료 휴가 연 6일 이내 · 가족돌봄 휴가 10일 · 휴직 90일 · 임신기 2시간 단축 · 법정의무 교육) ·
--     업무 교육(신입사원 OJT · 직무역량강화 · 승진자 · 리더십 · 인사제도 페이지 공통직무 과정) · 소통활동(티브릿지 · 리프레쉬위크) ·
--     임원 보수 칸 복리후생규정 선물대 · 화면에 안 보이는 대체 텍스트 전용 항목.
--   공고 근거 0행 / 전체 24행.
--   SORT 섹션 순서 = 정본 이미지 등장 순(health 10 · growth 20 · leisure 30 · time_off 40 · compensation 50 · family 60 ·
--     perks 70 · work_env 80), 보고서 · 공시에만 있는 flexibility 90.
-- 검증 · 감사 판정 반영(2026-10-15): 행 조치 없음 · 경영성과급 행 유지(리드 판정 136) — 최종 24행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('taekwang_ind', '태광산업',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화학', 'T', 'http://www.taekwang.co.kr/employment/employment_04.asp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'taekwang_ind');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'http://www.taekwang.co.kr/employment/employment_04.asp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 채용 페이지 복리후생 건강지원 · 보고서 25 · 26쪽 ──
  (@comp_id, 'health_check', '종합검진·건강검진 휴가', NULL, 'health',
   'est', NULL, TRUE, '종합검진 (공식 채용 페이지 복리후생 건강지원 항목), 임직원 건강 관리를 위한 건강검진 지원 · 건강검진 시 유급 반일 휴가 지원 (2026 지속가능경영보고서 25쪽 복리후생 프로그램 · 가족친화 제도 항목) — 검진 대상·주기·비용 지원 범위 미기재', 10),
  (@comp_id, 'insurance', '단체상해보험 가입', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 가입 (공식 채용 페이지 복리후생 건강지원 항목) — 보장 내용·가입 대상 미기재', 11),
  (@comp_id, 'fitness', '피트니스센터 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 체력 증진을 위한 피트니스센터 운영 및 지원 (2026 지속가능경영보고서 25쪽 복리후생 프로그램 문화생활지원 항목), 사내 피트니스센터 운영 (2026 지속가능경영보고서 26쪽 노사협의회 주요 논의사항 복리후생 개선 항목) — 운영 사업장·이용 조건 미기재', 12),
  -- ── 성장 (growth) — 채용 페이지 복리후생 교육지원 · 보고서 22 · 23 · 25쪽 · 노동관행 페이지 ──
  (@comp_id, 'self_development', '자기계발비·자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기계발비 지원 (공식 채용 페이지 복리후생 교육지원 항목), 임직원의 자기개발 및 역량 강화를 위한 비용 지원 (2026 지속가능경영보고서 25쪽 복리후생 프로그램 근무환경지원 항목), 자격증 취득 지원 제도 운영 (공식 지속가능경영 페이지 사회 노동관행 교육 항목) — 지원 금액·지원 범위 미기재', 20),
  (@comp_id, 'lang', '사내 어학강좌·어학교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '사내 어학강좌 운영 (공식 채용 페이지 복리후생 교육지원 항목), 다국어 어학 교육 지원 · 온·오프라인 과정 및 맞춤 학습 태광랭스 (2026 지속가능경영보고서 23쪽 어학교육 항목), 사외 어학원과 협력한 강의 수강료 지원 · 어학 시험 응시 지원 (공식 지속가능경영 페이지 사회 노동관행 교육 항목) — 지원 언어·지원 금액 미기재', 21),
  (@comp_id, 'edu_support', '온라인 교육 플랫폼', NULL, 'growth',
   'est', NULL, TRUE, '온라인 교육 플랫폼, 임직원 누구나 언제 어디서든 학습할 수 있도록 8,400여 개 과정의 강의 제공 · 직무·기술·인문 등 다양한 분야 (2026 지속가능경영보고서 23쪽 자기개발 지원 항목) — 수강 비용·수강 조건 미기재', 22),
  (@comp_id, 'conference', '사외위탁교육', NULL, 'growth',
   'est', NULL, TRUE, '심화 학습을 위해 외부 교육기관 및 전문 과정 참여 지원 (2026 지속가능경영보고서 23쪽 사외위탁교육 항목) — 지원 대상·지원 금액 미기재', 23),
  (@comp_id, 'retirement_support', '재취업 지원 서비스', NULL, 'growth',
   'est', NULL, TRUE, '재취업 지원 서비스 (2026 지속가능경영보고서 22쪽 임직원 육성 체계 항목) — 대상·지원 내용 미기재', 24),
  -- ── 여가 (leisure) — 채용 페이지 복리후생 교육지원 · 복지지원 · 보고서 23 · 25쪽 ──
  (@comp_id, 'library', '사내 도서관·모바일 도서관', NULL, 'leisure',
   'est', NULL, TRUE, '사내 도서관 운영 (공식 채용 페이지 복리후생 교육지원 항목), 임직원의 자기개발과 독서 문화 확산을 위한 모바일 도서관 서비스 운영 · 경영·인문·기술 등 다양한 분야의 도서 (2026 지속가능경영보고서 23쪽 자기개발 지원 모바일 도서관 항목) — 이용 대상·운영 방식 미기재', 30),
  (@comp_id, 'resort', '사내 콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 콘도 운영 (공식 채용 페이지 복리후생 복지지원 항목), 여름/겨울 성수기 시즌에 콘도 이용 지원 (2026 지속가능경영보고서 25쪽 복리후생 프로그램 문화생활지원 항목) — 콘도 위치·이용 비용 미기재', 31),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회비 지원 (공식 채용 페이지 복리후생 복지지원 항목), 동호회 지원 (2026 지속가능경영보고서 25쪽 복리후생 프로그램 여가생활 지원 항목) — 지원 금액·지원 조건 미기재', 32),
  (@comp_id, 'company_event', '야유회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '야유회비 지원 (공식 채용 페이지 복리후생 복지지원 항목), 야유회 지원 (2026 지속가능경영보고서 25쪽 복리후생 프로그램 여가생활 지원 항목) — 지원 금액·개최 주기 미기재', 33),
  (@comp_id, 'leisure_room', '미술관·영화관 운영', NULL, 'leisure',
   'est', NULL, TRUE, '미술관·영화관 운영 (2026 지속가능경영보고서 25쪽 복리후생 프로그램 여가생활 지원 항목) — 시설 위치·이용 조건 미기재', 34),
  -- ── 휴가 (time_off) — 채용 페이지 복리후생 복지지원 · 보고서 25쪽 ──
  (@comp_id, 'long_service_leave', '장기근속 포상휴가·포상금', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상휴가·포상금 지원 (공식 채용 페이지 복리후생 복지지원 항목), 장기 근속자를 대상으로 특별 휴가 및 휴가비 부여 (2026 지속가능경영보고서 25쪽 복리후생 프로그램 장기휴가 지원 항목) — 근속 기준·휴가 일수·금액 미기재', 40),
  -- ── 보상 (compensation) — 채용 페이지 복리후생 복지지원 · 인사제도 평가/보상 · 보고서 24 · 25쪽 ──
  (@comp_id, 'holiday_gift', '명절·창립기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물 지원 (공식 채용 페이지 복리후생 복지지원 항목), 회사 창립기념일, 명절 등 임직원에 선물 제공 (2026 지속가능경영보고서 25쪽 복리후생 프로그램 생활안정지원 기타 지원 항목) — 선물 품목·금액 미기재', 50),
  (@comp_id, 'profit_sharing', '경영성과급', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과급 (공식 채용 페이지 인사제도 평가/보상 성과 보상 항목) — 지급 기준·지급률 미기재', 51),
  (@comp_id, 'excellence_award', '올해의 태광인·스팟인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '뛰어난 성과와 헌신을 보인 임직원을 발굴하고 인정하기 위한 조직·개인 단위의 별도 보상제도 운영 · 우수성과자(부서) 포상 올해의 태광인 제도 · 우수직원 상시 발굴 수시 인센티브 지급 스팟인센티브 제도 (2026 지속가능경영보고서 24쪽 평가체계 및 보상 항목) — 포상 금액·선정 기준 미기재', 52),
  -- ── 가족 (family) — 채용 페이지 복리후생 복지지원 · 생활안정지원 · 보고서 25쪽 · 노동관행 페이지 ──
  (@comp_id, 'event', '경조사비·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조 휴가 보장 · 경조사비 지원 (공식 채용 페이지 복리후생 복지지원 항목), 결혼, 출산, 장례 등 경조사별 휴가 및 경조금 지원 (2026 지속가능경영보고서 25쪽 복리후생 프로그램 생활안정지원 항목) — 경조 유형별 휴가 일수·금액 미기재', 60),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원 (공식 채용 페이지 복리후생 생활안정지원 항목), 임직원 자녀 교육비 부담 감소를 위한 학자금 지원 (2026 지속가능경영보고서 25쪽 복리후생 프로그램 근무환경지원 항목) — 지원 학령·지원 한도 미기재', 61),
  (@comp_id, 'parenting', '출산 선물·경조금', NULL, 'family',
   'est', NULL, TRUE, '임직원 출산 시 선물 지원 (2026 지속가능경영보고서 25쪽 가족친화 제도 기타 지원 항목), 출산 시 경조금 및 선물 제공 (공식 지속가능경영 페이지 사회 노동관행 항목) — 선물 품목·금액 미기재', 62),
  -- ── 생활 · 금융 (perks) — 채용 페이지 복리후생 생활안정지원 · 보고서 25쪽 ──
  (@comp_id, 'housing_loan', '주택자금 융자', NULL, 'perks',
   'est', NULL, TRUE, '주택자금융자 (공식 채용 페이지 복리후생 생활안정지원 항목), 주택 구매 및 임차를 위한 대출 지원 (2026 지속가능경영보고서 25쪽 복리후생 프로그램 근무환경지원 항목) — 대출 한도·이율·대상 미기재', 70),
  -- ── 근무 환경 (work_env) — 채용 페이지 복리후생 생활안정지원 ──
  (@comp_id, 'dormitory', '사택 제공 (공장)', NULL, 'work_env',
   'est', NULL, TRUE, '사택제공(공장) (공식 채용 페이지 복리후생 생활안정지원 항목) — 대상 사업장·입주 조건 미기재', 80),
  -- ── 근무 유연성 (flexibility) — 보고서 25쪽 · 2026 반기보고서 ──
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '정시 출근 제도, 임직원의 정시 출퇴근 장려를 위해 PC-OFF 제도 운영 (2026 지속가능경영보고서 25쪽 가족친화 제도 항목) — 적용 시간·적용 대상 미기재', 90),
  (@comp_id, 'flex_work', 'Smart 출근제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, 'Smart 출근제, 자녀양육, 가족돌봄, 임신 중 근로자 대상 선택적 근무시간 운영 (2026 지속가능경영보고서 25쪽 가족친화 제도 항목), 유연근무제 활용 여부 시차출퇴근제 활용 (2026 반기보고서 유연근무제도 사용 현황 항목) — 근무시간 선택 범위 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
