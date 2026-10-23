-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LF 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://lf.career.greetinghr.com/ko/culture
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)LF 의 공식 홈(www.lfcorp.com:4440) 상단 채용 링크가 가리키는 LF 회사 계정 그리팅 채용 사이트
--   문화 메뉴 페이지다. 페이지 꼬리말 LF Corp. · 2023 LF, Inc. 저작권 · 문의 메일 lfcorp.com 도메인 · 공고 그룹 이름 LF.
--   SSR 이라 원본 HTML 본문에 Benefits 6블록 · LifeStyle 6블록 글이 다 있다 — 헤드리스 렌더 · 이미지 판독 불필요.
--   보조 출처: 자기 도메인 보도자료 2026-06-30 임직원 자율 성장 클래스 LF ON&OFF 운영(newsView.do seq 6617) ·
--   OpenDART 2026 반기보고서(접수 20260814002480) · 정정 2025 사업보고서(접수 20260601001924) 유연근무제도 사용 현황 표.
--   귀속: 채용 사이트 주어 · 공고 · 꼬리말이 모두 LF 단일 법인이고 계열사 · 그룹 공통 단서가 없다 — 각주 없음.
--   공고 중 경영관리 담당자(계열사/자회사) 1건은 LF 가 채용 주체인 직무 이름이라 다른 법인 페이지가 아니다.
--   금액: 원문 숫자는 할인 한도(700만원 · 180만원)와 인재추천 포상금(300만원)뿐 — 한도 · 1회성이라 전 행 BENEFIT_AMT NULL.
--   제외: 직급 제도 폐지 · 역량 Level 제도(인사 제도) · 사내추천제도 포상금(인재추천 포상) ·
--     공시 육아휴직 · 육아기 단축근무 · 배우자 출산휴가 사용 현황(법정) · 선택근무제 · 원격근무제(세 기간 모두 사용자 없음 · 자기 출처 언급 없음) ·
--     우리사주조합(주주 표 한 칸 · 정관 신주 배정 조항뿐) · 임원 복리후생 기준 지원금(임원 보수 칸) ·
--     기타장기종업원급여 회계정책 문장(장기 근속 낱말 없음) · LF ON&OFF 의 직무 역량 교육(AI · 경영 · 경제 · 패션) 몫.
--   공고 근거 0행 / 전체 22행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(perks 10 · leisure 20 · family 30 · compensation 40 · health 50 ·
--     growth 60 · time_off 70 · flexibility 80).
-- 검증 · 감사 판정 반영(2026-10-23): 건강검진 health_check 행 삭제(판정 172 · 자기 도메인 안전보건관리규정 일반건강진단 · 2025 안전보건 정보공개 법정대상 수검) · 같은 자료 10쪽 임직원 웰니스로 심리상담 · 헬스케어센터 서술 보강과 임직원 걷기운동 프로그램 fitness 추가(건강 섹션 머리 주석 10쪽) · MBA 꼬리 교체 · 항목 페이지 예외 4(통합 밖 리드 집행) · 참고 블록의 보조 출처 · 제외 줄(안전보건 자료 미수신)은 이 판정으로 뒤집힘 — 최종 22행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lf', 'LF',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '패션', 'L', 'https://lf.career.greetinghr.com/ko/culture');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lf');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://lf.career.greetinghr.com/ko/culture'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활 · 금융 (perks) — 정본 Benefits 01 · 03 ──
  (@comp_id, 'discount', 'LF 제품 할인 · LG 전자&생활건강 할인', NULL, 'perks',
   'est', NULL, TRUE, 'LF 제품할인 60~70% 할인 (700만원 한도), LG 전자&생활건강 15~20% 할인 (180만원 한도) (공식 채용 사이트 문화 페이지 Benefits 항목) — 한도 적용 기간·할인 대상 품목 미기재', 10),
  (@comp_id, 'birthday_gift', '생일축하금', NULL, 'perks',
   'est', NULL, TRUE, '생일축하금 (공식 채용 사이트 문화 페이지 Benefits 기념일 항목) — 지급액 미기재', 11),

  -- ── 여가 · 행사 (leisure) — 정본 Benefits 02 ──
  (@comp_id, 'sports_ticket', '스포츠(축구&야구) 관람권', NULL, 'leisure',
   'est', NULL, TRUE, '스포츠(축구&야구) 관람권 (공식 채용 사이트 문화 페이지 Benefits 문화생활 항목) — 제공 횟수·관람 구단 미기재', 20),
  (@comp_id, 'resort', '법인콘도', NULL, 'leisure',
   'est', NULL, TRUE, '법인콘도 (공식 채용 사이트 문화 페이지 Benefits 문화생활 항목) — 이용 가능 시설·이용 조건 미기재', 21),
  (@comp_id, 'club', '사내동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 (공식 채용 사이트 문화 페이지 Benefits 문화생활 항목) — 활동비 지원 여부·지원 규모 미기재', 22),

  -- ── 가족 (family) — 정본 Benefits 03 · 04 ──
  (@comp_id, 'event', '경조사 지원 (경조금·경조휴가·상제용품)', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원(경조금, 경조휴가, 상제용품) (공식 채용 사이트 문화 페이지 Benefits 기념일 항목) — 경조금 금액·경조휴가 일수·상제용품 품목 미기재', 30),
  (@comp_id, 'parenting', '위탁 보육비 지원 · 자녀 출산 및 입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '위탁 보육비 지원, 자녀 출산 및 입학 축하금 (공식 채용 사이트 문화 페이지 Benefits 자녀 항목) — 보육비 지원 한도·축하금 금액·대상 학령 미기재', 31),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 (공식 채용 사이트 문화 페이지 Benefits 자녀 항목) — 지원 학령·지원 한도 미기재', 32),

  -- ── 보상 (compensation) — 정본 Benefits 03 · LifeStyle 03 ──
  (@comp_id, 'holiday_gift', '명절선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절선물 (공식 채용 사이트 문화 페이지 Benefits 기념일 항목) — 선물 품목·금액 미기재', 40),
  (@comp_id, 'incentive', '성과급 제도', NULL, 'compensation',
   'est', NULL, TRUE, '개인과 조직 성과에 따른 성과급 제도 (공식 채용 사이트 문화 페이지 LifeStyle 보상 항목) — 지급 기준·지급률 미기재', 41),
  (@comp_id, 'excellence_award', '우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상 (공식 채용 사이트 문화 페이지 LifeStyle 보상 항목) — 포상 기준·포상 내용 미기재', 42),

  -- ── 건강 (health) — 정본 Benefits 05 · 2025 안전보건 정보공개 자료 10쪽 ──
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '단체보험 (공식 채용 사이트 문화 페이지 Benefits 건강 항목) — 보장 범위·가입 대상 미기재', 51),
  (@comp_id, 'mental', '심리상담', NULL, 'health',
   'est', NULL, TRUE, '심리상담 (공식 채용 사이트 문화 페이지 Benefits 건강 항목), 정신 건강 관리를 위한 심리상담 전문가 연계 마음건강 케어 프로그램 상시 운영 (2025 안전보건 정보공개 자료 10쪽 임직원 건강증진 프로그램 항목) — 이용 횟수·비용 지원 범위 미기재', 52),
  (@comp_id, 'clinic', '헬스케어센터', NULL, 'health',
   'est', NULL, TRUE, '헬스케어센터 (공식 채용 사이트 문화 페이지 Benefits 건강 항목), 사내 건강관리실(Health care center) 운영 · 체성분, 당화혈색소, 콜레스테롤, 스트레스 측정 장비 구축 (2025 안전보건 정보공개 자료 10쪽 임직원 웰니스 항목) — 운영 시간·의료 인력 상주 여부 미기재', 53),
  (@comp_id, 'fitness', '임직원 걷기운동 프로그램 (LF랑 걷자)', NULL, 'health',
   'est', NULL, TRUE, '신체 건강을 위해 임직원 걷기운동 프로그램(LF랑 걷자, 10월 시행) (2025 안전보건 정보공개 자료 10쪽 임직원 건강증진 프로그램 항목) — 운영 주기·참여 혜택 미기재', 54),

  -- ── 성장 · 교육 (growth) — 정본 Benefits 06 · 2026-06-30 보도자료 ──
  (@comp_id, 'lang', '어학 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학 지원 (공식 채용 사이트 문화 페이지 Benefits 성장 항목) — 지원 방식·지원 한도 미기재', 60),
  (@comp_id, 'conference', '외부교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '외부교육 지원 (공식 채용 사이트 문화 페이지 Benefits 성장 항목) — 지원 대상 교육·비용 지원 범위 미기재', 61),
  (@comp_id, 'mba', '사내외 MBA 지원', NULL, 'growth',
   'est', NULL, TRUE, '사내외 MBA 지원 (공식 채용 사이트 문화 페이지 Benefits 성장 항목) — 지원 대상·지원 범위 미기재', 62),
  (@comp_id, 'edu_support', '사내 세미나 운영 · 자율 성장 클래스 LF ON&OFF', NULL, 'growth',
   'est', NULL, TRUE, '사내 세미나 운영 (공식 채용 사이트 문화 페이지 Benefits 성장 항목), 임직원들은 매월 선정되는 교육·조직문화 키워드에 따라 개설되는 다양한 클래스에 자유롭게 참여, 외부 전문가 특강 · 트렌드 세미나 · 전시·공연 등 다양한 문화·예술 프로그램 (2026-06-30 공식 보도자료 LF ON&OFF 항목) — 운영 횟수·참여 비용 미기재', 63),

  -- ── 휴가 (time_off) — 정본 LifeStyle 01 ──
  (@comp_id, 'leave_general', '전사휴무제도 · 연중 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '샌드위치 휴가 고민없이 매년 함께 쉬는 전사휴무제도, 일과 휴식의 밸런스를 위한 연중 휴가 (공식 채용 사이트 문화 페이지 LifeStyle 휴식 항목) — 본인 휴가 차감 여부·일수·유급 여부 미기재', 70),

  -- ── 근무 유연성 (flexibility) — 정본 LifeStyle 02 · 04 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제도', NULL, 'flexibility',
   'est', NULL, TRUE, '상황에 맞게 출퇴근시간을 조정하여 하루 근무시간을 유지하는 시차출퇴근제도 (공식 채용 사이트 문화 페이지 LifeStyle 출퇴근 항목), 8-5시 · 9-6시 · 10-7시 근무 중 선택 가능 · 시차출퇴근제 사용자 230명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무 미기재', 80),
  (@comp_id, 'pc_off', 'PC OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC OFF 제도 (공식 채용 사이트 문화 페이지 LifeStyle 퇴근 후의 삶 항목) — 적용 시간·대상 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
