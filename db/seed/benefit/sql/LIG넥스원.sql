-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LIG넥스원 복리후생 데이터
-- 출처: AI 파싱 (2026-09-26)
-- URL: https://www.ligdefenseaerospace.com/people/welfare.do
-- badge: est
--
-- 참고:
--   정본은 자기 도메인 www.ligdefenseaerospace.com 의 인사제도 > 복리후생 페이지(/people/welfare.do) 안
--   「복리후생 알아보기」 팝업(div id=peoplePopup03)이다. 실 DOM 의 ol 5개 64항목
--   (자기개발 9 · 건강 10 · Work & Life Balance 21 · 가족 16 · 기타 8) — HTML 주석 속 블록이 아니다.
--   SSR HTML 이라 헤드리스 렌더 불필요. robots 는 User-agent: * / Allow:/ (전면 허용).
--   옛 도메인 www.lignex1.com 은 전부 이 도메인으로 301 된다(대조 보고서 2026-09-25 실측).
--   보조 출처(같은 사이트): /people/life.do 사내행사 안내 팝업 12행사 · /people/education.do 교육제도 ·
--   /esg/humanenv.do 근무환경(성과 Incentive · 유연근무제 Speed Gate · 휴가비 지원 · 퇴직예정자 생애 설계교육).
--   네 페이지 sha256 이 2026-09-25 대조 보고서 기록과 같다(원문 변동 없음).
--   ATS ligdna.recruiter.co.kr 은 복지 본문이 robots 금지 경로 /app* 아래라 쓰지 않았다.
--
--   금액: 공식 원문에 금액 숫자 0건. 금액 6행은 구본 추정치를 금액 정책 (a) 조건으로 승계했고
--     NOTE 끝에 (추정) 을 달았다(health_check 100 · insurance 30 · meal 432 · welfare_point 200 ·
--     resort 50 · commute_subsidy 120). meal 432 는 원문이 조/중/석식 3식을 명시해 앵커 조건을 충족한다.
--
--   분리: 구본은 64항목을 24행에 눌러 담아 한 행에 다른 제도가 섞였다. 같은 코드로 귀결되는 항목만 합쳤다.
--     refresh_leave 에 섞였던 여행비 3항목 → travel_support, 마이너스 휴가·이월 → leave_general ·
--     mental 의 헬스키퍼 → massage · event 의 입학·수능 선물 → parenting · edu_support 의 학위파견 → mba ·
--     lang 의 학회·세미나 → conference · long_service_bonus 의 정년 퇴임식 → retirement_support ·
--     club·snack_bar 의 가족초청·무비데이·호프데이 → company_event.
--   신규 코드 1개: medical_loan(perks) ← 건강 항목 「본인/배우자/자녀 의료비 대출」「가족 의료비 대출」.
--   제외: 법정 6항목(육아기·임신기 근로단축, 배우자 출산휴가, 난임치료휴가, 유사산휴가, 태아검진 외출) ·
--     징검다리 휴가 권장 · 출장 마일리지 · 해외 문화체험(해외출장 연계) · 금연·다이어트 캠페인 ·
--     복장 완전 자율화 · OJT/멘토링·직무전문가 세미나·외부강사 특강·온라인 독서통신 교육(사내 교육 과정) ·
--     명절 상여(임금 구성) · 가족친화인증.
--   SORT 섹션 순서 = 팝업에서 카테고리가 처음 나온 순서
--     (growth 10 · health 20 · perks 30 · time_off 40 · leisure 50 · flexibility 60 · family 70 ·
--      compensation 80 · work_env 90).
-- 재수집(2026-09-26): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다 — 대조 보고서 2026-09-25-official-compare
-- 감사(RA-1 2026-09-26) 반영: medical_loan 을 welfare_fund_loan 으로 흡수(신규 코드 0) · Re-Fill 휴가를 leave_general 로 재코딩해 휴가 당겨쓰기·이월과 병합 · 정년 퇴임식에서 법정 재취업지원 생애설계교육 문구 제거
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lig_nex1', 'LIG디펜스앤에어로스페이스(구 LIG넥스원)',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '방산', 'L', 'https://www.ligdefenseaerospace.com/people/welfare.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.ligdefenseaerospace.com/people/welfare.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장·교육 (growth) ──
  (@comp_id, 'mba', '핵심인재 학위파견', NULL, 'growth',
   'est', NULL, TRUE, '핵심인재 학위파견 (공식 인사제도 페이지 복리후생 알아보기 자기개발 항목). 교육제도 페이지에는 핵심인재 육성을 위한 국내/외 학위 파견으로 기재 — 선발 기준·인원·비용 부담 범위 미기재', 10),
  (@comp_id, 'edu_support', '사외 직무교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '사외 직무교육 지원 (공식 인사제도 페이지 복리후생 알아보기 자기개발 항목·교육제도 페이지 기타 항목 — 지원 한도·대상 과정 미기재)', 11),
  (@comp_id, 'lang', '어학교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학교육 지원 (공식 인사제도 페이지 복리후생 알아보기 자기개발 항목·교육제도 페이지 기타 항목 — 대상 언어·지원 방식·한도 미기재)', 12),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격증 취득지원 (공식 인사제도 페이지 복리후생 알아보기 자기개발 항목·교육제도 페이지 기타 항목 — 대상 자격증·지원 한도 미기재)', 13),
  (@comp_id, 'conference', '학회 논문 발표·세미나 참석 지원', NULL, 'growth',
   'est', NULL, TRUE, '학회 논문 발표/세미나 참석 지원 (공식 인사제도 페이지 복리후생 알아보기 자기개발 항목 — 지원 범위·한도 미기재)', 14),
  (@comp_id, 'retirement_support', '정년 퇴임식·기념품', NULL, 'growth',
   'est', NULL, TRUE, '정년 퇴임식 및 기념품 (공식 인사제도 페이지 복리후생 알아보기 가족 항목 — 기념품 내용 미기재)', 15),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '본인/배우자 종합건강검진 (공식 인사제도 페이지 복리후생 알아보기 건강 항목 — 검진 주기·비용 한도 미기재) (추정)', FALSE, NULL, 20),
  (@comp_id, 'insurance', '단체 정기보험', 30, 'health',
   'est', '본인/배우자 단체 정기보험 (공식 인사제도 페이지 복리후생 알아보기 건강 항목 — 보장 범위·보험료 부담 미기재) (추정)', FALSE, NULL, 21),
  (@comp_id, 'massage', '헬스키퍼 상주', NULL, 'health',
   'est', NULL, TRUE, '헬스키퍼 상주 (공식 인사제도 페이지 복리후생 알아보기 건강 항목 — 상주 사업장·이용 방식 미기재)', 22),
  (@comp_id, 'mental', '심리상담 지원', NULL, 'health',
   'est', NULL, TRUE, '본인/가족 심리상담지원 (공식 인사제도 페이지 복리후생 알아보기 건강 항목 — 상담 횟수·운영 방식 미기재)', 23),
  (@comp_id, 'fitness', '피트니스센터', NULL, 'health',
   'est', NULL, TRUE, '사내외 피트니스센터 운영', 24),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_fund_loan', '의료비 대출', NULL, 'perks',
   'est', NULL, TRUE, '본인/배우자/자녀 의료비 대출, 가족 의료비 대출 (공식 인사제도 페이지 복리후생 알아보기 건강 항목 — 대출 한도·이율·가족 범위 미기재)', 30),
  (@comp_id, 'meal', '조·중·석식 제공', 432, 'perks',
   'est', '조/중/석식 제공 (공식 인사제도 페이지 복리후생 알아보기 건강 항목 — 식대 단가·본인 부담 여부 미기재) (추정)', FALSE, NULL, 31),
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '복지포인트 (공식 인사제도 페이지 복리후생 알아보기 가족 항목 — 연간 지급액·사용처 미기재) (추정)', FALSE, NULL, 32),
  (@comp_id, 'housing_loan', '주택자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택 임대/매입 자금 대출 지원, 수도권 입사자 주택자금 특별대출 (공식 인사제도 페이지 복리후생 알아보기 가족 항목 — 대출 한도·이율 미기재)', 33),
  (@comp_id, 'snack_bar', '층별 Tea Zone·N-Cafe', NULL, 'perks',
   'est', NULL, TRUE, '층별 Tea Zone, N-Cafe (공식 인사제도 페이지 복리후생 알아보기 기타 항목 — 운영 시간·이용료 미기재)', 34),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '통근버스 (공식 인사제도 페이지 복리후생 알아보기 기타 항목 — 운행 사업장·노선 미기재) (추정)', FALSE, NULL, 35),

  -- ── 휴가·휴직 (time_off) ──
  (@comp_id, 'summer_leave', '여름휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '여름휴가 5일 별도 (공식 인사제도 페이지 복리후생 알아보기 Work & Life Balance 항목 — 유급 여부·사용 시기 미기재)', 40),
  (@comp_id, 'leave_general', 'Re-Fill 휴가·휴가 당겨쓰기·이월', NULL, 'time_off',
   'est', NULL, TRUE, 'Re-Fill 휴가, 마이너스 휴가제도(휴가 당겨쓰기), 미사용 휴가 이월제도 (공식 인사제도 페이지 복리후생 알아보기 Work & Life Balance 항목 — Re-Fill 휴가 부여 일수·부여 조건, 당겨 쓸 수 있는 일수·이월 한도 미기재)', 41),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'travel_support', '여행비 지원 (국내·해외)', NULL, 'leisure',
   'est', NULL, TRUE, 'Refresh 휴가지원금(국내여행비), 해외문화 체험비 지원(해외여행비), 여행Point 지급 (공식 인사제도 페이지 복리후생 알아보기 Work & Life Balance 항목). 지속가능경영 근무환경 페이지에는 여가시간 최대보장(휴가비 지원 등)으로 기재 — 지원 금액·대상·주기 미기재', 50),
  (@comp_id, 'resort', '휴양소', 50, 'leisure',
   'est', '휴양소 이용 지원 (공식 인사제도 페이지 복리후생 알아보기 Work & Life Balance 항목 — 휴양소 위치·이용 조건 미기재) (추정)', FALSE, NULL, 51),
  (@comp_id, 'company_event', '가족 초청행사·사내행사', NULL, 'leisure',
   'est', NULL, TRUE, '가족 초청행사, 무비데이 (공식 인사제도 페이지 복리후생 알아보기 가족 항목), 상하반기 팀야유회, 호프데이 (같은 팝업 기타 항목). 사내문화 페이지 사내행사 안내에는 역사DAY(임직원 가족 대상 전쟁기념관/국립중앙박물관 관람), 러브 DAY(어버이날 편지 및 카네이션), 패밀리DAY(가족 봄 캠핑·가족 사내 초청과 기념품), 피지컬 DAY(명랑 운동회), 리멤버 마이 DAY(사진 달력), 감사한 DAY(출근길 깜짝 선물) 등 12개 행사 기재 — 개최 주기·참가 대상 미기재', 52),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회(Informal Group) (공식 인사제도 페이지 복리후생 알아보기 기타 항목 — 지원 금액·동호회 종류 미기재)', 53),

  -- ── 유연근무 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 근무시간제·시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제, 주 40시간 선택적 근무시간제 (공식 인사제도 페이지 복리후생 알아보기 Work & Life Balance 항목). 지속가능경영 근무환경 페이지에는 유연근무제를 도입해 Speed Gate 시스템으로 근무시간을 관리한다고 기재 — 정산 기간·코어타임 미기재', 60),
  (@comp_id, 'pc_off', 'PC-Off제', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-Off제 (공식 인사제도 페이지 복리후생 알아보기 Work & Life Balance 항목 — 적용 시각 미기재)', 61),
  (@comp_id, 'family_day', '가정의 날', NULL, 'flexibility',
   'est', NULL, TRUE, '매주 가정의 날 (공식 인사제도 페이지 복리후생 알아보기 Work & Life Balance 항목 — 운영 요일·퇴근 시각 미기재)', 62),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 학자금·유치원비 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 수 무관 학자금 지원(중등/고등/대학교), 만6세 자녀 유치원비 지원 (공식 인사제도 페이지 복리후생 알아보기 가족 항목 — 지원 한도 미기재)', 70),
  (@comp_id, 'parenting', '자녀 입학·수능 축하선물', NULL, 'family',
   'est', NULL, TRUE, '초등/중등 입학 축하선물, 수능 자녀 축하선물 (공식 인사제도 페이지 복리후생 알아보기 가족 항목 — 선물 내용 미기재)', 71),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 (공식 인사제도 페이지 복리후생 알아보기 가족 항목 — 설치 사업장·정원 미기재)', 72),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금 및 경조휴가, 상조 인력/물품 지원, 재해 경조금, 사내커플 결혼 축하금 (공식 인사제도 페이지 복리후생 알아보기 가족 항목 — 경조 종류별 금액·휴가 일수 미기재)', 73),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기근속비', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속비 근속 10년 이상 5년단위 지급 (공식 인사제도 페이지 복리후생 알아보기 가족 항목 — 지급액 미기재)', 80),
  (@comp_id, 'incentive', '성과 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '성과에 상응하는 파격적 보상(Incentive) (공식 지속가능경영 근무환경 페이지 성과주의 강화 항목 — 지급 기준·지급률 미기재)', 81),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '지방 사업장 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '지방 사업장 기숙사 제공 (공식 인사제도 페이지 복리후생 알아보기 기타 항목 — 대상 사업장·입주 자격 미기재)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
