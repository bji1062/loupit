-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 안랩 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://company.ahnlab.com/kr/recruit/personnel_welfare.do
-- badge: est
--
-- 참고:
--   정본은 상장 법인 ㈜안랩의 자기 도메인 company.ahnlab.com 인재채용 > 인사제도 > 복리후생 탭이다.
--   SSR 이라 원본 HTML 에 복리후생 블록(선택적 복리후생 · 경제적지원 · 동호회 · 건강지원 · 근무환경 · 포상제도)이 다 있다.
--   보조 출처(같은 도메인): 인사제도 > 보상 탭(전사 경영성과 인센티브 · ASSA, ASSA 영역 3개는 이미지 판독) ·
--   인사제도 > 문화 탭(DAY 이벤트 · 창립기념일 단체사진 · 성장지원 제도 나열) · 인재채용 > 인재육성(자격증 · 전화영어 · 해외 컨퍼런스 · VIEW 특강) ·
--   지속가능경영 > Social > 인적자본 페이지(2025 수치 게시 · 가족친화경영 경제적 지원 · 자녀 코딩캠프 · 사내 특강 · 자율출퇴근제 · 탄력근무제).
--   공시 보조: OpenDART 2026 반기보고서(접수 20260813000644) 직원 등 현황 유연근무제도 사용 현황 · 별도 재무제표 주석 5 임차보증금(복리후생 목적 사택).
--   직원 1,272명(2026-06-30 반기보고서). 별도 지속가능경영보고서 PDF 는 지속가능경영 페이지에서 찾지 못했다.
--   렌더: 원본 HTML(SSR) · 헤드리스 렌더 없음 · 이미지 판독 2장(보상 탭 도식).
--   귀속: 모든 문장의 주어가 안랩 · 안랩인이고 그룹 · 계열사 단서가 없다. 자회사(안랩블록체인컴퍼니 · 나온웍스 등) 문장 없음. 각주 없음.
--   금액: 원문에 원 단위 금액 0건 — 전 행 BENEFIT_AMT NULL. 식대는 끼니가 적히지 않아 NULL.
--   제외: 법정(보상휴가 지급 · 태아검진시간 보장 · 임신기 육아기 근로시간 단축 · 출산휴가 · 배우자 출산휴가 · 가족돌봄휴가 ·
--     난임치료 휴가 · 유사산 휴가 · 육아휴직 · 가족돌봄휴직 · 법정 의무교육 · 분기별 산업안전보건 교육) ·
--     업무 교육(함성 가치관 교육 · VIEW 직무교육 · 직군별 스쿨 · 안랩 개발자 컨퍼런스 · 컨설팅스쿨 · Planning and Strategy Day · ESG 교육) ·
--     사회공헌(온라인 Live 견학 · 안랩샘 · 산학협력 · 불용 IT 자산 기부 · 아름다운재단 급여 나눔 · 판교ESG얼라이언스 · 복지포인트 기부) ·
--     급여(기본 연봉) · 공시 주주 표 우리사주조합 칸(주식 수 없음) · 임원 보수지급기준(조직 성과급 · 성과 인센티브).
--   공고 근거 0행 / 전체 27행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(perks 10 · family 20 · leisure 30 · health 40 · work_env 50 · time_off 60 · compensation 70),
--     보조 출처에만 있는 growth 80 · flexibility 90.
-- 검증 · 감사 판정 반영(2026-10-14): 생활안정자금 대출 welfare_fund_loan 행을 주택 관련 자금 대출 housing_loan 행에 병합(한 라벨) · 유연근무 행 공시 수치를 대상 인원으로 정정 — 최종 26행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ahnlab', '안랩',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        'IT서비스', 'A', 'https://company.ahnlab.com/kr/recruit/personnel_welfare.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ahnlab');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://company.ahnlab.com/kr/recruit/personnel_welfare.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 채용 페이지 복리후생 · 보상 탭 · 인적자본 페이지 ──
  (@comp_id, 'welfare_point', '선택적 복리후생제도 (자율형 복지포인트 · ASSA)', NULL, 'perks',
   'est', NULL, TRUE, '모든 안랩인에게 자율형 복지포인트를 제공하고 문화생활, 독서, 운동, 여행, 가족모임 등 개인의 필요에 따라 다양하게 사용하는 선택적 복리후생제도 (공식 채용 페이지 복리후생 선택적 복리후생제도 항목), 원하는 복리후생 항목을 스스로 선택해 가족까지 활용하는 안랩 고유의 복지제도 ASSA(AhnLab self-service area), 생활안정 · 자기개발 · 가정친화 영역 (공식 채용 페이지 인사제도 보상 ASSA 항목) — 포인트 배정액 미기재', 10),
  (@comp_id, 'housing_loan', '사내대출 (주택 관련 자금 · 생활안정자금)', NULL, 'perks',
   'est', NULL, TRUE, '주택 관련 자금 및 생활안정자금 대출 지원 (공식 채용 페이지 복리후생 경제적지원 사내대출 항목, 공식 지속가능경영 페이지 인적자본 가족친화경영 경제적 지원 항목) — 대출 한도·이율·대상 미기재', 11),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '구성원들에게 건강하고 맛있는 식단을 제공하는 사내식당 (공식 채용 페이지 복리후생 근무환경 사내식당 항목) — 제공 끼니·회사 부담 범위 미기재', 13),
  (@comp_id, 'snack_bar', '카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '언제든지 편안하고 저렴한 가격으로 커피, 녹차, 음료 등을 마실 수 있는 카페테리아 운영 (공식 채용 페이지 복리후생 근무환경 카페테리아 항목) — 회사 부담 범위 미기재', 14),
  -- ── 가족 (family) — 채용 페이지 복리후생 · 인적자본 페이지 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀들의 학자금 지원 (공식 채용 페이지 복리후생 경제적지원 학자금 항목), 자녀 학자금 (공식 지속가능경영 페이지 인적자본 가족친화경영 경제적 지원 항목) — 지원 학령·한도 미기재', 20),
  (@comp_id, 'event', '경조금', NULL, 'family',
   'est', NULL, TRUE, '경조사 발생 시 경조금 지급 (공식 채용 페이지 복리후생 경제적지원 경조사 항목), 경조사금 (공식 지속가능경영 페이지 인적자본 가족친화경영 경제적 지원 항목) — 경조 구분별 금액·경조휴가 미기재', 21),
  (@comp_id, 'parenting', '출산 축하금', NULL, 'family',
   'est', NULL, TRUE, '출산 축하금 (공식 지속가능경영 페이지 인적자본 가족친화경영 경제적 지원 항목) — 지급 금액 미기재', 22),
  (@comp_id, 'childcare', '어린이집 (아장아장)', NULL, 'family',
   'est', NULL, TRUE, '육아걱정 없이 업무에 집중할 수 있도록 공동으로 운영하는 어린이집 「아장아장」 (공식 채용 페이지 복리후생 근무환경 아장아장 항목) — 공동 운영 주체·입소 조건 미기재', 23),
  -- ── 여가 (leisure) — 채용 페이지 복리후생 · 문화 탭 · 인적자본 페이지 ──
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '축구, 농구, 야구, 레고, e-sports, 와인, 주말 농장 등 10여개의 동호회 운영, 매월 활동비 지원 (공식 채용 페이지 복리후생 동호회 지원 항목) — 활동비 금액 미기재', 30),
  (@comp_id, 'library', '사내도서관', NULL, 'leisure',
   'est', NULL, TRUE, '자유롭게 읽고 싶은 책을 빌리거나 다양한 신문, 잡지 등을 볼 수 있는 사내도서관 운영 (공식 채용 페이지 복리후생 근무환경 사내도서관 항목) — 이용 시간 미기재', 31),
  (@comp_id, 'company_event', '임직원 자녀 코딩캠프 · DAY 이벤트', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 자녀를 위한 미래상상 코딩캠프 (공식 지속가능경영 페이지 인적자본 가족친화경영 항목), 여름 아이스크림 데이 · 11월 11일 가래떡 데이 등 DAY 이벤트, 매년 3월 15일 창립기념일 모든 안랩인 단체사진 촬영 행사 (공식 채용 페이지 인사제도 문화 항목) — 참가 대상·운영 횟수 미기재', 32),
  -- ── 건강 (health) — 채용 페이지 복리후생 건강지원 ──
  (@comp_id, 'insurance', '단체 상해 보험', NULL, 'health',
   'est', NULL, TRUE, '단체 상해 보험을 통해 각종 질병/사고가 생길 경우 의료 실비 지원 (공식 채용 페이지 복리후생 건강지원 단체보험 항목) — 보장 한도·가족 포함 여부 미기재', 40),
  (@comp_id, 'health_check', '종합건강검진 · 독감 예방접종', NULL, 'health',
   'est', NULL, TRUE, '본인 및 배우자의 종합건강검진, 매년 겨울 독감 예방 접종 지원 (공식 채용 페이지 복리후생 건강지원 건강검진 · 무료독감예방접종 항목) — 검진 주기·지원 한도 미기재', 41),
  (@comp_id, 'fitness', 'Fitness Center', NULL, 'health',
   'est', NULL, TRUE, '안랩인의 체력증진을 위하여 언제든지 무료로 이용할 수 있는 Fitness Center 운영 (공식 채용 페이지 복리후생 건강지원 Fitness Center 항목) — 운영 시간 미기재', 42),
  (@comp_id, 'massage', '토닥토닥 (사내 안마시설)', NULL, 'health',
   'est', NULL, TRUE, '컴퓨터 앞에서 근무하는 안랩인들을 위한 사내 안마시설 토닥토닥 운영, 전문 Health Keeper 상주 (공식 채용 페이지 복리후생 건강지원 토닥토닥 항목) — 이용 횟수·이용 시간 미기재', 43),
  -- ── 근무환경 (work_env) — 채용 페이지 복리후생 근무환경 · 2026 반기보고서 ──
  (@comp_id, 'lounge', '스페인계단 · 그린 샤프트', NULL, 'work_env',
   'est', NULL, TRUE, '1층 로비와 각층 계단의 스페인계단 · 그린 샤프트, 동료들과 함께 담소를 나누며 휴식하는 공간 (공식 채용 페이지 복리후생 근무환경 스페인계단 · 그린 샤프트 항목) — 좌석 규모 미기재', 50),
  (@comp_id, 'dormitory', '사택', NULL, 'work_env',
   'est', NULL, TRUE, '임·직원을 대상으로 하는 복리후생 목적의 사택 (2026 반기보고서 재무제표 주석 기타금융자산 임차보증금 항목) — 입주 대상·조건·지역 미기재', 51),
  -- ── 휴가 (time_off) — 채용 페이지 복리후생 포상제도 ──
  (@comp_id, 'long_service_leave', '장기근속포상 (포상휴가 · 포상금)', NULL, 'time_off',
   'est', NULL, TRUE, '일정 기간 동안 함께 성장해온 구성원에게 근속년수에 따라 포상휴가와 함께 포상금 제공 (공식 채용 페이지 복리후생 포상제도 장기근속포상 항목) — 근속 기준·휴가 일수·포상금 금액 미기재', 60),
  -- ── 보상 (compensation) — 채용 페이지 복리후생 포상제도 · 보상 탭 · 문화 탭 · 인적자본 페이지 ──
  (@comp_id, 'excellence_award', '포상제도 (올해의 안랩인상 · 공로상 등)', NULL, 'compensation',
   'est', NULL, TRUE, '올해의 안랩인상, 공로상(포상금 · 포상휴가), 동료 및 후배직원의 롤 모델이 되는 리더에게 수여하는 올해의 리더상, 프론티어상(포상금 · 포상휴가), 글로벌 안랩인상, 개인 연구개발 활동을 장려하는 특허포상(특허등록 · 포상금), 매월 이달의 스타상(축하 메시지 · 케이크 · 꽃바구니) (공식 채용 페이지 복리후생 포상제도 항목), iQx R&D 제도 성과 포상 (공식 채용 페이지 인사제도 문화 항목) — 포상금 금액·포상휴가 일수 미기재', 70),
  (@comp_id, 'profit_sharing', '경영성과 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '전사 경영성과에 따른 인센티브 (공식 채용 페이지 인사제도 보상 항목) — 지급 기준·지급률 미기재', 71),
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물 (공식 지속가능경영 페이지 인적자본 가족친화경영 경제적 지원 항목) — 선물 품목·금액 미기재', 72),
  -- ── 성장 (growth) — 채용 페이지 인재육성 · 문화 탭 · 인적자본 페이지 ──
  (@comp_id, 'self_development', '자격증 지원 제도', NULL, 'growth',
   'est', NULL, TRUE, '직무전문성 향상을 위해 업무 관련성이 있는 자격증 취득 및 교육 지원 (공식 채용 페이지 인재육성 자격증 지원 제도 항목), 자격증 취득지원 (공식 채용 페이지 인사제도 문화 항목) — 지원 한도·대상 자격증 미기재', 80),
  (@comp_id, 'lang', '전화영어', NULL, 'growth',
   'est', NULL, TRUE, '글로벌 역량 향상을 위해 전화영어 매월 지원 (공식 채용 페이지 인재육성 전화영어 항목), 온라인 강의(영어) (공식 채용 페이지 인사제도 문화 항목) — 지원 금액·수강 조건 미기재', 81),
  (@comp_id, 'edu_support', '사내 온라인 교육 · 사내 특강', NULL, 'growth',
   'est', NULL, TRUE, '사내 온라인 교육 제도 (공식 채용 페이지 인재육성 전화영어 항목), 온라인 강의 · AI활용교육 (공식 채용 페이지 인사제도 문화 항목), Trend · Tech · Talent · Task 주제의 정기 전 임직원 대상 특강 VIEW (공식 채용 페이지 인재육성 VIEW 항목), 행복한 가정생활에 도움이 되는 사내 특강 (공식 지속가능경영 페이지 인적자본 가족친화경영 항목) — 수강 한도·지원 범위 미기재', 82),
  (@comp_id, 'conference', '해외 컨퍼런스 참석 지원', NULL, 'growth',
   'est', NULL, TRUE, '최신 보안 동향 및 기술 대응을 위한 Black hat, Defcon 등 해외 컨퍼런스 참석 지원 (공식 채용 페이지 인재육성 해외 컨퍼런스 참석 항목), 컨퍼런스/세미나 (공식 채용 페이지 인사제도 문화 항목) — 참석 대상·지원 범위 미기재', 83),
  -- ── 근무 유연성 (flexibility) — 인적자본 페이지 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '자율출퇴근제 · 탄력근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '자율출퇴근제, 탄력근무제 도입 및 활용 (공식 지속가능경영 페이지 인적자본 가족친화경영 일과 가정의 양립 지원 항목), 자율출퇴근제 대상 834명 · 탄력근무제(선택근무제) 대상 142명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 코어타임·적용 직무 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
