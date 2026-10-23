-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 세메스 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://www.semes.com/ko/careers/personnel-management-system
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 www.semes.com 채용 > 인사제도 페이지(서버 렌더 HTML · 보상체계 성과급 제도 + 복리후생·복지시설 33카드).
--   DART 홈 주소 www.semes.co.kr 은 http 메타 새로고침으로 www.semes.com 으로 보낸다(443 접속 거부).
--   보조 (1) 공식 홈 꼬리말 「세메스 채용」 링크의 회사 계정 채용 사이트 semes.careerlink.kr /benefits(Career and Life · 헤더 메뉴 생활) 와 /faq.
--   사이트 빌더가 한 응답에 전 페이지를 싣는다 — 헤더 메뉴에 걸린 benefits · faq 페이지의 사용 중 블록만 읽었다(비활성 블록 · 인턴 체험기 제외).
--   보조 (2) OpenDART 2026 반기보고서(20260814003111) · 2025 사업보고서(20260331003653) 유연근무제도 사용 현황 표(선택근무제 줄).
--   귀속: 두 웹 출처 모두 이 법인(세메스) 이름 · 도메인 · 사업자번호로 실린다 — 각주 없음. samsungcareers 관계사 목록에 세메스 없음(개별 채용).
--   금액: 식대 1행만 추정(하루 3끼 × 1끼 12,000원 × 연 240일 = 864) · stated 0. 개인연금 연봉의 2% 는 비율이라 NULL.
--   제외: 법정(임신기 근로시간 단축 · 출산전후휴가 · 배우자 출산휴가 · 육아휴직 · 육아기 근로시간 단축 · 난임휴가 일수) ·
--   업무 교육(직무교육 프로그램 상시운영) · 공시 임원 보수 칸(명절상여 · 인센티브 · 임원 처우) · 인턴 체험기(사내카페 등).
--   공고 근거 0행 / 전체 27행. SORT 섹션 순서 = compensation 10 · perks 20 · leisure 30 · family 40 · growth 50 · flexibility 60 · time_off 70 · health 80.
-- 검증 · 감사 판정 반영(2026-10-23): 두 출처 숫자가 갈린 출퇴근버스 노선 · 동호회 수 · 구기장 목록을 더 새 판인 채용 사이트 숫자만으로(배우자 출산휴가 3회 분할 개정 틀 · 정본 작업 주석 210521) · TAI OPI 는 incentive 한 행 · 정본 URL 은 자기 도메인 유지 — 최종 27행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('semes', '세메스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '반도체장비', 'S', 'https://www.semes.com/ko/careers/personnel-management-system');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'semes');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.semes.com/ko/careers/personnel-management-system'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 공식 홈페이지 인사제도 보상체계 · 복리후생 ──
  (@comp_id, 'incentive', '성과급 제도 (목표 인센티브 · 성과 인센티브)', NULL, 'compensation',
   'est', NULL, TRUE, '연봉제 포함항목 성과급 · 집단성과급(TAI, OPI) 및 기타 인센티브, 경영목표 달성도에 따라 연 2회 지급하는 목표 인센티브(TAI) · 경영목표를 초과하는 이익 달성도에 따라 연 1회 지급하는 성과 인센티브(OPI) (공식 홈페이지 인사제도 보상체계 성과급 제도 항목) — 지급률·지급 기준 미기재', 10),
  (@comp_id, 'excellence_award', '모범사원 · 우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '모범사원, 우수사원 포상 (공식 홈페이지 인사제도 복리후생 자기계발·휴가 항목), 다양한 시상 제도 운영 (공식 채용 사이트 Career & Life Work 항목) — 포상 기준·포상 내용 미기재', 11),

  -- ── 생활 편의 (perks) — 공식 홈페이지 인사제도 복리후생 · 공식 채용 사이트 ──
  (@comp_id, 'commute_subsidy', '출퇴근버스 지원', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근버스 운영 세메스 20여개 노선 · 삼성 300여개 노선 (공식 채용 사이트 Career & Life Work 항목), 출퇴근버스 지원 (공식 홈페이지 인사제도 복리후생 편안한 회사생활 항목), 수도권 지하철 천안역, 두정역, 직산역 및 KTX 천안아산역, 천안 버스터미널을 포함하여 천안/아산지역을 두루 경유하는 통근버스 · 천안 ↔ 서울(강남/잠실) 버스 운영 (공식 채용 사이트 FAQ 항목) — 이용 비용 미기재', 20),
  (@comp_id, 'meal', '사내식당 운영 (조식 · 중식 · 석식)', 864, 'perks',
   'est', '사내식당 운영 조 · 중 · 석식 무료제공 (공식 홈페이지 인사제도 복리후생 편안한 회사생활 항목) — 1끼 단가 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 21),
  (@comp_id, 'welfare_point', '선택적 복리후생 제도 (복지포인트)', NULL, 'perks',
   'est', NULL, TRUE, '선택적 복리후생 제도 복지포인트 (공식 홈페이지 인사제도 복리후생 편안한 회사생활 항목, 공식 채용 사이트 Career & Life Life 항목) — 연간 배정 포인트·사용처 미기재', 22),
  (@comp_id, 'discount', '할인몰 운영 · 제휴병원 할인', NULL, 'perks',
   'est', NULL, TRUE, '삼성전자제품 할인 등 할인몰 운영 (공식 홈페이지 인사제도 복리후생 편안한 회사생활 항목), 삼성가족구매센터, 삼성전자 패밀리몰 등 할인몰 운영 (공식 채용 사이트 Career & Life Life 항목), 병원 협업 할인 (공식 홈페이지 인사제도 복리후생 더 건강한 삶을 위해 항목), 제휴병원 할인 제공 (공식 채용 사이트 Career & Life Health 항목) — 할인율·제휴 병원 미기재', 23),
  (@comp_id, 'team_dinner', '즐거운 회사생활(GWP) 활동비 지원', NULL, 'perks',
   'est', NULL, TRUE, '즐거운 회사생활(GWP) 활동비 지원 (공식 홈페이지 인사제도 복리후생 편안한 회사생활 항목, 공식 채용 사이트 Career & Life Life 항목) — 지원 금액·지원 주기 미기재', 24),
  (@comp_id, 'pension_support', '개인연금 지원 (연봉의 2%)', NULL, 'perks',
   'est', NULL, TRUE, '노후를 위한 개인연금 지원 (공식 홈페이지 인사제도 복리후생 편안한 회사생활 항목), 개인연금 회사지원 연봉의 2% (공식 채용 사이트 Career & Life Health 항목) — 가입 조건·본인 부담 미기재', 25),
  (@comp_id, 'housing_support', '주거지원 (대졸 신입사원)', NULL, 'perks',
   'est', NULL, TRUE, '주거지원 (대졸 신입사원) (공식 홈페이지 인사제도 복리후생 숙소·리조트·경조사 항목), 신입사원 주거비 지원 (공식 채용 사이트 Career & Life Work 항목), 주거지원 규정에 의거하여 신입사원에게는 일정기간 주거지원금을 제공 (공식 채용 사이트 FAQ 항목) — 지원 기간·지원 금액 미기재', 26),

  -- ── 여가 (leisure) — 공식 홈페이지 인사제도 복리후생 · 공식 채용 사이트 ──
  (@comp_id, 'club', '사내 동호회 운영', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영 축구, 농구, 테니스 등 10여개 동호회 (공식 채용 사이트 Career & Life Life 항목), 사내 동호회 운영 (공식 홈페이지 인사제도 복리후생 편안한 회사생활 항목) — 동호회 지원 금액 미기재', 30),
  (@comp_id, 'resort', '리조트 회원권 보유', NULL, 'leisure',
   'est', NULL, TRUE, '리조트 회원권 보유 대명, 한화, 리솜 등 전국 (공식 홈페이지 인사제도 복리후생 숙소·리조트·경조사 항목), 제휴 리조트 이용 대명, 한화, 리솜 등 전국 (공식 채용 사이트 Career & Life Life 항목) — 이용 비용·이용 횟수 미기재', 31),
  (@comp_id, 'library', '임직원 전용 사이버 도서관 운영', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 전용 사이버 도서관 운영 (공식 홈페이지 인사제도 복리후생 자기계발·휴가 항목), 임직원 전용 전자 도서관 운영 (공식 채용 사이트 Career & Life Education 항목) — 이용 범위 미기재', 32),
  (@comp_id, 'leisure_ticket', '테마파크 이용권 할인', NULL, 'leisure',
   'est', NULL, TRUE, '테마파크 이용권 할인 에버랜드, 캐리비안베이 (공식 채용 사이트 Career & Life Life 항목) — 할인율·연간 매수 미기재', 33),

  -- ── 가족 (family) — 공식 홈페이지 인사제도 복리후생 임신·출산·육아·교육 · 경조사 ──
  (@comp_id, 'childcare', '사내 어린이집 운영', NULL, 'family',
   'est', NULL, TRUE, '세메스 어린이집 · 어린이집 운영 (공식 홈페이지 인사제도 복리후생 임신·출산·육아·교육 항목), 사내 어린이집 운영 (공식 채용 사이트 Career & Life Family 항목) — 정원·이용 대상 미기재', 40),
  (@comp_id, 'child_edu', '자녀 학자금 · 유치원비 지원', NULL, 'family',
   'est', NULL, TRUE, '고등 · 대학교(해외대학포함) 자녀 학자금 지원, 유치원비 지원 (공식 홈페이지 인사제도 복리후생 임신·출산·육아·교육 항목), 자녀 유치원비 지원 (공식 채용 사이트 Career & Life Family 항목) — 지원 한도·자녀 수 제한 미기재', 41),
  (@comp_id, 'fertility_support', '난임 치료비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 치료비 지원 (공식 홈페이지 인사제도 복리후생 임신·출산·육아·교육 항목, 공식 채용 사이트 Career & Life Family 항목) — 지원 한도·지원 횟수 미기재', 42),
  (@comp_id, 'event', '경조사비 지원 및 휴가 · 조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사비 지원 및 휴가 경사 및 조의, 조사 지원 상조서비스, 물품 (공식 홈페이지 인사제도 복리후생 숙소·리조트·경조사 항목), 경조사비 지원 및 휴가 경사 및 조의 (공식 채용 사이트 Career & Life Life 항목) — 경조금 금액·휴가 일수 미기재', 43),

  -- ── 성장 (growth) — 공식 홈페이지 인사제도 복리후생 자기계발·휴가 · 공식 채용 사이트 Education ──
  (@comp_id, 'mba', '학위지원 · 학술연수 지원', NULL, 'growth',
   'est', NULL, TRUE, '학위지원 공학 석사, eMBA (공식 홈페이지 인사제도 복리후생 자기계발·휴가 항목), 학술연수 지원 공학석사, EMBA, Visiting Researcher (공식 채용 사이트 Career & Life Education 항목) — 선발 기준·지원 범위 미기재', 50),
  (@comp_id, 'conference', '해외 · 국내 컨퍼런스 · 학회 참석 지원', NULL, 'growth',
   'est', NULL, TRUE, '해외컨퍼런스 · 학회 참석 지원 (공식 홈페이지 인사제도 복리후생 자기계발·휴가 항목), 해외/국내 컨퍼런스 · 학회 참석 지원 (공식 채용 사이트 Career & Life Education 항목) — 지원 범위·지원 횟수 미기재', 51),
  (@comp_id, 'lang', '외국어 학습지원 · 인텐시브과정', NULL, 'growth',
   'est', NULL, TRUE, '외국어 학습지원, 인텐시브과정 영어, 중국어 운영 (공식 홈페이지 인사제도 복리후생 자기계발·휴가 항목), 외국어 학습지원, 인텐시브과정 영어, 중국어, 일본어 (공식 채용 사이트 Career & Life Education 항목) — 수강 대상·비용 부담 미기재', 52),

  -- ── 근무 유연성 (flexibility) — 공식 홈페이지 · 공식 채용 사이트 · 공시 ──
  (@comp_id, 'flex_work', '유연근무제 운영 (자율출근제 · 재량근로시간제)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 운영 자율출근제, 재량근로시간제 (공식 홈페이지 인사제도 복리후생 자기계발·휴가 항목, 공식 채용 사이트 Career & Life Work 항목), 선택근무제 사용자 수 2026년 반기 2,712명 · 2025년 2,646명 · 2024년 2,571명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 적용 대상·운영 방식 미기재', 60),

  -- ── 휴가 (time_off) — 공식 홈페이지 인사제도 복리후생 자기계발·휴가 ──
  (@comp_id, 'long_service_leave', '장기근속휴가 및 휴가비 지원', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속휴가 및 휴가비 지원 (공식 홈페이지 인사제도 복리후생 자기계발·휴가 항목, 공식 채용 사이트 Career & Life Work 항목) — 근속 기준·휴가 일수·휴가비 금액 미기재', 70),

  -- ── 건강 (health) — 공식 홈페이지 인사제도 복지시설 더 건강한 삶을 위해 · 공식 채용 사이트 Health ──
  (@comp_id, 'medical', '의료비 지원 (본인 및 가족)', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 본인 및 가족 (공식 홈페이지 인사제도 복리후생 더 건강한 삶을 위해 항목, 공식 채용 사이트 Career & Life Health 항목) — 지원 한도·가족 범위 미기재', 80),
  (@comp_id, 'clinic', '사내 의무실 운영', NULL, 'health',
   'est', NULL, TRUE, '의무실 운영 (공식 홈페이지 인사제도 복리후생 더 건강한 삶을 위해 항목), 사내 의무실 운영 (공식 채용 사이트 Career & Life Health 항목) — 진료 범위·운영 시간 미기재', 81),
  (@comp_id, 'mental', '사내 심리상담실 운영', NULL, 'health',
   'est', NULL, TRUE, '심리상담실 운영 (공식 홈페이지 인사제도 복리후생 더 건강한 삶을 위해 항목), 사내 심리상담실 운영 (공식 채용 사이트 Career & Life Health 항목) — 상담 방식·이용 횟수 미기재', 82),
  (@comp_id, 'health_check', '종합검진 지원 (본인 및 배우자)', NULL, 'health',
   'est', NULL, TRUE, '종합검진 지원 (공식 홈페이지 인사제도 복리후생 더 건강한 삶을 위해 항목), 종합검진 지원 본인 및 배우자 (공식 채용 사이트 Career & Life Health 항목) — 검진 주기·비용 지원 범위 미기재', 83),
  (@comp_id, 'fitness', '휘트니스 센터 · 운동시설 운영', NULL, 'health',
   'est', NULL, TRUE, '휘트니스 센터 운영 (공식 홈페이지 인사제도 복리후생 더 건강한 삶을 위해 항목), 사내 휘트니스 센터 운영 (공식 채용 사이트 Career & Life Health 항목), 농구장, 축구장, 탁구장 시설 운영 (공식 채용 사이트 Career & Life Life 항목) — 이용 시간·이용 비용 미기재', 84)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
